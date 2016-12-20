-- Deploy t_download
-- requires: types

BEGIN;

--
-- Name: download; Type: TABLE; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE download (
    id integer NOT NULL,
    tagline character varying(80) NOT NULL,
    filename text NOT NULL
);


ALTER TABLE download OWNER TO postgres;

--
-- Name: download_id_seq; Type: SEQUENCE; Schema: my_yacht; Owner: postgres
--

CREATE SEQUENCE download_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE download_id_seq OWNER TO postgres;

--
-- Name: download_id_seq; Type: SEQUENCE OWNED BY; Schema: my_yacht; Owner: postgres
--

ALTER SEQUENCE download_id_seq OWNED BY download.id;
ALTER TABLE ONLY download ALTER COLUMN id SET DEFAULT nextval('download_id_seq'::regclass);
ALTER TABLE ONLY download
    ADD CONSTRAINT pk_id_download PRIMARY KEY (id);

GRANT SELECT ON TABLE download TO user_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE download TO manager;
GRANT SELECT ON TABLE download TO guest;


--
-- Name: download_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE download_id_seq TO guest;


COMMIT;
