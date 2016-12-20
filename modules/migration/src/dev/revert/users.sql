-- Revert users

BEGIN;

DROP OWNED BY manager;
DROP ROLE IF EXISTS manager;
DROP OWNED BY user_role;
DROP ROLE IF EXISTS user_role;
DROP OWNED BY authenticator;
DROP ROLE IF EXISTS authenticator;
DROP OWNED BY guest;
DROP ROLE IF EXISTS guest;

COMMIT;
