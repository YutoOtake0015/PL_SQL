DECLARE
    -- 定数の定義
    c_kbn_30 CONSTANT NUMBER := 30;

    -- kbn=30のレコードを格納するコレクション型を定義
    TYPE t_test_tbl_01 IS TABLE OF TEST_TBL_01%ROWTYPE INDEX BY PLS_INTEGER;
    v_test_tbl_01 t_test_tbl_01;

    -- 内部関数の定義
    FUNCTION get_kbn30_records(p_no IN TEST_TBL_01.NO%TYPE) RETURN t_test_tbl_01 IS
        v_result t_test_tbl_01;
    BEGIN
        SELECT *
        BULK COLLECT INTO v_result
        FROM TEST_TBL_01
        WHERE no = p_no
          AND kbn = c_kbn_30; -- 定数を使用

        RETURN v_result;
    END get_kbn30_records;

BEGIN
    -- noごとにループ
    FOR v_no_cur IN (SELECT DISTINCT no FROM TEST_TBL_01) LOOP
        -- kbn=30のレコードを取得
        v_test_tbl_01 := get_kbn30_records(v_no_cur.no);
        
        IF v_test_tbl_01.COUNT > 0 THEN 
          FOR i IN 1 .. v_test_tbl_01.COUNT LOOP
            -- kbn=30以外の期間を調整
            FOR rec IN (SELECT *
                        FROM TEST_TBL_01
                        WHERE no = v_no_cur.no AND kbn <> c_kbn_30) LOOP
                        
                -- kbn30の期間が他区分の期間内に重複する場合の処理
                IF v_test_tbl_01(i).st_date IS NOT NULL
                AND v_test_tbl_01(i).ed_date IS NOT NULL
                AND rec.st_date IS NOT NULL
                AND rec.ed_date IS NOT NULL THEN
                    IF rec.st_date <= v_test_tbl_01(i).st_date
                    AND rec.ed_date >= v_test_tbl_01(i).ed_date THEN
                        
                        -- 前半の期間を切り出し
                        UPDATE TEST_TBL_01
                        SET ed_date = v_test_tbl_01(i).st_date - 1
                        WHERE no = v_no_cur.no
                          and kbn <> c_kbn_30
                          and ed_date = rec.ed_date;
                        
                        -- 後半の期間を切り出し
                        INSERT INTO TEST_TBL_01 (tuban, no, kbn, st_date, ed_date)
                        VALUES (
                            rec.tuban,
                            rec.no,
                            rec.kbn,
                            v_test_tbl_01(i).ed_date + 1,
                            rec.ed_date
                        );
                    END IF;
                END IF;
                        
                -- kbn30のST_DATEと区分30以外のED_DATEを比較
                IF v_test_tbl_01(i).st_date IS NOT NULL
                AND rec.ed_date IS NOT NULL
                AND rec.ed_date BETWEEN v_test_tbl_01(i).st_date AND v_test_tbl_01(i).ed_date THEN
                    -- 区分30以外のED_DATEを調整（重複しない日付に変更）
                    UPDATE TEST_TBL_01
                    SET ed_date = v_test_tbl_01(i).st_date - 1
                    WHERE no = v_no_cur.no
                      and kbn <> c_kbn_30
                      and ed_date = rec.ed_date;
                END IF;
                
                -- kbn30のED_DATEと区分30以外のST_DATEを比較
               IF v_test_tbl_01(i).ed_date IS NOT NULL
               AND rec.st_date IS NOT NULL
               AND rec.st_date BETWEEN v_test_tbl_01(i).st_date AND v_test_tbl_01(i).ed_date THEN
                    -- 区分30以外のST_DATEを調整（重複しない日付に変更）
                    UPDATE TEST_TBL_01
                    SET st_date = v_test_tbl_01(i).ed_date + 1
                    WHERE no = v_no_cur.no
                      and kbn <> c_kbn_30
                      AND st_date = rec.st_date;
                END IF;
            END LOOP;
          END LOOP;
        END IF;
        
      -- ED_DATE < ST_DATE のレコードを削除
      DELETE FROM TEST_TBL_01
      WHERE ed_date < st_date
        AND no = v_no_cur.no;
      
      -- TUBANに連番を採番する処理
      MERGE INTO TEST_TBL_01 tgt
      USING (
          -- noごとにst_date昇順で連番を生成
          SELECT ROWID AS row_id,
                 ROW_NUMBER() OVER (PARTITION BY no ORDER BY st_date) AS new_tuban
          FROM TEST_TBL_01
      ) src
      ON (tgt.ROWID = src.row_id)
      WHEN MATCHED THEN
          UPDATE SET tgt.tuban = src.new_tuban;

      -- 更新を確定
      COMMIT;
    END LOOP;

    -- 更新を確定
    COMMIT;
    


    -- 削除を確定
    COMMIT;
END;
/
