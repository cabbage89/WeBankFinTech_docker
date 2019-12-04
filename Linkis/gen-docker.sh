LINKIS_VERSION="0.9.1"
port_begin=38180
deployUser="hadoop"

source .env

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

#docker build -t="linkis-lib-base:$LINKIS_VERSION" .

### 制作linkis各服务镜像

for file in $(find wedatasphere-linkis-0.9.1-dist-spark2.0-2.2 -iname '*.zip'|grep -v 'module.zip')
do
    filename=${file##*/}
    name=${filename%%.*}
    mkdir -p $name

    echo "FROM linkis-lib-base:$LINKIS_VERSION
ADD $file /$filename

RUN mkdir -p /opt \
&& unzip /$filename -d /opt \
&& rm -rf /$filename \
&& cp -frp /opt/module/lib/* /opt/$name/lib/ \
&& rm -rf /opt/module

ADD docker-entrypoint.sh /opt/$name/

RUN chmod 700 /opt/$name/docker-entrypoint.sh

WORKDIR /opt/$name

RUN find . -maxdepth 3

EXPOSE 8080

ENTRYPOINT [\"sh\",\"./docker-entrypoint.sh\"]
" > $name/Dockerfile

echo "
    $name:
        environment:
          - HADOOP_HOME=/host$HADOOP_HOME
          - HADOOP_CONF_DIR=/host$HADOOP_CONF_DIR
          - HIVE_HOME=/host$HIVE_HOME
          - HIVE_CONF_DIR=/host$HIVE_CONF_DIR
          - SPARK_HOME=/host$SPARK_HOME
          - SPARK_CONF_DIR=/host$SPARK_CONF_DIR
          - PYSPARK_ALLOW_INSECURE_GATEWAY=\$PYSPARK_ALLOW_INSECURE_GATEWAY
          - SERVICE_URL_DEFAULT_ZONE=http://eureka:8080/eureka/
          - SERVER_PORT=8080
          - SERVER_HOSTNAME=0.0.0.0
          - WDS_LINKIS_LDAP_PROXY_URL=\$WDS_LINKIS_LDAP_PROXY_URL
          - WDS_LINKIS_LDAP_PROXY_BASEDN=\$WDS_LINKIS_LDAP_PROXY_BASEDN
          - WDS_LINKIS_GATEWAY_ADMIN_USER=$deployUser
          - WDS_LINKIS_SERVER_MYBATIS_DATASOURCE_URL=jdbc:mysql://mysql8:3306/linkis?characterEncoding=UTF-8
          - WDS_LINKIS_SERVER_MYBATIS_DATASOURCE_USERNAME=root
          - WDS_LINKIS_SERVER_MYBATIS_DATASOURCE_PASSWORD=abc12345
          - WDS_LINKIS_WORKSPACE_FILESYSTEM_LOCALUSERROOTPATH=file:///opt/$name/tmp/
          - WDS_LINKIS_WORKSPACE_FILESYSTEM_HDFSUSERROOTPATH_PREFIX=\$HDFS_USER_ROOT_PATH
          - WDS_LINKIS_ENGINEMANAGER_SUDO_SCRIPT=/opt/$name/bin/rootScript.sh
          - WDS_LINKIS_ENTRANCE_CONFIG_LOGPATH=file:///opt/$name/tmp/
          - HIVE_META_URL=\$HIVE_META_URL
          - HIVE_META_USER=\$HIVE_META_USER
          - HIVE_META_PASSWORD=\$HIVE_META_PASSWORD
          - WDS_LINKIS_ENGINEMANAGER_CORE_JAR=/opt/$name/lib/linkis-ujes-spark-engine-$LINKIS_VERSION.jar
          - WDS_LINKIS_SPARK_DRIVER_CONF_MAINJAR=/opt/$name/conf:/opt/$name/lib/*
          - WDS_LINKIS_RESULTSET_STORE_PATH=\$HDFS_USER_ROOT_PATH
        image: \"$name:$LINKIS_VERSION\"
        ports:
          - $port_begin:8080
        restart: always
        volumes:
        - ${name}_logs:/opt/$name/logs
        - ${name}_tmp:/opt/$name/tmp
        - ./docker-entrypoint.sh:/opt/$name/bin/docker-entrypoint.sh
        - /:/host
" >> docker-compose.yaml

((port_begin++))

volumes="${name}_logs:
    ${name}_tmp:
    $volumes"

echo 'docker build -t="'$name':'$LINKIS_VERSION'" -f '$name'/Dockerfile .'
docker build -t="$name:$LINKIS_VERSION" -f $name/Dockerfile .

done

echo "
    mysql8:
      image: mysql:8
      restart: always
      environment:
        - MYSQL_ROOT_PASSWORD=abc12345
        - MYSQL_DATABASE=linkis
      ports:
        - 53306:3306
      volumes:
        - mysql_data:/var/lib/mysql
        - ./wedatasphere-linkis-0.9.1-dist-spark2.0-2.2/db:/docker-entrypoint-initdb.d:ro
volumes:
    mysql_data:
    $volumes
" >> docker-compose.yaml

