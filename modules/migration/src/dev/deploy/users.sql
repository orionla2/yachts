-- Deploy users
-- requires: schema_pure

BEGIN;

CREATE ROLE manager;
CREATE ROLE user_role;
CREATE ROLE guest;
CREATE ROLE authenticator LOGIN
ENCRYPTED PASSWORD 'md5b8d79b0dea1de1788ea7dd39fa0ec195'
NOSUPERUSER NOINHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
GRANT guest TO authenticator;
GRANT manager TO authenticator;
GRANT user_role TO authenticator;

GRANT USAGE ON SCHEMA auth TO guest;
GRANT USAGE ON SCHEMA auth TO manager;
GRANT USAGE ON SCHEMA auth TO user_role;

GRANT USAGE ON SCHEMA my_yacht TO guest;
GRANT USAGE ON SCHEMA my_yacht TO manager;
GRANT USAGE ON SCHEMA my_yacht TO user_role;


COMMIT;
