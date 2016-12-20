-- Deploy f_createbooking
-- requires: types

BEGIN;

SET search_path = my_yacht, pg_catalog;

CREATE OR REPLACE FUNCTION my_yacht.createbooking(
	email text,
	start_date timestamp with time zone,
	end_date timestamp with time zone,
	guests integer,
	firstname text,
	lastname text,
	payment_type text,
	phone text,
	user_id integer,
	y_id integer,
	additionals text)
	RETURNS boolean AS
$BODY$
declare
	ret_id int;
	sum int = 0;
	_extras int;
	_packages int;
	_money int;
	_amount int;
	_usr_id int;
	i json;
	m_id text;
	booking_id int;
	msg text;
begin
	IF createBooking.user_id is null OR createBooking.user_id = 0 THEN
		PERFORM my_yacht.signup(createBooking.firstname, createBooking.lastname, createBooking.email, createBooking.phone, createBooking.phone);
		SELECT my_yacht.getid(email) into ret_id;
		_usr_id := ret_id;
	ELSE
		_usr_id := user_id;
	END IF;
	--RAISE unique_violation USING MESSAGE = 'stop';
	IF (SELECT 1 FROM my_yacht.user WHERE id = _usr_id) THEN
		IF my_yacht.checkdate(start_date,end_date,1) THEN
			FOR i IN SELECT json_array_elements(createBooking.additionals::json)
			LOOP
				select i::json->>'money' into _money::text;
				if _money::int > 0 then
					sum = _money::int + sum::int;
				end if;
			END LOOP;
			insert into my_yacht.booking (y_id,start_date,end_date,user_id,payment,status,payment_type,discount) values
				(createBooking.y_id,createBooking.start_date,createBooking.end_date,_usr_id,sum,1,createBooking.payment_type,0);
			SELECT lastval() INTO booking_id;
			FOR i IN SELECT json_array_elements(createBooking.additionals::json)
			LOOP
				select i::json->>'extrasId' into _extras::text;
				select i::json->>'packageId' into _packages::text;
				select i::json->>'money' into _money::text;
				select i::json->>'amount' into _amount::text;

				insert into my_yacht.additional (booking_id,extras_id,packages_id,guests,amount,money) VALUES
					(booking_id,_extras::int,_packages::int,createBooking.guests,_amount::int,_money::int);
				--RAISE unique_violation USING MESSAGE = _extras || ' ' || _amount;
			END LOOP;

			IF (SELECT user) = 'user_role' THEN
				FOR m_id IN SELECT id FROM my_yacht.user WHERE role = 'manager'
				LOOP
					msg :=  _usr_id || '.' || m_id || '.booking.newBooking.push';
					SELECT pg_notify('messanger',msg) into msg;
					msg :=  _usr_id || '.' || m_id || '.booking.newBooking.email';
					SELECT pg_notify('messanger',msg) into msg;
				END LOOP;
				msg :=  _usr_id || '.' || _usr_id || '.booking.newBooking.email';
				SELECT pg_notify('messanger',msg) into msg;
				msg :=  _usr_id || '.' || _usr_id || '.booking.newBooking.sms';
				SELECT pg_notify('messanger',msg) into msg;
			ELSIF (SELECT user) = 'manager' THEN
				msg :=  _usr_id || '.' || _usr_id || '.booking.newBooking.email';
				SELECT pg_notify('messanger',msg) into msg;
				msg :=  _usr_id || '.' || _usr_id || '.booking.newBooking.push';
				SELECT pg_notify('messanger',msg) into msg;
			END IF;
			return true;
		ELSE
			return false;
		END IF;
	ELSE
		return false;
	END IF;
end
$BODY$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
COST 100;

ALTER FUNCTION my_yacht.createbooking(email text, start_date timestamp with time zone, end_date timestamp with time zone, guests integer, firstname text, lastname text, payment_type text, phone text, user_id integer, y_id integer, additionals text) OWNER TO postgres;


COMMIT;
