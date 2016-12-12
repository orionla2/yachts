#!/bin/bash
docker run -ti --rm --network="container:postgresql" \
	-v $(pwd)/../app/:/src orionla2/migration_microservice:1.0.2 run_pg_dump.sh