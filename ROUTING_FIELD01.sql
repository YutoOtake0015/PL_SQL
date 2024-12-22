create or replace PROCEDURE ROUTING_FIELD01(
    p_view_name IN VARCHAR2,
    p_target_table IN VARCHAR2
) AS
BEGIN
    IF p_view_name= 'VW_IKOSAKI02' THEN PKG_FIELD01.TO_IKOSAKI02(p_view_name, p_target_table); 
    END IF;
END;
