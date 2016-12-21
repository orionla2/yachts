-- Revert types

BEGIN;

DROP TYPE IF EXISTS auth.jwt_claims CASCADE;
DROP TYPE IF EXISTS public.token_type_enum CASCADE;

COMMIT;
