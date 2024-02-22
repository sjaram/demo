/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	UNIVERSO_PANES_CIERRE			================================*/
/* CONTROL DE VERSIONES
/* 
2022-11-24 -- V4 -- Ale M. --  
					-- Se cambia el filtro de tipo_tr a tipo_tarjeta.
2021-01-21 -- V3 -- Sergio J. --  
					-- Se dejan solo los cierres.
/* 2020-01-20 -- V2 -- Ximena Z.--
                    -- Se corrige la exclusión de CUENTA_VISTA y de MASTERCARD_DEBIT
/* 2020-12-02 -- V1 -- Nicole L. --  
					-- Se agrega 'MASTERCARD_DEBIT' al código
/* 2020-09-24 ---- Original 
*/
/*==================================================================================================*/

/*	DECLARACIÓN VARIABLE TIEMPO Y LIBRER		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/
%let libreria=RESULT;

/*==================================================================================================*/
/*	INICIO CÓDIGO DEL PROGRAMA	PM	*/
LIBNAME R_BOPERS ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME R_get ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017';


DATA _null_;
periodo = input(put(intnx('month',today(),-1,'end'),yymmn6. ),$10.);
corte = put(intnx('month',today(),0,'begin'),yymmdd10.);

Call symput("periodo", periodo);
Call symput("corte", corte);

RUN;

%put &periodo;
%put &corte;

PROC SQL;
CREATE TABLE &libreria..UNIVERSO_PANES_&PERIODO. AS 
SELECT t1.*
FROM &libreria..UNIVERSO_PANES t1
WHERE t1.FECALTA_TR < "&CORTE." AND TIPO_TARJETA IN ('TR','TAM')
;QUIT;


PROC SQL;
CREATE TABLE &libreria..UNIVERSO_PANES_TD_&PERIODO AS 
SELECT t1.*
FROM &libreria..UNIVERSO_PANES t1
WHERE t1.FECALTA_TR < "&CORTE." AND TIPO_TARJETA NOT IN ('TR','TAM')
;QUIT;

/*	FIN CÓDIGO DEL PROGRAMA	PM	*/
/*==================================================================================================*/


/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */


/*	Fecha ejecución del proceso	*/
data _null_;
execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechaeDVN", execDVN) ;
RUN;
%put &fechaeDVN;/*fecha ejecucion proceso */

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */

proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';

SELECT EMAIL into :DEST_2 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_CLIENTES';

SELECT EMAIL into :DEST_3 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';

SELECT EMAIL into :DEST_4
  FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_GOBIERNO_DAT_1';
quit;



%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;


data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
/*TO = ("&DEST_1")*/
TO = ("&DEST_1","&DEST_2","&DEST_3","&DEST_4")
SUBJECT="MAIL_AUTOM: UNIVESO_PANES_CIERRE - %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso UNIVERSO_PANES_CIERRE, ejecutado con fecha: &fechaeDVN";  
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 04'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
