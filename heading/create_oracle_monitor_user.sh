#!/bin/bash
read -p "实例id: " dbsid
read -p "用户,回车默认MONITOR: " dbuser
dbuser=${dbuser:-MONITOR}
dbpwd='h5d4z3b2x'
echo -e "$dbuser用户密码是 $dbpwd"

# 新建监控用户并授权
su - oracle -c "export ORACLE_SID=${dbsid};sqlplus / as sysdba" <<EOF
CREATE USER $dbuser IDENTIFIED BY $dbpwd DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP PROFILE DEFAULT ACCOUNT UNLOCK;
GRANT ALTER SESSION TO $dbuser;
GRANT CREATE SESSION TO $dbuser;
GRANT CONNECT TO $dbuser;
ALTER USER $dbuser DEFAULT ROLE ALL;
GRANT SELECT ON V_\$INSTANCE TO $dbuser;
GRANT SELECT ON DBA_USERS TO $dbuser;
GRANT SELECT ON V_\$LOG_HISTORY TO $dbuser;
GRANT SELECT ON V_\$PARAMETER TO $dbuser;
GRANT SELECT ON SYS.DBA_AUDIT_SESSION TO $dbuser;
GRANT SELECT ON V_\$LOCK TO $dbuser;
GRANT SELECT ON DBA_REGISTRY TO $dbuser;
GRANT SELECT ON V_\$LIBRARYCACHE TO $dbuser;
GRANT SELECT ON V_\$SYSSTAT TO $dbuser;
GRANT SELECT ON V_\$PARAMETER TO $dbuser;
GRANT SELECT ON V_\$LATCH TO $dbuser;
GRANT SELECT ON V_\$PGASTAT TO $dbuser;
GRANT SELECT ON V_\$SGASTAT TO $dbuser;
GRANT SELECT ON V_\$LIBRARYCACHE TO $dbuser;
GRANT SELECT ON V_\$PROCESS TO $dbuser;
GRANT SELECT ON DBA_DATA_FILES TO $dbuser;
GRANT SELECT ON DBA_TEMP_FILES TO $dbuser;
GRANT SELECT ON DBA_FREE_SPACE TO $dbuser;
GRANT SELECT ON V_\$SYSTEM_EVENT TO $dbuser;

grant select on v_\$log to $dbuser;
grant select on dba_objects to $dbuser;
grant select on v_\$locked_object to $dbuser;
grant select on v_\$session to $dbuser;
grant select on v_\$SQLAREA to $dbuser;
grant select on v_\$sqltext to $dbuser; 
grant select on V_\$DATAGUARD_STATUS to $dbuser; 
grant select on v_\$archived_log to $dbuser; 
grant select on dba_tablespaces to $dbuser;
grant select on dba_hist_sys_time_model to $dbuser;
grant select on dba_hist_snapshot to $dbuser;
grant select on v_\$SYS_TIME_MODEL to $dbuser;
grant select on v_\$ASM_DISKGROUP to $dbuser;
grant select on dba_jobs TO $dbuser;
exec dbms_workload_repository.modify_snapshot_settings(interval=>30, retention=>32*24*60);

grant select on Dba_Triggers TO $dbuser;
grant select on Dba_Procedures TO $dbuser;
grant select on v_\$database to $dbuser;

grant select on HD40.HD_MONITORLOG to $dbuser;
grant select on HD40.BUY1POOLS to $dbuser;
grant select on HD40.log to $dbuser;
grant select on HD40.BUY1S to $dbuser;

grant select on HD40.rbcomponentversion to $dbuser;
grant select on HD40.hdoption to $dbuser;
grant select on HD40.rbpreference to $dbuser;

Grant CONNECT,SELECT_CATALOG_ROLE to $dbuser;
grant select any table to $dbuser;
Grant EXECUTE ON SYS.DBMS_METADATA to $dbuser;
grant select on dba_jobs_running TO $dbuser;

grant select on dba_undo_extents to $dbuser;
GRANT SELECT ON V_$sort_segment TO $dbuser;
GRANT SELECT ON V_$tablespace TO $dbuser;
GRANT SELECT ON V_$tempfile TO $dbuser;
grant select on dba_scheduler_job_run_details to $dbuser;

CREATE OR REPLACE VIEW MONITOR.V_H6_BUSINESS_DATA_MONITOR(NAME,DATACATEGORY,CNT) AS  

SELECT '鼎力云订单接口:接收鼎力云订单' NAME, nvl(DATACATEGORY, 0), COUNT(1) CNT
  FROM HD40.NOTIFYMESSAGE
 WHERE DATACATEGORY LIKE 'ucconnector%'
   AND RETRY >= 1
   AND LSTUPDTIME >= SYSDATE - 3
 GROUP BY nvl(DATACATEGORY, 0)
 union all

