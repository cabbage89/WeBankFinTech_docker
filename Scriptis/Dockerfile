FROM  nginx:1.17.6

ADD wedatasphere-scriptis-0.7.0-dist /scriptis
ADD docker-entrypoint.sh /scriptis
ADD scriptis.conf /etc/nginx/conf.d/scriptis.conf

WORKDIR /scriptis

EXPOSE 8080

ENTRYPOINT ["sh","./docker-entrypoint.sh"]



