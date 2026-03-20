--Backup from below queries
SELECT *
  FROM METER_MF_CHANGE M
 WHERE M.CONSUMER_NO = '16003' --60218
 --AND M.STATUS_FLAG IS NULL
 ORDER BY M.SYS_DATE DESC ;

--OLD MF :
--OLD CTPT CODE :
--OLD CTPT SR :

SELECT *
  FROM METER_MASTER MM
 WHERE MM.CONS_NUMBER = '16003'
   and mm.meter_status_chg in ('A');


--Process
DECLARE
    V_BILL_COUNT        NUMBER := 0;
    V_MF_CONT           NUMBER := 0;
    V_MTR_CONT          NUMBER := 0;
    V_MAT_REC           NUMBER := 0;
    V_OLDMF             NUMBER;
    V_OLDCTPT           NUMBER;
    V_ERR_MSG           VARCHAR2(5000);
    V_MESSAGE           VARCHAR2(100);
    V_OLDCTPT_SR        VARCHAR2(90);
    V_METERNO           VARCHAR2(90);
BEGIN
    
    BEGIN
      
               
        /***************************************************************
                 CHECK IF CURRENT MONTH BILL IS MADE
        ****************************************************************/
        -- Check bill for current month
        SELECT COUNT(*)
        INTO V_BILL_COUNT
        FROM BILLING B
        WHERE B.CONS_NUMBER = '&P_CONS'
          AND B.READING_MONTH = EXTRACT(MONTH FROM SYSDATE)
          AND B.READING_YEAR  = EXTRACT(YEAR  FROM SYSDATE);

        IF V_BILL_COUNT <> 0 THEN
            DBMS_OUTPUT.PUT_LINE('Bill exists for current month. Cannot revert the MF, Contact L-1 to delete the current bill');
           RETURN;
        END IF;

     -- Check if latest change entry come, Meter or MF change:
     SELECT M.MESSAGE
       INTO V_MESSAGE
       FROM METER_MF_CHANGE M
      WHERE M.CONSUMER_NO = '&P_CONS'
        AND M.STATUS_FLAG IS NULl
        AND M.SYS_DATE = (SELECT MAX(M1.SYS_DATE)
                            FROM METER_MF_CHANGE M1
                           WHERE M1.CONSUMER_NO = M.CONSUMER_NO
                             AND M1.STATUS_FLAG IS NULl);
                             
       IF V_MESSAGE='METER CHANGE' THEN
           DBMS_OUTPUT.PUT_LINE('FIRST REVERT METER CHANGE THEN ONLY  MF CHANGE RECORD YOU CAN REVERT');
          RETURN;
       END IF;
      
        
        
        
        /***************************************************************
                   CHECK UNBILLED MF CHANGE ENTRY
        ****************************************************************/
        SELECT COUNT(*)
        INTO V_MF_CONT
        FROM METER_MF_CHANGE M
        WHERE M.CONSUMER_NO = '&P_CONS'
          AND M.MESSAGE = 'MF CHANGE'
          AND M.STATUS_FLAG IS NULL;

        -- Case 0: No unbilled entry → STOP
        IF V_MF_CONT = 0 THEN
            DBMS_OUTPUT.PUT_LINE(
                'There is no unbilled MF change entry, Contact L1 No MF change entry is done.'
            );
            RETURN;
        END IF;

        -- Case >1: Duplicate MF entries → STOP
        IF V_MF_CONT > 1 THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate multiple unbilled MF change entries found. Contact L1 to correct duplicates.');
            RETURN;
        END IF;

        -- Case 1: Exactly one MF entry → Continue process
        SELECT M.OLD_MF, M.OLD_CTPT, M.CTPT_SR_NO_OLD, M.METER_NO
          INTO V_OLDMF, V_OLDCTPT, V_OLDCTPT_SR, V_METERNO
          FROM METER_MF_CHANGE M
         WHERE M.CONSUMER_NO = '&P_CONS'
           AND M.MESSAGE = 'MF CHANGE'
           AND M.STATUS_FLAG IS NULL;
           
           --Check if Meter MF Meter number and Meter Master active meter number is same, whose MF is reverted.
           select count(m.meter_no)
            INTO V_MTR_CONT
             from meter_master m, meter_mf_change mf
            where m.cons_number = mf.consumer_no
              and m.meter_no = V_METERNO
              and m.meter_status_chg in ('A')
              and m.cons_number = '&P_CONS'
              and mf.message = 'MF CHANGE'
              and mf.status_flag is null;
              
              IF NVL(V_MTR_CONT,0) <> 1 THEN
                 DBMS_OUTPUT.PUT_LINE('ERROR! Duplicate entry or active meter number does not match MF change entry.');
                 RETURN;
              END IF;
              
              --Check MF Change entry with meter master active meter entry, Check New CTPT_SR_NO and MF match MF change entry.
            select count(m.meter_no)
              INTO V_MAT_REC
              from meter_master m, meter_mf_change mf
             where m.cons_number = mf.consumer_no
               and m.meter_no = V_METERNO
               and m.Mf = mf.chg_mf
               and m.meter_ctpt_sr_no = mf.ctpt_sr_no
               and m.meter_status_chg in ('A')
               and m.cons_number = '&P_CONS'
               and mf.message = 'MF CHANGE'
               and mf.status_flag is null;
               
               IF NVL(V_MAT_REC,0) <> 1 THEN
                 DBMS_OUTPUT.PUT_LINE('ERROR! Consumer active meter record new MF and CTPR_SR does not match with MF change unbilled record.');
                 RETURN;
              END IF;
              
              
              --Revert the MF: Update Meter Master with OLD MF, CTPT, and METER_CTPT_SR
              UPDATE meter_master m
                 SET m.mf               = V_OLDMF,
                     m.meter_ctpt_sr_no = V_OLDCTPT_SR,
                     m.ctpt_code        = V_OLDCTPT
               WHERE m.cons_number = '&P_CONS'
                 AND m.meter_no = V_METERNO
                 AND m.meter_status_chg = 'A';
                 
                 
                 --After Revert delete the Unbilled MF change entry
                 DELETE meter_mf_change MF
                  WHERE MF.CONSUMER_NO = '&P_CONS'
                    AND MF.METER_NO = V_METERNO
                    AND MF.STATUS_FLAG IS NULL
                    AND MF.MESSAGE = 'MF CHANGE';
              
              --FETCH RECORDS WHICH METECH MF CHANGE ENTRY RECORDS IN METER MASTER.
              /*select * from METER_MASTER M WHERE M.CONS_NUMBER='' AND M.METER_NO= V_METERNO AND M.; */
              
              DBMS_OUTPUT.PUT_LINE('MF Revert Success');
              DBMS_OUTPUT.PUT_LINE('Old MF         = ' || V_OLDMF);
              DBMS_OUTPUT.PUT_LINE('Old CTPT       = ' || V_OLDCTPT);
              DBMS_OUTPUT.PUT_LINE('Old CTPT SR No = ' || V_OLDCTPT_SR);
              DBMS_OUTPUT.PUT_LINE('Meter No       = ' || V_METERNO);
              
                 
  END;
    EXCEPTION
        WHEN OTHERS THEN
             V_ERR_MSG := 'Unexpected error: ' || SQLERRM;
             DBMS_OUTPUT.PUT_LINE(V_ERR_MSG);
END;
/
