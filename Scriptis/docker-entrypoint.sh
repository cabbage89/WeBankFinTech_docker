echo "环境变量:\n"

export

echo "正在配置nginx..."

sed -i "s%linkis_url%${LINKIS_URL}%g" /etc/nginx/conf.d/scriptis.conf

cat /etc/nginx/conf.d/scriptis.conf

echo "\n正在启动nginx..."

exec nginx -g 'daemon off;'