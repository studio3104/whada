#!/bin/bash

DATADIR=$(dirname $0)/../data
if [ ! -d $DATADIR ]; then
    mkdir $DATADIR
fi
cd $DATADIR
exec ktserver 'whadaadmin.kch' 'adminsession#type=*'
