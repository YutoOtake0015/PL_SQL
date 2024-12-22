create or replace PROCEDURE ROUTING_FIELD(
    p_view_name IN VARCHAR2,
    p_field_number OUT NUMBER
) AS
BEGIN
    IF p_view_name MEMBER OF PKG_CONST.C_FIELD01_LIST THEN p_field_number := PKG_CONST.NUM_FIELD01;
    END IF;
END;
