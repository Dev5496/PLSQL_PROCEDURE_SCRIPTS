
DECLARE
  P_SUBDIVN  VARCHAR2(4):='&SUBDIV';
  P_CYCLE NUMBER(2):=&CY;
  P_CUTOFF_DATE DATE:='&CUTOFFDATE'; 
  
  V_UNIT3 NUMBER;
  V_BT3               NUMBER(10, 4);
  V_UNIT1             NUMBER;
  V_BT1               NUMBER(10, 4);
  V_UNIT2             NUMBER;
  V_BT2               NUMBER(10, 4);
  V_UNIT4             NUMBER;
  V_BT4               NUMBER(10, 4);
  V_TOTALUNIT         NUMBER(20, 4) := 0.0000;
  V_MONTH_TYPE        NUMBER(10, 4) := 0.0000;
  V_AVG_UNIT          NUMBER(20, 4) := 0.0000;
  V_T_AVG_UNIT        NUMBER(20);
  V_STATUS            VARCHAR2(5);
  V_P_STAT            VARCHAR2(5);
  V_LK_DAYS           NUMBER(10);
  V_N_CYCLE           NUMBER(10);
  V_M_BT              NUMBER(10);
  V_NO_DAYS           NUMBER(10);
  V_CNT               NUMBER(10);
  V_ADJUNIT           NUMBER(20);
  VAR_PREV_CUT_DATE   DATE;
  V_NEW_CONS_FLAG     VARCHAR2(1);
  V_MR_AVG_UNIT       NUMBER(20, 4) := 0.0000;
  V_NEW_AVG_UNIT      NUMBER(20);
  V_PB_LOCK_INDICATOR NUMBER(10, 4) := 0.0000; --ADDED ON 17-JUN-2010 FOR ADDED DIFF DUE TO MORE THAN THREE LOCK BY SWETA
  V_PB_PREV_CONS      NUMBER(20, 4) := 0.0000; --ADDED ON 18-JUN-2010 FOR ADDE DIFF FOR >3 LOCK
