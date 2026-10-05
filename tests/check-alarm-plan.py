#!/usr/bin/env python3
"""Check that pending DB changes do not defer alarm metric account IDs."""
import json
from pathlib import Path
import subprocess
import sys


def check_plan(plan, expected_alarms):
    changes = plan["resource_changes"]
    assert any(
        resource["type"] in {"aws_rds_cluster", "aws_db_instance"}
        and "create" in resource["change"]["actions"]
        for resource in changes
    ), "Regression fixture must include a pending database creation"
    alarms = [r for r in changes if r["type"] == "aws_cloudwatch_metric_alarm"]
    assert len(alarms) == expected_alarms, f"Expected {expected_alarms} Aurora metric alarms"
    for alarm in alarms:
        queries = alarm["change"]["after"]["metric_query"]
        assert queries and all(
            query.get("account_id") == "000000000000" for query in queries
        ), f"Metric account_id must be known during planning: {alarm['address']}"


def main():
    result = subprocess.run(
        ["terraform", "test", "-filter=tests/alarm-plan.tftest.hcl", "-verbose", "-json"],
        cwd=Path(__file__).resolve().parents[1],
        capture_output=True,
        text=True,
    )
    events = [json.loads(line) for line in result.stdout.splitlines() if line.strip()]
    if result.returncode:
        for event in events:
            if event.get("type") == "diagnostic":
                print(event.get("diagnostic", {}), file=sys.stderr)
        print(result.stderr, file=sys.stderr)
        return result.returncode
    plans = {event["@testrun"]: event["test_plan"] for event in events if event.get("type") == "test_plan"}
    expected = {
        "alarm_account_is_known_with_pending_database": 8,
        "slow_query_account_is_known_with_pending_database": 9,
    }
    assert plans.keys() == expected.keys(), "Terraform must emit both regression plans"
    for name, expected_alarms in expected.items():
        check_plan(plans[name], expected_alarms)
    print("All Aurora alarm account IDs are known despite pending DB creation, with slow-query monitoring disabled and enabled.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
