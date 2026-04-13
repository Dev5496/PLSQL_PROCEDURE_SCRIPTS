-- FIX AND SET ADJUSTMENT PROCESS:
/*****************************************************************************************************************************************************
LOGIC:
1. ENTER THE TRANSACTION IDs IN THE LOOP MANUALLY, TO RUN THE PROCESS.

2. 4 OPTIONS IN PROCESS: ONLY ONE OPTION IS SELEACTED AT A TIME
     
     2.1 FIX APPROVE REJECT ISSUE [ADJUSTMENT_CHARGE_MASTER_DATA] - ARP
         2.1.1 REMOVE EXTRA DEGITS AFTER PRECESION AND ONLY KEEP 2 DIGITS.
         2.1.2 CHECK IF USERNAME IS NULL, IF NULL THE GET THE USER NAME FROM PREVIOUS RECORD, AND UPDATE IN USER NAME.
     
     2.2 SET ADJUSTMENT FOR BILL PROCES ONLY [ADJUSTMENT_CHARGE_MASTER] - BIL  
         CHECK IF ADJUSTMENT_STATUS AND PROCESSED_DATE IS NULL OR NOT, IF NOT NULL THEN ADJ IS ALREADY CONSIDERED IN BILL PROCESS
         SKIP TRANSACTION ID IF ALREADY CONSIDERED, CONTINUE WITH NEXT ID
         CHECK IF MONTH_END_STATUS AND MONTH_END_DTMONTH_END_DT IS NULL OR NOT, IF NOT THEN SKIP AND CONTINUE WITH OTHER IDs
         UPDATE MONTH_END_STATUS = p AND 
         MONTH_END_DT = '01-06-2022' 
         
    2.3 SET ADJUSTMENT FOR MONTH-END PROCES ONLY [ADJUSTMENT_CHARGE_MASTER] - MON
        CHECK IF MONTH_END_STATUS AND MONTH_END_DT IS NULL OR NOT, IF NOT NULL THEN ADJ IS ALREADY CONSIDERED IN MONTH-END PROCESS
        SKIP TRANSACTION ID IF ALREADY CONSIDERED, CONTINUE WITH NEXT IDs
        CHECK IF ADJUSTMENT_STATUS AND PROCESSED_DATE IS NULL OR NOT, IF NOT THEN SKIP AND CONTINUE WITH OTHER IDs
        UPDATE ADJUSTMENT_STATUS = p  
        PROCESSED_DATE = '01-06-2022'
        
    2.4 REMOVE DUPLICATE ADJUSTMENT[ADJUSTMENT_CHARGE_MASTER] - DUP 
        KEEP ONE RECORD FROM TWO.

3. PROCESS WILL MOSTLY USE AND RUN THROUGH TRANSACTION IDs.

4. PROCESS CODE:
   4.1 FIX APPROVE REJECT           - ARP
   4.2 BILL PROCESS ADJUSTMENT      - BILL
   4.3 MONTH-END PROCESS ADJUSTMENT - MON
   4.4 REMOVE DUPLICATE ADJ         - DUP
   
5. PROCESS WILL STOP FOR THE TRANSACTION ID WHOS' ADJUSTMENT IS ALREADY CONSIDERED EITHER IN BILL OR MONTH-END.

6. IF TRANSACTION ID NOT FOUND IN ADJUSTMENT_CHARGE_MASTER THEN THAT IDs IS STILL UNDER APPROVE/REJECT PROCESS.

7. SAVEPOINT, SO WHOLE PROCESS DOES NOT STOP WHEN ANY ID FAIL OR SKIPPED.

8. TO REMOVE DUPLICATE ADJUSTMENT, IT NEEDS TO BE UNPROCESS[NOT IN MONTH-END AND BILL PROCESS].
*****************************************************************************************************************************************************/

DECLARE
  -- VARIABLES:
  V_SKIP_CNT    NUMBER := 0;
  V_SUCCESS_CNT NUMBER := 0;
  V_FAIL_CNT    NUMBER := 0;
  V_DUP_ADJ_CNT NUMBER := 0;
  V_MIN_ROID    ROWID;

  -- VARIABLES: HARDCORE VALUES
  V_MANUAL_DT DATE := TO_DATE('01-06-2022', 'DD-MM-YYYY');

  -- INPUTS: 
  P_PROCESS_CODE VARCHAR(10) := TRIM(UPPER('&PROCESS_CODE'));