SELECT 'IWMS接口:基础资料和业务单据发送' NAME, nvl(DATACATEGORY, 0), COUNT(1) CNT
  FROM HD40.NOTIFYMESSAGE
 WHERE DATACATEGORY LIKE 'hd.iwms%'
   AND RETRY >= 1
   AND LSTUPDTIME >= SYSDATE - 3
 GROUP BY nvl(DATACATEGORY, 0)
 union all

SELECT 'IWMS接口:业务单据接收' NAME, APITYPE, COUNT(1) CNT
  FROM HD40.APIMONITOR
 WHERE LSTUPDTIME >= SYSDATE - 3
 GROUP BY APITYPE
 union all

SELECT 'VSS接口:基础资料和业务单据加工到中间表' NAME, nvl(DATACATEGORY, 0), COUNT(1) CNT
  FROM HD40.NOTIFYMESSAGE
 WHERE DATACATEGORY LIKE 'hd.vss%'
   AND RETRY >= 1
   AND LSTUPDTIME >= SYSDATE - 3
 GROUP BY nvl(DATACATEGORY, 0)
 union all

SELECT 'VSS接口:推送数据给VSS' NAME,'0', COUNT(1) CNT
  FROM (SELECT DISTINCT UUID, BIZTYPE, EVENT
          FROM HD40.VSS_PUSHLOG A
         WHERE A.PUSHRESULT <> 'ok'
           AND A.PUSHTIME >= SYSDATE - 3
           AND NOT EXISTS (SELECT 1
                  FROM HD40.VSS_PUSHLOG B
                 WHERE A.UUID = B.UUID
                   AND B.PUSHRESULT = 'ok'
                   AND B.PUSHTIME >= SYSDATE - 3))
  union all

SELECT 'VSS接口:接收VSS数据-接收失败' NAME, DATACLS, COUNT(1)
  FROM HD40.VSS_MIS_LOG
 WHERE RECVTIME >= SYSDATE - 3
   AND ACTION = '接收失败'
   AND DATACLS IN ('对账单确认',
                   '费用单确认',
                   '进货单确认',
                   '商品证照接收',
                   '供应商证照接收')
 GROUP BY DATACLS
 union all

SELECT 'OPENAPI2接口:接收数据' NAME, RESULT, COUNT(1)
  FROM HD40.HBCOREEVENTLOG
 WHERE RESULT = 'failed'
   AND CREATED >= SYSDATE - 3
 GROUP BY RESULT
 union all

SELECT 'SOS-TRANSFER接口:发送/接收数据' NAME, nvl(DATACATEGORY, 0), COUNT(1) CNT
  FROM HD40.NOTIFYMESSAGE
 WHERE DATACATEGORY LIKE 'sos%'
   AND RETRY >= 1
   AND LSTUPDTIME >= SYSDATE - 3
 GROUP BY nvl(DATACATEGORY, 0);
/

GRANT SELECT ON HD40.NOTIFYMESSAGE TO MONITOR;
GRANT SELECT ON HD40.APIMONITOR TO MONITOR;
GRANT SELECT ON HD40.VSS_PUSHLOG TO MONITOR;
GRANT SELECT ON HD40.VSS_MIS_LOG TO MONITOR;
GRANT SELECT ON HD40.HBCOREEVENTLOG TO MONITOR;
create index hd40.IDX_HBCOREEVENTLOG_2 on hd40.HBCOREEVENTLOG (CREATED, RESULT) Online;

GRANT SELECT ON HD40.SIMPLEJOBINSTANCE TO MONITOR;
GRANT SELECT ON HD40.HBREPORTDEFINE TO MONITOR;
GRANT SELECT ON HD40.HBUSEROPERATELOG TO MONITOR;
GRANT SELECT ON HD40.FAUSER TO MONITOR;
GRANT SELECT ON HD40.HBREPORTDEFINEPUBLISH TO MONITOR;
GRANT SELECT ON HD40.HBDATASOURCE TO MONITOR; 
CREATE OR REPLACE FUNCTION hd40.dba_parsejsonstr(p_jsonstr varchar2,
                                            startkey  varchar2,
                                            endkey    varchar2)
  RETURN VARCHAR2 IS
  rtnVal VARCHAR2(32767);
BEGIN
  if endkey = '}' then
    rtnVal := substr(p_jsonstr,
                     (instr(p_jsonstr, startkey) + length(startkey) + 2),
                     (instr(p_jsonstr, endkey, instr(p_jsonstr, startkey)) -
                     instr(p_jsonstr, startkey) - length(startkey) - 2));
  else
    rtnVal := substr(p_jsonstr,
                     (instr(p_jsonstr, startkey) + length(startkey) + 2 + 1),
                     (instr(p_jsonstr, endkey, instr(p_jsonstr, startkey)) -
                     instr(p_jsonstr, startkey) - length(startkey) - 4 - 2));
  end if;
  RETURN rtnVal;
END dba_parsejsonstr;
/
grant EXECUTE ON HD40.dba_parsejsonstr to MONITOR;

commit;
alter system switch logfile;
exit
EOF
crdrresult=$?
if [ "$crdrresult" != "0" ];then
	echo "create user failure!!!"
fi
