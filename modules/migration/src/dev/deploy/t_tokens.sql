-- Deploy t_tokens
-- requires: types

BEGIN;

SET search_path = auth, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: tokens; Type: TABLE; Schema: auth; Owner: postgres
--

CREATE TABLE tokens (
    token uuid NOT NULL,
    token_type public.token_type_enum NOT NULL,
    email text NOT NULL,
    created_at timestamp with time zone DEFAULT ('now'::text)::date NOT NULL
);


ALTER TABLE tokens OWNER TO postgres;
ALTER TABLE ONLY tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (token);
ALTER TABLE ONLY tokens
    ADD CONSTRAINT tokens_email_fkey FOREIGN KEY (email) REFERENCES my_yacht."user"(email) ON UPDATE CASCADE ON DELETE CASCADE;

GRANT INSERT ON TABLE tokens TO guest;

COMMIT;
