--HT MANUALLY BILL DELETE PROCESS:
/* LOGIC:
-- Previous month- bill cannot be deleated after month-end.
-- Check if month-end is compleated. Check consumer ledger for month end.
-- Check if particular consumers' circle and division month-end compleated, then cannot delete for that month.
*/

DECLARE
  V_CONS_CIR    NUMBER;
  V_CONS_DIV    NUMBER;
  V_MON_END_CHK NUMBER;
  V_CDC         NUMBER;
  V_EPV         NUMBER;
  V_DPV         NUMBER;
  V_EDCD        NUMBER;
  V_CPD         NUMBER;
  V_MR          NUMBER;
  V_BIL         NUMBER;
  V_CURR_YEAR   NUMBER := TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'));
  V_CURR_MON    NUMBER := TO_NUMBER(TO_CHAR(SYSDATE, 'MM'));

  --INPUT VARIABLES
  P_CONS      NUMBER(5) := &CONS;
  P_MON       NUMBER(2) := &MON;
  P_YEAR      NUMBER(4) := &YER;
  P_BILL_DATE DATE := '&BILL_DATE';
BEGIN
  
  -- MONTH VALIDATION
  IF P_MON < 1 OR P_MON > 12 THEN
    DBMS_OUTPUT.PUT_LINE('INVALID MONTH: ' || P_MON);
    DBMS_OUTPUT.PUT_LINE('MONTH SHOULD BE BETWEEN 1 AND 12 ONLY.');
    RETURN;
  END IF;

  -- YEAR VALIDATION
  IF P_YEAR < V_CURR_YEAR OR P_YEAR > V_CURR_YEAR THEN
    DBMS_OUTPUT.PUT_LINE('INVALID YEAR: ' || P_YEAR);
    DBMS_OUTPUT.PUT_LINE('YEAR SHOULD BE ' || V_CURR_YEAR ||' ONLY.');
    RETURN;
  END IF;
  

  BEGIN
    --CHECK IF BILL IS MADE TO DELETE THE BILL:
   SELECT COUNT(*)
     INTO V_BIL
     FROM BILLING B
    WHERE B.CONS_NUMBER = P_CONS
      AND B.READING_MONTH = P_MON
      AND B.READING_YEAR = P_YEAR
      AND B.BILLTYPE IS NULL;
      
      IF V_BIL = 0 THEN
        DBMS_OUTPUT.PUT_LINE('BILL NOT GENERATED, CANNOT DELETE BILL.');
       RETURN;
      END IF;
    
    --GET CNSUMER CIR AND DIVISION
    SELECT NVL(C.CIRCLE_CODE, 0), NVL(C.DIVCODE, 0)
      INTO V_CONS_CIR, V_CONS_DIV
      FROM CONSUMER_MASTER C
     WHERE C.CONSUMER_NO = P_CONS;
  
    --CIRCLE AND DIVISION PRESENT THEN CHECK MONTH-END
    IF V_CONS_CIR <> 0 AND V_CONS_DIV <> 0 THEN
      
      SELECT COUNT(*)
        INTO V_MON_END_CHK
        FROM CONSUMER_LEDGER CL
       WHERE CL.CIRCLE_CODE = V_CONS_CIR
         AND CL.DIVISION_CODE = V_CONS_DIV
         AND CL.BILLMONTH = P_MON
         AND CL.BILLYEAR = P_YEAR;
      
      IF V_MON_END_CHK <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('MONTH-END DONE FOR CONSUMER, CIRCLE AND DIVISION FOR THE ENTERED MONTH.');
        DBMS_OUTPUT.PUT_LINE('CANNOT DELETE BILL FOR MONTH: ' || P_MON);
        RETURN;
      END IF;
    
    ELSE
      DBMS_OUTPUT.PUT_LINE('CONSUMER CIRCLE AND DIVISION IS NULL. MASTER NOT CREATED PROPERLY.');
      RETURN;
    END IF;
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('CHECK CONSUMER AGAIN OR MASTER NOT CREATED.');
      RETURN;
  END;

  /***********************************************************************************************
                                  MAIN BILL DELETE PROCESS 
  ***********************************************************************************************/
  -- INPUT PARAMETER SUMMARY
  DBMS_OUTPUT.PUT_LINE('===== BILL DELETE REQUEST PARAMETERS =====');
  DBMS_OUTPUT.PUT_LINE('Consumer No:           ' || P_CONS);
  DBMS_OUTPUT.PUT_LINE('Circle Code:           ' || V_CONS_CIR);
  DBMS_OUTPUT.PUT_LINE('Division Code:         ' || V_CONS_DIV);
  DBMS_OUTPUT.PUT_LINE('Month:                 ' || P_MON);
  DBMS_OUTPUT.PUT_LINE('Year:                  ' || P_YEAR);
  DBMS_OUTPUT.PUT_LINE('Bill Date:             ' ||
                       TO_CHAR(P_BILL_DATE, 'DD-MON-YYYY'));
  DBMS_OUTPUT.PUT_LINE('===========================================');
  DBMS_OUTPUT.PUT_LINE('');

  SELECT COUNT(*)
    INTO V_BIL
    FROM BILLING B
   WHERE B.CONS_NUMBER = P_CONS
     AND B.READING_MONTH = P_MON
     AND B.READING_YEAR = P_YEAR
     AND B.BILLTYPE IS NULL;

  SELECT COUNT(*)
    INTO V_MR
    FROM METER_READ MR
   WHERE MR.CONS_NUMBER = P_CONS
     AND MR.BILLING_MONTH = P_MON
     AND MR.BILLING_YEAR = P_YEAR;

  SELECT COUNT(*)
    INTO V_CPD
    FROM CONS_PAY_DETAIL P
   WHERE P.CONSUMER_NO = P_CONS
     AND P.BILLING_MONTH = P_MON
     AND P.BILLING_YEAR = P_YEAR
     AND P.OLD_BILL_ENTRY_FLAG IS NULL;

  SELECT COUNT(*)
    INTO V_EDCD
    FROM ED_CHARGE_DETAIL ED
   WHERE ED.CONS_NUMBER = P_CONS
     AND ED.READING_MONTH = P_MON
     AND ED.READING_YEAR = P_YEAR;

  SELECT COUNT(*)
    INTO V_DPV
    FROM DEM_PRINT_VALUE D
   WHERE D.CONSUMER_NO = P_CONS
     AND D.READING_MONTH = P_MON
     AND D.READING_YEAR = P_YEAR;

  SELECT COUNT(*)
    INTO V_EPV
    FROM EXDEM_PRINT_VALUE D
   WHERE D.CONSUMER_NO = P_CONS
     AND D.READING_MONTH = P_MON
     AND D.READING_YEAR = P_YEAR;

  SELECT COUNT(*)
    INTO V_CDC
    FROM CONS_DPC_CAL CD
   WHERE CD.CONSUMER_NO = P_CONS
     AND CD.BILLDATE = P_BILL_DATE
     AND CD.ADJ_FLAG = 'Y';

  -- OUTPUT RECORD COUNTS SUMMARY
  DBMS_OUTPUT.PUT_LINE('===== RELATED RECORDS SUMMARY =====');
  DBMS_OUTPUT.PUT_LINE('Billing Records:        ' || V_BIL);
  DBMS_OUTPUT.PUT_LINE('Meter Read Records:     ' || V_MR);
  DBMS_OUTPUT.PUT_LINE('Payment Details:        ' || V_CPD);
  DBMS_OUTPUT.PUT_LINE('ED Charge Details:      ' || V_EDCD);
  DBMS_OUTPUT.PUT_LINE('Demand Print Values:    ' || V_DPV);
  DBMS_OUTPUT.PUT_LINE('Exdem Print Values:     ' || V_EPV);
  DBMS_OUTPUT.PUT_LINE('DPC Calculations:       ' || V_CDC);
  DBMS_OUTPUT.PUT_LINE('====================================');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('BILL DELEATED SUCCESSFULL. SET OUTSTANDING AND DPC.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('PROCESS COMPLETED UNSUCCESSFULLY');
    DBMS_OUTPUT.PUT_LINE('TECHNICAL ERROR:' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('ERROR LINE: ' ||
                         DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
/
