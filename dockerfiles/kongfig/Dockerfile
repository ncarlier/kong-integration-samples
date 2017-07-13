FROM node:alpine
MAINTAINER Nicolas Carlier <nicolas.carlier@worldline.com>

# Install deps
RUN npm install -g kongfig

# Add configuration file
ADD kongfig.yml /etc/kong.yml

# Add entrypoint script
ADD config.sh /configure-kong.sh

