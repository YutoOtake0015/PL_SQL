create or replace PROCEDURE MIGRATE_DATA(
    p_view_name IN VARCHAR2,
    p_target_table IN VARCHAR2
) AS
    v_view_name VARCHAR2(100);
    v_target_table VARCHAR2(100);
    v_field_number NUMBER;
BEGIN
    -- 引数を大文字に変更
    v_view_name := UPPER(p_view_name);
    v_target_table := UPPER(p_target_table);

    -- 領域の特定
    ROUTING_FIELD(v_view_name, v_field_number);

    -- インサートプログラムの実行
    CASE v_field_number WHEN PKG_CONST.NUM_FIELD01 THEN ROUTING_FIELD01(v_view_name, v_target_table);    
    END CASE;

END;
