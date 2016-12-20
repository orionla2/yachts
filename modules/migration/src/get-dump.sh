#!/bin/bash
docker run -ti --rm --network="container:postgresql" \
    -e PGHOST=postgresql \
	--entrypoint pg_dump \
	mapleukraine/yacht-migration:1.1.0