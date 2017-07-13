.SILENT :
.PHONY : wait build config stop start restart logs status cleanup

COMPOSE_FILES?=-f docker-compose.yml

## Wait until a service ($$service) is up and running (needs health run flag)
wait:
	sid=`docker-compose $(COMPOSE_FILES) ps -q $(service)`;\
	n=30;\
	while [ $${n} -gt 0 ] ; do\
		status=`docker inspect --format "{{json .State.Health.Status }}" $${sid}`;\
		if [ -z $${status} ]; then echo "No status informations."; exit 1; fi;\
		echo "Waiting for $(service) up and ready ($${status})...";\
		if [ "\"healthy\"" = $${status} ]; then exit 0; fi;\
		sleep 2;\
		n=`expr $$n - 1`;\
	done;\
	echo "Timeout" && exit 1

## Build services
build:
	echo "Building services ..."
	docker-compose $(COMPOSE_FILES) build $(service)

## Config a service ($$service)
config: wait
	echo "Configuring $(service)..."
	docker-compose $(COMPOSE_FILES) -f docker-compose.config.yml build config_$(service)
	docker-compose $(COMPOSE_FILES) -f docker-compose.config.yml run config_$(service)

## Stop a service ($$service)
stop:
	echo "Stoping service: $(service) ..."
	docker-compose $(COMPOSE_FILES) stop $(service)

## Stop a service ($$service)
start:
	echo "Starting service: $(service) ..."
	docker-compose $(COMPOSE_FILES) up -d $(service)

## Restart a service ($$service)
restart:
	echo "Restarting service: $(service) ..."
	docker-compose $(COMPOSE_FILES) restart $(service)

## View service logs ($$service)
logs:
	echo "Viewing $(service) service logs ..."
	docker-compose $(COMPOSE_FILES) logs -f $(service)

## View services status
status:
	echo "Viewing services status ..."
	docker-compose $(COMPOSE_FILES) ps

## Remove dangling Docker images
cleanup:
	echo "Removing dangling docker images..."
	-docker images -q --filter 'dangling=true' | xargs docker rmi

