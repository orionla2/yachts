-- Deploy f_notify
-- requires: types

BEGIN;

SET search_path = my_yacht, pg_catalog;
CREATE OR REPLACE FUNCTION notify(message text) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
  msg text;
  _role name;
begin
  SELECT pg_notify('messanger',message) into msg;
end;
$$;


ALTER FUNCTION my_yacht.notify(message text) OWNER TO postgres;

COMMIT;
