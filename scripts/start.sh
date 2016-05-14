#!/bin/bash

VAR_DIR=/data/var
ETC_DIR=/data/etc
USR_DIR=/data/usr
RUN_DIR=$VAR_DIR/run
LIB_DIR=$VAR_DIR/lib
SHARE_DIR=$USR_DIR/share
STATE_DIR=$VAR_DIR/state
INFLUXDB_ETCDIR=$ETC_DIR/influxdb
INFLUXDB_RUNDIR=$RUN_DIR/influxdb
INFLUXDB_LIBDIR=$LIB_DIR/influxdb
INFLUXDB_METADIR=$INFLUXDB_LIBDIR/meta
INFLUXDB_DATADIR=$INFLUXDB_LIBDIR/data
INFLUXDB_WALDIR=$INFLUXDB_LIBDIR/wal
INFLUXDB_COLLECTDDIR=$SHARE_DIR/collectd


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

if [ ! -d $LIB_DIR ]; then
    echo "Creating directory $LIB_DIR"
    mkdir -p $LIB_DIR
fi

if [ ! -d $SHARE_DIR ]; then
    echo "Creating directory $SHARE_DIR"
    mkdir -p $SHARE_DIR
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

if [ ! -d $INFLUXDB_METADIR ]; then
    echo "Creating directory $INFLUXDB_METADIR"
    mkdir -p $INFLUXDB_METADIR
fi

if [ ! -d $INFLUXDB_DATADIR ]; then
    echo "Creating directory $INFLUXDB_DATADIR"
    mkdir -p $INFLUXDB_DATADIR
    mkdir -p $INFLUXDB_DATADIR/_internal
fi

if [ ! -d $INFLUXDB_WALDIR ]; then
    echo "Creating directory $INFLUXDB_WALDIR"
    mkdir -p $INFLUXDB_WALDIR
fi
if [ ! -d $INFLUXDB_COLLECTDDIR ]; then
    echo "Creating directory $INFLUXDB_COLLECTDDIR"
    mkdir -p $INFLUXDB_COLLECTDDIR
fi

echo $INFLUXDB_DATADIR > $STATE_DIR/influxdb-datadir.txt

if [ ! -f $STATE_DIR/influxdb.initialized ]; then

    CONFFILE=$INFLUXDB_ETCDIR/influxdb.conf
    PIDFILE=$INFLUXDB_RUNDIR/influxdb.pid
    mv /tmp/influxdb-noauth.conf $CONFFILE
    
    echo "Starting influxdb"
    /usr/bin/influxd -config $CONFFILE -pidfile $PIDFILE &
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
chown -R influxdb:influxdb $INFLUXDB_LIBDIR
chown -R influxdb:influxdb $INFLUXDB_RUNDIR
chown -R influxdb:influxdb $INFLUXDB_COLLECTDDIR
chown -R influxdb:influxdb /var/log/influxdb

echo "Starting supervisord"
/usr/local/bin/supervisord -c /etc/supervisord.conf --loglevel=debug -n
