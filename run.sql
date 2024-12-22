SET SERVEROUTPUT ON
SPOOL D:\oracle\test\log\output.log

begin
    MIGRATE_DATA('vw_ikosaki02', 'ikosaki02');
end;
/

SPOOL OFF

-- truncate table ikosaki02;
-- vw_ikosaki02
-- IKOSAKI02




