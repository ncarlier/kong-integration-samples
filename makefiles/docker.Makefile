.SILENT :
.PHONY : network mount update image clean cleanup start stop wait rm shell logs

# Docker configuration regarding the system architecture
DOCKER=docker
DOCKERFILE?=Dockerfile
BASEIMAGE?=debian:jessie

NETWORK?=worldline-vlan

# Get IP of the running container
IP:=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' $(APPNAME)`

# Default registry
REGISTRY?=

# Default version
VERSION?=latest

# Default username
USERNAME?=worldline

# Default image name
IMAGE?=$(REGISTRY)$(USERNAME)/$(APPNAME):$(VERSION)

# Custom flags
RUN_CUSTOM_FLAGS?=
# Default Docker run flags
#RUN_FLAGS?=-d -h $(APPNAME) --name $(APPNAME) --net=$(NETWORK) $(RUN_CUSTOM_FLAGS)
RUN_FLAGS?=-d -h $(APPNAME) --name $(APPNAME) $(RUN_CUSTOM_FLAGS)
# Default Docker run command
RUN_CMD?=

# Custom flags
SHELL_CUSTOM_FLAGS?=$(RUN_CUSTOM_FLAGS)
# Default Docker run flags for shell access
#SHELL_FLAGS?=--rm -it --net=$(NETWORK) --entrypoint="/bin/bash" $(SHELL_CUSTOM_FLAGS)
SHELL_FLAGS?=--rm -it --entrypoint="/bin/bash" $(SHELL_CUSTOM_FLAGS)
# Default Docker run command for shell access
SHELL_CMD?=-c /bin/bash

# Volume base directory on the host
VOLUME_HOST_PATH?=$(PWD)
# Volume base directory into the container
VOLUME_CONTAINER_PATH?=/usr/src/app
# Volume flags
VOLUME_FLAGS:=

## Build the network
network:
	echo "Building Docker network: $(NETWORK)..."
	-$(DOCKER) network create $(NETWORK)

## Mount volume
mount:
	echo "Using volume: $(VOLUME_HOST_PATH) -> $(VOLUME_CONTAINER_PATH) ..."
	$(eval VOLUME_FLAGS += --volume $(VOLUME_HOST_PATH):$(VOLUME_CONTAINER_PATH))

## Update base image
update:
	echo "Updating Docker base image..."
	-$(DOCKER) pull $(BASEIMAGE)

## Build Docker image
image: update
	echo "Building $(IMAGE) docker image..."
	$(DOCKER) build --rm -t $(IMAGE) -f $(DOCKERFILE) .
	$(MAKE) cleanup

## Remove Docker image (also stop and delete the container)
clean: stop rm
	echo "Removing $(IMAGE) docker image..."
	-$(DOCKER) rmi $(IMAGE)

## Remove dangling Docker images
cleanup:
	echo "Removing dangling docker images..."
	-$(DOCKER) images -q --filter 'dangling=true' | xargs $(DOCKER) rmi

## Start Docker container
start:
	echo "Starting $(IMAGE) docker image..."
	$(DOCKER) run $(RUN_FLAGS) $(VOLUME_FLAGS) $(IMAGE) $(RUN_CMD)

## Stop Docker container
stop:
	echo "Stopping container $(APPNAME) ..."
	-$(DOCKER) stop $(APPNAME)

## Wait until the container is up and running (needs health run flag)
wait:
	n=30;\
	while [ $${n} -gt 0 ] ; do\
		status=`$(DOCKER) inspect --format "{{json .State.Health.Status }}" $(APPNAME)`;\
		if [ -z $${status} ]; then echo "No status informations."; exit 1; fi;\
		echo "Waiting for container $(APPNAME) up and ready ($${status})...";\
		if [ "\"healthy\"" = $${status} ]; then exit 0; fi;\
		sleep 2;\
		n=`expr $$n - 1`;\
	done;\
	echo "Timeout" && exit 1

## Delete container
rm:
	echo "Deleting container $(APPNAME) ..."
	-$(DOCKER) rm $(APPNAME)

## Run container with shell access
shell:
	echo "Running $(IMAGE) docker image with shell access..."
	$(DOCKER) run $(SHELL_FLAGS) $(VOLUME_FLAGS) $(IMAGE) $(SHELL_CMD)

## Show container logs
logs:
	echo "Logs of the $(APPNAME) container..."
	$(DOCKER) logs -f $(APPNAME)

