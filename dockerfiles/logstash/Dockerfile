FROM docker.elastic.co/logstash/logstash:5.5.0

RUN /usr/share/logstash/bin/logstash-plugin remove x-pack
RUN sed -i '/xpack/d' /usr/share/logstash/config/logstash.yml

COPY ./conf/* /conf/

CMD ["-f", "/conf", "-r"]
