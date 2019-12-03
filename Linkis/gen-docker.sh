version="0.9.1"
port_begin=38180

echo "version: '3.6'
services:" > docker-compose.yaml

volumes=""
### 制作基础镜像
module=$(find wedatasphere-linkis-0.9.1-dist-spark2.0-2.2 -iname 'module.zip')
echo "FROM openjdk:8u232-jdk 
ADD $module /module.zip

RUN mkdir -p /opt \
&& unzip module.zip -d /opt \
&& rm -rf module.zip" > Dockerfile

#docker build -t="linkis-lib-base:$version" .

### 制作linkis各服务镜像

for file in $(find wedatasphere-linkis-0.9.1-dist-spark2.0-2.2 -iname '*.zip'|grep -v 'module.zip')
do
    filename=${file##*/}
    name=${filename%%.*}
    mkdir -p $name

    echo "FROM linkis-lib-base:$version
ADD $file /$filename

RUN mkdir -p /opt && \
unzip /$filename -d /opt \
&& rm -rf /$filename \
&& mv -f /opt/module/lib/ /opt/$name/lib/module

WORKDIR /opt/$name

RUN find . -maxdepth 3

EXPOSE 8080

ENTRYPOINT [\"sh\",\"./bin/\$(ls bin|grep start)\"]
" > $name/Dockerfile

echo "
    $name:
        environment:
          - SERVICE_URL_DEFAULT_ZONE=http://eureka:8080
          - SERVER_PORT=8080
          - SERVER_HOSTNAME=0.0.0.0
          - WDS_LINKIS_LDAP_PROXY_URL=
          - WDS_LINKIS_LDAP_PROXY_BASEDN=
          - WDS_LINKIS_GATEWAY_ADMIN_USER=hadoop
          - WDS_LINKIS_SERVER_MYBATIS_DATASOURCE_URL=jdbc:mysql://mysql8:3306/linkis?characterEncoding=UTF-8
          - WDS_LINKIS_SERVER_MYBATIS_DATASOURCE_USERNAME=root
          - WDS_LINKIS_SERVER_MYBATIS_DATASOURCE_PASSWORD=abc12345
          - WDS_LINKIS_WORKSPACE_FILESYSTEM_LOCALUSERROOTPATH=
          - WDS_LINKIS_WORKSPACE_FILESYSTEM_HDFSUSERROOTPATH_PREFIX=
          - WDS_LINKIS_ENGINEMANAGER_SUDO_SCRIPT=
          - WDS_LINKIS_ENTRANCE_CONFIG_LOGPATH=
          - WDS_LINKIS_RESULTSET_STORE_PATH=
          - HIVE_META_URL=
          - HIVE_META_USER=
          - HIVE_META_PASSWORD=
          - WDS_LINKIS_ENGINEMANAGER_CORE_JAR=
          - WDS_LINKIS_SPARK_DRIVER_CONF_MAINJAR=
          - WDS_LINKIS_RESULTSET_STORE_PATH=
        image: \"$name:$version\"
        ports:
          - $port_begin:8080
        restart: always
        volumes:
        - ${name}_logs:/opt/$name/logs
" >> docker-compose.yaml

((port_begin++))

volumes="${name}_logs:
    $volumes"

echo 'docker build -t="'$name':'$version'" -f '$name'/Dockerfile .'
#docker build -t="$name:$version" -f $name/Dockerfile .

done

echo "
volumes:
    $volumes
">>docker-compose.yaml

