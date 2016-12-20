-- Deploy t_yacht
-- requires: types

BEGIN;

--
-- Name: yacht; Type: TABLE; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE yacht (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    description text NOT NULL,
    status boolean DEFAULT true NOT NULL
);


ALTER TABLE yacht OWNER TO postgres;

--
-- Name: yacht_id_seq; Type: SEQUENCE; Schema: my_yacht; Owner: postgres
--

CREATE SEQUENCE yacht_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE yacht_id_seq OWNER TO postgres;

--
-- Name: yacht_id_seq; Type: SEQUENCE OWNED BY; Schema: my_yacht; Owner: postgres
--

ALTER SEQUENCE yacht_id_seq OWNED BY yacht.id;
ALTER TABLE ONLY yacht ALTER COLUMN id SET DEFAULT nextval('yacht_id_seq'::regclass);
ALTER TABLE ONLY yacht
    ADD CONSTRAINT pr_id_yacht PRIMARY KEY (id);

--
-- Name: yacht; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT ON TABLE yacht TO user_role;
GRANT SELECT,INSERT,UPDATE ON TABLE yacht TO manager;
GRANT SELECT ON TABLE yacht TO guest;


--
-- Name: yacht_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE yacht_id_seq TO guest;


COMMIT;
