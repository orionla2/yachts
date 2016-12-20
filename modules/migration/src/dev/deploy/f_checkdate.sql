-- Deploy f_checkdate
-- requires: types

BEGIN;

SET search_path = my_yacht, pg_catalog;

--
-- Name: checkdate(timestamp with time zone, timestamp with time zone, integer); Type: FUNCTION; Schema: my_yacht; Owner: postgres
--

CREATE OR REPLACE FUNCTION checkdate(startdate timestamp with time zone, enddate timestamp with time zone, preperation integer) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  temp_id int;
  ch_st_date int;
  ch_end_date int;
  _startDate timestamp with time zone;
  _endDate timestamp with time zone;
  _prepTime text = preperation::text || ' hour';
begin
   _startDate = startdate - (_prepTime || ' hour')::interval;
   _endDate = enddate + (_prepTime || ' hour')::interval;
   if startDate >= endDate THEN
	RAISE unique_violation USING MESSAGE = 'Start date lower than End date';
   END if;

   select id from my_yacht.booking where start_date < _startDate order by start_date desc limit 1 into temp_id;

   if temp_id is null THEN
	ch_st_date:= 1;
   ELSE
	select 1 from my_yacht.booking where id = temp_id AND end_date <= _startDate order by start_date limit 1 into ch_st_date;
   END if;

   select id from my_yacht.booking where end_date >= _startDate order by start_date asc limit 1 into temp_id;

   if temp_id is null THEN
	ch_end_date:= 1;
   ELSE
	select 1 from my_yacht.booking where id = temp_id AND start_date >= _endDate order by start_date limit 1 into ch_end_date;
   END if;

   if ch_st_date = 1 AND ch_end_date = 1 THEN
	return true;
   ELSE
	return false;
   END if;
   --RAISE unique_violation USING MESSAGE = 'Logged in. User ID: ' || sDate;
end
$$;


ALTER FUNCTION my_yacht.checkdate(startdate timestamp with time zone, enddate timestamp with time zone, preperation integer) OWNER TO postgres;


COMMIT;
