-- Deploy types
-- requires: schema_pure

BEGIN;

SET search_path = auth, pg_catalog;
CREATE TYPE jwt_claims AS (
	role text,
	email text,
	exp integer
);
ALTER TYPE jwt_claims OWNER TO postgres;


SET search_path = public, pg_catalog;
CREATE TYPE token_type_enum AS ENUM (
    'validation',
    'reset'
);
ALTER TYPE token_type_enum OWNER TO postgres;

COMMIT;
