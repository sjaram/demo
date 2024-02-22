/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	CONTACT_QUIERO_SER_CLIENTE_NEW	================================*/
/* CONTROL DE VERSIONES
/* 2023-02-21 -- V3 -- Andrea S. -- Se agrega filtro de correos por inicio/dominio y se elimina la generación de bases por período para email y fonos (tablas finales son acumulativas)
									Se eliminan tablas QSC_HB_E_NEW2 y QSC_HB_F_NEW2 para no generar duplicidad de información.
/* 2022-04-05 -- V2 -- Esteban P. -- Se actualizan los correos: Se reemplaza a PIA_OLAVARRIA por PM_CONTACTABILIDAD y se elimina a vmartinezf.
/* 2022-01-20 -- V1 -- PIA OLAVARRIA. --  
					-- Versión Original
/* INFORMACIÓN:
	Programa que toma los datos desde "Quiero ser Cliente del nuevo HB"

	(IN) Tablas requeridas o conexiones a BD:
	- PUBLICIN.XXXX
	- RESULT.XXXX
	- DVASQUEZ.XXXX

	(OUT) Tablas de Salida o resultado:
	- &libreria..QSC_HB_E_NEW_&VdatePeriodo
	- &libreria..QSC_F_NEW_&VdatePeriodo
	- &libreria..QSC_HB_E_NEW
	- &libreria..QSC_HB_F_NEW
	
*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			
%let libreria=PUBLICIN; */

/*	VARIABLE LIBRERÍA	*/		
%let libreria=PUBLICIN; 

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/

PROC SQL NOERRORSTOP ;
CONNECT TO ORACLE (USER='PMUNOZC' PASSWORD='pmun2102' path ='REPORITF.WORLD' );
create table cuentas as
select *
from connection to ORACLE(
select
*
from SFADMI_BCO_DAT_CON_CO
) A
;QUIT;



/**********************************************************************************************/
/*******	UNA VEZ EXTRAIDA LA DATA DE LA TABLA, EJECUTAR ESTE PROCESO 				*******/ 
/******* 	PARA ACTUALIZAR TABLA 		 				*******/
/**********************************************************************************************/

DATA _null_;
/* Fecha Periodo */
datePeriodo	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
Call symput("VdatePeriodo", datePeriodo);

RUN;
%put &VdatePeriodo;

/*TOMO FONO SIN EL 9 INICIAL, FECHA A NUMÉRICA Y EL EMAIL EN UPCASE*/
PROC SQL;
   CREATE TABLE QSC_HB_A_new AS 
   SELECT RUT_CLIENTE AS RUT,
		  year(datepart(FCH_UPD))*10000+month(datepart(FCH_UPD))*100+day(datepart(FCH_UPD)) as FECHA_ACT,
		  FCH_UPD AS FECHA_ORIGINAL,
		  INPUT(NUM_TELEFONO, BEST.) AS TELEFONO,
          upcase(mail_CLIENTE) 	AS EMAIL,
		  scan(mail_CLIENTE,1,"@") as inicio_correo,
		  scan(mail_CLIENTE,2,"@") as dominio
      FROM work.CUENTAS  					/*ACTUALIZAR NOMBRE AQUI Y EN EL WORK*/

;QUIT;

/*  FILTROS A EMAIL */
PROC SQL;
CREATE TABLE QSC_HB_EMAIL AS 
   SELECT 	RUT,
		  	Email,
			TELEFONO,
          	FECHA_ACT,
			FECHA_ORIGINAL
      FROM 	QSC_HB_A_new
	Where 	RUT is not missing
			AND dominio not in (select dominio from RESULT.DOMINIO_INCORRECTOS_UNIF) 
		OR inicio_correo not in (select inicio_correo from RESULT.INICIO_CORREO_INCORRECTOS_UNIF)
	AND email not in (select email from POLAVARR.CORREOS_FAKE_V2)
;
QUIT;

proc sql;
	create table QSC_HB_E_NEW as
		select *
			from QSC_HB_EMAIL
				where email 
					not LIKE ('.-%') AND email not LIKE ('%.')
					AND email not LIKE ('-%')				AND email not LIKE	('%.@%')
					AND email not CONTAINS	('(')			AND email not CONTAINS 	(')')
					AND email not CONTAINS	('/')			AND email not CONTAINS	('?')
					AND email <>'@'							AND email <>'0' 
					AND email CONTAINS 	('@')
;quit;


/*Para obtener el mejor Email*/
/*AGREGO SECUENCIA Y ORIGEN, ADEMÁS DE RANGO DE RUTS VÁLIDOS*/
proc sql;
create table QSC_HB_E as
SELECT	RUT, 
        upcase(Email) as EMAIL, 
        FECHA_ACT,
		13 AS SEQUENCIA,
		'QSC_HB_NEW' AS ORIGEN
  	  FROM QSC_HB_E_NEW
	WHERE RUT > 100 AND RUT < 99999999 AND RUT IS NOT MISSING
