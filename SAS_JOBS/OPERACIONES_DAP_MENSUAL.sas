/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	OPERACIONES_DAP_MENSUAL			 ===============================*/
/* CONTROL DE VERSIONES
/* 2023-05-24 -- v02 -- David V.	-- Se agrega export to AWS.
/* 2020-10-09 -- v01 -- Karina M. 	-- Versión Original 
									-- Comentarios EDYP (Al inicio y al final)
									-- Envío de email notificando ejecución
/* INFORMACIÓN:
Tablas requeridas o conexiones a BD
	- BD GESTIÓN

Tabla de Salida
	- PUBLICIN.OPERACIONES_DAP_&periodo
*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

/*===============================================================================================================================================================*/
/*=== Extrae OPERACIONES  DAP MES EN CURSO  ==============================================================================================================================================*/
/*===============================================================================================================================================================*/


/*===============================================================================================================================================================*/
/*=== MACRO FECHAS MES ==============================================================================================================================================*/
/*===============================================================================================================================================================*/


data _null_;
date0 = input(put(intnx('month',today(),-1,'begin'),yymmn6. ),$10.);
date1 = input(put(intnx('month',today(),-1,'end'),YYMMDDN8. ),$10.);
exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);

Call symput("fechae", exec) ;
Call symput("periodo", date0);
Call symput("periodox", date1);
call symput('fechai',"TO_DATE('"||input(put(intnx('month',today(),-1,'begin'),DDMMYYD10. ),$10.)||"','DD-MM-YYYY')");
call symput('fechap',"TO_DATE('"||input(put(intnx('month',today(),-1,'end'),DDMMYYD10. ),$10.)||"','DD-MM-YYYY')");;RUN;

%put &periodo; /*periodo actual */
%put &fechai; /*fecha interes-dia anterior*/
%put &fechap;/*fecha proceso-dia actual*/
%put &periodox;/*periodo-dia actual*/
%put &fechae;/*fecha ejecucion proceso */

%let mz_connect_BANCO=CONNECT TO ORACLE as BANCO(USER='RIPLEYC' PASSWORD='ri99pley'
PATH="  (DESCRIPTION = 
    (ADDRESS_LIST = 
      (ADDRESS = 
        (PROTOCOL = TCP)
        (Host = 192.168.10.31)
        (Port = 1521)
      )
    )
    (CONNECT_DATA = 
      (SID = ripleyc)
    )
  )
");


proc sql;
&mz_connect_BANCO;
create table PUBLICIN.OPERACIONES_DAP_&periodo as
SELECT *,INPUT((SUBSTR(cli_identifica,1,(LENGTH(cli_identifica)-1))),BEST.) AS RUT,
INPUT(SUBSTR(put(datepart(PDA_FECHAPER),yymmddn8.),1,8),best.) as Fecha_Apertura,
INPUT(SUBSTR(put(datepart(PDA_FECHAPER),yymmddn8.),1,6),best.) as Periodo_Apertura
from  connection to BANCO(
select PDA_CUENTA, PDA_FECHAPER, PDA_MONEDA, PDA_STATUS, PDA_PLAZO, PDA_CAPITAL,PDA_CODSUC   codigo_sucursal,
SOL_CHANNEL, SOL_OPERADOR, SOL_NUMERO,cli_identifica
 from tpla_cuenta, /*MAESTRA DAP*/
TSOL_SOLICITUD,/*MAESTRA SOLICITUDES DAP*/
tcli_persona  /*MAESTRA DE CLIENTES BANCO*/
where pda_clientep  = cli_codigo
and  PDA_CUENTA=SOL_CUENTA 
and CLI_TIPOPER=1
and trunc(pda_fechaper) between &fechai  AND &fechap
) as X /*AND SOL_CHANNEL=10 o PDA_CODSUC =70  es canal internet*/
order by PDA_FECHAPER
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_ppff_operaciones_dap,raw,sasdata,-1);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_ppff_operaciones_dap,PUBLICIN.OPERACIONES_DAP_&periodo,raw,sasdata,-1);

/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	FECHA PROCESO Y ENVÍO DE EMAIL =============================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';
SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'KARINA_MARTINEZ';
SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';
quit;

%put &=EDP_BI; %put &=DEST_1; %put &=DEST_2; %put &=DEST_3;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_2")
CC = ("&DEST_1", "&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso OPERACIONES DAP CIERRE MENSUAL");
FILE OUTBOX;
 	PUT "Estimados:";
 	PUT "  Proceso OPERACIONES DAP CIERRE MENSUAL, ejecutado con fecha: &fechaeDVN";  
    PUT;
    PUT;
    PUT 'Proceso Vers. 02';
    PUT;
    PUT;
    PUT 'Atte.';
    PUT 'Equipo Arquitectura de Datos y Automatización BI';
    PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
