.SILENT :

# Compose files
COMPOSE_FILES?=-f docker-compose.yml

# Include common Make tasks
root_dir:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
makefiles:=$(root_dir)/makefiles
include $(makefiles)/help.Makefile
include $(makefiles)/docker/compose.Makefile

# Start HTTP proxy
start-proxy:
	-$(shell ./proxy.sh start)
.PHONY: start-proxy

# Stop HTTP proxy
stop-proxy:
	-$(shell ./proxy.sh stop)
.PHONY: stop-proxy

with-all: with-elk with-tig with-keycloak
.PHONY: with-all

## Using ELK stack (Warning: put this task before other tasks)
with-elk:
	echo "Using ELK stack..."
	$(eval COMPOSE_FILES += -f docker-compose.elk.yml)
.PHONY: with-elk

## Using TIG stack (Warning: put this task before other tasks)
with-tig:
	echo "Using TIG stack..."
	$(eval COMPOSE_FILES += -f docker-compose.tig.yml)
.PHONY: with-tig

## Using Keycloak stack (Warning: put this task before other tasks)
with-keycloak:
	echo "Using Keycloak stack..."
	$(eval COMPOSE_FILES += -f docker-compose.keycloak.yml)
.PHONY: with-keycloak

## Deploy containers to Docker host
deploy: compose-up start-proxy
.PHONY: deploy

## Un-deploy API from Docker host
undeploy: stop-proxy with-all compose-down
.PHONY: undeploy

## Clean generated files
clean:
	rm -f cert.pem pub.pem secret keys.json secret.json
.PHONY: clean

## View service logs ($$service)
logs: compose-logs
.PHONY: logs

## Get Keycloak Realm key
keys: clean
	docker exec -i kong-integration-samples_keycloak_1 /bin/bash < config/get-keycloak-realm-key.sh > keys.json
	jq ".keys[0].publicKey" -r keys.json > pub.tmp
	sed -e "1 i -----BEGIN PUBLIC KEY-----" -e "$ a -----END PUBLIC KEY-----" pub.tmp > pub.pem
	rm pub.tmp
	jq ".keys[0].certificate" -r keys.json > cert.tmp
	sed -e "1 i -----BEGIN CERTIFICATE-----" -e "$ a -----END CERTIFICATE-----" cert.tmp > cert.pem
	rm cert.tmp
	rm keys.json
	cat pub.pem
.ONESHELL:
.PHONY: keys

## Get Keycloak client secret
secret:
	docker exec -i kong-integration-samples_keycloak_1 /bin/bash < config/get-keycloak-client-secret.sh > secret.json
	cat secret.json
.PHONY: secret

