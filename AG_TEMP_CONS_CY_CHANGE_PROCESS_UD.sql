/*
1. ONLY RUN FOR CY8 TEMP AND AG CONSUMERS.
2. CHECK METER RENT CODE IN METER MASTER, IF METER RENT CODE IS NOT S THEN KEEP AS IT IS, OTHERWISE CHANGE ACCORDING TO PHASE CODE.
   1.1 PHASE(S) --> THEN RENT CODE A
   1.2 PHASE(T) --> THEN RENT CODE B
   1.3 PHASE(NULL) --> THEN RENT CODE WILL BE NULL [ONLY FOR A1 CONSUMERS]
3. PROCESS CAN UPDTE TO CYCLE 5 ONLY.
*/

DECLARE
  -- VARIABLES 
  V_FAIL_CNT      NUMBER := 0;
  V_SUCCS_CNT     NUMBER := 0;
  V_SUCCS_MTR_CNT NUMBER := 0;
  V_PHAS          VARCHAR(1);
  V_MTR_RNT_COD   VARCHAR2(2);

  -- VARTUAL TABLE[TEMP TABLE]
  V_CONS_LIST SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST(
                                    /*INSERT CONSUMER LIST HERE*/
                                    );
BEGIN
  FOR CUS_CUR IN (SELECT CUS.CUSCODE,
                         CUS.CCAT,
                         CUS.TCODE,
                         CUS.CYCLE_NO,
                         CUS.SUBDIV_CODE
                    FROM CUSTMASTER CUS
                   WHERE CUS.CCAT IN ('CAT05', 'CAT07')
                     AND CUS.CYCLE_NO = '8'
                     AND CUS.CUSCODE IN
                         (SELECT COLUMN_VALUE FROM TABLE(V_CONS_LIST))) LOOP
  
    BEGIN
      DBMS_OUTPUT.PUT_LINE('---------------------------------------');
      DBMS_OUTPUT.PUT_LINE('START CONSUMER : ' || CUS_CUR.CUSCODE);
      DBMS_OUTPUT.PUT_LINE('CCAT : ' || CUS_CUR.CCAT || ' TCODE : ' ||
                           CUS_CUR.TCODE || ' CYCLE : ' ||
                           CUS_CUR.CYCLE_NO || ' SUBDIV : ' ||
                           CUS_CUR.SUBDIV_CODE);
    
      SAVEPOINT SP_CUS_UP;
    
      -- UPDATE CUSTMASTER
      DBMS_OUTPUT.PUT_LINE('Attempting CYCLE update to 5...');
    
      UPDATE CUSTMASTER CUS
         SET CUS.CYCLE_NO = 5
       WHERE CUS.CCAT IN ('CAT05', 'CAT07')
         AND CUS.CYCLE_NO = '8'
         AND CUS.CUSCODE = CUS_CUR.CUSCODE
         AND CUS.TCODE = CUS_CUR.TCODE
         AND CUS.SUBDIV_CODE = CUS_CUR.SUBDIV_CODE;
    
      DBMS_OUTPUT.PUT_LINE('CYCLE UPDATE ROWCOUNT : ' || SQL%ROWCOUNT);
    
      IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('CYCLE NOT UPDATED FOR ' || CUS_CUR.CUSCODE);
        ROLLBACK SP_CUS_UP;
      ELSE
        DBMS_OUTPUT.PUT_LINE('CYCLE UPDATED SUCCESSFULLY');
        V_SUCCS_CNT := V_SUCCS_CNT + 1;
      END IF;
    
      -- FETCH METER DETAILS
      DBMS_OUTPUT.PUT_LINE('Fetching METER_MASTER details...');
    
      SELECT MM.PHASE, MM.MRENT_CODE
        INTO V_PHAS, V_MTR_RNT_COD
        FROM METER_MASTER MM
       WHERE MM.CUSTOMER_NO = CUS_CUR.CUSCODE;
    
      DBMS_OUTPUT.PUT_LINE('PHASE : ' || V_PHAS);
      DBMS_OUTPUT.PUT_LINE('MRENT_CODE : ' || V_MTR_RNT_COD);
    
      -- CHECK IF METER RENT CODE IS S
      IF V_MTR_RNT_COD = 'S' THEN
        DBMS_OUTPUT.PUT_LINE('MRENT_CODE = S → Updating based on PHASE');
      
        UPDATE METER_MASTER MM
           SET MM.MRENT_CODE = CASE
                                 WHEN MM.PHASE = 'S' THEN
                                  'A'
                                 WHEN MM.PHASE = 'T' THEN
                                  'B'
                                 WHEN MM.PHASE IS NULL AND
                                      CUS_CUR.TCODE = 'A1' THEN
                                  NULL
                                 ELSE
                                  MM.MRENT_CODE
                               END
         WHERE MM.CUSTOMER_NO = CUS_CUR.CUSCODE;
      
        -- CHECK RESULT
        IF SQL%ROWCOUNT >= 1 THEN
          DBMS_OUTPUT.PUT_LINE('METER UPDATE ROWCOUNT : ' || SQL%ROWCOUNT);
          V_SUCCS_MTR_CNT := V_SUCCS_MTR_CNT + 1;
        ELSE
          DBMS_OUTPUT.PUT_LINE('METER RENT CODE NOT UPDATED FOR ' ||
                               CUS_CUR.CUSCODE);
          ROLLBACK SP_CUS_UP;
          V_FAIL_CNT := V_FAIL_CNT + 1;
          CONTINUE;
        END IF;
      
      ELSE
        DBMS_OUTPUT.PUT_LINE('MRENT_CODE != S → SKIPPED UPDATE');
      END IF;
    
      DBMS_OUTPUT.PUT_LINE('STATUS => CONSUMER : ' || CUS_CUR.CUSCODE ||
                           ' | CYCLE SUCCESS : ' || V_SUCCS_CNT ||
                           ' | METER SUCCESS : ' || V_SUCCS_MTR_CNT ||
                           ' | FAIL COUNT : ' || V_FAIL_CNT);
    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('⚠ NO RECORD FOUND FOR : ' ||
                             CUS_CUR.CUSCODE);
        ROLLBACK SP_CUS_UP;
        V_FAIL_CNT := V_FAIL_CNT + 1;
      
      WHEN OTHERS THEN
        ROLLBACK SP_CUS_UP;
        DBMS_OUTPUT.PUT_LINE('❌ FAILED FOR CONSUMER : ' || CUS_CUR.CUSCODE);
        DBMS_OUTPUT.PUT_LINE('ERROR : ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('TRACE : ' ||
                             DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        V_FAIL_CNT := V_FAIL_CNT + 1;
      
    END;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('======================================');
  DBMS_OUTPUT.PUT_LINE('FINAL SUMMARY');
  DBMS_OUTPUT.PUT_LINE('TOTAL CYCLE UPDATED : ' || V_SUCCS_CNT);
  DBMS_OUTPUT.PUT_LINE('TOTAL METER UPDATED : ' || V_SUCCS_MTR_CNT);
  DBMS_OUTPUT.PUT_LINE('TOTAL FAILED        : ' || V_FAIL_CNT);

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('PROCESS COMPLETED UNSUCCESSFULLY');
    DBMS_OUTPUT.PUT_LINE('TECHNICAL ERROR : ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('ERROR LINE : ' ||
                         DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
/
