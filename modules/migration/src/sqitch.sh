#!/bin/bash
docker run -ti --rm --network="container:postgresql" \
	-v $(pwd)/dev:/src schema_setup
