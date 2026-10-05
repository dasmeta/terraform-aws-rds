#!/usr/bin/env python3
"""Check rendered mocked plans and optionally test their filters with AWS's parser."""

import argparse
import json
from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[1]
FIXTURES = json.loads((ROOT / "tests/fixtures/slow-query-logs.json").read_text())
LEGACY_PATTERNS = {
    "postgres": '[day, time, log="*:LOG:", containsDuration="duration:", duration=*, unit, statement="statement:*"]',
    "mysql": '[start, time="Time:", date, separatorOne, userHost, username, separatorTwo, ip, id, idNumber, separatorThree, queryTime, duration, ...]',
}


def execute(arguments):
    result = subprocess.run(arguments, cwd=ROOT, text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr or result.stdout)
    return result.stdout


def verify_plans(events):
    plans = [event for event in events if event.get("type") == "test_plan"]
    assert len(plans) == 10, "Expected all ten mocked test plans"
    filters_to_test = []
    for event in plans:
        name = event["@testrun"]
        resources = event["test_plan"]["resource_changes"]
        filters = [r for r in resources if r["type"] == "aws_cloudwatch_log_metric_filter"]
        counts = [r for r in filters if r["change"]["after"]["name"].endswith("-RDSSlowQueryCount")]
        durations = [r for r in filters if r["change"]["after"]["name"].endswith("-RDSSlowQueries")]
        alarms = [r for r in resources if r["type"] == "aws_cloudwatch_metric_alarm"
                  and "Excessive Slow Queries" in r["change"]["after"]["alarm_name"]]
        disabled = name == "disabled_slow_queries_create_no_filters_or_alarm"
        assert len(counts) == (0 if disabled else 1), (name, "Count filters must select one query log")
        expected_durations = 0 if disabled else (2 if name == "auxiliary_log_exports_do_not_change_query_log_selection" else 1)
        assert len(durations) == expected_durations, (name, "Legacy duration filters must be preserved")
        assert len(alarms) == (0 if disabled or name == "disabled_alarms_keep_query_telemetry" else 1), name
        for resource in counts:
            after = resource["change"]["after"]
            metric = after["metric_transformation"][0]
            assert metric["value"] == "1" and metric["default_value"] == "0" and metric["unit"] == "Count", name
            assert metric["namespace"] == "RDSLogBasedMetrics", name
            engine = "postgres" if after["log_group_name"].endswith("/postgresql") else "mysql"
            assert after["log_group_name"].endswith("/postgresql" if engine == "postgres" else "/slowquery"), name
            threshold = 1500 if name == "fractional_seconds_become_milliseconds" else 3000
            filters_to_test.append((name, after["pattern"], engine, threshold))
        for resource in durations:
            after = resource["change"]["after"]
            metric = after["metric_transformation"][0]
            engine = "postgres" if "postgres" in after["pattern"] or 'containsDuration="duration:"' in after["pattern"] else "mysql"
            assert after["pattern"] == LEGACY_PATTERNS[engine], (name, "Legacy filter changed")
            assert metric["value"] == "$duration" and metric["default_value"] == "0", name
            assert metric["unit"] == ("Milliseconds" if engine == "postgres" else "Seconds"), name
        for resource in alarms:
            after = resource["change"]["after"]
            metric = after["metric_query"][0]["metric"][0]
            assert metric["metric_name"] == "example-RDSSlowQueryCount", name
            overridden = name == "explicit_overrides_keep_precedence"
            assert metric["stat"] == ("Maximum" if overridden else "Sum"), name
            assert after["threshold"] == (9 if overridden else 5), name
            assert metric["period"] == (600 if overridden else 300), name
            assert after["comparison_operator"] == ("GreaterThanThreshold" if overridden else "GreaterThanOrEqualToThreshold"), name
        print(f"PASS rendered plan: {name}")
    return filters_to_test


def verify_aws_filters(filters, profile, region):
    checked = set()
    cases = 0
    for name, pattern, engine, threshold in filters:
        key = (pattern, engine, threshold)
        if key in checked:
            continue
        checked.add(key)
        fixtures = FIXTURES[engine]
        messages = [f["message"].replace("{threshold}", str(threshold))
                    .replace("{below_threshold}", str(threshold - 0.001)) for f in fixtures]
        expected = {i + 1 for i, f in enumerate(fixtures) if f["matches"]}
        arguments = ["aws", "logs", "test-metric-filter", "--region", region,
                     "--filter-pattern", pattern, "--log-event-messages", json.dumps(messages),
                     "--output", "json", "--no-cli-pager"]
        if profile:
            arguments.extend(["--profile", profile])
        result = json.loads(execute(arguments))
        actual = {match["eventNumber"] for match in result.get("matches", [])}
        assert actual == expected, (name, "AWS filter fixture mismatch", sorted(expected), sorted(actual))
        cases += len(fixtures)
        print(f"PASS AWS parser: {engine}, {threshold}ms configuration, {len(fixtures)} fixtures")
    print(f"Verified {cases} fixture cases; no metrics published or infrastructure changed.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--plans-json", type=Path, help="Reuse terraform test -json -verbose output")
    parser.add_argument("--offline", action="store_true", help="Check mocked plans without calling AWS")
    parser.add_argument("--profile", help="AWS profile with logs:TestMetricFilter permission")
    parser.add_argument("--region", default="eu-central-1")
    args = parser.parse_args()
    text = args.plans_json.read_text() if args.plans_json else execute([
        "terraform", "test", "-filter=tests/slow-query-count.tftest.hcl", "-json", "-verbose"])
    events = [json.loads(line) for line in text.splitlines() if line.strip()]
    summaries = [e["test_summary"] for e in events if e.get("type") == "test_summary"]
    assert summaries and summaries[-1]["status"] == "pass", "Native tests must pass before filter verification"
    filters = verify_plans(events)
    if not args.offline:
        verify_aws_filters(filters, args.profile, args.region)


if __name__ == "__main__":
    main()
