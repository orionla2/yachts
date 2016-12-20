#!/bin/bash
cd /tmp
mkdir ymigration
cd ymigration
ssh-add /root/.ssh/ym_deployment_key.rsa
git clone -b $SQITCH_BUNDLE_BRANCH $SQITCH_BUNDLE_REPO .
echo "Deploy $SQITCH_BUNDLE_BRANCH to change "$([ "$SQITCH_DEPLOY_CHANGE" = "" ] && echo "latest" || echo "$SQITCH_DEPLOY_CHANGE")
sqitch deploy $SQITCH_DEPLOY_CHANGE
cd ..
rm -R ymigration
