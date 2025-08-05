#!/bin/bash
docker kill bw-xapp-24
docker rm bw-xapp-24
docker rmi bw-xapp:latest
./setup-bw-xapp.sh ns-o-ran

docker exec -it bw-xapp-24 bash