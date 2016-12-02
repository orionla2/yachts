Migration tool
==============

1. Get current database dump
----------------------------
Gets postgres database dump by means of `pg_dump` command
```
./get-dump.sh
```

2. Sqitch migration tool operations
-----------------------------------
Run *./service.sh*, make followinf commands:
```
cd ym-dev
git-ident.sh
``` 
In ym-dev folder you can run `sqitch` program.


```
sqitch status
```
	shows current migration status


Files used:
*schema-actualize.sh* - executes during normal docker-compose startup, downloads actual migration bundle and apply it.
