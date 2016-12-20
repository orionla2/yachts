-- Deploy t_yacht_description
-- requires: types
-- requires: t_yacht

BEGIN;

CREATE TABLE my_yacht.yacht_description (
  yacht_id integer NOT NULL,
  category character varying(126) NOT NULL,
  content text,
  id integer NOT NULL
);


ALTER TABLE my_yacht.yacht_description OWNER TO postgres;

--
-- Name: yacht_description_id_seq; Type: SEQUENCE; Schema: my_yacht; Owner: postgres
--

CREATE SEQUENCE my_yacht.yacht_description_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

ALTER TABLE my_yacht.yacht_description_id_seq OWNER TO postgres;

--
-- Name: yacht_description_id_seq; Type: SEQUENCE OWNED BY; Schema: my_yacht; Owner: postgres
--

ALTER SEQUENCE my_yacht.yacht_description_id_seq OWNED BY my_yacht.yacht_description.id;
ALTER TABLE ONLY my_yacht.yacht_description ALTER COLUMN id SET DEFAULT nextval('my_yacht.yacht_description_id_seq'::regclass);
SELECT pg_catalog.setval('my_yacht.yacht_description_id_seq', 1, false);
ALTER TABLE ONLY my_yacht.yacht_description
  ADD CONSTRAINT yacht_description_pkey PRIMARY KEY (id);
CREATE INDEX yacht_id_index ON my_yacht.yacht_description USING btree (yacht_id);
ALTER TABLE ONLY my_yacht.yacht_description
  ADD CONSTRAINT yacht_fk FOREIGN KEY (yacht_id) REFERENCES my_yacht.yacht(id) ON UPDATE CASCADE ON DELETE CASCADE;

GRANT SELECT ON TABLE my_yacht.yacht_description TO user_role;
GRANT SELECT,INSERT,UPDATE ON TABLE my_yacht.yacht_description TO manager;
GRANT SELECT ON TABLE my_yacht.yacht_description TO guest;

-- GRANT ALL ON SEQUENCE my_yacht.yacht_description_id_seq TO guest;
GRANT USAGE, SELECT ON SEQUENCE my_yacht.yacht_description_id_seq TO manager;
/*
CREATE TABLE my_yacht.yacht_description
(
   yacht_id integer NOT NULL,
   category character varying(126) NOT NULL,
   content text,
   CONSTRAINT p_key PRIMARY KEY (yacht_id, category),
   CONSTRAINT yacht_fk FOREIGN KEY (yacht_id) REFERENCES my_yacht.yacht (id) ON UPDATE CASCADE ON DELETE CASCADE
)
WITH (
  OIDS = FALSE
)
;

ALTER TABLE my_yacht.yacht_description
  OWNER TO postgres;
-- CREATE INDEX yacht_id_index
--   ON my_yacht.yacht_description (yacht_id ASC NULLS LAST);


CREATE INDEX yacht_id_index
  ON my_yacht.yacht_description
  USING btree
  (yacht_id);
*/

COMMIT;
