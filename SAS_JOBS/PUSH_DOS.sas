/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROGRAMA_TIPO_EDYP_BI		================================*/
/* CONTROL DE VERSIONES
/* 2020-10-20 -- V1 -- David V. --  
					-- Versión Original
/* INFORMACIÓN:
	Programa tipo con comentarios e instrucciones básicas para ser estandarizadas al equipo.

	(IN) Tablas requeridas o conexiones a BD:
	- PUBLICIN.LNEGRO_CAR
	- PUBLICIN.NOTPUSH

	(OUT) Tablas de Salida o resultado:
	- PUBLICIN.NOTPUSH
*/


/*TIPO_INHIBICION
CALL	    CALL_CENTER liberado
COMPLIANCE	RIESGO
DIRECTORES	DIRECTORES
FALLECIDO	RIESGO
FALLECIDOS	AURIS
FALLECIDOS	RIESGO
INTER    	AURIS
INTER   	OFICIO
LISTA_NEGRA_CAR	ANTIGUOS
LISTA_NEGRA_CAR	AURIS
LISTA_NEGRA_CAR	BANCO
LISTA_NEGRA_CAR	CALL_CENTER
LISTA_NEGRA_CAR	CANON
LISTA_NEGRA_CAR	CORREO
LISTA_NEGRA_CAR	OFICIO
LISTA_NEGRA_CAR	RI_OP
LISTA_NEGRA_CAR	SERNAC

LRI	RIESGO
PEP	RIESGO
SERNAC	OFICIO
SERNAC	RI_OP
SERNAC	SERNAC
SERNAC_BCO	SERNAC_BCO
SIR	RIESGO
TRIBUNAL	AURIS*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*INICIO DE LOS NUEVOS NOTPUSH 
3.039.225 ln car al 0107*/
/*2.932.960  2932,960nuevos NOTCALL */
DATA _null_;
date = put(today(),date10.);
Call symput("fecha", date);
RUN;
%put &fecha;PROC SQL;
	CREATE TABLE WORK.CAR AS
	SELECT RUT,	
TIPO_INHIBICION,
CANAL_RECLAMO,	
			FECHA_INGRESO,
			"&fecha"d FORMAT = DATE10. AS FECHA
	FROM PUBLICIN.LNEGRO_CAR
	WHERE TIPO_INHIBICION IN ('COMPLIANCE','LRI','PEP','SIR','TRIBUNAL', 'FALLECIDOS', 'FALLECIDO')
	and  CANAL_RECLAMO IN ('RIESGO', 'RI_OP')
and RUT NOT IN (SELECT RUT FROM PUBLICIN.NOTPUSH)
;QUIT;
 PROC SQL;
 CREATE TABLE WORK.NOTPUSH AS 
 SELECT T1.RUT, T1.TIPO_INHIBICION, T1.CANAL_RECLAMO,T1.FECHA_INGRESO, T1.FECHA
 FROM PUBLICIN.NOTPUSH T1
 ;QUIT;
/*2.932.960  2932,960nuevos NOTCALL 2933 132 */
PROC SQL;
INSERT INTO WORK.NOTPUSH
SELECT *
	FROM WORK.CAR
;QUIT;


PROC SQL;/*2933132*/
CREATE TABLE WORK.NOTPUSH2 AS
	SELECT DISTINCT RUT,
	TIPO_INHIBICION,
CANAL_RECLAMO,
	       MIN(FECHA_INGRESO) FORMAT=DATE9. AS FECHA_INGRESO,
		   FECHA
	FROM WORK.NOTPUSH/*PUBLICIN.NOTPUSH*/
	WHERE RUT NOT = .
	GROUP BY RUT
	ORDER BY FECHA

;QUIT;

;options cmplib=sbarrera.funcs;

proc sql;
create table NOTPUSH_salida as 
select CATS(put(RUT,commax10.),'-',SB_DV(RUT)) AS RUTPUSH,
RUT,
TIPO_INHIBICION,
CANAL_RECLAMO,
FECHA_INGRESO,
FECHA
from WORK.NOTPUSH2
WHERE RUT IS NOT MISSING 


;quit;

/*NO REPETIR MISMO NUMERO/RUT CON DIF TIPO_INHIBICION ? (CAR/BANCO) 2.929.384  2.929.546 3.062.516 

*/
PROC SQL;
	create table RESULT.NOTPUSH AS
	SELECT distinct RUTPUSH,
	RUT,
TIPO_INHIBICION,
CANAL_RECLAMO,
FECHA_INGRESO,
FECHA
	FROM WORK.NOTPUSH_salida
;QUIT;



/*-----------  EXPORTAR ARCHIVO -----------------*/

/* archivos a revisar */
proc export data=RESULT.NOTPUSH
/* OUTFILE="/sasdata/users94/ougarte/temp/NOTPUSH.CSV"*/
  OUTFILE="/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SERNAC_PARTE_3/NOTPUSH2.CSV"
 dbms=dlm REPLACE;
 delimiter=',';
 PUTNAMES=yes;
RUN;

PROC SQL;
	CREATE TABLE publicin.NOTPUSH AS
	SELECT *
	FROM RESULT.NOTPUSH
	order by fecha_ingreso desc
;QUIT;

/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

SELECT EMAIL into :DEST_3
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'XXXXXXXXXXX';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1", "&DEST_2")
SUBJECT = ("MAIL_AUTOM - TEST: Proceso PUSH");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso PUSH, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put ; 
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 01'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
