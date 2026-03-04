/*
=============================================================
Create Database and Schemas (PostgreSQL)
=============================================================
Script Purpose:
    This script drops and recreates a database named 'datawarehouse'
    and creates three schemas: bronze, silver, and gold.

WARNING:
    Running this script will drop the entire 'datawarehouse' database
    if it exists. All data will be permanently deleted.
=============================================================
*/

-- STEP 1: Connect to a different database first (postgres)
\c postgres;

-- STEP 2: Terminate existing connections to the target database
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_database WHERE datname = 'datawarehouse') THEN
        PERFORM pg_terminate_backend(pid)
        FROM pg_stat_activity
        WHERE datname = 'datawarehouse'
          AND pid <> pg_backend_pid();
    END IF;
END
$$;

-- STEP 3: Drop database if exists
DROP DATABASE IF EXISTS datawarehouse;

-- STEP 4: Create database
CREATE DATABASE datawarehouse;

-- STEP 5: Connect to the new database
\c datawarehouse;

-- STEP 6: Create schemas
CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;