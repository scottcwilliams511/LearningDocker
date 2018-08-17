#!/bin/bash
# webApps.sh
# Tutorial code from https://docker-curriculum.com "Webapps with Docker" chapter.

# Scott Williams
# August 16, 2018
# Runs on macOs High Sierra v10.13.6 in Terminal
# Developed in Visual Studio Code


# --- Static Sites ---

# The image to be used is a single-page website. We can download and run the image directly in one go using docker run.
echo "Attempting to run a website image from 'prakhar1989/static-site'"
echo "If the command works, the text 'Nginx is running...' should be displayed.\n"
echo "The container can be stopped using 'ctrl+c'\n"
docker run --rm prakhar1989/static-site  # --rm will remove the container once it finishes running.

# You will want to kill the container as it has no ports exposed and thus we cannot connect to it *sadness*

# flag `-d` will detatch our terminal, `-P` will publish all exposed ports to random ports and
# `--name` corresponds to a name we want to give.
echo "\n\nWe will try that again with exposed ports and detatch the container from the terminal"
docker run --rm -d -P --name static-site prakhar1989/static-site

echo "The site should now be running in detached mode."

# This command tells us what ports are exposed for static-site
echo "Use one of these ports (web addresses) to view the website (probably the '80/tcp' one if available)\n"
docker port static-site

# On one instance this output. The second one didn't load a page tho:
# 80/tcp -> 0.0.0.0:32769
# 443/tcp -> 0.0.0.0:32768

read -p "Press any key to stop the website" -n1 -s
echo "\nStopping detached container"
# To stop a detached contaimer, run `docker stop` with the container id (or name!)
docker stop static-site

# Specify a custom port to which the client will forward connections to the container
echo "\nTry connecting to 'http://localhost:8888' now...\n"
docker run --rm -d -p 8888:80 --name static-site prakhar1989/static-site

read -p "Press any key to stop the website" -n1 -s
echo "\nStopping detached container"
docker stop static-site


# --- Docker Images ---

# An image is similar to a github repo - images can be commited with changes and have multiple versions. If you
# dont provide a specific version number, te client defaults to `latest`

# There are two types of images: Base and Child
# - Base images: images that have no parent image, usually images with an OS like ubuntu, busybox, or debian.
# - Child images: images that build on base images and add additional functionality

# Time to "create our own image"...
# The goal of this is to create an image that sandboxes a simple Flask app.
# This one will display a random cat `.gif` everytime it is loaded ^_^
TempPath="temp"

echo "\nWe will now clone git repo 'docker-curriculum' into the new folder '$TempPath'\n"
read -p "Press any key..." -n1 -s
echo ""

mkdir $TempPath

# Clone the latest code from GitHub
git clone https://github.com/prakhar1989/docker-curriculum $TempPath
cd $TempPath/flask-app

# The next step is to create an image with this web app. All user images are based off of a base image.
# This app is written in Python, so the base image we will need is "Python 3" onbuild version.
# onbuild version includes helpers that automate the boring parts of getting the app running.


# --- Docker File ---

# A Dockerfile is a simple text-file that contains a list of commands that the Docker client
# calls while creating an image. It's a simple way to automate the image creation process.
rm Dockerfile # We don't want the existing one, let's make our own...

# Now here's a fun way to create a new file...
echo ""
read -p "Press any key to create our Dockerfile..." -n1 -s

# How to create a 'file' inside of a sh script, probably not the right way, but it works lol...
# --- Start Dockerfile ---
echo "# Specify the base image we want to use.
# onbuild takes care of copying files and installing dependencies.
FROM python:3-onbuild

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

echo "\n\nTime to build this image!"
read -p "Press any key..." -n1 -s
echo ""

# The `docker build` command does the heavy-lifting of creating a Docker image from a Dockerfile
# `-t` adds an optional tag name
# `.` is the location of the Dockerfile
docker build -t scottcwilliams511/catnip .

echo "\nNow let's try to run the image! It will be located at http://localhost:8888"
read -p "Press any key..." -n1 -s
echo ""

# This will run the newly built image on localhost:8888 and will use port 5000 that is inside of the container.
docker run --rm -p 8888:5000 scottcwilliams511/catnip


# --- Docker on AWS ---

# We wont do the AWS bits since an account requires a credit card, put will document steps/commands...

# The first thing that we need to do before deploying to AWK is to publish the image to
# a registry that can be accessed by AWS. Let's try docker hub!

# Note: It is NOT required to put the image on Docker Hub, especially if said image should be private.
#       Docker Hub will make that image publish, which is fine for this test image hehe...

echo "\n\nWe will now push the image onto Docker Hub!"
read -p "Press any key..." -n1 -s
echo ""

docker push scottcwilliams511/catnip

# If "denied: requested access to the resource is denied" is displayed then run `docker login`

echo "\nFor fun, we can verify that we can use the pushed image by pulling it"
echo "Lets remove the image we created"
read -p "Press any key..." -n1 -s
echo ""
# Remove the local version we built
docker rmi -f scottcwilliams511/catnip

echo "\nRemoved old! Now pulling and running!"
docker run --rm -p 8888:5000 scottcwilliams511/catnip

# Cleanup
echo "\nRemoving cloned git repo"
read -p "Press any key..." -n1 -s
echo ""
cd ../../
rm -f -r $TempPath

echo "All docker images will be removed. Press enter to proceed or kill the script"
read -p "Press enter..."
docker rm $(docker ps -a -q -f status=exited)
docker rmi $(docker images -q)