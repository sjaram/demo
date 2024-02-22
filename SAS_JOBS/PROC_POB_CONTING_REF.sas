
/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROC_POB_CONTING_REF		================================*/
/* CONTROL DE VERSIONES
/* 2020-05-12 ---- Original 
*/
/*==================================================================================================*/


		  /* poblamientos datos contactabilidad Contingencia REF (uso riesgo) */

/* FONOS CELULAR SOBRE tabla  VU */
PROC SQL;
   CREATE TABLE WORK.FONOS_MOVIL_NOMBRES AS 
   SELECT t1.CLIRUT AS RUT,
	      T2.Nombres AS NOMBRE , 
          T2.Paterno AS PATERNO, 
          T2.Materno AS MATERNO, 
          t1.AREA, 
          t1.TELEFONO,
		  T1.TIPO/*,
		  T3.VU_C*/
      FROM PUBLICIN.FONOS_MOVIL_FINAL t1
	  INNER join PUBLICIN.BASE_NOMBRES T2 on T1.CLIRUT =T2.rut
	  INNER JOIN  PUBLICIN.VU T3 on T1.CLIRUT =T3.rut
	   WHERE t1.TELEFONO NOT IN (SELECT fono FROM PUBLICIN.LNEGRO_CALL)/*SIEMPRE EXCLUIR SERNAC */
	   AND T3.VU_C not in ('a FALLECIDO',
'b CASTIGADO',
'c REPACTADO')
;QUIT;


 PROC SQL;
   CREATE TABLE POBLAMIENTO AS 
   SELECT t1.RUT, 
          t1.NOMBRE, 
          t1.PATERNO, 
          t1.MATERNO, 
          t2.COMUNA, 
          t2.REGION, 
          t2.COD_REGION, 
          CASE WHEN T3.RUT NOT IS MISSING THEN 'SI' ELSE 'NO' END AS LNEGRO_CAR,
		  CASE WHEN T4.RUT NOT IS MISSING THEN 'SI' ELSE 'NO' END AS LNEGRO_CALL, 
          t1.AREA, 
          t1.TELEFONO, 
          t1.TIPO
                FROM FONOS_MOVIL_NOMBRES T1 
				left join PUBLICIN.direcciones T2 on T1.rut =T2.rut 
				left join PUBLICIN.LNEGRO_CAR T3 on T1.rut =T3.rut
				left join PUBLICIN.LNEGRO_CALL T4 on T1.rut =T4.rut
			;QUIT;

DATA _null_;
exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechae",exec);
RUN;

PROC SQL;
CREATE TABLE PUBLICIN.CONTACT_REF AS
SELECT A.*,
CASE WHEN A.TELEFONO NOT IS MISSING THEN 1 ELSE 0 end as T_fono,
case when A.TELEFONO NOT IS MISSING and LNEGRO_CAR ='NO' and LNEGRO_CALL ='NO' then 'SI'  else 'no' END AS Tiene_contactabilidad,
&fechae as FEC_EJECUCION
FROM POBLAMIENTO A
WHERE  CALCULATED T_fono=1
AND CALCULATED Tiene_contactabilidad ='SI'
;QUIT;

