Migration development folder
============================

Here is the folder to develop migration bundles for sqitch.
See _sqitch_ tutorial here [https://metacpan.org/pod/sqitchtutorial](https://metacpan.org/pod/sqitchtutorial).

To make new migration do following:

I. Initial database deployment
------------------------------
First deployment should init all objects used on development stage.
1. Get the database dump using `get-dump.sh` script.

2. Insert ist content into `deploy/appschema.sql` file between `BEGIN;` and `COMMIT;` commands. 
  Right after schema creation states `CREATE SCHEMA my_yacht; ALTER SCHEMA my_yacht OWNER TO postgres;` put following code:
  ```
  CREATE ROLE manager;
  CREATE ROLE user_role;
  CREATE ROLE authenticator noinherit;
  GRANT manager TO authenticator;
  GRANT user_role TO authenticator;
  ```
  Those commands do not present in database dump but required.

3. `revert/appschema.sql` should drop all objects you create in `deploy/appschema.sql`.
4. `verify/appschema.sql` should check presence of all objects created in `deploy/appschema.sql`.
5. After you made deploy/revert/verify files tag your file. Run docker image by means of `sqitch.sh`. Use `sqitch tag` to see used tags and add next tag. For example:
```
> # sqitch tag

> @v1.0.0-dev1

> @v1.0.0-dev2

> # sqitch tag v1.0.0-dev3 -n 'Tag v1.0.0-dev3'

> Tagged "appschema" with @v1.0.0-dev3
```
6. Make deployment bundle.
```
> # sqitch bundle

> Bundling into bundle

> Writing config

> Writing plan

> Writing scripts

>  + appschema @v1.0.0-dev1 @v1.0.0-dev2 @v1.0.0-dev3
```

 Exit from docker image. Enter to *migration/dev/bundle* folder and issue command 
  ` git commit -am "v1.0.0-dev3" `then `git push origin master`.
   
That's it, you have deployed new version of database schema. After `docker-compose up` database will be built with new schema.

