-- Deploy schema_pure
-- requires: clearance

BEGIN;

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

COMMENT ON DATABASE postgres IS 'default administrative connection database';

CREATE SCHEMA auth;
ALTER SCHEMA auth OWNER TO postgres;

CREATE SCHEMA my_yacht;
ALTER SCHEMA my_yacht OWNER TO postgres;

COMMIT;
