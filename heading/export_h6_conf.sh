#!/bin/bash
# 抽取h6各组件的容器配置、程序配置信息，用于方便切换新cd采集配置使用
# 使用：
# 	直接采集配置:      curl -4s https://mirrors.itan90.cn/export_h6_conf.sh|bash -s 应用名称
# 	部署了多个应用时:   curl -4s https://mirrors.itan90.cn/export_h6_conf.sh|bash -s 容器名称 应用名称

# 排除容器名称
exclude_app='zookeeper|redis|mysql|spms-web-ui'

# 获取应用名称
app_name=$2
if [[ -z ${app_name} ]];then app_name=$1;fi


# 用户判断
user_list=("bohai" "lisi")
if [[ -z "${user}" || ! " ${user_list[@]} " =~ " ${user} " ]]; then
  echo "- 使用帮助"
  echo " - 脚本作用: 收集h6各组件的容器配置、程序配置信息，用于方便切换新cd采集配置使用"
  echo ""
  echo "- 运行前环境变量配置"
  echo " - export user=姓名                              例如:export user=zhangsan (必须)"
  echo " - export config_upload=false                    不上传配置,仅存储到本地 (可选)"
  echo " - export config_path='/opt/xxx.conf'            自定义配置文件地址 (可选)"
  echo " - export transfer_url=自定义transfer地址        例如:export transfer_url=http://1.1.1.1:8080 (可选)"
  echo ""
  echo "- 运行前参数指定配置"
  echo " - 获取应用配置: $0 应用名称 (必须)"
  echo " "
  echo "当前未指定使用用户或未在用户白名单,退出脚本执行,企微联系: yaobohai"
  exit 1
fi

# 获取容器名称
con_name=$1
dir_name="${app_name}"

if [[ $con_name == '' ]];then
	echo "[WARN] 未键入目标组件的名称:  $0 应用名称;例如: $0 hdpos4-dist"
	echo " "
	exit 1
fi

# 获取容器数量
container_num=$(docker ps |grep -w ${con_name}|grep -Ev ${exclude_app}| wc -l)
if [[ ${container_num} -eq 0 ]];then
        echo "[WARN] 未在主机上找到${con_name}应用"
        exit 1
elif [[ ${container_num} -gt 1 ]];then
        echo "[WARN] ${con_name}存在${container_num}个请人工处理 或指定容器名称和应用名称 <容器名称 镜像名称>;例如: $0 h4cs_zs h4cs-dist"
        exit 1
fi

container_name=$(docker ps |grep -w ${con_name}|grep -Ev ${exclude_app}|awk '{print $NF}')

# 获取容器配置
view_app_config(){
	config_file=$1
	docker cp ${container_name}:${config_file} ./
}

# 获取env以及容器信息
view_ops_config(){
	echo "容器开放端口(容器端口-->主机端口): " > ${con_name}_info.txt
	echo "" >> ${con_name}_info.txt
	docker port $container_name >> ${con_name}_info.txt
	echo "" >> ${con_name}_info.txt
	echo "" >> ${con_name}_info.txt
	echo "${container_name}内存限制: $(docker stats --no-stream ${container_name}|awk '{print $6}'|sed -n '2p')" >> ${con_name}_info.txt
	echo "${container_name}镜像标签: $(docker ps |grep ${container_name}|awk '{print $2}')" >> ${con_name}_info.txt
	echo "${container_name}部署节点: $(hostname -I|awk '{print $1}')" >> ${con_name}_info.txt
	docker exec -t ${container_name} env |grep -Ev 'JAVA_HOME|LANG|JAR_FILE|JAR_PATH|HOME|TERM|HOSTNAME|PATH'> ${con_name}_env.txt
	echo "" >> ${con_name}_info.txt
	echo "" >> ${con_name}_info.txt
	echo "容器文件/目录挂载信息(主机路径-->容器路径): " >> ${con_name}_info.txt
	docker inspect --format='{{range .Mounts}}{{if eq .Type "bind"}}{{printf "%s --> %s\n" .Source .Destination}}{{end}}{{end}}' $container_name >> ${con_name}_info.txt
}

