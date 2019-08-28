
set feedback off term off head on und off trimspool on echo off lines 4000 colsep ',' arraysize 5000 verify off newpage none

COLUMN name NEW_VALUE _instname NOPRINT
select lower(instance_name) name from v$instance;

spool storage_08_timeseries_asm-&_instname..csv


select * from (    
            WITH snaplist as (
            SELECT 
            to_char(a.begin_interval_time, 'yyyy-mm-dd') as logdate,
            to_char(a.begin_interval_time, 'MM/DD/YY') as logdate2,
            to_char(a.begin_interval_time, 'yyyy') as logyear,
            to_char(a.begin_interval_time, 'mm') as logmonth,
            a.snap_id, a.dbid, case 
            when a.dbid = '2024176565'   then 'EXP1'
            when a.dbid = '1890029227'   then 'EXP2'
            when a.dbid = '1922913859'   then 'EXP3'
            when a.dbid = '1826652812'   then 'EXP5'
            else 'OTHER-'||a.dbid
            end as SYSTEM_ID,
            b.name as dname
            from DBA_HIST_SNAPSHOT a, v$database b
            where a.dbid = b.dbid
            and to_date(to_char(a.begin_interval_time,'MM/DD/YY HH24:MI:SS'),'MM/DD/YY HH24:MI:SS')  >= trunc(add_months(sysdate,-13),'MM') 
            order by a.snap_id, a.dbid,to_char(a.begin_interval_time, 'yyyy-mm-dd')
            )
            select 
            dname, system_id, logdate, logdate2, logyear, logmonth, g.group_number,g.name,g.type,
            round(max(s.total_mb/(1024*1024)),2) TOTAL_RAW_TB, 
            round(max(s.free_mb/(1024*1024)),2) FREE_RAW_TB,
            round(max(s.total_mb/(1024*1024))/2,2) TOTAL_USABLE_TB, 
            round(max(s.free_mb/(1024*1024))/2,2) FREE_USABLE_TB,
            round(max(s.total_mb/(1024*1024))/2,2) - round(max(s.free_mb/(1024*1024))/2,2) TOTAL_USABLE_USED_TB
                  FROM DBA_HIST_ASM_DISKGROUP_STAT s, 
                       snaplist sn,
                       DBA_HIST_ASM_DISKGROUP g 
                 WHERE sn.snap_id = s.snap_id
                   AND sn.dbid = s.dbid
                   AND sn.dbid = g.con_dbid
                   AND s.con_dbid = g.con_dbid 
                   AND s.group_number = g.group_number
            group by dname, system_id, logdate, logdate2, logyear, logmonth, g.group_number,g.name,g.type
            order by sn.system_id, g.name, g.type, logdate
        );

spool off        