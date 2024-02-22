/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	CHEK_DUPLICADOS				================================*/
/* CONTROL DE VERSIONES
/* 2022-10-28 -- V04	-- Esteban P.   -- Nueva sentencia include para borrar y exportar a RAW.
/* 2022-08-29 -- V03	-- Sergio J. 	-- Se añade sentencia include para borrar y exportar a RAW
/* 2022-07-11 -- V02	-- David V. 	-- Ajustes mínimos para nuevo flujo "Oracloud AWS Athena".
/* 2021-05-04 -- V01 	-- Mario .G 	-- Nueva Versión Automática Equipo Datos y Procesos BI
*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio = %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*CONEXION A ORACLECLOUD*/
LIBNAME ORACLOUD ORACLE sql_functions=all  READBUFF=1000  INSERTBUFF=1000  PATH="REPORTSAS.WORLD"  SCHEMA=SAS_ADM authdomain=DBOracleCloud_Auth;

PROC SQL noprint;
DROP TABLE ORACLOUD.COMMERCES_CHEK_DUPLICADOS_2
;QUIT;

PROC SQL;
CREATE TABLE ORACLOUD.COMMERCES_CHEK_DUPLICADOS_2 AS 
SELECT 
	A.* 
FROM 
	ORACLOUD.CHEK_COMMERCES A
LEFT JOIN 
	ORACLOUD.COMMERCES_CHEK_DUPLICADOS B 
ON A.PRIMARYACCOUNTID = B.PRIMARYACCOUNTID 
;QUIT;

PROC SQL noprint;
create table work.CHEK_COMMERCES_DUPLICADOS as
select * from ORACLOUD.COMMERCES_CHEK_DUPLICADOS_2
;QUIT;

%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(chek_commerces_duplicados,raw,oracloud,0);


%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(chek_commerces_duplicados,work.chek_commerces_duplicados,raw,oracloud,0);




/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*=========================================================================================*/
/*=======================       FECHA PROCESO Y ENVÍO DE EMAIL      =======================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_DIGITAL';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_CHEK_1';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_CHEK_2';

quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;
%put &=DEST_6;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4","&DEST_5", "&DEST_6")
CC = ("&DEST_1","&DEST_2", "&DEST_3")
SUBJECT = ("MAIL_AUTOM: PROCESO CHEK_DUPLICADOS");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "    	Proceso CHEK_DUPLICADOS, ejecutado con fecha: &fechaeDVN";  
 PUT '		Tabla resultante en Athena: CHEK_COMMERCES_DUPLICADOS';
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 04'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

