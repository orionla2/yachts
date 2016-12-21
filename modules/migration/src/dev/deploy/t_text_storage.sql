-- Deploy t_text_storage
-- requires: schema_pure

BEGIN;

SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE my_yacht.text_storage
(
  id integer NOT NULL,
  category character varying(126) NOT NULL,
  content text,
  CONSTRAINT pk_id PRIMARY KEY (id)
)
WITH (
OIDS = FALSE
)
;
ALTER TABLE my_yacht.text_storage
  OWNER TO postgres;

-- CREATE INDEX category_index
--   ON my_yacht.text_storage (category ASC NULLS LAST);

CREATE INDEX category_index
  ON my_yacht.text_storage
  USING btree
  (category COLLATE pg_catalog."default");


CREATE SEQUENCE text_storage_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;


ALTER TABLE text_storage_id_seq OWNER TO postgres;

--
-- Name: booking_id_seq; Type: SEQUENCE OWNED BY; Schema: my_yacht; Owner: postgres
--

ALTER SEQUENCE text_storage_id_seq OWNED BY my_yacht.text_storage.id;
ALTER TABLE ONLY text_storage ALTER COLUMN id SET DEFAULT nextval('text_storage_id_seq'::regclass);


COMMIT;
