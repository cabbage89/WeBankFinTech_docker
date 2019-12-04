bootscript=$(find bin -iname "start-*.sh")

echo "发现启动脚本:$bootscript,执行中..."

line_nohup=$(cat $bootscript |grep -n nohup| cut -d ":" -f 1)
sed -i "${line_nohup}i\export" $bootscript

sed -i "s/\/lib\/\*/\/lib\/\*:\/opt\/module\/lib\/\*/g"  $bootscript

echo "
sleep 2s

out=\$(find \$DWS_ENTRANCE_LOG_PATH -iname \"*.out\")

echo \"发现输出文件：\$out\"

tail -f \$out 
">>$bootscript

exec $bootscript