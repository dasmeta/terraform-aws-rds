# Implementation Plan: Writer Read IOPS Alarm

**Branch**: `006-writer-read-iops` | **Date**: 2026-11-06 | **Spec**: [spec.md](spec.md)

## Summary

Scope Aurora ReadIOPS alarms to the current WRITER role while preserving existing instance behavior, threshold overrides, and notification routing. The Sela production pin must use a published revision containing this change.

## Technical Context

**Language/Version**: Terraform HCL 1.5+
**Primary Dependencies**: AWS RDS metrics; dasmeta/monitoring/aws alerts module 1.3.5
**Storage**: N/A
**Testing**: Terraform format and plan checks, targeted static assertions, historical CloudWatch metric replay when credentials are available
**Target Platform**: AWS Aurora PostgreSQL and existing RDS instances
**Project Type**: Terraform module
**Performance Goals**: No reader-only false alarms; writer threshold unchanged
**Constraints**: Preserve alarm resource identity and unrelated dimensions
**Scale/Scope**: One shared alarm definition and one production caller

## Constitution Check

The repository constitution is an uncustomized Spec Kit template. No project-specific gate is defined. The change preserves current module interfaces and avoids changing unrelated alarms.

## Project Structure

- `alerts.tf`: shared ReadIOPS alarm definition
- `tests/`: existing plan verification and a focused dimension assertion
- `specs/006-writer-read-iops/`: design and verification evidence

## Design

Select `{ DBClusterIdentifier = var.identifier, Role = "WRITER" }` for the Aurora ReadIOPS alarm. Retain `local.alarms_metric_filters` for non-Aurora. Existing alarm name and threshold do not change, so the remote monitoring alarm should update in place. AWS documents role aggregation as following instance role, including after failover.

## Validation and Rollback

Validate HCL formatting and inspect the planned alarm dimension change. Replay November 5 metric data when production credentials are available. Roll back by restoring the previous module revision in the caller; expect reader-inclusive noise to return.
