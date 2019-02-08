#!/usr/bin/env bash

set -ex

cd "$(dirname "$0")"

aws rds-data execute-sql \
--db-cluster-or-instance-arn "arn:aws:rds:us-east-1:361301349588:cluster:efng" \
--schema "mysql" \
--aws-secret-store-arn "arn:aws:secretsmanager:us-east-1:361301349588:secret:efng/aurora-uD1DRL" \
--region us-east-1 \
--sql-statements "drop database efng; create database efng;" \
--profile efng

aws rds-data execute-sql \
--db-cluster-or-instance-arn "arn:aws:rds:us-east-1:361301349588:cluster:efng" \
--schema "mysql" \
--aws-secret-store-arn "arn:aws:secretsmanager:us-east-1:361301349588:secret:efng/aurora-uD1DRL" \
--region us-east-1 \
--sql-statements "$(cat ../database/migration/V1__initial_setup.sql)" \
--database "efng" \
--profile efng

aws rds-data execute-sql \
--db-cluster-or-instance-arn "arn:aws:rds:us-east-1:361301349588:cluster:efng" \
--schema "mysql" \
--aws-secret-store-arn "arn:aws:secretsmanager:us-east-1:361301349588:secret:efng/aurora-uD1DRL" \
--region us-east-1 \
--sql-statements "$(cat ../database/migration/V2__initial_procedures.sql)" \
--database "efng" \
--profile efng

aws rds-data execute-sql \
--db-cluster-or-instance-arn "arn:aws:rds:us-east-1:361301349588:cluster:efng" \
--schema "mysql" \
--aws-secret-store-arn "arn:aws:secretsmanager:us-east-1:361301349588:secret:efng/aurora-uD1DRL" \
--region us-east-1 \
--sql-statements "$(cat ../database/migration/V3__populate_levels.sql)" \
--database "efng" \
--profile efng

aws rds-data execute-sql \
--db-cluster-or-instance-arn "arn:aws:rds:us-east-1:361301349588:cluster:efng" \
--schema "mysql" \
--aws-secret-store-arn "arn:aws:secretsmanager:us-east-1:361301349588:secret:efng/aurora-uD1DRL" \
--region us-east-1 \
--sql-statements "$(cat ../database/migration/V4__populate_levels.sql)" \
--database "efng" \
--profile efng

aws rds-data execute-sql \
--db-cluster-or-instance-arn "arn:aws:rds:us-east-1:361301349588:cluster:efng" \
--schema "mysql" \
--aws-secret-store-arn "arn:aws:secretsmanager:us-east-1:361301349588:secret:efng/aurora-uD1DRL" \
--region us-east-1 \
--sql-statements "$(cat ../database/migration/V5__populate_levels.sql)" \
--database "efng" \
--profile efng

aws rds-data execute-sql \
--db-cluster-or-instance-arn "arn:aws:rds:us-east-1:361301349588:cluster:efng" \
--schema "mysql" \
--aws-secret-store-arn "arn:aws:secretsmanager:us-east-1:361301349588:secret:efng/aurora-uD1DRL" \
--region us-east-1 \
--sql-statements "$(cat ../database/migration/V6__populate_levels.sql)" \
--database "efng" \
--profile efng

aws rds-data execute-sql \
--db-cluster-or-instance-arn "arn:aws:rds:us-east-1:361301349588:cluster:efng" \
--schema "mysql" \
--aws-secret-store-arn "arn:aws:secretsmanager:us-east-1:361301349588:secret:efng/aurora-uD1DRL" \
--region us-east-1 \
--sql-statements "$(cat ../database/migration/V7__populate_levels.sql)" \
--database "efng" \
--profile efng
