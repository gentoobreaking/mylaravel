#!/bin/sh
export my_version='v0.1'

docker build --squash -t myweb:"${my_version}" . --no-cache

