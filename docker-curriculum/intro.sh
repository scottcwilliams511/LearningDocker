#!/bin/bash
# intro.sh
# Tutorial code from https://docker-curriculum.com "Hello World" chapter.

# Scott Williams
# August 16, 2018
# Runs on macOs High Sierra v10.13.6 in Terminal
# Developed in Visual Studio Code


# We are running on macOs. First make sure docker is installed on this machine
# Then verify that the docker daemon is running (basically start the docker
# application).

# To verify that docker is working correctly, run the below command
echo "\nVerifying Docker has been set up corrently...\n"
docker run hello-world
# Output should be something like "Hello from Docker. ..."

read -p "Press any key..." -n1 -s

# Try pulling an image. The `docker pull image-name` command fetches the image from the docker
# registry and saves it to our system.
echo "\nPulling \"busybox\" image now!\n"
docker pull busybox

# You can use the `docker images` command to see a list of all images on your system
echo "\nDocker images on this system\n"
docker images

read -p "Press any key..." -n1 -s

# Try this
echo "\nTrying 'docker run image-name' command...\n"
docker run busybox

echo "... nothing should have happened!\n"

# When you call `run`, the Docker client finds the image (busybox in this case), loads up the container
# and then runs a command in that container. We didn't provide a command above, so the container booted up, ran
# an empty command and then exited... yay!
echo "\nLets pass a command to the container this time...\n"
docker run busybox echo "hello from busybox"

echo ""

# The `docker ps` command shows you all containers that are currently running
docker ps

# Or `docker ps -a` to see a list of all containers that we ran
docker ps -a

# ls outside and inside of container!
echo "\nls of current directory\n"
ls -l

echo "\nls inside of container\n"
docker run -it busybox ls -l

# Running with the -it flags attaches us to an interactive tty in the container. Now we can run as many
# commands in the container as we want!
echo "\nNow run your own command inside of the container. Run 'exit' to leave\n"
docker run -it busybox sh

read -p "Press any key..." -n1 -s

# After running `docker run`, a stray container will be left and will eat disc space. Use the command `docker rm`
# with the arguments that follow being container id's. Syntax `docker rm container-id1 containerid-2 ...`
# Alternatively, this will remove all containers that have a status of 'exited'
echo "\nRemoving all docker containers that have exited\n"
docker rm $(docker ps -a -q -f status=exited) # You can substitute `status=created` if there are containers you dont want that didn't run.

# Also, using the --rm flag when using docker run will auto-delete the container once it has exited.

echo "All docker images will be removed. Press enter to proceed or kill the script"
read -p "Press enter..."

# Lastly, you can delete images that are no longer needed by running docker rmi `docker rmi image-id1 image-id2 ...`
docker rmi $(docker images -q) # syntax for delete ALL

# --- Terms ---
# Images -> Blueprints of our application which form the basis of containers. Using `docker pull` command created one.
#           A list of docker images can be seen by running `docker images`.
#
# Containers -> Created from docker images and run the actual application. Created using `docker run`. A list of running containers
#               can be seen by running `docker ps`.
#
# Docker Daemon -> The background service running on the host that manages building, running and distributing docker containers.
#                  The daemon is the process that runs in the operating system which clients talk to.
#
# Docker Client -> Command line tool that allows the user to interact with the daemon.
#
# Docker Hub -> Registry of docker images. You can think of the registry as a directory of all available docker images.
#               If required, one can host their own docker registries and can use them for pulling images.
