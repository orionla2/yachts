#!/bin/bash
docker run -ti --rm --network="container:postgrest_test" \
	-v $(pwd)/dev:/src postgrestdb_schema_setup
