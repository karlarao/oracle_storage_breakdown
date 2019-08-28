
DEF v_object_prefix = 'v$';
DEF skip_11g_script = '';
COL skip_11g_script NEW_V skip_11g_script;
SELECT ' -- skip 11g ' skip_11g_column, ' echo skip 11g ' skip_11g_script FROM &&v_object_prefix.instance WHERE version LIKE '11%' or version LIKE '10%';

DEF skip_12c_script = '';
COL skip_12c_script NEW_V skip_12c_script;
SELECT ' -- skip 12c ' skip_12c_column, ' echo skip 12c ' skip_12c_script FROM &&v_object_prefix.instance WHERE version LIKE '12%' or version LIKE '18%' or version LIKE '19%';



@&&skip_12c_script.00_run_awr_storagebreakdown.sql
@&&skip_11g_script.00_run_awr_storagebreakdown_12c.sql
