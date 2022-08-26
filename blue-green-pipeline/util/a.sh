#!/usr/bin/env bash
echo 1
echo ${1:-foo}
if [ ${1:-no} = "no" ]
then
    echo aaaa
else
    echo ${1:-no}
fi