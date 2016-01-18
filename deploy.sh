#!/bin/bash

HOMEPAGE=dist/build/homepage/homepage

echo "1. git upload ..."
echo "----------------------------------------------------------------------"
git add events/* projects/* papers/* software/*
git commit -a -m "content update at `date`"
git push

echo "2. compiling ..."
echo "----------------------------------------------------------------------"
$HOMEPAGE build

echo "3. deploying ..."
echo "----------------------------------------------------------------------"
$HOMEPAGE deploy


