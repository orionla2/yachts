-- Deploy t_file
-- requires: types

BEGIN;

--
-- Name: file; Type: TABLE; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE file (
    id integer NOT NULL,
    type character varying(45) NOT NULL,
    url text NOT NULL,
    y_id integer NOT NULL
);


ALTER TABLE file OWNER TO postgres;

--
-- Name: file_id_seq; Type: SEQUENCE; Schema: my_yacht; Owner: postgres
--

CREATE SEQUENCE file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE file_id_seq OWNER TO postgres;

--
-- Name: file_id_seq; Type: SEQUENCE OWNED BY; Schema: my_yacht; Owner: postgres
--

ALTER SEQUENCE file_id_seq OWNED BY file.id;
ALTER TABLE ONLY file ALTER COLUMN id SET DEFAULT nextval('file_id_seq'::regclass);
ALTER TABLE ONLY file
    ADD CONSTRAINT pk_id_file PRIMARY KEY (id);
ALTER TABLE ONLY file
    ADD CONSTRAINT fk_file_yacht FOREIGN KEY (y_id) REFERENCES yacht(id);

--
-- Name: file; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT ON TABLE file TO user_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE file TO manager;
GRANT SELECT ON TABLE file TO guest;


--
-- Name: file_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE file_id_seq TO guest;



COMMIT;
