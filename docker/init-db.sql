-- Kittywork Initial Database Setup
-- This script is executed automatically by PostgreSQL container on first startup
-- It serves as a bootstrap for additional configuration

-- Set timezone for consistent timestamps
SET timezone = 'UTC';

-- Create extension for UUID support (if not using Liquibase)
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Note: All table creation is handled by Liquibase migrations
-- This file is reserved for any runtime setup (e.g., roles, grants, functions)
-- See: src/main/resources/db/changelog/db.changelog-master.yaml

-- Example: Create a read-only role for analytics (optional)
-- CREATE ROLE analytics_user WITH LOGIN PASSWORD 'analytics_password';
-- GRANT CONNECT ON DATABASE kittywork TO analytics_user;
-- GRANT USAGE ON SCHEMA public TO analytics_user;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_user;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO analytics_user;
