#!/bin/bash
# dockerCompose.sh
# Tutorial code from https://docker-curriculum.com "Docker Compose" chapter.

# Scott Williams
# August 17, 2018
# Runs on macOs High Sierra v10.13.6 in Terminal
# Developed in Visual Studio Code

# Goal is to simplify the SF Food Truck app using docker-compose

# Incase only this script is run, here are the building blocks from multiContainer.sh
TempPath="temp_3"
echo "Running set-up from multiContainer.sh"
echo "We will clone git repo 'FoodTrucks' into the new folder '$TempPath'\n"
mkdir $TempPath
git clone https://github.com/prakhar1989/FoodTrucks $TempPath
cd $TempPath
echo "\nPulling Elasticsearch image...\n"
docker pull docker.elastic.co/elasticsearch/elasticsearch:6.3.2
rm Dockerfile

# --- Start Dockerfile ---
echo "# Specify the base image we want to use.
# Use unbuntu since we need a custom build step
FROM ubuntu:14.04

# Install system-wide dependancies for python and node.js
# Use package manager apt-get to install dependancies.
# -yqq flag suppresses output and assumes \"YES\" to all prompts
RUN apt-get -yqq update
RUN apt-get -yqq install python-pip python-dev curl gnupg
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash
RUN apt-get install -yq nodejs

# Copy our application code. ADD copies the code to a new volume in the container.
ADD flask-app /opt/flask-app

# Set this as our working directory so following commands will be run in this context.
WORKDIR /opt/flask-app

# Fetch app specific dependancies
RUN npm install
RUN npm run build
RUN pip install -r requirements.txt

# Specify port number that needs to be exposed
EXPOSE 5000

# Write the command for running the application. CMD tells the container which command it should
# run when it is started.
CMD [\"python\", \"./app.py\"]" > Dockerfile
# --- End Dockerfile ---

echo "\nUsing some fun method, this is the created file...\n"
echo "----------------------------------------------------------------------------------"
cat Dockerfile
echo "----------------------------------------------------------------------------------"

echo "\n\nTime to build the Flask image!"
docker build -t scottcwilliams511/foodtrucks-web .

# Should have at least "scottcwilliams511/foodtrucks-web", "docker.elastic.co/elasticsearch/elasticsearch", "ubuntu"
docker images


# --- Docker Compose ---

# Compose is a tool that is used fir defining and running multi-container Docker apps in an easy way. The configuration
# file ias called `docker-compose.yml`

echo "\n\nLet's create our docker-compose.yml file"
read -p "Press any key..." -n1 -s

rm docker-compose.yml

# --- Start docker-compose.yml ---
echo "version: \"3\"

services:
    es:
        # Refer to the elasticsearch image available on Elastic registry
        image: docker.elastic.co/elasticsearch/elasticsearch:6.3.2
        container_name: es
        # Pass environment variables
        environment:
            - discovery.type=single-node
        ports:
            - 9200:9200
        # Specifies a mount point in our container where the code will reside
        # This is optional, but useful to accrdd logs etc.
        volumes:
            - esdata1:/usr/share/elasticsearch/data

    web:
        # Refer to the recently built image
        image: scottcwilliams511/foodtrucks-web
        command: python app.py
        # Tells docker to start the specified container(s) before this one.
        depends_on:
            - es
        ports:
            - \"5000:5000\"
        # Data we load persists between restarts
        volumes:
            - ./flask-app:/opt/flask-app

volumes:
    esdata1:
        driver: local" > docker-compose.yml
# --- End docker-compose.yml ---

echo "\nUsing some fun method, this is the created file...\n"
echo "----------------------------------------------------------------------------------"
cat docker-compose.yml
echo "----------------------------------------------------------------------------------"

echo "Lets try out docker-compose now!\n"
read -p "Press any key..." -n1 -s

# Starts up all the services
docker-compose up -d
docker-compose logs -f --tail=100

# Check what networks were created if any
echo "\nActive networks\n"
docker network ls

echo "\nOnce finished verifying the site works at http://localhost:5000/\n"
read -p "Press any key to continue..." -n1 -s

# Data volumes will persist, so it's possible to start the cluster again with the same data using
# `docker-compose up`. To destroy the cluster and the data volumes, run this command 
docker-compose down -v

# Cleanup
read -p "Press any key..." -n1 -s
docker stop es
docker stop foodtrucks-web
docker rm $(docker ps -a -q -f status=exited)