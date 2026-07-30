PROC SQL;
   CREATE TABLE RESULT.UNIV_TI_VIG AS
   SELECT t1.RUT,
          t1.CODENT,
          t1.CENTALTA,
          t1.CUENTA,
          t1.TIPO_TARJETA,
          t1.Tipo_Tarjeta_RSAT,
          t1.PAN,
          t1.PANANT,
          (MAX(t1.NUMPLASTICO)) FORMAT=13. AS MAX_of_NUMPLASTICO
      FROM RESULT.UNIVERSO_PANES t1
      WHERE t1.CALPART = 'TI' AND t1.T_CTTO_VIGENTE = 1 AND t1.T_TR_VIG=1
      GROUP BY t1.RUT,
          t1.CODENT,
          t1.CENTALTA,
          t1.CUENTA,
          t1.TIPO_TARJETA,
          t1.Tipo_Tarjeta_RSAT,
               t1.PAN,
               t1.PANANT
;QUIT;
PROC SQL;
SELECT COUNT(1) FROM RESULT.UNIVERSO_PANES
WHERE CALPART = 'TI' AND T_CTTO_VIGENTE = 1 AND T_TR_VIG=1;
QUIT;


PROC SQL;
   CREATE TABLE RESULT.UNIV_TI_VIG_ANT AS
   SELECT t1.RUT,
          t1.CODENT,
          t1.CENTALTA,
          t1.CUENTA,
               case when t1.TIPO_TARJETA in ('MASTERCARD DEBITO','MAESTRO DEBITO') then 'TD'
               when t1.TIPO_TARJETA in ('DEBITO CTACTE') then 'CC' else t1.TIPO_TARJETA end as TIPO_TARJETA,
		  t1.Tipo_Tarjeta_RSAT,
			   T2.Tipo_Tarjeta_RSAT AS Tipo_Tarjeta_RSAT_ANT,
               CASE WHEN T2.Tipo_Tarjeta in ('MASTERCARD DEBITO','MAESTRO DEBITO') then 'TD'
               when T2.Tipo_Tarjeta in ('DEBITO CTACTE') then 'CC' else T2.Tipo_Tarjeta end as TIPO_ANT,
               t1.PAN,
               t1.PANANT,
          T1.MAX_of_NUMPLASTICO,
               CASE
                    WHEN T1.Tipo_Tarjeta_RSAT=T2.Tipo_Tarjeta_RSAT THEN 0
                    WHEN T1.PANANT IS NULL THEN 0
                    ELSE 1 END AS CDTT
      FROM RESULT.UNIV_TI_VIG t1 LEFT JOIN RESULT.UNIVERSO_PANES T2
         ON T1.PANANT=T2.PAN AND T1.CUENTA=T2.CUENTA
         ;QUIT;