upload_config(){
	# 调用上传文件接口
	cd ../
	tar zcf ${dir_name}.tar.gz ${dir_name}
	# 文件只保留一天且只允许下载一次
	export save_file_control=true
	export max_save_days=1
	export max_download_nums=1
	# 自定义上传服务接口使用: export transfer_url=http://xxxx:8080
	curl -4s -k https://transfer.init.ac/init/file.sh | bash -s ${dir_name}.tar.gz

	rm -rf ${dir_name}.tar.gz
	# 为避免误删除--删除文件指令暂时注释
	# rm -rf ${dir_name} ${dir_name}.tar.gz
}

# 配置文件
## 通用配置
app_conf(){
	env_config_file='/etc/hosts'
	app_config_file='/opt/heading/config/application.properties'

	if [[ $1 == 'env' ]];then
		config_files=${env_config_file}
	else
		config_files=${app_config_file}
	fi
  #
}

## 使用特定配置
jposbo(){
	config_files='/opt/heading/tomcat6/webapps/jposbo/WEB-INF/datasource.xml /opt/heading/tomcat6/webapps/jposbo/WEB-INF/hdhome/jpos/conf/posboSettings.xml /opt/heading/tomcat6/webapps/jposbo/WEB-INF/hdhome/jpos/HDLicense.properties'
}

hdpos4-dist(){
	config_files='/opt/heading/tomcat7/webapps/hdpos4-web/WEB-INF/classes/hdpos4-web.properties /opt/heading/tomcat7/webapps/hdpos4-web/WEB-INF/classes/META-INF/hdpos4-config.xml'
}

hdpos4-nome-dist(){
	config_files='/opt/heading/tomcat7/webapps/hdpos4-miniso-web/WEB-INF/classes/hdpos4-web.properties'
}

hdpos4-mincha-dist(){
	config_files='/opt/heading/tomcat7/webapps/hdpos4-mincha-web/WEB-INF/classes/hdpos4-web.properties'
}

hdpos4-mci-dist(){
	config_files='/opt/heading/tomcat7/webapps/hdpos4-mci-web/WEB-INF/classes/hdpos4-web.properties'
}

panther-dts-server(){
	config_files='/opt/heading/tomcat7/webapps/panther-dts-server/WEB-INF/classes/panther-dts-server.properties'
}

panther-taskweb(){
	config_files='/opt/heading/tomcat7/webapps/panther-web/WEB-INF/classes/panther-web.properties'
}

adi_zs(){
	config_files='/opt/heading/tomcat7/webapps/adi-server/WEB-INF/classes/adi-server.properties /opt/heading/tomcat7/webapps/adi-web/WEB-INF/classes/adi-web.properties'
}

pasoreport-web(){
	config_files='/apache-tomcat/webapps/pasoreport-web/WEB-INF/classes/pasoreport-web.properties'
}

router(){
	config_files='/opt/heading/tomcat7/webapps/router/WEB-INF/classes/router.properties'
}

init-tool(){
	config_files='/opt/heading/config/application.yml'
}

zjgssm-service(){
	config_files='/opt/heading/config/application.yml /opt/heading/config/log4j2.xml'
}

taobaowdk-service(){
	config_files='/opt/heading/config/application.yml'
}

h4cs-dist(){
	config_files='/opt/heading/tomcat7/webapps/h4cs-web/WEB-INF/classes/h4cs-web.properties /opt/heading/tomcat7/webapps/h4cs-web/WEB-INF/classes/dsRouter.json /opt/heading/tomcat7/webapps/h4cs-web/WEB-INF/classes/stos-activeOrgs.properties'
}

c3-dist(){
	config_files='/opt/heading/tomcat7/webapps/c3-web/WEB-INF/classes/c3-web.properties'
}

eaccount-server(){
	config_files='/opt/heading/tomcat7/webapps/eaccount-server/WEB-INF/classes/eaccount-server.properties'
}

jcrm-server-card(){
	config_files='/opt/heading/tomcat7/webapps/jcrm-server-card/WEB-INF/classes/jcrm-server-card.properties /opt/heading/tomcat7/webapps/jcrm-rest-doc-server/WEB-INF/classes/jcrm-rest-doc-server.properties'
}

ncconnector-server(){
	config_files='/apache-tomcat/webapps/ncconnector-server/WEB-INF/classes/ncconnector-server.properties'
}