;quit;


proc sql;
create table QSC_HB_E_MAX AS
SELECT	DISTINCT RUT, 
        EMAIL, 
        MAX(FECHA_ACT) AS FECHA_ACT,
        SEQUENCIA,
        ORIGEN
    FROM QSC_HB_E 
GROUP BY RUT
;quit;


proc sql;
create table QSC_HB_E_UNI AS
SELECT	DISTINCT T2.RUT, 
        T1.EMAIL, 
		T2.FECHA_ACT,
        T2.SEQUENCIA,
        T2.ORIGEN
    FROM QSC_HB_E T1 INNER JOIN QSC_HB_E_MAX t2
	ON (T1.RUT = T2.RUT AND T1.FECHA_ACT = T2.FECHA_ACT)
group by T2.RUT
order by 1
;quit;

/*	ACA QUDARÁN TODOS LOS EMAIL HASTA EL MINUTO	*/
proc sort data=QSC_HB_E_UNI out=&libreria..QSC_HB_E_NEW nodupkeys dupout=WORK.duplicados_RUT;			
by rut;
run; 


PROC SQL;
CREATE INDEX rut ON &libreria..QSC_HB_E_NEW (RUT);
QUIT; 




/*  CONVIERTO A FORMATO FECHA HOMOLOGADA Y FILTROS TELÉFONOS  */
PROC SQL;
  /*CREATE TABLE &libreria..QSC_HB_F_NEW_&VdatePeriodo AS  */
  CREATE TABLE QSC_HB_FONO AS  
   SELECT 	RUT,
			TELEFONO,
          	DHMS((MDY(INPUT(SUBSTR(PUT(FECHA_ACT,BEST8.),5,2),BEST4.),
                  INPUT(SUBSTR(PUT(FECHA_ACT,BEST8.),7,2),BEST4.),
                  INPUT(SUBSTR(PUT(FECHA_ACT,BEST8.),1,4),BEST4.))),0,0,0) FORMAT=datetime20. AS FECHA_ACTUALIZACION,
			FECHA_ORIGINAL
      FROM 	QSC_HB_A_new;
QUIT;

/*Para obtener el mejor FONO*/
/*AGREGO SECUENCIA Y ORIGEN, ADEMÁS DE RANGO DE RUTS VÁLIDOS*/
proc sql;
create table QSC_HB_F as
SELECT	RUT, 
        TELEFONO, 
		FECHA_ORIGINAL,
		0 AS SEQUENCIA, /* ES TOMADA COMO NOTA O SCORE EN LOS FONOS */
		'QSC_HB_NEW' AS ORIGEN
  	FROM QSC_HB_FONO 	
	WHERE RUT > 100 AND RUT < 99999999
			AND RUT is not missing AND 
			TELEFONO BETWEEN 30000000 AND 99999999
			and TELEFONO not in (99999999,88888888,77777777,66666666,55555555,44444444,
									33333333,22222222,11111111,00000000,98989898,89898989,
									88889999,99998888)
;quit;

proc sql;
create table QSC_HB_F_MAX AS
SELECT	DISTINCT RUT, 
        TELEFONO, 
		MAX(FECHA_ORIGINAL) AS FECHA_ORIGINAL,
        SEQUENCIA,
        ORIGEN
    FROM QSC_HB_F
GROUP BY RUT
;quit;


proc sql;
create table QSC_HB_F_UNI AS
SELECT	DISTINCT T2.RUT, 
        t1.TELEFONO, 
        T1.FECHA_ORIGINAL as FECHA,
        T2.SEQUENCIA AS NOTA,
        T2.ORIGEN AS FUENTE
    FROM QSC_HB_F T1 INNER JOIN QSC_HB_F_MAX t2
	ON (T1.RUT = T2.RUT AND T1.FECHA_ORIGINAL = T2.FECHA_ORIGINAL)
	ORDER BY T1.FECHA_ORIGINAL 
;quit;


/*	ACA QUDARÁN TODOS LOS FONOS HASTA EL MINUTO	*/
proc sort data=QSC_HB_F_UNI out=&libreria..QSC_HB_F_NEW nodupkeys dupout=WORK.duplicados_RUT;			/* cambiado desde result */
by rut;
run;

PROC SQL;
CREATE INDEX rut ON &libreria..QSC_HB_F_NEW (RUT);
QUIT;


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
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CONTACTABILIDAD';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_3")
CC = ("&DEST_1", "&DEST_2")
SUBJECT = ("MAIL_AUTOM: Proceso CONTACT_QUIERO_SER_CLIENTE");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso CONTACT_QSC_NEW, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put ; 
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 03'; 
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
