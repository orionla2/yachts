-- Deploy t_status
-- requires: schema_pure

BEGIN;

-- Table: my_yacht.status

-- DROP TABLE my_yacht.status;

CREATE TABLE my_yacht.status
(
  id integer NOT NULL,
  title character varying(126),
  CONSTRAINT id_pk PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE my_yacht.status
  OWNER TO postgres;

--
-- Name: status; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT ON TABLE my_yacht.status TO manager;
GRANT SELECT ON TABLE my_yacht.status TO user_role;
GRANT SELECT ON TABLE my_yacht.status TO guest;


insert into my_yacht.status (id, title) values (1, 'Active');
insert into my_yacht.status (id, title) values (2, 'Pending');
insert into my_yacht.status (id, title) values (3, 'Approved');
insert into my_yacht.status (id, title) values (4, 'Cancelled');
insert into my_yacht.status (id, title) values (5, 'Completed');

COMMIT;
