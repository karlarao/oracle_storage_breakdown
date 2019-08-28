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

set termout off
set heading on
set markup html on
spool storage_07_autoextend-&_instname-&_conname-&_conid..html

    -- SHOW AUTOEXTEND TABLESPACES 
    set lines 300
    col file_name format a65
    select 
            c.file#, a.tablespace_name as "TS", a.file_name, a.bytes/1024/1024/1024 as "SIZE GB", a.increment_by * c.block_size/1024/1024/1024 as "INCREMENT_BY GB", a.maxbytes/1024/1024/1024 as "MAX GB"
    from 
            dba_data_files a, dba_tablespaces b, v$datafile c
    where 
            a.tablespace_name = b.tablespace_name
            and a.file_name = c.name
            and a.tablespace_name in (select tablespace_name from dba_tablespaces)
            and a.autoextensible = 'YES'
    union all
    select 
            c.file#, a.tablespace_name as "TS", a.file_name, a.bytes/1024/1024/1024 as "SIZE GB", a.increment_by * c.block_size/1024/1024/1024 as "INCREMENT_BY GB", a.maxbytes/1024/1024/1024 as "MAX GB"
    from 
            dba_temp_files a, dba_tablespaces b, v$tempfile c
    where 
            a.tablespace_name = b.tablespace_name
            and a.file_name = c.name
            and a.tablespace_name in (select tablespace_name from dba_tablespaces)
            and a.autoextensible = 'YES'
    union all        
    select 
            null filen, 'TOTAL PERM' ts, null datafiles, sum(a.bytes/1024/1024/1024) as "SIZE GB", sum(a.increment_by * c.block_size/1024/1024/1024) as "INCREMENT_BY GB", sum(a.maxbytes/1024/1024/1024) as "MAX GB"
    from 
            dba_data_files a, dba_tablespaces b, v$datafile c
    where 
            a.tablespace_name = b.tablespace_name
            and a.file_name = c.name
            and a.tablespace_name in (select tablespace_name from dba_tablespaces)
            and a.autoextensible = 'YES'
    union all        
    select 
            null filen, 'TOTAL TEMP' ts, null datafiles, sum(a.bytes/1024/1024/1024) as "SIZE GB", sum(a.increment_by * c.block_size/1024/1024/1024) as "INCREMENT_BY GB", sum(a.maxbytes/1024/1024/1024) as "MAX GB"
    from 
            dba_temp_files a, dba_tablespaces b, v$tempfile c
    where 
            a.tablespace_name = b.tablespace_name
            and a.file_name = c.name
            and a.tablespace_name in (select tablespace_name from dba_tablespaces)
            and a.autoextensible = 'YES'        
    /        

spool off 
set markup html off
