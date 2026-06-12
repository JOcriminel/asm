# SQL Server Docker Deployment

## Directory Structure

```text
asm-production/
├── backups/
├── data/
├── secrets/
└── sqlserver/
```

## Create Folders

```bash
#!/bin/bash

mkdir -p asm-production/data
mkdir -p asm-production/sqlserver
mkdir -p asm-production/backups
mkdir -p asm-production/secrets

echo "Folders created successfully."
```

## docker-compose.yml

```yaml
services:
  sqlsrv:
    container_name: sqlsrv
    image: mcr.microsoft.com/mssql/server:2022-CU14-ubuntu-20.04
    restart: always

    environment:
      ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: "P5v9yast34Iy9qU"

    ports:
      - "1433:1433"

    volumes:
      - ./asm-production/data:/var/opt/mssql/data
      - ./asm-production/sqlserver:/var/opt/mssql/sqlserver
      - ./asm-production/backups:/var/opt/mssql/backups
      - ./asm-production/secrets:/var/opt/mssql/secrets
```

## Start Container

```bash
docker compose up -d
```

## Verify Volumes

```bash
docker logs -f sqlsrv
```
