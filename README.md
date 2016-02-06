Summary
-------

InfluxDB server image. For persistent storage, you could use the cburki/volume-data
container to store the databases data. This image does not yet support the
clustering.


Build the image
---------------

To create this image, execute the following command in the docker-influxdb folder.

    docker build -t cburki/influxdb .


Configure the image
-------------

You can configure the image with environment variables.

 - INFLUXDB_PASSWORD : The root password. Authentication is not enabled if none is given.


Run the image
-------------

When you run the image, you will bind the ports 8083 and 8086. InfluxDB will
write the data in the /data/var/opt/influxdb folder which could be used from
a volume data container.

    docker run \
        --name influxdb \
        --volumes-from influxdb-data \
        -d \
        -e INFLUXDB_PASSWORD=my_secret_password \
        -p 8083:8083 \
        -p 8086:8086 \
        cburki/influxdb:latest

The volume data container could be started using the following command.

    docker run \
        --name influxdb-data \
        -d \
        cburki/volume-data:latest