BEGIN
  -- CHECK PROCESS CODE: NOT VALID THEN PROCESS STOP.
  IF P_PROCESS_CODE NOT IN ('ARP', 'BILL', 'MON', 'DUP') THEN
    DBMS_OUTPUT.PUT_LINE('ENTER VALID PROCESS CODE : ARP / BILL / MON / DUP');
    RETURN;
  END IF;

  DBMS_OUTPUT.PUT_LINE('======================================================');
  DBMS_OUTPUT.PUT_LINE('ADJUSTMENT PROCESS STARTED');
  DBMS_OUTPUT.PUT_LINE('PROCESS CODE [ACTION] : ' || P_PROCESS_CODE);
  DBMS_OUTPUT.PUT_LINE('======================================================');

  /***********************************************
   ADJUSTMENT CHARGE MASTER RELATD PROCESS ONLY
  ***********************************************/
  IF P_PROCESS_CODE IN ('BILL', 'MON', 'DUP') THEN
    FOR ADJ_TRANS_ID IN (SELECT AM.TRANSACTION_ID,
                                AM.ADJUSTMENT_STATUS,
                                AM.PROCESSED_DATE,
                                AM.MONTH_END_STATUS,
                                AM.MONTH_END_DT,
                                AM.ADJUSTMENT_AMOUNT
                           FROM ADJUSTMENT_CHARGE_MASTER AM
                          WHERE AM.TRANSACTION_ID IN
                                (SELECT COLUMN_VALUE
                                   FROM TABLE(SYS.ODCINUMBERLIST( /*INSERT TRANSACTION ID HERE*/
                                              )))
                          ORDER BY AM.TRANSACTION_ID, AM.ROWID) LOOP
      SAVEPOINT SP_PER_ID;
      BEGIN
      
        DBMS_OUTPUT.PUT_LINE('----------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('TRANSACTION ID : ' ||
                             ADJ_TRANS_ID.TRANSACTION_ID || '  AMOUNT : ' ||
                             ADJ_TRANS_ID.ADJUSTMENT_AMOUNT);
      
        /******************************************************************
                              BILL PROCESS ADJUSTMENT
        ******************************************************************/
        IF P_PROCESS_CODE = 'BILL' THEN
        
          -- CHECK IF ADJUSTMENT IS ALREADY CONSIDERED IN THE BILL PROCESS OR MONTH-EN PROCESS
          IF (ADJ_TRANS_ID.ADJUSTMENT_STATUS IS NOT NULL AND
             ADJ_TRANS_ID.PROCESSED_DATE IS NOT NULL) OR
             (ADJ_TRANS_ID.MONTH_END_STATUS IS NOT NULL AND
             ADJ_TRANS_ID.MONTH_END_DT IS NOT NULL) THEN
          
            -- CHECK IF ADJUSTMENT IS CONSIDERED IN MONTH-END
            IF ADJ_TRANS_ID.MONTH_END_STATUS IS NOT NULL AND
               ADJ_TRANS_ID.MONTH_END_DT IS NOT NULL THEN
            
              DBMS_OUTPUT.PUT_LINE('SKIPPED : ADJUSTMENT ALREADY CONSIDERED IN MONTH-END, ALSO IT WILL CONSIDERED IN BILL PROCESS.');
              DBMS_OUTPUT.PUT_LINE('MONTH_END_DT : ' ||
                                   ADJ_TRANS_ID.MONTH_END_DT);
              V_SKIP_CNT := V_SKIP_CNT + 1;
            
            ELSE
              -- UPDATE IF MONTH-END FLAG AND DATE IS NULL, TO CONSIDERED ADJ ONLY IN BILL PROCESS
              UPDATE ADJUSTMENT_CHARGE_MASTER UACM
                 SET UACM.MONTH_END_STATUS = 'p',
                     UACM.MONTH_END_DT     = V_MANUAL_DT
               WHERE UACM.TRANSACTION_ID = ADJ_TRANS_ID.TRANSACTION_ID
                 AND UACM.MONTH_END_STATUS IS NULL
                 AND UACM.MONTH_END_DT IS NULL;
            
              DBMS_OUTPUT.PUT_LINE('UPDATED1.1 : SET FOR ONLY BILL PROCESS');
              V_SUCCESS_CNT := V_SUCCESS_CNT + 1;
            
            END IF;
            -- UPDATE IF ADJ IS NOT CONSIDERED IN BILL AS WELL AS MONTH-END.  
          ELSIF ADJ_TRANS_ID.ADJUSTMENT_STATUS IS NULL AND
                ADJ_TRANS_ID.PROCESSED_DATE IS NULL AND
                ADJ_TRANS_ID.MONTH_END_STATUS IS NULL AND
                ADJ_TRANS_ID.MONTH_END_DT IS NULL THEN
          
            UPDATE ADJUSTMENT_CHARGE_MASTER UACM
               SET UACM.MONTH_END_STATUS = 'p',
                   UACM.MONTH_END_DT     = V_MANUAL_DT
             WHERE UACM.TRANSACTION_ID = ADJ_TRANS_ID.TRANSACTION_ID
               AND UACM.MONTH_END_STATUS IS NULL
               AND UACM.MONTH_END_DT IS NULL;
          
            DBMS_OUTPUT.PUT_LINE('UPDATED1.2 : SET FOR ONLY BILL PROCESS');
            V_SUCCESS_CNT := V_SUCCESS_CNT + 1;
          
          END IF;
        
          /******************************************************************
                             MONTH-END PROCESS ADJUSTMENT
          ******************************************************************/
        ELSIF P_PROCESS_CODE = 'MON' THEN
        
          -- CHECK IF ADJUSTMENT IS ALREADY CONSIDERED IN THE BILL PROCESS OR MONTH-EN PROCESS
          IF (ADJ_TRANS_ID.ADJUSTMENT_STATUS IS NOT NULL AND
             ADJ_TRANS_ID.PROCESSED_DATE IS NOT NULL) OR
             (ADJ_TRANS_ID.MONTH_END_STATUS IS NOT NULL AND
             ADJ_TRANS_ID.MONTH_END_DT IS NOT NULL) THEN
          
            -- CHECK IF ADJUSTMENT IS CONSIDERED IN MONTH-END
            IF ADJ_TRANS_ID.ADJUSTMENT_STATUS IS NOT NULL AND
               ADJ_TRANS_ID.PROCESSED_DATE IS NOT NULL THEN
            
              DBMS_OUTPUT.PUT_LINE('SKIPPED : ADJUSTMENT ALREADY CONSIDERED IN BILL PROCESS, ALSO IT WILL CONSIDERED IN MONTH-END PROCESS.');
              DBMS_OUTPUT.PUT_LINE('PROCESSED_DATE : ' ||
                                   ADJ_TRANS_ID.PROCESSED_DATE);
              V_SKIP_CNT := V_SKIP_CNT + 1;
            
            ELSE
              -- UPDATE IF MONTH-END FLAG AND DATE IS NULL, TO CONSIDERED ADJ ONLY IN BILL PROCESS
              UPDATE ADJUSTMENT_CHARGE_MASTER UACM
                 SET UACM.ADJUSTMENT_STATUS = 'p',
                     UACM.PROCESSED_DATE    = V_MANUAL_DT
               WHERE UACM.TRANSACTION_ID = ADJ_TRANS_ID.TRANSACTION_ID
                 AND UACM.ADJUSTMENT_STATUS IS NULL
                 AND UACM.PROCESSED_DATE IS NULL;
            
              DBMS_OUTPUT.PUT_LINE('UPDATED : SET FOR ONLY MONTH-END PROCESS');
              V_SUCCESS_CNT := V_SUCCESS_CNT + 1;
            
            END IF;
          
            -- UPDATE IF ADJ IS NOT CONSIDERED IN BILL AS WELL AS MONTH-END.
          ELSIF ADJ_TRANS_ID.ADJUSTMENT_STATUS IS NULL AND
                ADJ_TRANS_ID.PROCESSED_DATE IS NULL AND
                ADJ_TRANS_ID.MONTH_END_STATUS IS NULL AND
                ADJ_TRANS_ID.MONTH_END_DT IS NULL THEN
          
            UPDATE ADJUSTMENT_CHARGE_MASTER UACM
               SET UACM.ADJUSTMENT_STATUS = 'p',
                   UACM.PROCESSED_DATE    = V_MANUAL_DT
             WHERE UACM.TRANSACTION_ID = ADJ_TRANS_ID.TRANSACTION_ID
               AND UACM.ADJUSTMENT_STATUS IS NULL
               AND UACM.PROCESSED_DATE IS NULL;
          
            DBMS_OUTPUT.PUT_LINE('UPDATED1.2 : SET FOR ONLY MONTH-END PROCESS');
            V_SUCCESS_CNT := V_SUCCESS_CNT + 1;
          
          END IF;
        
          /******************************************************************
                                DUPLICATE ADJUSTMENT
          ******************************************************************/
        ELSIF P_PROCESS_CODE = 'DUP' THEN
        
          SELECT COUNT(*)
            INTO V_DUP_ADJ_CNT
            FROM ADJUSTMENT_CHARGE_MASTER DACM
           WHERE DACM.TRANSACTION_ID = ADJ_TRANS_ID.TRANSACTION_ID;
        
          IF V_DUP_ADJ_CNT > 1 THEN
            DBMS_OUTPUT.PUT_LINE('DUPLICATE ADJUSTMENT FOUND');
            IF ADJ_TRANS_ID.ADJUSTMENT_STATUS IS NULL AND
               ADJ_TRANS_ID.PROCESSED_DATE IS NULL AND
               ADJ_TRANS_ID.MONTH_END_STATUS IS NULL AND
               ADJ_TRANS_ID.MONTH_END_DT IS NULL THEN
            
              DELETE FROM ADJUSTMENT_CHARGE_MASTER
               WHERE ROWID IN (SELECT RID
                                 FROM (SELECT ROWID RID,
                                              ROW_NUMBER() OVER(PARTITION BY DAM.TRANSACTION_ID ORDER BY DAM.ENTRY_DATE, ROWID) RN
                                         FROM ADJUSTMENT_CHARGE_MASTER DAM
                                        WHERE DAM.TRANSACTION_ID =
                                              ADJ_TRANS_ID.TRANSACTION_ID
                                          AND DAM.PROCESSED_DATE IS NULL
                                          AND DAM.ADJUSTMENT_STATUS IS NULL
                                          AND DAM.MONTH_END_DT IS NULL
                                          AND DAM.MONTH_END_STATUS IS NULL)
                                WHERE RN > 1);
            
              DBMS_OUTPUT.PUT_LINE('DUPLICATE REMOVED');
              V_SUCCESS_CNT := V_SUCCESS_CNT + 1;
            ELSE
              DBMS_OUTPUT.PUT_LINE('SKIPPED: ADJUSTMENT ALREADY PROCESSED ');
              V_SKIP_CNT := V_SKIP_CNT + 1;
            END IF;
          ELSE
            DBMS_OUTPUT.PUT_LINE('NO DUPLICATE FOUND.');
            V_SKIP_CNT := V_SKIP_CNT + 1;
          END IF;
        
          /* ADD OTHER CHECKS CONSIDTIONS HEAR RELATED TO ADJUSTMENT_CHARGE MASTER CHECK*/
        
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK TO SP_PER_ID;
          DBMS_OUTPUT.PUT_LINE('FAILED FOR TRANSACTION ID : ' ||
                               ADJ_TRANS_ID.TRANSACTION_ID);
          DBMS_OUTPUT.PUT_LINE('ERROR : ' || SQLERRM);
          DBMS_OUTPUT.PUT_LINE('ERROR LINE : ' ||
                               DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
          V_FAIL_CNT := V_FAIL_CNT + 1;
      END;
    
    END LOOP;
  
  ELSIF P_PROCESS_CODE = 'ARP' THEN
    FOR ADJ_MSTR_DTA IN (SELECT ACD.TRANS_ID,
                                ACD.CONSUMER_NO,
                                ACD.ADJUSTMENT_AMOUNT,
                                ACD.USER_NAME,
                                ACD.REJECTED_DATE,
                                ACD.APPROVAL_DATE
                           FROM ADJUSTMENT_CHARGE_MASTER_DATA ACD
                          WHERE ACD.TRANS_ID IN
                                ( /* INSERT TRANSACTION ID HERE */)
                            AND ACD.REJECTED_DATE IS NULL
                            AND ACD.APPROVAL_DATE IS NULL
                          ORDER BY ACD.TRANS_ID) LOOP
      SAVEPOINT SP_ACD_PER_ID;
      BEGIN
        --CHECK IF ADJUSTMENT IS NOT ALREADY PROCESSED.
        IF ADJ_MSTR_DTA.REJECTED_DATE IS NULL AND
           ADJ_MSTR_DTA.APPROVAL_DATE IS NULL THEN
        
          --CHECK IF USERNAME IS NULL OR NOT,IF NULL UPDATE USERNAME WITH PREVIOUS USERNAME.
          IF ADJ_MSTR_DTA.USER_NAME IS NULL THEN
          
            -- GET LATEST USERNAME FROM LATEST ENTRIES.
            SELECT AMD.USER_NAME
              FROM ADJUSTMENT_CHARGE_MASTER_DATA AMD
             WHERE AMD.CONSUMER_NO = ADJ_MSTR_DTA.
               AND AMD.USER_NAME IS NOT NULL
               AND AMD.ENTRY_DATE IN
                   (SELECT MAX(A.ENTRY_DATE)
                      FROM ADJUSTMENT_CHARGE_MASTER_DATA A
                     WHERE A.CONSUMER_NO = '50135009553'
                       AND A.USER_NAME IS NOT NULL);
          
          END IF;
        
        END IF;
      
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK TO SP_ACD_PER_ID;
          DBMS_OUTPUT.PUT_LINE('FAILED FOR TRANSACTION ID : ' ||
                               ADJ_MSTR_DTA.TRANS_ID);
          DBMS_OUTPUT.PUT_LINE('ERROR : ' || SQLERRM);
          DBMS_OUTPUT.PUT_LINE('ERROR LINE : ' ||
                               DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
          V_FAIL_CNT := V_FAIL_CNT + 1;
      END;
    
    END LOOP;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('PROCESS COMPLETED UNSUCCESSFULLY');
    DBMS_OUTPUT.PUT_LINE('TECHNICAL ERROR : ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('ERROR LINE : ' ||
                         DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
/
