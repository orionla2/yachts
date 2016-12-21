#!/bin/bash
docker run -ti --rm --network="container:postgresql" \
    -e PGHOST=postgresql \
    -e SQITCH_BUNDLE_REPO=git@bitbucket.org:mapleukraine/ymigration.git \
    -e SQITCH_BUNDLE_BRANCH=master \
    -e SQITCH_DEPLOY_CHANGE=f_updatebookingstatus \
	-v $(pwd)/../app/:/src \
	--entrypoint /bin/bash \
	mapleukraine/yacht-migration $@

# docker run -ti --rm -e PGHOST=postgresql -e SQITCH_BUNDLE_REPO=git@bitbucket.org:mapleukraine/ymigration.git -e SQITCH_BUNDLE_BRANCH=master -e SQITCH_DEPLOY_CHANGE=f_updatebookingstatus --entrypoint /bin/bash mapleukraine/yacht-migration