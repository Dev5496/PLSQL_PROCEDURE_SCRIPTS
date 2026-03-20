DECLARE
  --VARIABLES
  V_MM_FINALMF                 NUMBER := 0;
  V_MM_PAST_RDG_MM             NUMBER := 0;
  V_MM_PAST_PEAK_MM            NUMBER := 0;
  V_MM_PAST_PEAK2_MM           NUMBER := 0;
  V_PB_TARIFF_CODE             NUMBER := 0;
  V_PB_CYCLE_NUMBER            NUMBER := 0;
  V_PB_METER_READER_NO         NUMBER := 0;
  V_PB_BOOK_NUMBER             NUMBER := 0;
  V_PB_ROUTE_CODE              NUMBER := 0;
  V_PB_START_METER             NUMBER := 0;
  V_PB_START_METER_KVARH       NUMBER := 0;
  V_PB_AVERAGE_UNIT            NUMBER := 0;
  V_PB_AVERAGE_PEAK_UNIT       NUMBER := 0;
  V_PB_AVERAGE_PEAK2_UNIT      NUMBER := 0;
  V_PB_AVERAGE_NIGHT_UNIT      NUMBER := 0;
  V_PB_AVERAGE_REST_UNIT       NUMBER := 0;
  V_PB_AVERAGE_IMP_UNIT        NUMBER := 0;
  V_PB_AVERAGE_EXP_UNIT        NUMBER := 0;
  V_PB_NEW_AVG_UNIT            NUMBER := 0;
  V_PB_NEW_AVG_PEAK_UNIT       NUMBER := 0;
  V_PB_NEW_AVG_PEAK2_UNIT      NUMBER := 0;
  V_PB_NEW_AVG_NIGHT_UNIT      NUMBER := 0;
  V_PB_NEW_AVG_REST_UNIT       NUMBER := 0;
  V_PB_NEW_AVG_IMP_UNIT        NUMBER := 0;
  V_PB_NEW_AVG_EXP_UNIT        NUMBER := 0;
  V_PB_PREVIOUS_READ_STATUS    VARCHAR2(4);
  V_PB_LOCK_DAYS_FACTOR        NUMBER := 0;
  V_PB_BILLING_FACTOR          NUMBER := 0;
  V_PB_BILLING_PERIOD          NUMBER := 0;
  V_PB_NUMBER_OF_DAYS          NUMBER := 0;
  V_PB_LOCK_DAYS               NUMBER := 0;
  V_PB_FUSE_MISC_CHARGE        NUMBER := 0;
  V_PB_DELAY_PAYMENT_CHARGE    NUMBER := 0;
  V_PB_PROVISIONAL_BILL_AMOUNT NUMBER := 0;
  V_PB_BF_ARREARS_AMOUNT       NUMBER := 0;
  V_PB_PAYDATE                 DATE;
  V_PB_PROVI_BILL_AMOUNT_REF   NUMBER := 0;
  V_PB_MTR_CHANGE_FLAG         NUMBER := 0;
  V_PB_NEW_PAST_RDNG           NUMBER := 0;
  V_PB_NEW_PAST_PEAK_RDNG      NUMBER := 0;
  V_PB_NEW_PAST_PEAK2_RDNG     NUMBER := 0;
  V_PB_NEW_PAST_NIGHT_RDNG     NUMBER := 0;
  V_PB_NEW_PAST_REST_RDNG      NUMBER := 0;
  V_AVERAGE_MAXIMUM_DEMAND     NUMBER := 0;
  V_PB_LITIGATION_ARREARS      NUMBER := 0;
  V_PB_THEFT_ARREARS           NUMBER := 0;
  V_IMP_RDNG                   NUMBER := 0;
  V_EXP_RDNG                   NUMBER := 0;
  V_PB_START_METER_PEAK        NUMBER := 0;
  V_PB_START_METER_PEAK2       NUMBER := 0;
  V_PB_START_METER_NIGHT       NUMBER := 0;
  V_PB_START_METER_REST        NUMBER := 0;
  V_BULB_AMT                   NUMBER := 0;
  V_B_AMT                      NUMBER := 0;
  V_F_AMT                      NUMBER := 0;
  V_T_AMT                      NUMBER := 0;
  V_G_AMT                      NUMBER := 0;
  V_CUS_CAT                    VARCHAR2(20);
  V_CUS_TARIFF_CODE            VARCHAR2(20);
  V_CUS_FEEDER_NO              NUMBER := 0;
  V_CUS_CLOAD                  NUMBER := 0;
  V_CUS_DEMAND                 NUMBER := 0;
  V_CUS_KVAR                   NUMBER := 0;
  V_CUS_CUST_STATUS            VARCHAR2(20);
  V_CUS_CYCLE_NUMBER           NUMBER := 0;
  V_CUS_AVG_UNIT_CUS           NUMBER := 0;
  V_CUS_AVG_PEAK_UNIT_CUS      NUMBER := 0;
  V_CUS_AVG_PEAK2_UNIT_CUS     NUMBER := 0;
  V_CUS_AVG_NIGHT_UNIT_CUS     NUMBER := 0;
  V_CUS_AVG_REST_UNIT_CUS      NUMBER := 0;
  V_CUS_AVG_IMP_UNIT_CUS       NUMBER := 0;
  V_CUS_AVG_EXP_UNIT_CUS       NUMBER := 0;
  V_CUS_COMB_CODE              VARCHAR2(50);
  V_CUS_METER_READER_NO        NUMBER := 0;
  V_CUS_BOOK_NUMBER            NUMBER := 0;
  V_CUS_ROUTE_CODE             NUMBER := 0;
  V_SEASIONAL_INDICATOR        VARCHAR2(20);
  V_FIXTURE_LOAD               NUMBER := 0;
  V_ED_EXEMPTION_DATE          DATE;
  V_CNAME                      VARCHAR2(100);
  V_ADDRESS1                   VARCHAR2(150);
  V_CONN_DATE                  NUMBER;
  V_INDUSTRY_TYPE              VARCHAR2(15);
  V_CUS_PHASE                  VARCHAR2(2);
  V_SOLAR_CONSUMER             VARCHAR2(2);
  V_SKY_CONSUMER               VARCHAR2(2);
  V_SOLAR_AG_DATE              DATE;
  V_SOLAR_RATE                 NUMBER := 0;
  V_GOV_INDICATOR              VARCHAR2(2);
  V_IMP_DIFF                   NUMBER := 0;
  V_EXP_DIFF                   NUMBER := 0;
  V_ACTUAL_CONSUMED_UNITS      NUMBER := 0;
  V_CONSUMED_UNITS_KVARH       NUMBER := 0;
  V_CONSUMED_UNITS_PEAK        NUMBER := 0;
  V_CONSUMED_UNITS_PEAK2       NUMBER := 0;
  V_CONSUMED_UNITS_NIGHT       NUMBER := 0;
  V_CONSUMED_UNITS_REST        NUMBER := 0;
  V_GTR_RDNG_CONS              NUMBER;
  V_MM_PAST_KVARH_RDG_MM       NUMBER := 0;
  V_MM_PAST_NIGHT_MM           NUMBER := 0;
  V_MM_PAST_REST_MM            NUMBER := 0;
  V_MM_PAST_RDG_IMP_MM         NUMBER := 0;
  V_MM_PAST_RDG_EXP_MM         NUMBER := 0;
  V_PEAK_RDNG                  NUMBER := 0;
  V_PEAK2_RDNG                 NUMBER := 0;
  V_PREV_BILL_DATE             NUMBER := 0;
  V_CONSUMED_UNITS             NUMBER := 0;
  V_MM_PEAK_PAST_RDG_MM        NUMBER := 0;
  V_MM_PEAK2_PAST_RDG_MM       NUMBER := 0;

  --INPUTS:
  P_SUBDIVISION_CODE NUMBER(4) := &SUBDIVISION;
  P_CYCLE_NUMBER     NUMBER(2) := &CY;
  P_BILLED_MONTH     NUMBER(3) := &MON;
  P_BILLED_YEAR      NUMBER(5) := &YER;

