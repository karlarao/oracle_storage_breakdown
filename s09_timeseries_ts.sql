
set feedback off term off head on und off trimspool on echo off lines 4000 colsep ',' arraysize 5000 verify off newpage none

COLUMN name NEW_VALUE _instname NOPRINT
select lower(instance_name) name from v$instance;

COLUMN conname NEW_VALUE _conname NOPRINT
select case 
            when a.conname = 'CDB$ROOT'   then 'ROOT'
            when a.conname = 'PDB$SEED'   then 'SEED'
            else a.conname
            end as conname
from (select SYS_CONTEXT('USERENV', 'CON_NAME') conname from dual) a;

COLUMN conid NEW_VALUE _conid NOPRINT
select SYS_CONTEXT('USERENV', 'CON_ID') conid from dual;

spool storage_09_timeseries_ts-&_instname-&_conname-&_conid..csv

    
    -- variable section start 
    COLUMN name NEW_VALUE _instname NOPRINT
    select lower(instance_name) name from v$instance;
    COLUMN name NEW_VALUE _hostname NOPRINT
    select lower(host_name) name from v$instance;
    COL ecr_dbid NEW_V ecr_dbid;
    SELECT 'get_dbid', TO_CHAR(dbid) ecr_dbid FROM v$database;
    COL ecr_instance_number NEW_V ecr_instance_number;
    SELECT 'get_instance_number', TO_CHAR(instance_number) ecr_instance_number FROM v$instance;
    COL ecr_min_snap_id NEW_V ecr_min_snap_id;
    SELECT 'get_min_snap_id', TO_CHAR(MIN(snap_id)) ecr_min_snap_id
    FROM dba_hist_snapshot WHERE dbid = &&ecr_dbid.
    and to_date(to_char(END_INTERVAL_TIME,'MM/DD/YY HH24:MI:SS'),'MM/DD/YY HH24:MI:SS') > sysdate - 300;
    -- variable section end 

    
    WITH
    ts_per_snap_id AS (
    SELECT /*+ MATERIALIZE NO_MERGE */
           us.snap_id,
           TRUNC(CAST(sn.end_interval_time AS DATE), 'HH') + (1/24) end_time,
           SUM(us.tablespace_size * ts.block_size)/1024/1024/1024 all_tablespaces_gb,
           SUM(CASE ts.contents WHEN 'PERMANENT' THEN us.tablespace_size * ts.block_size ELSE 0 END)/1024/1024/1024 perm_tablespaces_gb,
           SUM(CASE ts.contents WHEN 'UNDO'      THEN us.tablespace_size * ts.block_size ELSE 0 END)/1024/1024/1024 undo_tablespaces_gb,
           SUM(CASE ts.contents WHEN 'TEMPORARY' THEN us.tablespace_size * ts.block_size ELSE 0 END)/1024/1024/1024 temp_tablespaces_gb,
           SUM(us.tablespace_maxsize * ts.block_size)/1024/1024/1024 all_tablespaces_maxgb,
           SUM(CASE ts.contents WHEN 'PERMANENT' THEN us.tablespace_maxsize * ts.block_size ELSE 0 END)/1024/1024/1024 perm_tablespaces_maxgb,
           SUM(CASE ts.contents WHEN 'UNDO'      THEN us.tablespace_maxsize * ts.block_size ELSE 0 END)/1024/1024/1024 undo_tablespaces_maxgb,
           SUM(CASE ts.contents WHEN 'TEMPORARY' THEN us.tablespace_maxsize * ts.block_size ELSE 0 END)/1024/1024/1024 temp_tablespaces_maxgb,
           SUM(us.tablespace_usedsize * ts.block_size)/1024/1024/1024 all_tablespaces_usedgb,
           SUM(CASE ts.contents WHEN 'PERMANENT' THEN us.tablespace_usedsize * ts.block_size ELSE 0 END)/1024/1024/1024 perm_tablespaces_usedgb,
           SUM(CASE ts.contents WHEN 'UNDO'      THEN us.tablespace_usedsize * ts.block_size ELSE 0 END)/1024/1024/1024 undo_tablespaces_usedgb,
           SUM(CASE ts.contents WHEN 'TEMPORARY' THEN us.tablespace_usedsize * ts.block_size ELSE 0 END)/1024/1024/1024 temp_tablespaces_usedgb
      FROM dba_hist_tbspc_space_usage us,
           dba_hist_snapshot sn,
           v$tablespace vt,
           dba_tablespaces ts
     WHERE us.snap_id >= TO_NUMBER(NVL('&&ecr_min_snap_id.','0'))
       AND us.dbid = &&ecr_dbid.
       AND sn.snap_id = us.snap_id
       AND sn.dbid = us.dbid
       AND sn.instance_number = &&ecr_instance_number.
       AND vt.ts# = us.tablespace_id
       AND ts.tablespace_name = vt.name
     GROUP BY
           us.snap_id,
           sn.end_interval_time
    )
    SELECT
      trim('&_instname') instname,
      trim('&ecr_dbid') db_id,
      trim('&_hostname') hostname,
    TO_CHAR(end_time, 'MM/DD/YY') end_time,
    round(MAX(all_tablespaces_gb),2) all_size_gb,
    round(MAX(perm_tablespaces_gb),2) perm_size_gb,
    round(MAX(undo_tablespaces_gb),2) undo_size_gb,
    round(MAX(temp_tablespaces_gb),2) temp_size_gb,
    round(MAX(all_tablespaces_maxgb),2) all_size_maxgb,
    round(MAX(perm_tablespaces_maxgb),2) perm_size_maxgb,
    round(MAX(undo_tablespaces_maxgb),2) undo_size_maxgb,
    round(MAX(temp_tablespaces_maxgb),2) temp_size_maxgb,
    round(MAX(all_tablespaces_usedgb),2) all_size_usedgb,
    round(MAX(perm_tablespaces_usedgb),2) perm_size_usedgb,
    round(MAX(undo_tablespaces_usedgb),2) undo_size_usedgb,
    round(MAX(temp_tablespaces_usedgb),2) temp_size_usedgb
      FROM ts_per_snap_id
     GROUP BY
           TO_CHAR(end_time, 'MM/DD/YY')
     ORDER BY
     4 desc
    /

spool off 
