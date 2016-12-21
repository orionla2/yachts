-- Deploy f_getid
-- requires: types

BEGIN;

SET search_path = my_yacht, pg_catalog;
CREATE OR REPLACE FUNCTION getid(email text) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  ret_id int;
begin
	return(SELECT id FROM my_yacht.user WHERE my_yacht.user.email = getId.email);
end
$$;


ALTER FUNCTION my_yacht.getid(email text) OWNER TO postgres;

COMMIT;
