#!/bin/bash

VAR_DIR=/data/var
ETC_DIR=/data/etc
RUN_DIR=$VAR_DIR/run
OPT_DIR=$VAR_DIR/opt
STATE_DIR=$VAR_DIR/state
INFLUXDB_ETCDIR=$ETC_DIR/influxdb
INFLUXDB_RUNDIR=$RUN_DIR/influxdb
INFLUXDB_OPTDIR=$OPT_DIR/influxdb
INFLUXDB_DATADIR=$INFLUXDB_OPTDIR/data
INFLUXDB_METADIR=$INFLUXDB_OPTDIR/meta
INFLUXDB_HHDIR=$INFLUXDB_OPTDIR/influxdb/hh

# Setup data directories
if [ ! -d $VAR_DIR ]; then
    echo "Creating directory $VAR_DIR"
    mkdir -p $VAR_DIR
fi

if [ ! -d $ETC_DIR ]; then
    echo "Creating directory $ETC_DIR"
    mkdir -p $ETC_DIR
fi

if [ ! -d $RUN_DIR ]; then
    echo "Creating directory $RUN_DIR"
    mkdir -p $RUN_DIR
fi

if [ ! -d $OPT_DIR ]; then
    echo "Creating directory $OPT_DIR"
    mkdir -p $OPT_DIR
fi

if [ ! -d $STATE_DIR ]; then
    echo "Creating directory $STATE_DIR"
    mkdir -p $STATE_DIR
fi

if [ ! -d $INFLUXDB_ETCDIR ]; then
    echo "Creating directory $INFLUXDB_ETCDIR"
    mkdir -p $INFLUXDB_ETCDIR
fi

if [ ! -d $INFLUXDB_RUNDIR ]; then
    echo "Creating directory $INFLUXDB_RUNDIR"
    mkdir -p $INFLUXDB_RUNDIR
fi

if [ ! -d $INFLUXDB_DATADIR ]; then
    echo "Creating directory $INFLUXDB_DATADIR"
    mkdir -p $INFLUXDB_DATADIR
fi

if [ ! -d $INFLUXDB_METADIR ]; then
    echo "Creating directory $INFLUXDB_METADIR"
    mkdir -p $INFLUXDB_METADIR
fi

if [ ! -d $INFLUXDB_HHDIR ]; then
    echo "Creating directory $INFLUXDB_HHDIR"
    mkdir -p $INFLUXDB_HHDIR
fi

echo $INFLUXDB_DATADIR > $STATE_DIR/influxdb-datadir.txt

if [ ! -f $STATE_DIR/influxdb.initialized ]; then

    CONFFILE=$INFLUXDB_ETCDIR/influxdb.conf
    PIDFILE=$INFLUXDB_RUNDIR/influxdb.pid
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
fi

# Set influxdb permissions.
chown -R influxdb:influxdb $INFLUXDB_OPTDIR
chown -R influxdb:influxdb $INFLUXDB_RUNDIR
chown -R influxdb:influxdb /opt/influxdb
chown -R influxdb:influxdb /var/opt/influxdb

echo "Starting supervisord"
/usr/local/bin/supervisord -c /etc/supervisord.conf --loglevel=debug -n
