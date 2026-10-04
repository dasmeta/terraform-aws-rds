# Effective storage alarm
Fields: existing human-facing name, AWS/RDS metric source, one resource identifier dimension, period seconds, threshold bytes, equation, statistic. Aurora includes provisioned-member local storage; standalone includes allocated storage. One definition is forwarded to the existing renderer, preserving SNS routing.
