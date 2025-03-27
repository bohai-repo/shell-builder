#!/bin/bash

app_name=$1
datetime=$(date "+%Y-%m-%d")

kubectl_command(){
        kubectl --kubeconfig /home/heading/prod_config -n iwms $@
}

get_pod_name(){
    pod_name=$(kubectl_command get po -n iwms -l app=${app_name}|awk '{print $1}'|grep -vE 'dbupgrade|NAME')
    node01=$(echo "${pod_name}"|sed -n 1p)
    node02=$(echo "${pod_name}"|sed -n 2p)
}

# 获取rf日志
rf(){
    if [[ -f /tmp/rf-logs-${datetime}.tar.gz ]];then
        rm -rf /tmp/rf-logs-${datetime}.tar.gz
    fi
    export app_name='wms-server';get_pod_name
    mkdir -p /tmp/rf-logs-${datetime}/;cd /tmp/rf-logs-${datetime}
    kubectl_command cp iwms/${node01}:/apache-tomcat/logs/iwms-wms/rf.log ./rf-node01.log
    kubectl_command cp iwms/${node02}:/apache-tomcat/logs/iwms-wms/rf.log ./rf-node02.log
    cd ../
    tar zcvf rf-logs-${datetime}.tar.gz rf-logs-${datetime}
    rm -rf rf-logs-${datetime}
}

openapi-server(){
    if [[ -f /tmp/${app_name}-logs-${datetime}.tar.gz ]];then
        rm -rf /tmp/${app_name}-logs-${datetime}.tar.gz
    fi
    get_pod_name
    mkdir -p /tmp/${app_name}-logs-${datetime}/node{01,02};cd /tmp/${app_name}-logs-${datetime}

    # access日志
    kubectl_command cp iwms/${node01}:/apache-tomcat/logs/localhost_access_log.${datetime}.txt ./node01/localhost_access_log.${datetime}.txt
    kubectl_command cp iwms/${node02}:/apache-tomcat/logs/localhost_access_log.${datetime}.txt ./node02/localhost_access_log.${datetime}.txt
    # 业务日志
    kubectl_command cp iwms/${node01}:/apache-tomcat/logs/iwms-openapi/main.log ./node01/main.log
    kubectl_command cp iwms/${node02}:/apache-tomcat/logs/iwms-openapi/main.log ./node02/main.log

    cd ../
    tar zcvf ${app_name}-logs-${datetime}.tar.gz ${app_name}-logs-${datetime}
    rm -rf ${app_name}-logs-${datetime}
}

wms-server(){
    if [[ -f /tmp/${app_name}-logs-${datetime}.tar.gz ]];then
        rm -rf /tmp/${app_name}-logs-${datetime}.tar.gz
    fi
    get_pod_name
    mkdir -p /tmp/${app_name}-logs-${datetime}/node{01,02};cd /tmp/${app_name}-logs-${datetime}

    # access日志
    kubectl_command cp iwms/${node01}:/apache-tomcat/logs/localhost_access_log.${datetime}.txt ./node01/localhost_access_log.${datetime}.txt
    kubectl_command cp iwms/${node02}:/apache-tomcat/logs/localhost_access_log.${datetime}.txt ./node02/localhost_access_log.${datetime}.txt
    # 业务日志
    kubectl_command cp iwms/${node01}:/apache-tomcat/logs/iwms-wms/main.log ./node01/main.log
    kubectl_command cp iwms/${node02}:/apache-tomcat/logs/iwms-wms/main.log ./node02/main.log

    cd ../
    tar zcvf ${app_name}-logs-${datetime}.tar.gz ${app_name}-logs-${datetime}
    rm -rf ${app_name}-logs-${datetime}
}

basic-server(){
    if [[ -f /tmp/${app_name}-logs-${datetime}.tar.gz ]];then
        rm -rf /tmp/${app_name}-logs-${datetime}.tar.gz
    fi
    get_pod_name
    mkdir -p /tmp/${app_name}-logs-${datetime}/node{01,02};cd /tmp/${app_name}-logs-${datetime}

    # access日志
    kubectl_command cp iwms/${node01}:/apache-tomcat/logs/localhost_access_log.${datetime}.txt ./node01/localhost_access_log.${datetime}.txt
    kubectl_command cp iwms/${node02}:/apache-tomcat/logs/localhost_access_log.${datetime}.txt ./node02/localhost_access_log.${datetime}.txt
    # 业务日志
    kubectl_command cp iwms/${node01}:/apache-tomcat/logs/iwms-basic/main.log ./node01/main.log
    kubectl_command cp iwms/${node02}:/apache-tomcat/logs/iwms-basic/main.log ./node02/main.log

    cd ../
    tar zcvf ${app_name}-logs-${datetime}.tar.gz ${app_name}-logs-${datetime}
    rm -rf ${app_name}-logs-${datetime}
}

account-server(){
    if [[ -f /tmp/${app_name}-logs-${datetime}.tar.gz ]];then
        rm -rf /tmp/${app_name}-logs-${datetime}.tar.gz
    fi
    get_pod_name
    mkdir -p /tmp/${app_name}-logs-${datetime}/node{01,02};cd /tmp/${app_name}-logs-${datetime}

    # access日志
    kubectl_command cp iwms/${node01}:/apache-tomcat/logs/localhost_access_log.${datetime}.txt ./node01/localhost_access_log.${datetime}.txt
    kubectl_command cp iwms/${node02}:/apache-tomcat/logs/localhost_access_log.${datetime}.txt ./node02/localhost_access_log.${datetime}.txt
    # 业务日志
    kubectl_command cp iwms/${node01}:/apache-tomcat/logs/iwms-account/main.log ./node01/main.log
    kubectl_command cp iwms/${node02}:/apache-tomcat/logs/iwms-account/main.log ./node02/main.log

    cd ../
    tar zcvf ${app_name}-logs-${datetime}.tar.gz ${app_name}-logs-${datetime}
    rm -rf ${app_name}-logs-${datetime}
}


if [[ -z ${app_name} ]];then
    echo "输入要提取日志的应用名: 例如: bash $0 openapi-server"
    exit 1
else
    ${app_name}
fi