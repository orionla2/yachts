-- Deploy f_send_validation
-- requires: types

BEGIN;

SET search_path = auth, pg_catalog;
CREATE OR REPLACE FUNCTION send_validation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  tok uuid;
begin
  select gen_random_uuid() into tok;
  insert into auth.tokens (token, token_type, email)
  values (tok, 'validation', new.email);
  perform pg_notify('validate',
                    json_build_object(
                        'email', new.email,
                        'token', tok,
                        'token_type', 'validation'
                    )::text
  );
  return new;
end
$$;


ALTER FUNCTION auth.send_validation() OWNER TO postgres;

COMMIT;
