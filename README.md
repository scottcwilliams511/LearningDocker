# Intoduction to Docker

The purpose of this repository is to provide sample uses for Docker that may help one learn how to use it.

These were ran using terminal on macOS with the Docker daemon installed and running.

As of September 5th, 2018, this followed these two walkthroughs:

- https://docker-curriculum.com/
- https://docs.docker.com/compose/gettingstarted/

## docker-curriculum

Inside of the docker-curriculum directory, you will first 4 *.sh files and 4 *-out.txt files. Each of these corresponds to a 
chapter on the docker-curriculum website.

The order these file should be looked at in are:
- intro.sh
- webApps.sh
- multiContainer.sh
- dockerCompose.sh

These scripts also contain my notes on how various docker features work so it is worth reading through them before blindly executing them.

Each of the output files shows sample output from whem I ran these scripts.


## docker-compose

This directory holds a sample python flask app that is ready to be dockerized. The essential non-app components are:
 - Dockerfile
 - docker-compose.yml
 
Running ```$ docker-compose up``` in this directory should first cause the image to be built, then a container will be ran with the flask app inside.