cardserver(){
	config_files='/opt/heading/cs/server/default/deploy/cardserver.war/WEB-INF/web.xml /opt/heading/cs/server/default/deploy/hdcard-xa-ds.xml /opt/heading/cs/server/default/deploy/hdcard-ejb-ear.ear/hdcard-ejb-user.jar/custommade/appOptions.xml /opt/heading/cs/server/default/deploy/hdcard-ejb-ear.ear/hdcard-ejb-user.jar/custommade/card-user.xml /opt/heading/cs/server/default/deploy/hdcard-ejb-ear.ear/hdcard-ejb-user.jar/custommade/cardserver-user.xml /opt/heading/cs/server/default/deploy/hdcard-ejb-ear.ear/hdcard-ejb-user.jar/custommade/job-config.xml /opt/heading/cs/server/default/conf/rumba-rt.xml /opt/heading/cs/server/default/deploy/hdcard-ejb-ear.ear/hdcard-ejb-user.jar/maintain/init.xml /opt/heading/cs/server/default/deploy/hdcard-ejb-ear.ear/hdcard-ejb-user.jar/maintain/CloudCardserverConf.xml /opt/heading/cs/server/default/deploy/hdcard-ejb-ear.ear/hdcard-ejb-user.jar/maintain/cloud/CloudCrmConfig.xml /opt/heading/cs/server/default/deploy/hdcard-ejb-ear.ear/hdcard-ejb-user.jar/maintain/PHXSyncConf.xml /opt/heading/upgrade/rumba-upgrader-3.3.8/bin/upgrade_env.sh'
}

card(){
	config_files='/opt/heading/ct/server/default/deploy/hdcard-ejb-ear.ear/hdcard-ejb-user.jar/custommade/appOptions.xml /opt/heading/ct/server/default/deploy/hdcard-ejb-ear.ear/hdcard-ejb-user.jar/custommade/card-user.xml /opt/heading/ct/server/default/deploy/hdcard-ejb-ear.ear/hdcard-ejb-user.jar/custommade/cardserver-user.xml /opt/heading/ct/server/default/deploy/hdcard-ejb-ear.ear/hdcard-ejb-user.jar/custommade/job-config.xml /opt/heading/ct/server/default/deploy/hdcard-ejb-ear.ear/hdcard-ejb-user.jar/maintain/init.xml /opt/heading/ct/server/default/deploy/hdcard-ejb-ear.ear/hdcard-ejb-user.jar/maintain/CloudCardserverConf.xml /opt/heading/ct/server/default/deploy/hdcard-ejb-ear.ear/hdcard-ejb-user.jar/maintain/cloud/CloudCrmConfig.xml /opt/heading/ct/server/default/deploy/hdcard-ejb-ear.ear/hdcard-ejb-user.jar/maintain/PHXSyncConf.xml /opt/heading/cs/server/default/deploy/hdcard-xa-ds.xml /opt/heading/cs/server/default/conf/rumba-rt.xml'
}

otter-mcyp-gn-sap(){
	config_files='/opt/heading/jboss/server/default/conf/jboss-log4j.xml /opt/heading/jboss/server/default/deploy/OTTER.war/WEB-INF/classes/com/hd123/rumba/rumba.properties /opt/heading/jboss/server/default/deploy/otter-oracle-xa-ds.xml /opt/heading/jboss/server/default/deploy/quartz-xa-ds.xml /opt/heading/jboss/server/default/deploy/OTTER.war/WEB-INF/classes/myrumba.xml'
}

otter-r3-sap(){
  config_files='/opt/heading/jboss/server/default/deploy/otter-oracle-xa-ds.xml /opt/heading/jboss/server/default/deploy/quartz-xa-ds.xml /opt/heading/jboss/server/default/deploy/OTTER.war/WEB-INF/classes/com/hd123/rumba/rumba.properties /opt/heading/jboss/server/default/deploy/OTTER.war/WEB-INF/classes/myrumba.xml'
}

