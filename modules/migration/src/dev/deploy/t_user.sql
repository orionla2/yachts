-- Deploy t_user
-- requires: types

BEGIN;

--
-- Name: user; Type: TABLE; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE "user" (
    id integer NOT NULL,
    firstname character varying(80),
    lastname character varying(80) NOT NULL,
    email character varying(255) NOT NULL,
    mobile character varying(16) NOT NULL,
    password character varying(64) NOT NULL,
    role character varying(45) NOT NULL,
    discount numeric(2,2) DEFAULT 0,
    status boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_email CHECK (((email)::text ~* '^.+@.+\..+$'::text)),
    CONSTRAINT chk_pass CHECK ((length((password)::text) < 65))
);


ALTER TABLE "user" OWNER TO postgres;

--
-- Name: user_id_seq; Type: SEQUENCE; Schema: my_yacht; Owner: postgres
--

CREATE SEQUENCE user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_id_seq OWNER TO postgres;

--
-- Name: user_id_seq; Type: SEQUENCE OWNED BY; Schema: my_yacht; Owner: postgres
--

ALTER SEQUENCE user_id_seq OWNED BY "user".id;
ALTER TABLE ONLY "user" ALTER COLUMN id SET DEFAULT nextval('user_id_seq'::regclass);
ALTER TABLE ONLY "user"
    ADD CONSTRAINT pk_id_yacht PRIMARY KEY (id);
ALTER TABLE ONLY "user"
    ADD CONSTRAINT unq_email UNIQUE (email);

CREATE TRIGGER encrypt_pass BEFORE INSERT OR UPDATE ON "user" FOR EACH ROW EXECUTE PROCEDURE auth.encrypt_pass();

insert into my_yacht."user" (
    firstname, lastname, email, mobile,
    password,
    role, discount, status)
values (
    'dutch', 'oriental', 'dutch@oriental.com', '+971557616155',
    '971553594649',
    'manager', 0.0, TRUE
);

--
-- Name: user; Type: ACL; Schema: my_yacht; Owner: postgres
--

REVOKE ALL ON TABLE "user" FROM postgres;
GRANT SELECT,UPDATE ON TABLE "user" TO user_role;
GRANT SELECT,INSERT,UPDATE ON TABLE "user" TO manager;


--
-- Name: user_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE user_id_seq TO guest;


COMMIT;