BEGIN
  DBMS_OUTPUT.PUT_LINE('PROCESS ONGOING....');
  DBMS_OUTPUT.PUT_LINE('FETCHING DATA AND CALCULATING....');
  FOR G41_VALUES IN (SELECT ROWID,
                            TRIM(ST.CONS_NO) CONS_NO,
                            TRIM(ST.BIL_DATE) BIL_DATE,
                            TRIM(ST.DUE_DATE) DUE_DATE,
                            TRIM(ST.CUR_RDG) CUR_RDG,
                            TRIM(ST.UNITS) UNITS,
                            TRIM(ST.STA) STA,
                            TRIM(ST.BILL_AMT) BILL_AMT,
                            TRIM(ST.NET_AMT) NET_AMT,
                            TRIM(ST.RCURR) RCURR,
                            TRIM(ST.ACT_DEM) ACT_DEM,
                            TRIM(ST.IMP_RDNG) IMP_RDNG,
                            TRIM(ST.EXP_RDNG) EXP_RDNG,
                            TRIM(ST.PEAK_READING) PEAK,
                            TRIM(ST.PEAK_2_READING) PEAK2,
                            TRIM(ST.NIGHT) NIGHT,
                            TRIM(ST.REST_KWH) REST,
                            NVL(TRIM(ST.METER_SEQ), 1) METER_SEQ,
                            NVL(TRIM(ST.METER_TYPE), 'M') METER_TYPE,
                            NVL(TRIM(ST.PREPAID_FLAG), 'N') PREPAID_FLAG,
                            TRIM(ST.CREATED_BY) CREATED_BY
                       FROM G41_FILE_STAGING_TABLE_GPRS ST
                      WHERE ST.SUBDIVISION = P_SUBDIVISION_CODE
                        AND ST.BILLED_MONTH = P_BILLED_MONTH
                        AND ST.BILLED_YEAR = P_BILLED_YEAR
                        AND ST.CYCLE_NO = P_CYCLE_NUMBER
                           --AND ST.CONS_NO IN(/* '20001007530','15518083823',*/'20001007530')
                        AND ST.INSERT_DATE =
                            (SELECT MAX(STT.INSERT_DATE)
                               FROM G41_FILE_STAGING_TABLE_GPRS STT
                              WHERE STT.SUBDIVISION = P_SUBDIVISION_CODE
                                AND STT.BILLED_MONTH = P_BILLED_MONTH
                                AND STT.BILLED_YEAR = P_BILLED_YEAR
                                AND STT.CYCLE_NO = P_CYCLE_NUMBER
                                AND STT.CONS_NO = ST.CONS_NO
                                AND NVL(STT.METER_SEQ, '1') =
                                    NVL(ST.METER_SEQ, '1'))
                      ORDER BY ST.CONS_NO, ST.METER_SEQ) LOOP
    -- G41_VALUES LOOP START
  
    IF (G41_VALUES.METER_TYPE IN ('M', 'T')) THEN
      --GET MF AND INITIAL READING OF SUB METER CONSUMERS
      SELECT NVL(MM.FINAL_MF, 1),
             MM.I_READING,
             MM.I_READING_PEAK,
             MM.I_READING_PEAK_2
        INTO V_MM_FINALMF,
             V_MM_PAST_RDG_MM,
             V_MM_PAST_PEAK_MM,
             V_MM_PAST_PEAK2_MM
        FROM METER_MASTER MM
       WHERE MM.SUBDIVISION_CODE = P_SUBDIVISION_CODE
         AND MM.CUSTOMER_NO = G41_VALUES.CONS_NO;
    
      IF length(TO_CHAR(V_MM_PAST_RDG_MM)) >= 8 OR
         length(TO_CHAR(V_MM_PAST_PEAK_MM)) >= 8 OR
         length(TO_CHAR(V_MM_PAST_PEAK2_MM)) >= 8 THEN
      
        DBMS_OUTPUT.PUT_LINE('MAIN METER INITIAL READINGS ENTER IS GRATER THAN EQUAL TO 8 DIGITS');
        DBMS_OUTPUT.PUT_LINE('CONS: ' || G41_VALUES.CONS_NO);
        DBMS_OUTPUT.PUT_LINE('MF: ' || V_MM_FINALMF);
        DBMS_OUTPUT.PUT_LINE('I_READING:' || V_MM_PAST_RDG_MM ||
                             '  I_READING_PEAK:' || V_MM_PAST_PEAK_MM ||
                             ' I_READING_PEAK_2:' || V_MM_PAST_PEAK2_MM);
        DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------------------------------------------------------');
      END IF;
    ELSE
      --GET MF AND INITIAL READING OF SUB METER CONSUMERS
      SELECT NVL(MM.FINAL_MF, 1), MM.I_READING
        INTO V_MM_FINALMF, V_MM_PAST_RDG_MM
        FROM SUB_METER_MASTER MM
       WHERE MM.SUBDIVISION_CODE = P_SUBDIVISION_CODE
         AND MM.CUSTOMER_NO = G41_VALUES.CONS_NO
         AND MM.METER_SEQ = G41_VALUES.METER_SEQ;
    
      IF LENGTH(TO_CHAR(V_MM_PAST_RDG_MM)) >= 8 THEN
      
        DBMS_OUTPUT.PUT_LINE('SUB-METER INITIAL READINGS ENTER IS GRATER THAN EQUAL TO 8 DIGITS');
        DBMS_OUTPUT.PUT_LINE('CONS: ' || G41_VALUES.CONS_NO);
        DBMS_OUTPUT.PUT_LINE('I_READING:' || V_MM_PAST_RDG_MM);
        DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------------------------------------------------------');
      END IF;
    END IF;
  
    --GET READINGS FROM CUSTMASTER:
    BEGIN
      SELECT CUS.CCAT,
             CUS.TCODE,
             CUS.FEEDER_NO,
             CUS.CLOAD,
             CUS.CDEMAND,
             CUS.KVAR,
             CUS.CUST_STATUS,
             CUS.CYCLE_NO,
             CUS.AVG_UNIT,
             CUS.PEAK_AVG_UNIT,
             CUS.PEAK_2_AVG_UNIT,
             CUS.NIGHT_AVG_UNIT,
             CUS.REST_AVG_UNIT,
             CUS.IMP_AVG_UNIT,
             CUS.EXP_AVG_UNIT,
             CUS.EDUTY_CODE,
             CUS.MR_NO,
             CUS.BOOK_NO,
             CUS.ROUTE_CODE,
             CUS.NO_DAYS,
             CUS.SEASONAL_INDICATOR,
             CUS.FIXTURE_LOAD,
             CUS.ED_EXEMPTION_DATE,
             CUS.CNAME,
             CUS.ADDRESS1,
             TO_CHAR(CUS.CONNECTION_RELEASE_DT, 'YYYYMMDD'),
             NVL(CUS.INDUSTRY_TYPE, ' '),
             CUS.PHASE,
             NVL(CUS.SOLAR_CONSUMER, 'N'),
             NVL(CUS.SKY_CONSUMER, 'N'),
             CUS.SOLAR_AGREEMENT_DATE,
             CUS.SOLAR_RATE,
             NVL(CUS.GOVT_INDICATOR, 'N')
        INTO V_CUS_CAT,
             V_CUS_TARIFF_CODE,
             V_CUS_FEEDER_NO,
             V_CUS_CLOAD,
             V_CUS_DEMAND,
             V_CUS_KVAR,
             V_CUS_CUST_STATUS,
             V_CUS_CYCLE_NUMBER,
             V_CUS_AVG_UNIT_CUS,
             V_CUS_AVG_PEAK_UNIT_CUS,
             V_CUS_AVG_PEAK2_UNIT_CUS,
             V_CUS_AVG_NIGHT_UNIT_CUS,
             V_CUS_AVG_REST_UNIT_CUS,
             V_CUS_AVG_IMP_UNIT_CUS,
             V_CUS_AVG_EXP_UNIT_CUS,
             V_CUS_COMB_CODE,
             V_CUS_METER_READER_NO,
             V_CUS_BOOK_NUMBER,
             V_CUS_ROUTE_CODE,
             V_PB_NUMBER_OF_DAYS,
             V_SEASIONAL_INDICATOR,
             V_FIXTURE_LOAD,
             V_ED_EXEMPTION_DATE,
             V_CNAME,
             V_ADDRESS1,
             V_CONN_DATE,
             V_INDUSTRY_TYPE,
             V_CUS_PHASE,
             V_SOLAR_CONSUMER,
             V_SKY_CONSUMER,
             V_SOLAR_AG_DATE,
             V_SOLAR_RATE,
             V_GOV_INDICATOR
        FROM CUSTMASTER CUS
       WHERE CUS.CUSCODE = G41_VALUES.CONS_NO;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('CONSUMER NOT FOUND');
        DBMS_OUTPUT.PUT_LINE('CONS: ' || G41_VALUES.CONS_NO);
      
    END;
  
    -- GET BILL READINGS;
    BEGIN
      SELECT PB.TARIFF,
             PB.CYCLE_NUMBER,
             PB.METER_REAADER_NO,
             PB.BOOK_NO,
             PB.ROUTE_CODE,
             DECODE(PB.NEW_PAST_RDNG,
                    NULL,
                    PB.PAST_READING_KWH,
                    PB.NEW_PAST_RDNG),
             DECODE(PB.NEW_REACTIVE_REDG,
                    NULL,
                    PB.PAST_READING_KVARH,
                    PB.NEW_REACTIVE_REDG),
             DECODE(PB.NEW_AVG_UNIT,
                    NULL,
                    NVL(PB.AVG_UNIT_NOD, 0),
                    PB.NEW_AVG_UNIT),
             DECODE(PB.NEW_AVG_UNIT_PEAK,
                    NULL,
                    NVL(PB.AVG_UNIT_NOD_PEAK, 0),
                    PB.NEW_AVG_UNIT_PEAK),
             DECODE(PB.NEW_AVG_UNIT_PEAK_2,
                    NULL,
                    NVL(PB.AVG_UNIT_NOD_PEAK_2, 0),
                    PB.NEW_AVG_UNIT_PEAK_2),
             DECODE(PB.NEW_AVG_UNIT_NIGHT,
                    NULL,
                    NVL(PB.AVG_UNIT_NOD_NIGHT, 0),
                    PB.NEW_AVG_UNIT_NIGHT),
             DECODE(PB.NEW_AVG_UNIT_REST,
                    NULL,
                    NVL(PB.AVG_UNIT_NOD_REST, 0),
                    PB.NEW_AVG_UNIT_REST),
             DECODE(PB.NEW_AVG_UNIT_IMP,
                    NULL,
                    NVL(PB.AVG_UNIT_NOD_IMP, 0),
                    PB.NEW_AVG_UNIT_IMP),
             DECODE(PB.NEW_AVG_UNIT_EXP,
                    NULL,
                    NVL(PB.AVG_UNIT_NOD_EXP, 0),
                    PB.NEW_AVG_UNIT_EXP),
             PB.NEW_AVG_UNIT,
             PB.NEW_AVG_UNIT_PEAK,
             PB.NEW_AVG_UNIT_PEAK_2,
             PB.NEW_AVG_UNIT_NIGHT,
             PB.NEW_AVG_UNIT_REST,
             PB.NEW_AVG_UNIT_IMP,
             PB.NEW_AVG_UNIT_EXP,
             PB.METER_STATUS,
             NVL(PB.LOCK_INDICATOR, 0),
             PB.BILLING_FACTOR,
             PB.BILLING_PERIOD,
             NULLIF(DECODE(PB.NEW_NO_OF_DAYS,
                           NULL,
                           NVL(PB.NO_OF_DAYS, 0),
                           PB.NEW_NO_OF_DAYS),
                    0), --ADDED  27062008
             PB.LOCK_DAYS,
             PB.MISCHARGE,
             PB.D_P_C,
             PB.PROVISIONAL_BILL_AMOUNT,
             PB.V_ARREARS_AMOUNT,
             PB.PAYEMENT_UPTO_DATE,
             PB.PROVAMT_REF,
             PB.METER_CHANGE_FLAG,
             PB.NEW_PAST_RDNG,
             PB.NEW_PEAK_REDG,
             PB.NEW_PEAK_2_REDG,
             PB.NEW_NIGHT_REDG,
             PB.NEW_REST_REDG,
             NVL(PB.AVERAGE_MAXIMUM_DEMAND, 0),
             NVL(PB.LITIGATION_ARREARS, 0),
             NVL(PB.THEFT_ARREARS, 0),
             DECODE(PB.NEW_IMP_KWH, NULL, PB.END_IMP_RDNG, PB.NEW_IMP_KWH),
             DECODE(PB.NEW_EXP_KWH, NULL, PB.END_EXP_RDNG, PB.NEW_EXP_KWH),
             DECODE(PB.NEW_PEAK_REDG,
                    NULL,
                    PB.PAST_PEAK_RDING,
                    PB.NEW_PEAK_REDG),
             DECODE(PB.NEW_PEAK_2_REDG,
                    NULL,
                    PB.PAST_PEAK_2_RDING,
                    PB.NEW_PEAK_2_REDG),
             DECODE(PB.NEW_NIGHT_REDG,
                    NULL,
                    PB.PAST_NIGHT_RDING,
                    PB.NEW_NIGHT_REDG),
             DECODE(PB.NEW_REST_REDG,
                    NULL,
                    PB.PAST_REST_RDING,
                    PB.NEW_REST_REDG),
             NVL(PB.BULB_AMT, 0),
             NVL(PB.B_AMT, 0),
             NVL(PB.F_AMT, 0),
             NVL(PB.T_AMT, 0),
             NVL(PB.G_AMT, 0)
        INTO V_PB_TARIFF_CODE,
             V_PB_CYCLE_NUMBER,
             V_PB_METER_READER_NO,
             V_PB_BOOK_NUMBER,
             V_PB_ROUTE_CODE,
             V_PB_START_METER,
             V_PB_START_METER_KVARH,
             V_PB_AVERAGE_UNIT,
             V_PB_AVERAGE_PEAK_UNIT,
             V_PB_AVERAGE_PEAK2_UNIT,
             V_PB_AVERAGE_NIGHT_UNIT,
             V_PB_AVERAGE_REST_UNIT,
             V_PB_AVERAGE_IMP_UNIT,
             V_PB_AVERAGE_EXP_UNIT,
             V_PB_NEW_AVG_UNIT,
             V_PB_NEW_AVG_PEAK_UNIT,
             V_PB_NEW_AVG_PEAK2_UNIT,
             V_PB_NEW_AVG_NIGHT_UNIT,
             V_PB_NEW_AVG_REST_UNIT,
             V_PB_NEW_AVG_IMP_UNIT,
             V_PB_NEW_AVG_EXP_UNIT,
             V_PB_PREVIOUS_READ_STATUS,
             V_PB_LOCK_DAYS_FACTOR,
             V_PB_BILLING_FACTOR,
             V_PB_BILLING_PERIOD,
             V_PB_NUMBER_OF_DAYS,
             V_PB_LOCK_DAYS,
             V_PB_FUSE_MISC_CHARGE,
             V_PB_DELAY_PAYMENT_CHARGE,
             V_PB_PROVISIONAL_BILL_AMOUNT,
             V_PB_BF_ARREARS_AMOUNT,
             V_PB_PAYDATE,
             V_PB_PROVI_BILL_AMOUNT_REF,
             V_PB_MTR_CHANGE_FLAG,
             V_PB_NEW_PAST_RDNG,
             V_PB_NEW_PAST_PEAK_RDNG,
             V_PB_NEW_PAST_PEAK2_RDNG,
             V_PB_NEW_PAST_NIGHT_RDNG,
             V_PB_NEW_PAST_REST_RDNG,
             V_AVERAGE_MAXIMUM_DEMAND,
             V_PB_LITIGATION_ARREARS,
             V_PB_THEFT_ARREARS,
             V_IMP_RDNG,
             V_EXP_RDNG,
             V_PB_START_METER_PEAK,
             V_PB_START_METER_PEAK2,
             V_PB_START_METER_NIGHT,
             V_PB_START_METER_REST,
             V_BULB_AMT,
             V_B_AMT,
             V_F_AMT,
             V_T_AMT,
             V_G_AMT
        FROM PRINTED_BILL PB
       WHERE PB.SUB_DIVISION_CODE = P_SUBDIVISION_CODE
         AND PB.CONSUMER_NO = G41_VALUES.CONS_NO
         AND NVL(PB.MT_TYPE, 'M') IN ('M', 'T')
         AND PB.PAYEMENT_UPTO_DATE =
             (SELECT MAX(PBIN.PAYEMENT_UPTO_DATE)
                FROM PRINTED_BILL PBIN
               WHERE PBIN.SUB_DIVISION_CODE = P_SUBDIVISION_CODE
                 AND PBIN.CONSUMER_NO = G41_VALUES.CONS_NO
                 AND NVL(PBIN.MT_TYPE, 'M') IN ('M', 'T'));
    EXCEPTION
      WHEN OTHERS THEN
        V_PB_START_METER       := NULL;
        V_PB_START_METER_KVARH := NULL;
        V_PB_START_METER_PEAK  := NULL;
        V_PB_START_METER_PEAK2 := NULL;
        V_PB_START_METER_NIGHT := NULL;
        V_PB_START_METER_REST  := NULL;
    END;
  
    -- USE PAST READINGS IF NEW READINGS ARE NULL
    IF (V_PB_AVERAGE_UNIT IS NULL) THEN
      V_PB_AVERAGE_UNIT := V_CUS_AVG_UNIT_CUS;
    END IF;
    IF (V_PB_AVERAGE_PEAK_UNIT IS NULL) THEN
      V_PB_AVERAGE_PEAK_UNIT := V_CUS_AVG_PEAK_UNIT_CUS;
    END IF;
  
    IF (V_PB_AVERAGE_PEAK2_UNIT IS NULL) THEN
      V_PB_AVERAGE_PEAK2_UNIT := V_CUS_AVG_PEAK2_UNIT_CUS;
    END IF;
  
    IF (V_PB_AVERAGE_NIGHT_UNIT IS NULL) THEN
      V_PB_AVERAGE_NIGHT_UNIT := V_CUS_AVG_NIGHT_UNIT_CUS;
    END IF;
  
    IF (V_PB_AVERAGE_REST_UNIT IS NULL) THEN
      V_PB_AVERAGE_REST_UNIT := V_CUS_AVG_REST_UNIT_CUS;
    END IF;
  
    IF (V_PB_AVERAGE_IMP_UNIT IS NULL) THEN
      V_PB_AVERAGE_IMP_UNIT := V_CUS_AVG_IMP_UNIT_CUS;
    END IF;
  
    IF (V_PB_AVERAGE_EXP_UNIT IS NULL) THEN
      V_PB_AVERAGE_EXP_UNIT := V_CUS_AVG_EXP_UNIT_CUS;
    END IF;
    ----------------------------------------------------------
  
    IF (V_PB_START_METER IS NULL) THEN
      V_PB_START_METER := V_MM_PAST_RDG_MM;
    END IF;
    ----------------------------------------------------------
  
    IF (V_PB_START_METER_KVARH IS NULL) THEN
      V_PB_START_METER_KVARH := V_MM_PAST_KVARH_RDG_MM;
    END IF;
    IF (V_PB_START_METER_PEAK IS NULL) THEN
      V_PB_START_METER_PEAK := V_MM_PAST_PEAK_MM;
    END IF;
    IF (V_PB_START_METER_PEAK2 IS NULL) THEN
      V_PB_START_METER_PEAK2 := V_MM_PAST_PEAK2_MM;
    END IF;
    IF (V_PB_START_METER_NIGHT IS NULL) THEN
      V_PB_START_METER_NIGHT := V_MM_PAST_NIGHT_MM;
    END IF;
    IF (V_PB_START_METER_REST IS NULL) THEN
      V_PB_START_METER_REST := V_MM_PAST_REST_MM;
    END IF;
    -----------------------------------------------------------
  
    IF (V_IMP_RDNG IS NULL) THEN
      V_IMP_RDNG := V_MM_PAST_RDG_IMP_MM;
    END IF;
    ----------------------------------------------------------
    IF (V_EXP_RDNG IS NULL) THEN
      V_EXP_RDNG := V_MM_PAST_RDG_EXP_MM;
    END IF;
    IF (V_PEAK_RDNG IS NULL) THEN
      V_PEAK_RDNG := V_MM_PEAK_PAST_RDG_MM;
    END IF;
    ----------------------------------------------------------
    IF (V_PEAK2_RDNG IS NULL) THEN
      V_PEAK2_RDNG := V_MM_PEAK2_PAST_RDG_MM;
    END IF;
    V_PREV_BILL_DATE := NULL;
  
    -- CHECK IF CONSUMER IS NORMAL,SKY,OR SOLAR      
  
    BEGIN
    
      SELECT CUS.SOLAR_CONSUMER, CUS.SKY_CONSUMER
        INTO V_SOLAR_CONSUMER, V_SKY_CONSUMER
        FROM CUSTMASTER CUS
       WHERE CUS.CUSCODE = G41_VALUES.CONS_NO;
    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      
        DBMS_OUTPUT.PUT_LINE('CONSUMER NOT FOUND');
        DBMS_OUTPUT.PUT_LINE('CONS: ' || G41_VALUES.CONS_NO);
      
    END;
  
    IF (NVL(G41_VALUES.STA, ' ') = 'U') THEN
    
      V_CONSUMED_UNITS        := 0;
      V_CONSUMED_UNITS_KVARH  := 0;
      V_ACTUAL_CONSUMED_UNITS := V_CONSUMED_UNITS;
      V_CONSUMED_UNITS_PEAK   := 0;
      V_CONSUMED_UNITS_PEAK2  := 0;
      V_CONSUMED_UNITS_NIGHT  := 0;
      V_CONSUMED_UNITS_REST   := 0;
    
      /**********************************************************
                        CONSUMPTION CALCULATION
      ***********************************************************/
    ELSE
      IF (V_SOLAR_CONSUMER = 'Y' or V_SKY_CONSUMER = 'Y') THEN
      
        V_IMP_DIFF       := DIAL_COMPLETION(NVL(V_IMP_RDNG, 0),
                                            G41_VALUES.IMP_RDNG,
                                            G41_VALUES.STA) * V_MM_FINALMF;
        V_EXP_DIFF       := DIAL_COMPLETION(NVL(V_EXP_RDNG, 0),
                                            G41_VALUES.EXP_RDNG,
                                            G41_VALUES.STA) * V_MM_FINALMF;
        V_CONSUMED_UNITS := V_IMP_DIFF - V_EXP_DIFF;
      
        -- To get consumed units, multiply the consumption with Final MF
        V_CONSUMED_UNITS := FLOOR(V_CONSUMED_UNITS);
      ELSE
        V_CONSUMED_UNITS := DIAL_COMPLETION(NVL(V_PB_START_METER, 0),
                                            G41_VALUES.CUR_RDG,
                                            G41_VALUES.STA);
      
        -- To get consumed units, multiply the consumption with Final MF
        V_CONSUMED_UNITS := FLOOR(V_CONSUMED_UNITS * V_MM_FINALMF);
      END IF;
      V_ACTUAL_CONSUMED_UNITS := V_CONSUMED_UNITS;
      V_CONSUMED_UNITS_KVARH  := DIAL_COMPLETION(NVL(V_PB_START_METER_KVARH,
                                                     0),
                                                 G41_VALUES.RCURR,
                                                 G41_VALUES.STA);
      --  To get consumed KVARH units, multiply the reading with Final MF
      V_CONSUMED_UNITS_KVARH := FLOOR(V_CONSUMED_UNITS_KVARH * V_MM_FINALMF);
    
      --PEAK 1
      V_CONSUMED_UNITS_PEAK := DIAL_COMPLETION(NVL(V_PB_START_METER_PEAK, 0),
                                               G41_VALUES.PEAK,
                                               G41_VALUES.STA);
      V_CONSUMED_UNITS_PEAK := FLOOR(V_CONSUMED_UNITS_PEAK * V_MM_FINALMF);
    
      --PEAK 2
      V_CONSUMED_UNITS_PEAK2 := DIAL_COMPLETION(NVL(V_PB_START_METER_PEAK2,
                                                    0),
                                                G41_VALUES.PEAK2,
                                                G41_VALUES.STA);
      V_CONSUMED_UNITS_PEAK2 := FLOOR(V_CONSUMED_UNITS_PEAK2 * V_MM_FINALMF);
    
      --NIGHT
      V_CONSUMED_UNITS_NIGHT := DIAL_COMPLETION(NVL(V_PB_START_METER_NIGHT,
                                                    0),
                                                G41_VALUES.NIGHT,
                                                G41_VALUES.STA);
      V_CONSUMED_UNITS_NIGHT := FLOOR(V_CONSUMED_UNITS_NIGHT * V_MM_FINALMF);
    
      --REST
      V_CONSUMED_UNITS_REST := DIAL_COMPLETION(NVL(V_PB_START_METER_REST, 0),
                                               G41_VALUES.REST,
                                               G41_VALUES.STA);
      V_CONSUMED_UNITS_REST := FLOOR(V_CONSUMED_UNITS_REST * V_MM_FINALMF);
    END IF;
  
    --CHECK CALCULATED CONSUMER UNIT LENGTH
    IF LENGTH(TO_CHAR(V_CONSUMED_UNITS)) >= 9 THEN
      DBMS_OUTPUT.PUT_LINE('CONSUME GRATER CONS: ' || G41_VALUES.CONS_NO ||
                           ' CONSUM_UNIT:' || V_CONSUMED_UNITS);
    --KVARH
    ELSIF LENGTH(TO_CHAR(V_CONSUMED_UNITS_KVARH)) >= 9 THEN
      DBMS_OUTPUT.PUT_LINE('CONSUME KVARH GRATER CONS: ' ||
                           G41_VALUES.CONS_NO || ' CONSUM_UNIT:' ||
                           V_CONSUMED_UNITS_KVARH);
    
      --PEAK1
    ELSIF LENGTH(TO_CHAR(V_CONSUMED_UNITS_PEAK)) >= 9 THEN
      DBMS_OUTPUT.PUT_LINE('CONSUME PK GRATER CONS: ' ||
                           G41_VALUES.CONS_NO || ' CONSUM_UNIT:' ||
                           V_CONSUMED_UNITS_PEAK);
    
    --PEAK 2
    ELSIF LENGTH(TO_CHAR(V_CONSUMED_UNITS_PEAK2)) >= 9 THEN
      DBMS_OUTPUT.PUT_LINE('CONSUME PK2 GRATER CONS: ' ||
                           G41_VALUES.CONS_NO || ' CONSUM_UNIT:' ||
                           V_CONSUMED_UNITS_PEAK2);
    
    --NIGHT
    ELSIF LENGTH(TO_CHAR(V_CONSUMED_UNITS_NIGHT)) >= 9 THEN
      DBMS_OUTPUT.PUT_LINE('CONSUME NIGHT GRATER CONS: ' ||
                           G41_VALUES.CONS_NO || ' CONSUM_UNIT:' ||
                           V_CONSUMED_UNITS_NIGHT);
    
    -- REST
    ELSIF LENGTH(TO_CHAR(V_CONSUMED_UNITS_REST)) >= 9 THEN
      DBMS_OUTPUT.PUT_LINE('CONSUME REST GRATER CONS: ' ||
                           G41_VALUES.CONS_NO || ' CONSUM_UNIT:' ||
                           V_CONSUMED_UNITS_REST);
    END IF;
  END LOOP; -- G41_VALUES LOOP END
  DBMS_OUTPUT.PUT_LINE('PROCESS COMPLEATED');
  
  EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('TECHNICAL ERROR:' || SQLERRM);
         DBMS_OUTPUT.PUT_LINE('ERROR LINE: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
/
