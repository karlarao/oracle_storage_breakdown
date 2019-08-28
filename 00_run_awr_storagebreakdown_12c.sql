
COLUMN name NEW_VALUE _instname NOPRINT
select lower(instance_name) name from v$instance;

alter session set container = CDB$ROOT;

-- exadata
@s01_celliorm.sql
@s01_cellpd.sql
@s01_cellpdx.sql
@s01_cellver.sql
@s01_exadisktopo.sql
@s01_exadisktopo2.sql

-- autoextend 
-- @s07_autoextend.sql 

-- time series asm 
@s08_timeseries_asm.sql

-- asm
@s02_asmfree.sql

-- db size pdb
@s03_db_size.sql

-- ts size pdb
@s04_ts_size.sql

-- obj size pdb
@s05_obj_size.sql

-- obj top sql pdb
@s06_run_awr_topsql_bigobj_topn_v3_by_elap.sql
@s06_run_awr_topsql_bigobj_topn_v3_by_elap_exec.sql
@s06_run_awr_topsql_bigobj_topn_v3_by_exec.sql

-- time series ts pdb 
@s09_timeseries_ts.sql

-- hcc tables ts pdb
@s10_hcc_tables_ts.sql 

-- execute for each pdb 
spool krlforeachpdb-&_instname..sql 
set head off
select 'alter session set container = ' || name || ';' 
|| CHR(10) || '@s03_db_size.sql' 
|| CHR(10) || '@s04_ts_size.sql' 
|| CHR(10) || '@s05_obj_size.sql' 
|| CHR(10) || '@s06_run_awr_topsql_bigobj_topn_v3_by_elap.sql'
|| CHR(10) || '@s06_run_awr_topsql_bigobj_topn_v3_by_elap_exec.sql'
|| CHR(10) || '@s06_run_awr_topsql_bigobj_topn_v3_by_exec.sql'
|| CHR(10) || '@s09_timeseries_ts.sql'
|| CHR(10) || '@s10_hcc_tables_ts.sql'
from v$pdbs
where con_id != 2;
spool off 
@krlforeachpdb-&_instname..sql

-- asm
@s02_asmfree2.sql


exit

