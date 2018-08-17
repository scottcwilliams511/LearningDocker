#!/bin/bash
# multiContainer.sh
# Tutorial code from https://docker-curriculum.com "Multi Container Environments" chapter.

# Scott Williams
# August 16, 2018
# Runs on macOs High Sierra v10.13.6 in Terminal
# Developed in Visual Studio Code

# Multi-Container Environments

# Goal is to Dockerize a SF Food Truck app that relies on at least one service.

TempPath="temp_2"

# First we clone the git repo
echo "We will clone git repo 'FoodTrucks' into the new folder '$TempPath'\n"
read -p "Press any key..." -n1 -s
echo ""

mkdir $TempPath

# Clone the latest code from GitHub
git clone https://github.com/prakhar1989/FoodTrucks $TempPath
cd $TempPath

# This cloned app consists of a Flask backend server and an Elasticsearch service.
# A container should be built for each of these.

# Create Elasticsearch image
echo "\nPulling Elasticsearch image...\n"
docker pull docker.elastic.co/elasticsearch/elasticsearch:6.3.2

echo "\nRunning Elasticsearch image...\n"
docker run -d --rm --name elastic-search -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:6.3.2

# `docker container logs` allows us to see the logs for that container given its name or id
echo ""

# It takes the image some number of seconds to get started and initialized. To make sure that it has at
# least started, we wait until we see the `started` text in the output logs. Try this for 15 seconds...
let SLEEP=0
let TIMEOUT=15

# Grep should either return nothing or the string
WORD=$(docker container logs elastic-search | grep -c "started")

# While grep didn't find the string and TIMEOUT seconds haven't passed
while ((WORD == 0)) && ((SLEEP < TIMEOUT)); do
    # Pause the script for one second
    let SLEEP=$SLEEP+1
    echo "Waiting... $SLEEP\n"
    sleep 1 

    # Check the state of the logs now
    WORD=$(docker container logs elastic-search | grep -c "started")
done

# Stop the container and bomb out if the container still isnt ready after $TIMEOUT seconds...
if [ $SLEEP -ge $TIMEOUT ]; then
    echo "Service didn't start after $TIMEOUT seconds... stopping script..."
    docker stop elastic-search
    exit
fi

echo "\n----- Startup logs -----\n"
docker container logs elastic-search

# Test the container is working by sending a curl request
echo "\nWe will now send an empty curl request to 0.0.0.0:9200\n"
read -p "Press any key..." -n1 -s
echo ""
curl 0.0.0.0:9200

# Create Dockerfile for Flask service
rm Dockerfile

echo ""
read -p "Press any key to create our Dockerfile for the Flask service..." -n1 -s
echo ""

# How to create a 'file' inside of a sh script, probably not the right way, but it works lol...
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
read -p "Press any key..." -n1 -s
echo ""

# The `docker build` command does the heavy-lifting of creating a Docker image from a Dockerfile
# `-t` adds an optional tag name
# `.` is the location of the Dockerfile
docker build -t scottcwilliams511/foodtrucks-web .

echo "\nStarting up Flask service"
read -p "Press any key (then wait like 30 seconds)..." -n1 -s
echo ""

docker run -P --rm scottcwilliams511/foodtrucks-web
# Whoops, the flask app isn't able to communicate with the elastc-search service, bleh...


# --- Docker Network ---

# When docker is installed, it creates 3 networks automatically
# - bridge -> Network in which containers are run by default.
docker network ls

echo "Validating that elastic-search is running on the bridge network"
read -p "Press any key..." -n1 -s
echo ""
docker network inspect bridge

WORD=$(docker network inspect bridge | grep -c "elastic-search")
if ((WORD == 0)); then
    # This get hit if `docker stop elastic-search` is run first ;)
    echo "The elastic-search container is not on the bridge network..."
else
    echo "The elastic-search container is on on the bridge network!"
fi

# By using the "IPv4Address" key, ex value: "172.17.0.2", you can run the Flask container
# in bash code then curl 172.17.0.2:9200 and that would work, but its not good to do :(

# Instead, let's create our own network
# The `docker network create` command creates a new bridge network
echo "\nLet's build our own bridge network named foodtrucks-net!"
read -p "Press any key..." -n1 -s
echo ""
docker network create foodtrucks-net

docker network ls

# A bridge network uses a software bridge which allows containers connected to the same bridge
# network to communicate, while providing isolation from containers what are not connected to that bridge network.
echo "\nStopping elastic-search container on the default bridge and starting on foodtrucks-net bridge network"
read -p "Press any key..." -n1 -s
echo ""
docker stop elastic-search

# `--net` flag allows launching the container in a specific network
# NOTE: for this demo, the image name MUST BE `es`
docker run -d --name es --net foodtrucks-net -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:6.3.2

echo "\nValidating that elastic-search is running on the foodtrucks-net bridge network"
read -p "Press any key..." -n1 -s
echo ""
docker network inspect foodtrucks-net

WORD=$(docker network inspect foodtrucks-net | grep -c "es")
if ((WORD == 0)); then
    echo "The elastic-search container is not on the foodtrucks-net bridge network..."
else
    echo "The elastic-search container is on on the foodtrucks-net bridge network!"
fi

# Try running
# `curl es:9200`
# `ls`
# `python app.py`
# `exit`
echo "\nNow lets re-try running the Flask app. Type \"exit\" to leave\n"
docker run -it --net foodtrucks-net scottcwilliams511/foodtrucks-web bash
docker rm $(docker ps -a -q -f status=exited)

echo "\nNow let's launch the container for real"
read -p "Press any key..." -n1 -s
echo "\n"

docker run -d --net foodtrucks-net -p 5000:5000 --name foodtrucks-web scottcwilliams511/foodtrucks-web

docker container ls

echo "\nThe application should be live at http://localhost:5000 (give it a few seconds to load...)"
read -p "Press any key once you are finished viewing the live application..." -n1 -s
echo ""


# Cleanup
echo "\nRemoving cloned git repo"
read -p "Press any key..." -n1 -s
cd ../
rm -f -r $TempPath

echo "\nAll docker images will be removed. Press enter to proceed or kill the script"
read -p "Press enter...."
docker stop es
docker stop foodtrucks-web
docker rm $(docker ps -a -q -f status=exited)
docker network rm foodtrucks-net
docker rmi $(docker images -q)