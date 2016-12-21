-- Deploy f_current_email
-- requires: types

BEGIN;

SET search_path = auth, pg_catalog;
CREATE OR REPLACE FUNCTION current_email() RETURNS text
    LANGUAGE plpgsql
    AS $$
begin
  return current_setting('postgrest.claims.email');
end;
$$;

ALTER FUNCTION auth.current_email() OWNER TO postgres;


COMMIT;