otter-r3-std(){
	config_files='/opt/heading/jboss/server/default/deploy/otter-oracle-xa-ds.xml /opt/heading/jboss/server/default/deploy/quartz-xa-ds.xml /opt/heading/jboss/server/default/deploy/OTTER.war/WEB-INF/classes/com/hd123/rumba/rumba.properties /opt/heading/jboss/server/default/deploy/OTTER.war/WEB-INF/classes/myrumba.xml'
}

pfs(){
	config_files='/opt/heading/tomcat7/webapps/pfs-server/WEB-INF/classes/pfs-server.properties'
}

dts-store(){
	config_files='/opt/heading/tomcat7/webapps/dts-store-web/WEB-INF/classes/dts-store-web.properties /opt/heading/tomcat7/webapps/dts-store-server/WEB-INF/classes/dts-store-server.properties'
}

ays-dm-web(){
	config_files='/opt/heading/config/application.properties /opt/heading/config/log4j2.xml'
}

# 使用通用配置
card-server-proxy-service(){ app_conf; }

h6-yzvcm-service(){ app_conf; }

fas-h6-transfer-service(){ app_conf; }

h6-qnh-service(){ app_conf; }

gem-service(){ app_conf; }

up-connector-service(){ app_conf; }

h6-openapi-service(){ app_conf; }

h6-openapi2-service(){ app_conf; }

hdpos6-mdata-service(){ app_conf; }

h6-cloudfund-service(){ app_conf; }

h6-wms-service(){ app_conf; }

hdpos6-notice-service(){ app_conf; }

openapi-doc-service(){ app_conf; }

h6-crm-service(){ app_conf; }

h6-sop-service(){ app_conf; }

h6-greeneryfruit-service(){ app_conf; }

h6-wos-service(){ app_conf; }

gssm-service(){ app_conf; }

tobaccocpos-service(){ app_conf; }

tmallwdk-server(){ app_conf; }

category-manage-service(){ app_conf; }

h4cs-syncdata-service(){ app_conf; }

hdpos-oas-service(){ app_conf; }

hdpos-wms-service(){ app_conf; }

mpa-service(){ app_conf; }

h6-vendor-service(){ app_conf; }

h6-tobacco-cis-service(){ app_conf; }

vss-spider-server(){ app_conf env; }

ras-h4-transfer(){ app_conf env; }

sas-h4-transfer(){ app_conf env; }

spms-h4-transfer(){ app_conf env; }

mas2c-transfer(){ app_conf env; }

ays-transfer2-server(){ app_conf env; }

spms-stdpms-transfer(){ app_conf env; }

mkh-mas-transfer-server(){ app_conf env; }

config-service(){ app_conf env; }

spms-server(){ app_conf env; }

spms-web(){ app_conf env; }

sydaojia-mas-transfer-server(){ app_conf env; }

sos-h6-transfer-service(){ app_conf; }

h6-jd-eclp-service(){ app_conf; }

ppmt-web(){ app_conf; }

datamanager-web(){ app_conf; }

jjleg-service(){ app_conf; }

jjl-service(){ app_conf; }

ays-service(){ app_conf; }

hdpos-stdcomponent-service(){ app_conf; }

# iwms
account-server(){ app_conf env; }

basic-server(){ app_conf env; }

wms-server(){ app_conf env; }

openapi-server(){ app_conf env; }

iwms-platform-web(){ app_conf env; }

iwms-web(){ app_conf env; }

iwms-zuul(){ app_conf env; }

iwms-eureka(){ app_conf env; }

ips-bill-server(){ app_conf env; }

ips-control-server(){ app_conf env; }

ips-archive-server(){ app_conf env; }

main(){
	# 判断是否已维护
	type ${app_name} &>/dev/null
	if [[ $? != 0 ]];then echo "[WARN] ${app_name}应用待补充,企微联系: yaobohai";exit 1;fi

	# 为每个应用都单独创建文件夹
	mkdir -p ${dir_name} && cd $_
	${app_name}

	# 获取应用配置方法
	if [[ -z ${config_path} ]];then
	    for config_file in ${config_files};do
		    view_app_config ${config_file}
	    done
	else
	    for config_file in ${config_path};do
	      view_app_config ${config_file}
	    done
	fi

	# 获取容器配置方法
	view_ops_config

 if [[ ${config_upload} == "false" ]];then
    return 0
  else
	  # 上传配置方法
	  upload_config
 fi
}

main
