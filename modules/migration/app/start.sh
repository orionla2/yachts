#!/bin/bash

wfi/wait-for-it.sh target_service:5432 -s -t 600  -- /bin/bash schema-actualize.sh
