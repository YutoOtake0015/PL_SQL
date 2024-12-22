create or replace PACKAGE PKG_CREATE_SQL AS
    PROCEDURE SELECT_SQL(p_view_name IN VARCHAR2, p_select_sql OUT VARCHAR2);
    PROCEDURE INSERT_SQL(p_target_table IN VARCHAR2, p_insert_sql OUT VARCHAR2, p_column_list OUT VARCHAR2, p_column_placeholder OUT VARCHAR2);
END PKG_CREATE_SQL;
/

create or replace PACKAGE BODY PKG_CREATE_SQL AS
    -- SELECT文
    PROCEDURE SELECT_SQL(p_view_name IN VARCHAR2, p_select_sql OUT VARCHAR2)
    IS
    BEGIN
        p_select_sql := 'SELECT * FROM ' || p_view_name;
    END;

    -- INSERT文
    PROCEDURE INSERT_SQL(p_target_table IN VARCHAR2, p_insert_sql OUT VARCHAR2, p_column_list OUT VARCHAR2, p_column_placeholder OUT VARCHAR2)
    IS
    BEGIN
        -- カラムリスト、プレースホルダーを生成
        SELECT LISTAGG(COLUMN_NAME, ', ') WITHIN GROUP (ORDER BY COLUMN_ID),
               LISTAGG(':' || ROWNUM, ', ') WITHIN GROUP (ORDER BY COLUMN_ID)
        INTO p_column_list, p_column_placeholder
        FROM user_tab_columns
        WHERE table_name = UPPER(p_target_table);

        -- SQL生成
        p_insert_sql := 'INSERT INTO ' || p_target_table ||  ' (' || p_column_list || ') ' || 'VALUES (' || p_column_placeholder || ')';
    END;
END PKG_CREATE_SQL;

/
