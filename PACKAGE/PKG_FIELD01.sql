create or replace PACKAGE PKG_FIELD01 AS
    PROCEDURE TO_IKOSAKI02(p_view_name IN VARCHAR2, p_target_table IN VARCHAR2);
END PKG_FIELD01;
/

CREATE OR REPLACE PACKAGE BODY PKG_FIELD01 AS
    -- SQL作成用
    v_select_sql          VARCHAR2(4000) :='';
    v_insert_sql          VARCHAR2(4000) :='';
    v_column_list         VARCHAR2(4000) :='';  -- カラムリスト
    v_column_placeholder  VARCHAR2(4000) :='';  -- プレースホルダ
    
    -- カーソル用
    v_counter    PLS_INTEGER := 0;          -- カウンタ変数
    c_batch_size CONSTANT PLS_INTEGER := 2; -- バッチサイズ

    -- エラーログ用
    v_error_message VARCHAR2(4000) := '';
    v_error_code    NUMBER := 0;
    v_current_sql   VARCHAR2(4000) := '';
    
    -- IKOSAKI02へのインサート
    PROCEDURE TO_IKOSAKI02(p_view_name IN VARCHAR2, p_target_table IN VARCHAR2)
    IS
        TYPE type_vw_ikosaki02 IS RECORD(
            NAME     VARCHAR2(100),
            TOROKUBI DATE,
            SURYO    NUMBER
        );
        -- レコード型のコレクション
        TYPE t_data02 IS TABLE OF type_vw_ikosaki02 INDEX BY PLS_INTEGER;
        v_data02 t_data02;
        
        cur_view     SYS_REFCURSOR;                 -- 動的カーソル
    BEGIN
        -- SQL、カラムリスト、プレースホルダーを生成
        PKG_CREATE_SQL.SELECT_SQL(p_view_name, v_select_sql);
        PKG_CREATE_SQL.INSERT_SQL(p_target_table, v_insert_sql, v_column_list, v_column_placeholder);
    
        -- カーソルオープン
        OPEN cur_view FOR v_select_sql;
    
        LOOP
            -- 指定サイズ分のデータをフェッチ
            FETCH cur_view BULK COLLECT INTO v_data02 LIMIT c_batch_size;
            EXIT WHEN v_data02.COUNT = 0;
            
            -- バルクインサート
            BEGIN
                FORALL i IN 1 .. v_data02.COUNT SAVE EXCEPTIONS                    
                    EXECUTE IMMEDIATE v_insert_sql 
                    USING 
                        v_data02(i).name, 
                        v_data02(i).torokubi, 
                        v_data02(i).suryo;
                COMMIT;
                
                -- カウンタを増加
                v_counter := v_counter + v_data02.COUNT;
            EXCEPTION
                WHEN OTHERS THEN
                    FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                        -- エラー情報を取得
                        v_error_code := SQL%BULK_EXCEPTIONS(i).ERROR_CODE;
                        v_error_message := SQLERRM(-v_error_code);
                        
                        -- 実際に失敗したSQLとパラメータを取得
                        v_current_sql := 'INSERT INTO ' || p_target_table || '(' || v_column_list || ')' || ' VALUES (' || 
                                         NVL(v_data02(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).name, 'NULL') || ', ' ||
                                         NVL(TO_CHAR(v_data02(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).torokubi, 'YYYY-MM-DD'), 'NULL') || ', ' ||
                                         NVL(TO_CHAR(v_data02(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).suryo), 'NULL') || ')';
                        DBMS_OUTPUT.PUT_LINE('エラーコード: ' || v_error_code || 
                                             ', メッセージ: ' || v_error_message ||
                                             ', インサートSQL: ' || v_current_sql ||
                                             ', VIEW: ' || UPPER(p_view_name));
                    END LOOP;
            END;
        END LOOP;
        
        -- カーソルを閉じる
        CLOSE cur_view;
    END;
END PKG_FIELD01;
/
