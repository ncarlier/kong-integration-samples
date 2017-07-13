FROM kong:latest
MAINTAINER Nicolas Carlier <nicolas.carlier@worldline.com>

# Kong install dir
ENV KONG_HOME /usr/local/share/lua/5.1/kong

# Install OIDC plugin
RUN yum install -y git unzip && \
    git clone https://github.com/nokia/kong-oidc.git $KONG_HOME/plugins/kong-oidc && \
    (cd $KONG_HOME/plugins/kong-oidc/ && luarocks make)

# Patch NGINX config to set the session secret
RUN sed -i '/$upstream_scheme nil;/a \\tset $session_secret nil;' /usr/local/share/lua/5.1/kong/templates/nginx_kong.lua
