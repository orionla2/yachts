#!/bin/bash
cd /tmp
mkdir ymigration
cd ymigration
git clone $SQITCH_BUNDLE_REPO .
sqitch deploy
cd ..
rm -R ymigration
