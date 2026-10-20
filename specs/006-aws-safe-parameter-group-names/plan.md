# Implementation Plan: AWS-safe parameter group names

**Branch**: `fix/mariadb-parameter-group-naming` | **Date**: 2026-10-20 | **Spec**: [spec.md](./spec.md)

## Summary

Separate the AWS parameter group family from the custom resource name. Retain the version-family suffix for PostgreSQL and Aurora PostgreSQL, where the module already needs family-specific names for major upgrades. For other engines, use the engine name as the suffix, preserving existing MariaDB/MySQL names while excluding periods from custom names.

## Technical Context

- **Module**: `dasmeta/rds/aws`, Terraform root wrapper.
- **Current behavior**: `local.parameter_group_name` uses `local.parameter_group_family` for every engine.
- **Compatibility target**: TeamPlus MariaDB 11.4 keeps `rds-teamplus-main-mariadb`; `local.parameter_group_family` remains `mariadb11.4` for AWS resource family selection.
- **Affected files**: `locals.tf`, `README.md`, the related PostgreSQL naming spec, this feature package, and `.specify/feature.json`.
- **Public interface**: No variables, outputs, resource addresses, or provider constraints change.
- **AWS naming constraint**: Custom parameter group names permit letters, numbers, and hyphens only. Source: [AWS RDS DB parameter groups](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.Creating.html).

## Design

Update only the shared `local.parameter_group_name` expression. Select `local.parameter_group_family` when `local.is_postgres_engine` is true; otherwise select `var.engine`. Keep `local.parameter_group_family` unchanged, and keep all instance and cluster resources referencing the shared name local. This preserves PostgreSQL upgrade behavior and restores the historical non-PostgreSQL name shape.

Update the README upgrade note to say that PostgreSQL names include the parameter group family, while other engine names retain the engine suffix. Keep the existing warning that a PostgreSQL family change can replace a parameter group.

## Constitution Check

- [x] One module responsibility; no interface widening or breaking change.
- [x] Existing resource addresses and the DB/cluster name relationship stay unchanged.
- [x] No new provider capability or minimum-version change.
- [x] README is updated because consumer-visible naming behavior is clarified.
- [x] AWS naming constraints use the primary AWS documentation source.

## Validation

- Review the expression against the MariaDB 11.4, MySQL 8.0.35, PostgreSQL 17, and Aurora PostgreSQL 17.7 examples in the specification.
- Review the shared name references in `main.tf` and ensure the cluster suffix remains `-cluster`.
- Run `git diff --check`.
- The repository's CI remains responsible for the module test and validation workflows; this task does not add or run tests.

**Completed locally (2026-10-20)**: `terraform fmt -check locals.tf` and `git diff --check` passed. Automated Terraform tests were not run locally; PR CI is pending.

## Risks and Rollback

The name expression changes from family-based to engine-based for non-PostgreSQL consumers. This deliberately preserves their pre-family-naming names and avoids a resource rename on upgrade. PostgreSQL behavior is unchanged. Rollback is a source revert; no state migration is expected.
