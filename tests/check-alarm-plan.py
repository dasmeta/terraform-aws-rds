#!/usr/bin/env python3
"""Check that pending DB changes do not defer alarm metric account IDs."""
import json
from pathlib import Path
import subprocess
import sys


def check_plan(plan):
    changes = plan["resource_changes"]
    assert any(
        resource["type"] in {"aws_rds_cluster", "aws_db_instance"}
        and "create" in resource["change"]["actions"]
        for resource in changes
    ), "Regression fixture must include a pending database creation"
    alarms = [r for r in changes if r["type"] == "aws_cloudwatch_metric_alarm"]
    assert len(alarms) == 8, "Expected all eight Aurora metric alarms"
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
    plans = [event["test_plan"] for event in events if event.get("type") == "test_plan"]
    assert len(plans) == 1, "Terraform must emit the regression plan"
    for plan in plans:
        check_plan(plan)
    print("All eight Aurora metric account IDs are known despite pending DB creation.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