BEGIN

  --VAR_PREV_CUT_DATE := PREVIOUSDATE(P_CYCLE,P_SUBDIVN,P_CUTOFF_DATE);
  --HIDED ON 14-JUN-2010 BY SWETA FOR AVG DIFF OF FAULTY CONSUMER IN 156 DUE TO MONTH TYPE IN CYCLE CHANGE CASE
  FOR C1 IN (SELECT CUS.CUSCODE, CUS.CUST_STATUS, CUS.TCODE, CUS.AVG_UNIT
               FROM CUSTMASTER CUS
              WHERE CUS.SUBDIV_CODE = P_SUBDIVN
                AND CUS.CYCLE_NO = P_CYCLE
                AND CUS.CUSCODE = '34514027154'  
             ) LOOP
    BEGIN
      V_TOTALUNIT     := 0.0000;
      V_T_AVG_UNIT    := 0;
      V_AVG_UNIT      := 0.0000;
      V_BT3           := 0.0000;
      V_LK_DAYS       := 0;
      V_P_STAT        := '';
      V_N_CYCLE       := 0;
      V_NO_DAYS       := 0;
      V_CNT           := 0;
      V_UNIT3         := 0;
      V_UNIT1         := 0;
      V_UNIT2         := 0;
      V_UNIT4         := 0;
      V_BT1           := 0;
      V_BT2           := 0;
      V_BT4           := 0;
      V_N_CYCLE       := 0;
      V_M_BT          := 0;
      V_P_STAT        := 0;
      V_LK_DAYS       := 0;
      V_T_AVG_UNIT    := 0;
      V_NO_DAYS       := 0;
      V_STATUS        := NULL;
      V_ADJUNIT       := 0;
      V_NEW_CONS_FLAG := 'N';
      V_MR_AVG_UNIT   := 0.0000;
      V_NEW_AVG_UNIT  := NULL;
      BEGIN
        ------- consuemr's last 3 months reading detail
        SELECT NVL(MR.CONSUNIT, 0),
               NVL(MR.MON_CONS1, 0),
               NVL(MR.MON_CONS2, 0),
               NVL(MR.MON_CONS3, 0),
               NVL(MR.BT1, 1),
               NVL(MR.BT2, 1),
               NVL(MR.BT3, 1),
               MR.CYCLE_NO,
               MR.BILLING_TYPE, MR.READSTATUS, MR.AVG_UNIT, MR.MONTH_TYPE
          INTO V_UNIT4,
               V_UNIT1,
               V_UNIT2,
               V_UNIT3,
               V_BT1,
               V_BT2,
               V_BT3,
               V_N_CYCLE,
               V_BT4,
               V_STATUS,
               V_MR_AVG_UNIT,
               V_MONTH_TYPE --ADDED ON 14-JUN-2010
          FROM METERREADING MR
         WHERE MR.SUBDIV_CODE = P_SUBDIVN
           AND MR.CUSTOMER_NO = C1.CUSCODE
           AND NVL(MR.METER_TYPE, 'M') IN ('M', 'T')
           AND
              -- MR.MON=12;
               (MR.YEAR * 100 + MR.MON) =
               (/*SELECT MAX(MRIN.YEAR * 100 + MRIN.MON)
                  FROM METERREADING MRIN
                 WHERE MRIN.SUBDIV_CODE = P_SUBDIVN
                   AND MRIN.CUSTOMER_NO = C1.CUSCODE
                   AND NVL(MRIN.METER_TYPE, 'M') IN ('M', 'T')*/'202511');
      
      EXCEPTION
        WHEN OTHERS THEN
          V_UNIT3      := 0;
          V_UNIT1      := 0;
          V_UNIT2      := 0;
          V_UNIT4      := 0;
          V_BT1        := 0;
          V_BT2        := 0;
          V_BT4        := 0;
          V_N_CYCLE    := 0;
          V_M_BT       := 0;
          V_STATUS     := NULL;
          V_MONTH_TYPE := 0; --ADDED ON 14-JUN-2010
      
      END;
      IF NVL(V_MONTH_TYPE, 0) = 0 THEN
        IF P_CYCLE IN (1, 2, 3, 4) THEN
          V_MONTH_TYPE := 2;
        ELSE
          V_MONTH_TYPE := 1;
        END IF;
      END IF;
      ------------ Previous bill record
      BEGIN
        SELECT P.METER_STATUS,
               P.LOCK_DAYS,
               NVL(P.NEW_AVG_UNIT, P.AVG_UNIT_NOD),
               NVL(P.NO_OF_DAYS, 0),
               P.NEW_AVG_UNIT,
               P.LOCK_INDICATOR, --ADDED ON 17-JUN-2010 FOR ADDED DIFFERENCE DUE TO LOCK INDICATOR>=2
               P.PREVIOUS_CONSUMPTION --ADDED ON 18-JUN-2010 FOR ADDED DIFFERENCE DUE TO >2 LOCK
          INTO V_P_STAT,
               V_LK_DAYS,
               V_T_AVG_UNIT,
               V_NO_DAYS,
               V_NEW_AVG_UNIT,
               V_PB_LOCK_INDICATOR,
               V_PB_PREV_CONS
          FROM PRINTED_BILL P
         WHERE P.SUB_DIVISION_CODE = P_SUBDIVN
           AND P.CONSUMER_NO = C1.CUSCODE
           AND NVL(P.MT_TYPE, 'M') IN ('M', 'T')
           AND P.PAYEMENT_UPTO_DATE =
               (SELECT MAX(PB.PAYEMENT_UPTO_DATE)
                  FROM PRINTED_BILL PB
                 WHERE PB.SUB_DIVISION_CODE = P_SUBDIVN
                   AND PB.CONSUMER_NO = C1.CUSCODE
                   AND PB.PAYEMENT_UPTO_DATE < P_CUTOFF_DATE
                   AND NVL(PB.MT_TYPE, 'M') IN ('M', 'T'));
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_P_STAT        := 0;
          V_LK_DAYS       := 0;
          V_T_AVG_UNIT    := 0;
          V_NO_DAYS       := 0;
          V_NEW_CONS_FLAG := 'Y';
          V_NEW_AVG_UNIT  := NULL;
          V_PB_PREV_CONS  := 0;
      END;
      ----- current month billl record
      BEGIN
        SELECT PB.ADJUSTMENT_UNITS
          INTO V_ADJUNIT
          FROM PRINTED_BILL PB
         WHERE PB.SUB_DIVISION_CODE = P_SUBDIVN
           AND PB.CONSUMER_NO = C1.CUSCODE
           AND PB.PAYEMENT_UPTO_DATE = P_CUTOFF_DATE
           AND NVL(PB.MT_TYPE, 'M') IN ('M', 'T');
      EXCEPTION
        WHEN OTHERS THEN
        
          V_ADJUNIT := 0;
      END;
    
      SELECT COUNT(*)
        INTO V_CNT
        FROM METERREADING MR
       WHERE MR.SUBDIV_CODE = P_SUBDIVN
         AND MR.CUSTOMER_NO = C1.CUSCODE
         AND NVL(MR.METER_TYPE, 'M') IN ('M', 'T');
    
      -------------------------------------------------------------------------------------------------
      --CONSUMER NOT NORMAL CONSUMER LAST ASSESSMENT CONSUMPTION IS ZERO THEN PREVIOUS AVG UNIT TO BE CONSIDERED
      IF V_STATUS IN ('L', 'F', 'X', 'Y', 'D', 'N') OR /*V_UNIT3 = 0*/
         V_UNIT4 = 0 THEN
        V_AVG_UNIT := V_T_AVG_UNIT;
      ELSE
        --CONSUMER NORMAL AND NEW AVG UNIT AVAILABLE THROUGH MASTER THEN PREVIOUS AVG UNIT TO BE CONSIDERED
        IF V_NEW_AVG_UNIT IS NOT NULL THEN
          V_AVG_UNIT := V_NEW_AVG_UNIT;
          --CONSUMER NORMAL AND NEW AVG UNIT NOT AVAILABLE THROUGH MASTER THEN AVG UNIT TO BE CALCULATED
        ELSE
        
          -------- LOCK TO NORAML WE HAVE TO CONSIDER LOCK DAYS FOR BILLING FACTOR
          IF V_P_STAT in ('L', 'N') AND
             NVL(V_STATUS, ' ') NOT IN ('L', 'N') AND
             V_PB_LOCK_INDICATOR <= 2 AND V_PB_PREV_CONS <> 0 THEN
            --COMMENTED ON 19122008
            --DUE TO SAMA AVG DIFF 15628066427 E-155 L-130 L-N ENABLED 196 LINE
            --HIDED ON 15-JUN-2010 FOR AVG DIFF IN LOCK CONSUMERS
            -- V_BT3 := (V_LK_DAYS / 30) + V_BT3;
            -- V_BT1 := (V_LK_DAYS / 30) + V_BT1; HIDED BY SWETA ON 13-JULY-2011 DUE TO LOCK CONSUMER  AVG CALCULATION
            NULL;
          END IF;
        
          IF (V_UNIT1 = 0) THEN
            V_UNIT1 := V_UNIT4;
            V_BT3   := V_BT1;
            V_BT1   := V_BT4;
          END IF;
        
          IF V_NO_DAYS = 1 THEN
            --HIDED ON 15-JUN-2010 FOR AVG DIFF IN LOCK CONSUMERS
            -- V_BT3 := (V_NO_DAYS / 30);
            V_BT1 := (V_NO_DAYS / 30);
          END IF;
        
          IF V_BT1 = 0 THEN
            V_BT1 := 1;
          END IF;
          -- 18-AUG-07
          -- IF ADJUSTMENT UNIT IS GREATER THAN ZERO THEN
          IF (V_ADJUNIT > 0 AND (V_T_AVG_UNIT * 5) > V_ADJUNIT) THEN
            V_UNIT1 := V_UNIT1 + V_ADJUNIT;
          END IF;
        
          IF (V_ADJUNIT < 0) THEN
            IF (V_UNIT3 > ABS(V_ADJUNIT)) THEN
              V_UNIT3 := V_UNIT3 + V_ADJUNIT;
            ELSIF (V_UNIT1 > ABS(V_ADJUNIT)) THEN
              V_UNIT1 := V_UNIT1 + V_ADJUNIT;
            ELSIF (V_UNIT2 > ABS(V_ADJUNIT)) THEN
              V_UNIT2 := V_UNIT2 + V_ADJUNIT;
            END IF;
          END IF;
        
          IF (V_UNIT1 <> 0) THEN
            V_UNIT1     := (V_UNIT1 * V_MONTH_TYPE) / V_BT1;
            V_TOTALUNIT := V_TOTALUNIT + V_UNIT1;
            
            DBMS_OUTPUT.PUT_LINE('UNIT1.1:' || V_UNIT1);
            DBMS_OUTPUT.PUT_LINE('TOTUNIT1.1:' || V_TOTALUNIT);  
          END IF;
          IF (V_UNIT2 <> 0 AND V_BT2 <> 0) THEN
            V_UNIT2     := (V_UNIT2 * V_MONTH_TYPE) / V_BT2;
            V_TOTALUNIT := V_TOTALUNIT + V_UNIT2;
            
            DBMS_OUTPUT.PUT_LINE('UNIT1.2:' || V_UNIT2);
            DBMS_OUTPUT.PUT_LINE('TOTUNIT1.2:' || V_TOTALUNIT);  
          END IF;
          IF (V_UNIT3 <> 0 AND V_BT3 <> 0) THEN
            V_UNIT3     := (V_UNIT3 * V_MONTH_TYPE) / V_BT3;
            V_TOTALUNIT := V_TOTALUNIT + V_UNIT3;
            
            DBMS_OUTPUT.PUT_LINE('UNIT1.3:' || V_UNIT3);
            DBMS_OUTPUT.PUT_LINE('TOTUNIT1.3:' || V_TOTALUNIT);  
          END IF;
        
          V_AVG_UNIT := ROUND(((V_TOTALUNIT / 30) * 10), 4);
          DBMS_OUTPUT.PUT_LINE('AVG_UNIT:' || V_AVG_UNIT);
          
          SELECT ROUND(V_AVG_UNIT, -1) INTO V_AVG_UNIT FROM DUAL;
          DBMS_OUTPUT.PUT_LINE('AVG UNIT - 1 :' || V_AVG_UNIT);
          V_AVG_UNIT := V_AVG_UNIT / V_MONTH_TYPE;
          
          DBMS_OUTPUT.PUT_LINE('MONTH TYPE1.1:' || V_MONTH_TYPE);
          DBMS_OUTPUT.PUT_LINE('AVG_UNIT1.1:' || V_AVG_UNIT);

          IF V_UNIT3 = 0 AND V_STATUS IS NULL THEN
            V_AVG_UNIT := (V_T_AVG_UNIT / V_MONTH_TYPE);
            V_BT3      := V_MONTH_TYPE;
            
            DBMS_OUTPUT.PUT_LINE('BT3_1.1:' || V_BT3);
            DBMS_OUTPUT.PUT_LINE('T_AVG_UNIT:' || V_T_AVG_UNIT);
            DBMS_OUTPUT.PUT_LINE('AVG_UNIT1.2:' || V_AVG_UNIT);
          END IF;
          
          IF (V_UNIT1 = 0) THEN
            -- V_AVG_UNIT := V_MR_AVG_UNIT / V_BT1;
            V_AVG_UNIT := V_MR_AVG_UNIT / V_MONTH_TYPE;
          END IF;
        END IF;
      END IF;
    
      IF V_NEW_CONS_FLAG = 'Y' THEN
        V_AVG_UNIT := C1.AVG_UNIT;
      END IF;
      DBMS_OUTPUT.PUT_LINE('-------------------------------------------');
      DBMS_OUTPUT.PUT_LINE('MON TYPE:' || V_MONTH_TYPE);    
      DBMS_OUTPUT.PUT_LINE('STATUS:' || V_STATUS);
      DBMS_OUTPUT.PUT_LINE('NEW AVG UNIT:' || V_NEW_AVG_UNIT); 
      DBMS_OUTPUT.PUT_LINE('P STATUS:' || V_P_STAT);
      DBMS_OUTPUT.PUT_LINE('UNIT1:' || V_UNIT1);
      DBMS_OUTPUT.PUT_LINE('TOTUNIT1.1:' || V_TOTALUNIT);  
      DBMS_OUTPUT.PUT_LINE('NO OF DAYS:' || V_NO_DAYS);
      DBMS_OUTPUT.PUT_LINE('BT1:' || V_BT1);
      DBMS_OUTPUT.PUT_LINE('ADJ UNIT:' || V_ADJUNIT);
      DBMS_OUTPUT.PUT_LINE('UNIT1.2:' || V_UNIT1);
      DBMS_OUTPUT.PUT_LINE('MONTH TYPE:' || V_MONTH_TYPE);             
      DBMS_OUTPUT.PUT_LINE('AVG UNIT:' || V_AVG_UNIT);

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
  
  END LOOP;
END;
/
