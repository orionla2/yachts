-- Deploy t_extras
-- requires: types

BEGIN;

--
-- Name: extras; Type: TABLE; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE extras (
    id integer NOT NULL,
    title character varying(45) NOT NULL,
    price numeric(64,2) NOT NULL,
    min_charge integer NOT NULL,
    unit character varying(45) NOT NULL,
    description character varying(255) NOT NULL,
    status boolean DEFAULT true
);


ALTER TABLE extras OWNER TO postgres;

--
-- Name: extras_id_seq; Type: SEQUENCE; Schema: my_yacht; Owner: postgres
--

CREATE SEQUENCE extras_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE extras_id_seq OWNER TO postgres;

--
-- Name: extras_id_seq; Type: SEQUENCE OWNED BY; Schema: my_yacht; Owner: postgres
--

ALTER SEQUENCE extras_id_seq OWNED BY extras.id;
ALTER TABLE ONLY extras ALTER COLUMN id SET DEFAULT nextval('extras_id_seq'::regclass);
ALTER TABLE ONLY extras
    ADD CONSTRAINT pk_id_extras PRIMARY KEY (id);

GRANT SELECT ON TABLE extras TO user_role;
GRANT SELECT,INSERT,UPDATE ON TABLE extras TO manager;
GRANT SELECT ON TABLE extras TO guest;


--
-- Name: extras_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE extras_id_seq TO guest;



COMMIT;
