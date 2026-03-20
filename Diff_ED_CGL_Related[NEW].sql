SELECT *
FROM   PRT_135_EDUTY M
WHERE  M.MODULE = 'HT'
AND    M.CIRCLE_CODE = '&CIRCLE'
AND    M.DIVISION_CODE = '&DIVISION'
AND    M.ED_MONTH = '&MON'
AND    M.ED_YEAR = '&year';

--Get Company Code:
select c.company_code, c.company_name from company_master c where c.company_shortname like '%&COM%';  


DECLARE
  V_BUNIT          NUMBER;
  V_BEDUTY         NUMBER;
  V_EUNITS         NUMBER;
  V_EEDAMT         NUMBER;
  V_ASS_UNIT       NUMBER;
  V_TOTAL_ASS_UNIT NUMBER;
  V_ED_AMT         NUMBER;
  V_TOTAL_ED_AMT   NUMBER;
BEGIN

  FOR C1 IN (SELECT D.CIRCLE_CODE, D.DIVISION_CODE
               FROM DIVISION_MASTER D
              WHERE D.COMPANY_CODE = '&company'
                AND D.CIRCLE_CODE = '&CIRCLE'
                AND D.DIVISION_CODE = '&DIVISION'
                AND D.TO_DT IS NULL) LOOP
    BEGIN
      SELECT NVL(SUM(M.UNITS_BILLED), 0) UNIT, NVL(SUM(M.EDUTY), 0) EDUTY
        INTO V_BUNIT, V_BEDUTY
        FROM BRIEF_ASS_CGL M
       WHERE M.B_MODULE = 'HT'
         AND M.P_MONTH = '&MON'
         AND M.P_YEAR = '&year'
         AND M.COMPANY_CODE = '&company'
         AND M.CIRCLE_CODE = C1.CIRCLE_CODE
         AND M.DIVISION_CODE = C1.DIVISION_CODE;
    EXCEPTION
      WHEN OTHERS THEN
        V_BUNIT  := 0;
        V_BEDUTY := 0;
    END;
  
    BEGIN
    
      SELECT SUM(P.TOTAL_UNIT) V_UNITS, SUM(P.TOTAL_ED_AMT) V_EDAMT
        INTO V_EUNITS, V_EEDAMT
        FROM PRT_135_EDUTY P
       WHERE P.MODULE = 'HT'
         AND P.COMPANY_CODE = '&company'
         AND P.ED_MONTH = '&MON'
         AND P.ED_YEAR = '&year'
         AND P.CIRCLE_CODE = C1.CIRCLE_CODE
         AND P.DIVISION_CODE = C1.DIVISION_CODE;
    
    EXCEPTION
      WHEN OTHERS THEN
        V_EUNITS := 0;
        V_EEDAMT := 0;
    END;
  
    IF V_BUNIT <> V_EUNITS THEN
      
        UPDATE PRT_135_EDUTY S
           SET S.ASSESNENT_UNIT = (S.ASSESNENT_UNIT + (V_BUNIT - V_EUNITS)),
               
               S.TOTAL_UNIT    = (S.TOTAL_UNIT + (V_BUNIT - V_EUNITS))   
         WHERE S.MODULE = 'HT'
           AND S.COMPANY_CODE = '&company'
           AND S.ED_MONTH = '&MON'
           AND S.ED_YEAR = '&year'
           AND S.CIRCLE_CODE = C1.CIRCLE_CODE
           AND S.DIVISION_CODE = C1.DIVISION_CODE
           AND S.ED_PERSENTAGE = '15';
  
      END IF;

    IF V_BEDUTY <> V_EEDAMT THEN
     
        UPDATE PRT_135_EDUTY S
           SET S.EDUTY_AMT = (S.EDUTY_AMT + (V_BEDUTY - V_EEDAMT)),
              
               S.TOTAL_ED_AMT =  (S.EDUTY_AMT + (V_BEDUTY - V_EEDAMT))
              
         WHERE S.MODULE = 'HT'
           AND S.COMPANY_CODE = '&company'
           AND S.ED_MONTH = '&MON'
           AND S.ED_YEAR = '&year'
           AND S.CIRCLE_CODE = C1.CIRCLE_CODE
           AND S.DIVISION_CODE = C1.DIVISION_CODE
           AND S.ED_PERSENTAGE = '15';
    END IF; 
  END LOOP;
END;
