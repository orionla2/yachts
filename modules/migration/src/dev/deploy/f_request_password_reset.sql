-- Deploy f_request_password_reset
-- requires: types

BEGIN;

SET search_path = my_yacht, pg_catalog;
CREATE OR REPLACE FUNCTION request_password_reset(email text) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
  tok uuid;
begin
  delete from auth.tokens
  where token_type = 'reset'
        and tokens.email = request_password_reset.email;

  select gen_random_uuid() into tok;
  insert into auth.tokens (token, token_type, email)
  values (tok, 'reset', request_password_reset.email);
  perform pg_notify('reset',
                    json_build_object(
                        'email', request_password_reset.email,
                        'token', tok,
                        'token_type', 'reset'
                    )::text
  );
end;
$$;


ALTER FUNCTION my_yacht.request_password_reset(email text) OWNER TO postgres;

GRANT ALL ON FUNCTION request_password_reset(email text) TO manager;
GRANT ALL ON FUNCTION request_password_reset(email text) TO user_role;


COMMIT;
