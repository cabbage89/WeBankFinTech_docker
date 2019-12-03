### 构建命令

```
docker build -t="webankfintech/scriptis:v0.7.0" -f Scriptis/Dockerfile Scriptis/

```

### 运行

```
docker run -p 65123:8080 -e LINKIS_URL=http://localhost webankfintech/scriptis:v0.7.0

```