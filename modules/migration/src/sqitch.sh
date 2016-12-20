#!/bin/bash
#docker run -ti --rm --network="container:postgrest_test" \
#	-v $(pwd)/dev:/src postgrestdb_schema_setup

docker run -ti --rm --network="container:postgresql" \
    -e PGHOST=postgresql \
    -v $(pwd)/dev:/src \
	mapleukraine/yacht-migration:1.1.0 $@
sudo chown -R andriy:andriy dev/