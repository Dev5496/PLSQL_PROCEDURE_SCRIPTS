--THIS PROCESS IS ONLY FOR BILL AND ASSESSMENT PROCESS.
/*

*/

DECLARE
  V_RUN_CNT            NUMBER := 0;
  V_MR_CNT             NUMBER := 0;
  V_PRINT_BIL_CNT      NUMBER := 0;
  V_MDM_DUP_CNT        NUMBER := 0;
  V_G41_DUP_CNT        NUMBER := 0;
  V_SUB_MTR_CNT        NUMBER := 0;
  V_MR_DUP_CHK         NUMBER := 0;
  V_SUB_DUP_CHK        NUMBER :=0;
  V_SUBDIV             NUMBER := 0;
  V_PROS_CODE          VARCHAR2(10);
  V_ST_TIME            DATE;
  V_PRO_CYCLE          NUMBER := 0;
  V_JC_MAX_MONN        NUMBER(3);
  V_JC_MAX_YER         NUMBER(5);
  V_JC_MAX_MONN_N      NUMBER(3);
  V_JC_MAX_YER_N       NUMBER(5);

  --INPUT VARIABLES:
  P_SUBDIV             NUMBER(3) := &P_SUBDIV;
  P_CYCLE              NUMBER(1) := &P_CYCLE;
  V_MONTH              NUMBER(2) := &V_MONTH;
  V_YEAR               NUMBER(4) := &V_YEAR;
  P_PROCESS_CODE       VARCHAR2(30) := UPPER('&P_PROCESS_CODE');

