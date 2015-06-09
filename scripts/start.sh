#!/bin/bash

VARDIR=/data/var
OPTDIR=$VARDIR/opt
STATEDIR=$VARDIR/state
INFLUXDB_DATADIR=$OPTDIR/influxdb/data
INFLUXDB_METADIR=$OPTDIR/influxdb/meta
INFLUXDB_HHDIR=$OPTDIR/influxdb/hh

# Setup data directories
if [ ! -d $VARDIR ]; then
    echo "Creating directory $VARDIR"
    mkdir -p $VARDIR
fi

if [ ! -d $OPTDIR ]; then
    echo "Creating directory $OPTDIR"
    mkdir -p $OPTDIR
fi

if [ ! -d $STATEDIR ]; then
    echo "Creating directory $STATEDIR"
    mkdir -p $STATEDIR
fi

if [ ! -d $INFLUXDB_DATADIR ]; then
    echo "Creating directory $INFLUX_DATADIR"
    mkdir -p $INLUXDB_DATADIR
fi

if [ ! -d $INFLUXDB_METADIR ]; then
    echo "Creating directory $INFLUX_METADIR"
    mkdir -p $INLUXDB_METADIR
fi

if [ ! -d $INFLUXDB_HHDIR ]; then
    echo "Creating directory $INFLUX_HHDIR"
    mkdir -p $INLUXDB_HHDIR
fi

echo $INFLUXDB_DATADIR > $STATEDIR/influxdb-datadir.txt

if [ ! -f $STATEDIR/influxdb.initialized ]; then

    CONFFILE=/etc/opt/influxdb/influxdb.conf
    PIDFILE=/var/run/influxdb/influxdb.pid
    mv /tmp/influxdb-noauth.conf $CONFFILE
    
    echo "Starting influxdb"
    /opt/influxdb/influxd -config=$CONFFILE -pidfile=$PIDFILE &
    sleep 10

    if [ -n "$INFLUXDB_PASSWORD" ]; then
        # Set the root password and enable authentication
        echo $INFLUXDB_PASSWORD > $STATEDIR/influxdb-db-pwd.txt

        echo "Setting up influxdb cluster admin privileges"
        # Set the influxdb root password
        curl -G 'http://localhost:8086/query' --data-urlencode "q=CREATE USER root WITH PASSWORD '$INFLUXDB_PASSWORD' WITH ALL PRIVILEGES"

        # Copy the configuration with authentication enabled
        mv /tmp/influxdb.conf $CONFFILE
    fi
    
    kill `cat $PIDFILE`
    echo "done" > $STATEDIR/influxdb.initialized
    rm -f $PIDFILE

    chown -R influxdb:influxdb $INFLUXDB_DATADIR
    chown -R influxdb:influxdb $INFLUXDB_METADIR
    chown -R influxdb:influxdb $INFLUXDB_HHDIR
    chown -R influxdb:influxdb /opt/influxdb
    chown -R influxdb:influxdb /var/opt/influxdb
    chown -R influxdb:influxdb /var/run/influxdb
fi

echo "Starting supervisord"
/usr/local/bin/supervisord -c /etc/supervisord.conf --loglevel=debug -n
