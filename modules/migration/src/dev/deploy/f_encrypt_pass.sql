-- Deploy f_encrypt_pass
-- requires: types

BEGIN;

SET search_path = auth, pg_catalog;
CREATE OR REPLACE FUNCTION encrypt_pass() RETURNS trigger
LANGUAGE plpgsql
AS $$
begin
  if tg_op = 'INSERT' or new.password <> old.password then
    new.password = public.crypt(new.password, public.gen_salt('bf'));
  end if;
  return new;
end
$$;


ALTER FUNCTION auth.encrypt_pass() OWNER TO postgres;


COMMIT;
