# Kong integration samples

This project is a small collection of demonstration showing how to integrate
[Kong][kong] with other systems:

- With an external authentication system such as [Keycloak][keycloak]
- With an external metric system such as [Telegraf][telegraf],
  [InfluxDB][influxdb] and [Grafana][grafana].
- With an external logging system such as [Elasticsearch][elasticsearch],
  [Logstash][logstash] and [Kibana][kibana].

## Prerequisites

Before starting you have to install those tools.

- [Docker][docker]
- [Docker Compose][docker-compose]
- [Make][make]


## Kong with Keycloak (OIDC)

This demonstration setup:

- a Keycloak instance with a minimal configuration: a realm, a client and an
  user.
- a Kong instance with a minimal configuration: an API with the OIDC plugin.

The OIDC plugin is not available with the open-source version of Kong.
Therefore we have to install a similar plugin coming from Nokia:
[kong-oidc][kong-oidc]. This is why we build our own Docker image for Kong.

Because we don't have proper DNS configuration and in order to not break the
OIDC redirection you have to do some modification into the `/etc/hosts` file of
your Docker host:

```
127.0.1.1 keycloak
```

You are now ready to setup the demo.

### Deploy and configure the stack

```bash
$ make with-keycloak build deploy
$ make with-keycloak config service=keycloak
```

The configuration of Keycloak should output a JSON with the secret:

```json
{
  "realm": "sample",
  "auth-server-url": "http://localhost:8080/auth",
  "ssl-required": "external",
  "resource": "sample-api",
  "credentials": {
    "secret": "434200e2-ff27-4760-9141-5e4b92581017"
  }
}
```
Note this secret! You will have to use it for the next configuration.

Update the [Kongfig][kongfig] configuration file (`./config/kongfig.yml`) in
order to activate the OIDC plugin:

```yaml
---
apis:
  - name: sample_api
    ensure: present
    attributes:
      uris: /sample
      strip_uri: true
      upstream_url: http://api.icndb.com/jokes/random
    plugins:
      - name: oidc
        attributes:
          config:
            scope: openid
            session_secret: 623q4hR325t36VsCD3g567922IC0073T
            response_type: code
            token_endpoint_auth_method: client_secret_post
            ssl_verify: no
            client_id: sample-api
            discovery: http://localhost:8080/auth/realms/sample/.well-known/openid-configuration
            client_secret: 434200e2-ff27-4760-9141-5e4b92581017
```

Apply this configuration:

```bash
$ make config service=kong
```

### Playground

If you try to access to the API you will receive a redirect response:

```bash
$ curl -i -X GET --url http://localhost:8000/sample
HTTP/1.1 302 Moved Temporarily
...
```

