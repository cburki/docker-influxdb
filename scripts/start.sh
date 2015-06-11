#!/bin/bash

VAR_DIR=/data/var
OPT_DIR=$VAR_DIR/opt
STATE_DIR=$VAR_DIR/state
INFLUXDB_DIR=$OPT_DIR/influxdb
INFLUXDB_DATADIR=$INFLUXDB_DIR/data
INFLUXDB_METADIR=$INFLUXDB_DIR/meta
INFLUXDB_HHDIR=$INFLUXDB_DIR/influxdb/hh

# Setup data directories
if [ ! -d $VAR_DIR ]; then
    echo "Creating directory $VAR_DIR"
    mkdir -p $VAR_DIR
fi

if [ ! -d $OPT_DIR ]; then
    echo "Creating directory $OPT_DIR"
    mkdir -p $OPT_DIR
fi

if [ ! -d $STATE_DIR ]; then
    echo "Creating directory $STATE_DIR"
    mkdir -p $STATE_DIR
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

echo $INFLUXDB_DATADIR > $STATE_DIR/influxdb-datadir.txt

if [ ! -f $STATE_DIR/influxdb.initialized ]; then

    CONFFILE=/etc/opt/influxdb/influxdb.conf
    PIDFILE=/var/run/influxdb/influxdb.pid
    mv /tmp/influxdb-noauth.conf $CONFFILE
    
    echo "Starting influxdb"
    /opt/influxdb/influxd -config=$CONFFILE -pidfile=$PIDFILE &
    sleep 10

    if [ -n "$INFLUXDB_PASSWORD" ]; then
        # Set the root password and enable authentication
        echo $INFLUXDB_PASSWORD > $STATE_DIR/influxdb-db-pwd.txt

        echo "Setting up influxdb cluster admin privileges"
        # Set the influxdb root password
        curl -G 'http://localhost:8086/query' --data-urlencode "q=CREATE USER root WITH PASSWORD '$INFLUXDB_PASSWORD' WITH ALL PRIVILEGES"

        # Copy the configuration with authentication enabled
        mv /tmp/influxdb.conf $CONFFILE

    else
        # Do not enable authentication
        echo "WARNING : Authentication not enabled"
    fi
    
    kill `cat $PIDFILE`
    echo "done" > $STATE_DIR/influxdb.initialized
    rm -f $PIDFILE

    chown -R influxdb:influxdb $INFLUXDB_DIR
    chown -R influxdb:influxdb /opt/influxdb
    chown -R influxdb:influxdb /var/opt/influxdb
    chown -R influxdb:influxdb /var/run/influxdb
fi

echo "Starting supervisord"
/usr/local/bin/supervisord -c /etc/supervisord.conf --loglevel=debug -n
