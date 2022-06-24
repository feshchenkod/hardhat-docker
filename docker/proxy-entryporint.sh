#!/bin/sh

envsubst '$URL,$SUBDIR' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf
timeout $TIMEOUT nginx -g 'daemon off;'