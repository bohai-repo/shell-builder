#!/bin/bash

# 依赖jq工具
# yum -y install epel-release && yum -y install jq
set -e

# 处理命令行动作
ops_command=$1

api_server='http://lvs.xxx.com'
api_accessid='test01'
api_accesskey='test01password'

# 目标实例IP
instance_ip=$2
# 目标实例端口
instance_port=$3
# 目标组ID
instance_group_id=$4

# 获取token方法
function get_token(){
	# @input: 平台地址 api_server='http://xxx.com'
	# @input: 平台用户 api_accessid='demo' 
	# @input: 平台密码 api_accesskey='demo'
	curl -s "${api_server}/api/auth/getToken/" -H 'Content-Type: application/json' --data '{"accessId":"'"${api_accessid}"'","accessKey":"'"${api_accesskey}"'"}' > ${TOKEN_TEXT_FILE}
	if [[ $? != 0 ]];then echo "获取token失败 请检查api地址、accessid、accesskey";exit 1;fi
 	token=$(cat ${TOKEN_TEXT_FILE}|awk -F '"' '{print $(NF-1)}')
}

# 根据IP查询实例ID方法
function get_instanceid(){
	# @input: instance_ip='12.12.11.33'
	# @return: instance_id
	curl -s -X POST "${api_server}/api/lvsApi/rsServer/list" -H 'Content-Type: application/json' --header "accessId: ${api_accessid}" --header "Authorization: ${token}" > ${SOCKET_TEXT_FILE}
	instance_id=$(cat ${SOCKET_TEXT_FILE}|jq '.data[] | select(.ip == "'"${instance_ip}"'") | .id')
	if [[ ${instance_id} = '' ]];then
		echo "未能查询到 ${instance_ip} 实例ID 请检查实例IP或配置信息是否正确"
		exit 1
	fi

	# 命令行查询实例ID
	# @run: sh xxx.sh get_instanceid 12.12.11.33
	if [[ ${ops_command} == 'get_instanceid' ]];then
  		echo "${instance_ip}实例ID: ${instance_id}"
 	fi
}

# 根据IP添加主机方法
function add(){
	# @input: 实例IP instance_ip='12.12.11.33' 
	# @input: 实例端口 instance_port='80'
	# @input: 实例组ID instance_group_id='3'
	# @run: sh xxx.sh add 12.12.11.33 80 3
	if [[ -z ${instance_port} ]]; then
		echo "未定义实例端口";exit 1
	fi

	if [[ -z ${instance_group_id} ]]; then
		echo "未定义实例组ID";exit 1
	fi

	curl -s -X POST "${api_server}/api/lvsApi/rsServer/insert" -H 'Content-Type: application/json' --header "accessId: ${api_accessid}" --header "Authorization: ${token}" --data '{"ip":"'"${instance_ip}"'","lvsGroupId":"'"${instance_group_id}"'","port":"'"${instance_port}"'"}' &>/dev/null
	if [[ $? != 0 ]];then echo "添加主机失败";exit 1;else
		get_instanceid
		echo "添加主机${instance_ip}成功 主机ID: ${instance_id}"
	fi
}

# 根据IP、ID删除主机方法
function del(){
	# @input: 实例IP instance_id='3' 
	# @run: sh xxx.sh del 12.12.11.33
	get_instanceid
	curl -s -X POST "${api_server}/api/lvsApi/rsServer/delete/${instance_id}" -H 'Content-Type: application/json' --header "accessId: ${api_accessid}" --header "Authorization: ${token}" &>/dev/null
	if [[ $? != 0 ]];then echo "删除主机失败";exit 1;else
		echo "删除主机${instance_ip}成功"
	fi
}

function main(){
	# 处理临时文件;存储token
	trap 'rm -f "$TOKEN_TEXT_FILE" "$SOCKET_TEXT_FILE"' EXIT
	readonly TOKEN_TEXT_FILE=$(mktemp) || exit 1
	readonly SOCKET_TEXT_FILE=$(mktemp) || exit 1

	if [[ -z ${ops_command} ]]; then
		echo "usage: sh $0 add/del";exit 1
	fi

	if [[ -z ${api_server} ]]; then
		echo "未定义api_server";exit 1
	fi

	if [[ -z ${api_accessid} ]]; then
		echo "未定义accessid";exit 1
	fi

	if [[ -z ${api_accesskey} ]]; then
		echo "未定义accesskey";exit 1
	fi

	if [[ -z ${instance_ip} ]]; then
		echo "未定义实例IP";exit 1
	fi

	# 执行获取token
 	get_token
	# 执行相关动作: add(添加主机)/del(删除主机)
	${ops_command}
}

main