BEGIN

  --------------------------------------------------
  -- CHECK INPUTS
  --------------------------------------------------
  IF P_PROCESS_CODE NOT IN ('BIL', 'G41') THEN
     DBMS_OUTPUT.PUT_LINE('ENTER CORRECT PROCESS CODE NAME');
     RETURN;
  END IF;

  --------------------------------------------------
  -- CHECK RUNNING PROCESS
  --------------------------------------------------
  BEGIN
     --GET PROCESS DETAILS IF RUNNING
     SELECT COUNT(*)
     INTO V_RUN_CNT
     FROM PROCESS_LOG P
     WHERE P.SUBDIV_CODE = P_SUBDIV
       AND P.CYCLE = P_CYCLE
       AND P.P_MONTH = V_MONTH
       AND P.P_YEAR = V_YEAR
       AND P.PROCESS_CODE =P_PROCESS_CODE
       AND P.END_FLAG IS NULL;

     IF V_RUN_CNT > 0 THEN
        DBMS_OUTPUT.PUT_LINE('PROCESS IS STUCK OR ONGOING. REMOVE FROM PROCESS LOG');

        SELECT P.SUBDIV_CODE,
               P.PROCESS_CODE,
               P.START_TIME,
               P.CYCLE
        INTO V_SUBDIV,
             V_PROS_CODE,
             V_ST_TIME,
             V_PRO_CYCLE
        FROM PROCESS_LOG P
        WHERE P.SUBDIV_CODE = P_SUBDIV
          AND P.CYCLE = P_CYCLE
          AND P.P_MONTH = V_MONTH
          AND P.P_YEAR = V_YEAR
          AND P.PROCESS_CODE = P_PROCESS_CODE
          AND P.END_FLAG IS NULL;
          
          DBMS_OUTPUT.PUT_LINE(
             'SUBDIV:' || V_SUBDIV ||
             ' PROCESS:' || V_PROS_CODE ||
             '  START_TIME:' || TO_CHAR(V_ST_TIME,'DD-MM-YYYY HH24:MI:SS') ||
             ' CY:' || V_PRO_CYCLE
          );

     ELSE
        DBMS_OUTPUT.PUT_LINE('PROCESS COMPLEATED WITH ERROR OR PROCESS LOG IS ALREADY CLEARED');
     END IF;

  EXCEPTION
     WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('NO RUNNING PROCESS FOUND.');
  END;

   
  --------------------------------------------------
  -- BILL PROCESS VALIDATION
  --------------------------------------------------
  IF P_PROCESS_CODE = 'BIL' THEN
    
    --GET MAX MONTH OF ASSESSMENT FOR CYCLE OTHER THAN 8 AND 5.
     IF P_CYCLE NOT IN (5, 8) THEN

       SELECT MAX(SP.P_MONTH)
         INTO V_JC_MAX_MONN 
         FROM SUBDIV_PROCESS_LOG SP
        WHERE SP.SUBDIV_CODE   = P_SUBDIV
          AND SP.CYCLE         = P_CYCLE
          AND SP.P_YEAR        = V_YEAR
          AND SP.ROLLBACK_FLAG = 'N'
          AND SP.PROCESS_CODE  = 'G41';

         IF V_JC_MAX_MONN IS NOT NULL THEN
            V_MONTH := V_JC_MAX_MONN;

            DBMS_OUTPUT.PUT_LINE('MONTH UPDATED TO LAST G41 MONTH: ' || V_MONTH ||'  FOR YEAR:'|| V_YEAR);
         ELSE
            DBMS_OUTPUT.PUT_LINE('NO G41 PROCESS FOUND IN SUBDIV_PROCESS_LOG');
         END IF;
         
     END IF;
     
     SELECT COUNT(*)
     INTO V_PRINT_BIL_CNT
     FROM PRINTED_BILL PB
     WHERE PB.SUB_DIVISION_CODE = P_SUBDIV
       AND PB.BILLED_MONTH = V_MONTH
       AND PB.BILLED_YEAR = V_YEAR
       AND PB.CYCLE_NUMBER = P_CYCLE;

     IF V_PRINT_BIL_CNT <> 0 THEN
        DBMS_OUTPUT.PUT_LINE(
          'PRINTED BILL COUNT FOUND: ' || V_PRINT_BIL_CNT ||
          '. REVERT BEFORE RUN AGAIN'
        );
     END IF;

     DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------');


     -- DUPLICATE METERREADING CHECK
     SELECT COUNT(*)
       INTO V_MR_DUP_CHK
       FROM (SELECT MR.CUSTOMER_NO, MR.METER_SEQ, COUNT(*) CNT
               FROM METERREADING MR
              WHERE MR.SUBDIV_CODE = P_SUBDIV
                AND MR.MON = V_MONTH
                AND MR.YEAR = V_YEAR
                AND MR.CYCLE_NO = P_CYCLE
              GROUP BY MR.CUSTOMER_NO, MR.METER_SEQ
             HAVING COUNT(*) > 1);
     
     IF V_MR_DUP_CHK<> 0 THEN
     
     DBMS_OUTPUT.PUT_LINE('DUPLICATE ASSESSMENT FOUND:'||V_MR_DUP_CHK);
         FOR DUP_MR IN
         (
           SELECT MR.CUSTOMER_NO,
                  MR.METER_SEQ,
                  COUNT(*) CNT
           FROM METERREADING MR
           WHERE MR.SUBDIV_CODE = P_SUBDIV
             AND MR.MON = V_MONTH
             AND MR.YEAR = V_YEAR
             AND MR.CYCLE_NO = P_CYCLE
           GROUP BY MR.CUSTOMER_NO, MR.METER_SEQ
           HAVING COUNT(*) > 1
         )
         LOOP
           DBMS_OUTPUT.PUT_LINE(DUP_MR.CUSTOMER_NO||',');
           
           --INSERT RECORDS METERREADING BACKUP TABLE:
           INSERT INTO ASS_BACKUP
             SELECT *
               FROM METERREADING MR
              WHERE MR.SUBDIV_CODE = P_SUBDIV
                AND MR.CYCLE_NO = P_CYCLE
                AND MR.MON = V_MONTH
                AND MR.YEAR = V_YEAR
                AND MR.CUSTOMER_NO=DUP_MR.CUSTOMER_NO;   
         END LOOP;
         
         
                
         DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------');
     END IF;

  --------------------------------------------------
  -- G41 PROCESS VALIDATION
  --------------------------------------------------
  ELSIF P_PROCESS_CODE = 'G41' THEN

     SELECT COUNT(*)
     INTO V_MR_CNT
     FROM METERREADING MR
     WHERE MR.SUBDIV_CODE = P_SUBDIV
       AND MR.CYCLE_NO = P_CYCLE
       AND MR.MON = V_MONTH
       AND MR.YEAR = V_YEAR
       AND MR.TAR_CODE <> 'A1';
     
     IF V_MR_CNT <> 0 THEN
     DBMS_OUTPUT.PUT_LINE(
       'ASSESSMENT COUNT: ' || V_MR_CNT ||
       ' FOUND. REVERT BEFORE RUN AGAIN'
     );
     END IF;

     DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------');

     --------------------------------------------------
     -- CYCLE 8 MDM DUPLICATE CHECK
     --------------------------------------------------
     IF P_CYCLE = 8 THEN

        SELECT COUNT(*)
        INTO V_MDM_DUP_CNT
        FROM
        (
          SELECT S.SUBDIVN,S.CONSUMER_NO,S.BILLED_MONTH,S.BILLED_YEAR,S.ENTRY_DATE,COUNT(*)
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
          HAVING COUNT(*) > 1
        );

        IF V_MDM_DUP_CNT > 0 THEN

           DBMS_OUTPUT.PUT_LINE(
             'DUPLICATE MDM FOUND: ' || V_MDM_DUP_CNT
           );

        END IF;

     END IF;


     --------------------------------------------------
     -- GPRS DUPLICATE CHECK
     --------------------------------------------------
     SELECT COUNT(*)
     INTO V_G41_DUP_CNT
     FROM
     (
       SELECT G.CONS_NO,G.METER_SEQ,G.CREATED_BY,COUNT(*)
       FROM G41_FILE_STAGING_TABLE_GPRS G
       WHERE G.SUBDIVISION = P_SUBDIV
         AND G.CYCLE_NO = P_CYCLE
         AND G.BILLED_MONTH = V_MONTH
         AND G.CREATED_BY NOT IN ('MDM')
         AND G.BILLED_YEAR = V_YEAR
       GROUP BY G.CONS_NO,
                G.METER_SEQ,
                G.CREATED_BY
       HAVING COUNT(*) > 1
     );


     IF V_G41_DUP_CNT > 0 THEN

        DBMS_OUTPUT.PUT_LINE(
          'DUPLICATE GPRS FOUND: ' || V_G41_DUP_CNT
        );

        DBMS_OUTPUT.PUT_LINE(
          'REMOVE DUPLICATES FROM G41 STAGING TABLE.'
        );

     END IF;

     DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------');

  END IF;
  
  -------------------------------------------------
  -- CHECK NULL SUBMETER NUMBER 
  -------------------------------------------------
  SELECT COUNT(SM.CUSTOMER_NO)
  INTO V_SUB_MTR_CNT
    FROM SUB_METER_MASTER SM
   WHERE SM.SUBDIVISION_CODE = P_SUBDIV
     AND (SM.MAIN_METER_NO IS NULL OR SM.SUB_METER_NO IS NULL);
     
  IF V_SUB_MTR_CNT <> 0 THEN
      DBMS_OUTPUT.PUT_LINE('SUB-METER OR MAIN-METER NUMBER IS NULL IN SUBMETER MASTER.');
    FOR SUB_MASTR IN(
      SELECT SM.CUSTOMER_NO
        FROM SUB_METER_MASTER SM
       WHERE SM.SUBDIVISION_CODE = P_SUBDIV
         AND (SM.MAIN_METER_NO IS NULL OR SM.SUB_METER_NO IS NULL)
      )LOOP
      DBMS_OUTPUT.PUT_LINE(SUB_MASTR.CUSTOMER_NO);
      
      --SUB METER MASTER BACK UP
      /*INSERT INTO SUB_METER_MASTER_BACKUP
        (SELECT *
           FROM SUB_METER_MASTER SM
          WHERE SM.SUBDIVISION_CODE = P_SUBDIV
            AND (SM.MAIN_METER_NO IS NULL OR SM.SUB_METER_NO IS NULL)
            AND SM.CUSTOMER_NO = SUB_MASTR.CUSTOMER_NO);*/
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------');
  END IF;-- SUBMETER CHECK IF END
 
    -------------------------------------------------
    -- CHECK DUPLICATE SUBMETERMASTER
    -------------------------------------------------
    
      SELECT COUNT(*) INTO V_SUB_DUP_CHK
        FROM (SELECT s.customer_no, s.meter_seq, COUNT(*)
               FROM sub_meter_master s
             WHERE s.subdivision_code = P_SUBDIV
             GROUP BY s.customer_no, s.meter_seq
             HAVING COUNT(*) > 1);
              
     IF V_SUB_DUP_CHK <> 0 THEN
       DBMS_OUTPUT.PUT_LINE('DUPLICATE SUB-METER MASTER FOUND:'||V_SUB_DUP_CHK);
       
       FOR SUB_DUP IN(SELECT SMM.SUBDIVISION_CODE, SMM.CUSTOMER_NO,SMM.METER_SEQ, COUNT(*)
                FROM SUB_METER_MASTER SMM
               WHERE SMM.SUBDIVISION_CODE = P_SUBDIV
               GROUP BY SMM.SUBDIVISION_CODE, SMM.CUSTOMER_NO,SMM.METER_SEQ
              HAVING COUNT(*) > 1)LOOP
              DBMS_OUTPUT.PUT_LINE(SUB_DUP.CUSTOMER_NO);
              
       --SUB METER MASTER BACK UP FOR DUPLICATE
      /* INSERT INTO SUB_METER_MASTER_BACKUP
         (SELECT *
            FROM SUB_METER_MASTER SMM
           WHERE SMM.SUBDIVISION_CODE = P_SUBDIV
           AND SMM.CUSTOMER_NO=SUB_DUP.CUSTOMER_NO);*/
           
       END LOOP;
     END IF;
     
     EXCEPTION WHEN OTHERS THEN
       
            DBMS_OUTPUT.PUT_LINE('TECHNICAL ERROR:'||SQLERRM);                       
END;
/