Open your browser and browse to the API (http://localhost:8000/sample).
You are redirected to the Keycloak login page of the `Sample` realm.
You can log in by using `test/test` as credentials. Once logged in you will be
redirect to the API and you will be able to interact with.

The API is now protected using a simple session id. Kong act as an OIDC client
with Keycloak.

## Kong with Keycloak (JWT)

In the previous demonstration we used Kong as a OIDC client. This is cool but
with such a solution Kong is tightly linked with OIDC provider. Something maybe
more interesting is to use JWT in order to decoupling both systems.

This demonstration setup:

- a Keycloak instance with a minimal configuration: a realm, a client and an
  user.
- a Kong instance with a minimal configuration: an API with the JWT plugin.

### Deploy and configure the stack

```bash
$ make with-keycloak build deploy
$ make with-keycloak config service=keycloak
```

TODO...

See: https://ncarlier.gitbooks.io/oss-api-management/content/howto-kong_with_keycloak.html


## Kong with TIG (Telegraf, InfluxDB and Grafana)

This demonstration setup:

- a time series database (InfluxDB)
- a StatsD agent (Telegraf)
- a data visualization & monitoring platform (Grafana)
- a Kong instance with a minimal configuration: an API with the StatsD plugin.

The purpose of this demo is to produce metrics from the API gateway and build
some visualization dashboard.

### Deploy and configure the stack

```bash
$ make with-tig build deploy
```

Update the [Kongfig][kongfig] configuration file (`./config/kongfig.yml`) in
order to activate the StatsD plugin:

```yaml
---
apis:
  - name: sample_api
    ensure: present
    attributes:
      uris: /sample
      strip_uri: true
      upstream_url: http://api.icndb.com/jokes/random
    plugins:
      - name: statsd
        attributes:
          config:
            host: statsd
```

Apply this configuration:

```bash
$ make config service=kong
```

### Playground

Now any access of the API will produce some StatsD metrics gathered by Telegraf
and stored into InfluxDB.

Let's call the API several times:

```bash
$ watch -n 2 curl -i -X GET --url http://localhost:8000/sample
```

Open your browser and go to the Grafana console (http://localhost:3000):

- Login: admin/admin
- Add a data source:
  - Name: `influxdb`
  - Type: `InfluxDB`
  - Url: `http://influxdb:8086`
  - Access: `proxy`
  - Database: `telegraf`
- Import new dashboard:
  - `Dashboards->Import`
  - Choose `./dashboards/grafana.json`

You should visualize some metrics. You can play with Grafana to modify or create
great dashboard.
This is super cool but this plugin is quite limited. You only have very basic
metrics (count, latency, status and size) by API.
It's a good start but there is little work to do to make this plugin great
(by using tagged metrics for instance).


## Kong with ELK (Elasticsearch, Logstash, Kibana)

This demonstration setup:

- a indexed document database (Elasticksearch)
- a log collector and transformer (Logstash)
- a data visualization & monitoring platform (Kibana)
- a Kong instance with a minimal configuration: an API with the UDP-log plugin.

The purpose of this demo is to produce logs from the API gateway and build some
visualization dashboard.

### Deploy and configure the stack

Deploy and configure the stack:

```bash
$ make with-elk build deploy
```

Note that elasticsearch may fail to start:

```bash
$ make logs service=elasticsearch
...
max virtual memory areas vm.max_map_count [65530] is too low, increase to atleast [262144]
...
```

If so, you have to increase the following system property and restart the
service:

```bash
sudo sysctl -w vm.max_map_count=262144
make with-elk restart service=elasticsearch
```

Then you can configure Kong to use Logstash as an UDP logger.
Update the [Kongfig][kongfig] configuration file (`./config/kongfig.yml`) in
order to activate the UDP-log plugin:

```yaml
---
apis:
  - name: sample_api
    ensure: present
    attributes:
      uris: /sample
      strip_uri: true
      upstream_url: http://api.icndb.com/jokes/random
    plugins:
      - name: udp-log
        attributes:
          config:
            host: logstash
            port: 5000
```

Apply this configuration:

```bash
$ make config service=kong
```

### Playground

Now any access of the API will produce JSON logs gathered by Logstash and stored
into Elasticsearch.

Let's call the API several times:

```bash
$ watch -n 2 curl -i -X GET --url http://localhost:8000/sample
```

Open your browser and go to the Grafana console (http://localhost:5601):

Note that Kibana is very long to start the first time.

- Configure an index pattern: `logstash-*`
- You should see many fields.
- Click on Discover and you should see incoming events.
- Import new dashboard:
  - `Management->Saved Objects->Import`
  - Choose `./kibana/dashboard.json`

You should visualize some metrics. Feel free to play with Kibana and improve
this dashboard.


## Cleanup

You can undeploy all stacks with:

```bash
$ make undeploy
```


---

[kong]: https://getkong.org/
[keycloak]: http://www.keycloak.org/
[telegraf]: https://www.influxdata.com/time-series-platform/telegraf/
[influxdb]: https://www.influxdata.com/time-series-platform/influxdb/
[grafana]: https://grafana.com/
[docker]: https://www.docker.com/
[docker-compose]: https://github.com/docker/compose
[make]: https://www.gnu.org/software/make/
[kongfig]: https://github.com/mybuilder/kongfig
[kong-oidc]: https://github.com/nokia/kong-oidc
[elasticsearch]: https://www.elastic.co/fr/products/elasticsearch
[logstash]: https://www.elastic.co/fr/products/logstash
[kibana]: https://www.elastic.co/fr/products/kibana

