#!/bin/sh
arm-none-linux-gnueabi-readelf -a $1 | grep "Shared library:"
