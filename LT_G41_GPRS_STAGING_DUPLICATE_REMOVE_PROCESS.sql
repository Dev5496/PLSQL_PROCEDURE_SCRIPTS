-- GPRS duplication remove process.

DECLARE
  V_CURR_YEAR          NUMBER := TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'));
  V_CURR_MON           NUMBER := TO_NUMBER(TO_CHAR(SYSDATE, 'MM'));
  V_MR_CNT             NUMBER := 0;
  V_RUN_PRO_CHK        NUMBER := 0;
  V_MDM_DUP_CNT        NUMBER := 0;
  V_GPRS_DUP_CNT       NUMBER := 0;
  V_COM_CODE           NUMBER := 0;
  V_SUBDIV_CHK         NUMBER := 0;
  V_ASS_COM_CHK        NUMBER := 0;

  --INPUT VARIABLES:
  P_SUBDIV NUMBER(3) := &SUBDIV;
  P_CYCLE  NUMBER(1) := &CYCL;
  V_MONTH  NUMBER(2) := &MON;
  V_YEAR   NUMBER(4) := &YER;

BEGIN
  -- MONTH VALIDATION
  IF (V_MONTH < 1 OR V_MONTH > 12) THEN
    DBMS_OUTPUT.PUT_LINE('INVALID MONTH: ' || V_MONTH);
    DBMS_OUTPUT.PUT_LINE('MONTH SHOULD BE BETWEEN 1 AND 12 ONLY.');
    RETURN;
  END IF;

  -- YEAR VALIDATION
  IF V_YEAR < V_CURR_YEAR OR V_YEAR > V_CURR_YEAR THEN
    DBMS_OUTPUT.PUT_LINE('INVALID YEAR: ' || V_YEAR);
    DBMS_OUTPUT.PUT_LINE('YEAR SHOULD BE ' || V_CURR_YEAR || ' ONLY.');
    RETURN;
  END IF;
  
  --VALIDATION CYCLE: CANNOT BE LESS THAN 1 AND GRATER THAN 8
  IF (P_CYCLE < 1 OR P_CYCLE > 8) THEN
    DBMS_OUTPUT.PUT_LINE('INVALID CYCLE: ' || P_CYCLE);
    DBMS_OUTPUT.PUT_LINE('CYCLE SHOULD BE BETWEEN 1 AND 8 ONLY.');
    RETURN;
  END IF;
  
  -- CHECK SUBDIVISION MASTER WITH COMPANY CODE: IF SUBDIVISION NOT PRESENT THEN RETURN.
  BEGIN
     SELECT DISTINCT E.COMPANY_CODE
       INTO V_COM_CODE
       FROM PRT_135_EDUTY E
      WHERE E.MODULE = 'LT'
        AND E.SUB_DIVN_CODE = P_SUBDIV;
        
    IF V_COM_CODE IS NOT NULL THEN 
      SELECT COUNT(1) 
      INTO V_SUBDIV_CHK
        FROM SUBDIVISION_MASTER SM
       WHERE SM.SUBDIV_CODE = P_SUBDIV
         AND SM.COMPANY_CODE = V_COM_CODE
         AND SM.TO_DT IS NULL;
         
         IF V_SUBDIV_CHK = 0 THEN 
           DBMS_OUTPUT.PUT_LINE('CHECK SUBDIVISION, SUBDIVISION MASTER NOT FOUND OR UNDER OTHER COMPANY.');
           RETURN;
         END IF;
   
    END IF;  
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('NO DATA FOUND... ENTER CORRECT SUBDIVISION.');
     RETURN;   
  END;

  --CHECK IF ASSESSMENT IS STUCK OR ONGOING: 
  SELECT COUNT(*)
    INTO V_RUN_PRO_CHK
    FROM PROCESS_LOG P
   WHERE P.SUBDIV_CODE = P_SUBDIV
     AND P.PROCESS_CODE = 'G41'
     AND P.P_MONTH = V_MONTH
     AND P.P_YEAR = V_YEAR
     AND P.CYCLE = P_CYCLE
     AND P.END_FLAG IS NULL;

  IF NVL(V_RUN_PRO_CHK, 0) <> 0 THEN
    DBMS_OUTPUT.PUT_LINE('PROCESS IS ONGOING OR STUCK. CANNOT REMOVE DUPLICATE.');
    RETURN;
  END IF;
  
  SELECT COUNT(*)
  INTO V_ASS_COM_CHK
    FROM SUBDIV_PROCESS_LOG SPL
   WHERE SPL.SUBDIV_CODE = P_SUBDIV
     AND SPL.PROCESS_CODE = 'G41'
     AND SPL.P_MONTH = V_MONTH
     AND SPL.P_YEAR = V_YEAR
     AND SPL.CYCLE = P_CYCLE
     AND SPL.ROLLBACK_FLAG='N';
     
     IF V_ASS_COM_CHK <> 0  THEN
       DBMS_OUTPUT.PUT_LINE('ASSESSMENT RECORDS FOUND IN JOBCHART. REVERT ASSESSMENT BEFORE REMOVING DUPLICATE.');
      RETURN;
     END IF;

  --CHECK IF ASSESSMENT DONE HALFLLY:
  SELECT COUNT(*)
    INTO V_MR_CNT
    FROM METERREADING MR
   WHERE MR.SUBDIV_CODE = P_SUBDIV
     AND MR.CYCLE_NO = P_CYCLE
     AND MR.MON = V_MONTH
     AND MR.YEAR = V_YEAR
     AND MR.TAR_CODE <> 'A1';

  IF NVL(V_MR_CNT, 0) <> 0 THEN
    DBMS_OUTPUT.PUT_LINE('ASSESSMENT RECORD FOUND: ' || V_MR_CNT);
    DBMS_OUTPUT.PUT_LINE('REVERT ASSESSMENT BEFORE REMOVING DUPLICATE.');
    RETURN;
  END IF;

  IF P_CYCLE = 8 THEN
    SELECT COUNT(*)
      INTO V_MDM_DUP_CNT
      FROM (SELECT S.SUBDIVN,
                   S.CONSUMER_NO,
                   S.BILLED_MONTH,
                   S.BILLED_YEAR,
                   S.ENTRY_DATE,
                   COUNT(*)
              FROM SMART_METERREADING_G41_DATA S
             WHERE S.SUBDIVN = P_SUBDIV
               AND S.BILLED_MONTH = V_MONTH
               AND S.BILLED_YEAR = V_YEAR
               AND S.CYCLE_NO = P_CYCLE
             GROUP BY S.SUBDIVN,
                      S.CONSUMER_NO,
                      S.BILLED_MONTH,
                      S.BILLED_YEAR,
                      S.ENTRY_DATE
            HAVING COUNT(*) > 1);
    IF V_MDM_DUP_CNT <> 0 THEN
      DBMS_OUTPUT.PUT_LINE('DUPLICATE MDM FOUND: ' || V_MDM_DUP_CNT);
      DBMS_OUTPUT.PUT_LINE('REMOVE DUPLICATE MDM MANUALLY, CANNOT REMOVE THROUGH PROCESS');
      RETURN;
    END IF;
  END IF;

  IF P_CYCLE NOT IN (8, 5) THEN
    SELECT COUNT(*)
      INTO V_GPRS_DUP_CNT
      FROM (SELECT g.cons_no,
                   g.meter_seq,
                   g.created_by,
                   COUNT(*) AS record_count
              FROM G41_FILE_STAGING_TABLE_GPRS g
             WHERE g.subdivision = P_SUBDIV
               AND g.cycle_no = P_CYCLE
               AND g.billed_month = V_MONTH
               AND g.billed_year = V_YEAR
             GROUP BY g.cons_no, g.meter_seq, g.created_by
            HAVING COUNT(*) > 1);
    
    IF V_GPRS_DUP_CNT = 0 THEN
      DBMS_OUTPUT.PUT_LINE('DUPLICATE RECORDS NOT FOUND.');
      RETURN;
    ELSE
     DELETE FROM G41_FILE_STAGING_TABLE_GPRS
       WHERE ROWID IN (
             SELECT RID
               FROM (
                     SELECT ROWID RID,
                            ROW_NUMBER() OVER (
                                PARTITION BY
                                    CONS_NO,
                                    BIL_DATE,
                                    DUE_DATE,
                                    CUR_RDG,
                                    UNITS,
                                    STA,
                                    BILL_AMT,
                                    NET_AMT,
                                    RCURR,
                                    RUNIT,
                                    ACT_DEM,
                                    SUBDIVISION,
                                    CYCLE_NO,
                                    BILLED_MONTH,
                                    BILLED_YEAR,
                                    CREATED_BY,
                                    PROCESS_FLAG,
                                    METER_SEQ,
                                    METER_TYPE,
                                    IMP_RDNG,
                                    EXP_RDNG,
                                    PREPARED_BY,
                                    IMP_RDNG_LOSS,
                                    EXP_RDNG_LOSS,
                                    PEAK_READING,
                                    NIGHT,
                                    REST_KWH,
                                    PEAK_UNIT,
                                    REST_UNIT,
                                    NIGHT_UNIT,
                                    CMD_CURR,
                                    CMD,
                                    NIGHT_CMD_CURR,
                                    NIGHT_CMD,
                                    REST_CMD_CURR,
                                    REST_CMD,
                                    SMART_METR_REBATE,
                                    REV_PROCESS,
                                    PEAK_2_UNIT,
                                    PEAK_2_READING,
                                    PREPAID_FLAG
                                ORDER BY INSERT_DATE
                            ) RN
                       FROM G41_FILE_STAGING_TABLE_GPRS G
                      WHERE G.SUBDIVISION  = P_SUBDIV
                        AND G.CYCLE_NO     = P_CYCLE
                        AND G.BILLED_MONTH = V_MONTH
                        AND G.BILLED_YEAR  = V_YEAR
                        AND G.PROCESS_FLAG IS NULL
                   )
              WHERE RN > 1
            );
          DBMS_OUTPUT.PUT_LINE('DUPLICATE GPRS RECORDS DELETED SUCCESSFULLY: ' || SQL%ROWCOUNT);
           
    END IF;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('PROCESS COMPLETED UNSUCCESSFULLY');
    DBMS_OUTPUT.PUT_LINE('TECHNICAL ERROR:' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('ERROR LINE: ' ||
                         DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
/
