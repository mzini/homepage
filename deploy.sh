#!/bin/bash

echo "1. git upload ..."
echo "----------------------------------------------------------------------"
git add events/* projects/* papers/* software/*
git commit -a -m "content update at `date`"

echo "2. compiling ..."
echo "----------------------------------------------------------------------"
homepage build

echo "3. deploying ..."
echo "----------------------------------------------------------------------"
homepage deploy


