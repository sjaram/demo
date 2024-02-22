/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	VENTAS_MES_PWA_CONSUMO			 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-07-04 -- V04 -- David V.	-- Actualización password nuevo backend pwa + correo area digital bi
/* 2022-03-31 -- V03 -- Esteban P.	-- Se actualizan los correos: Se cambia a Constanza Celery por "PM_BI_DIGITAL".
/* 2021-08-10 -- V02 -- David V. 	-- */
/* 2021-04-01 -- V01 -- Edmundo p.	-- */

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

options validvarname=any;

	LIBNAME libbehb ODBC  DATASRC="BR-BACKENDHB"  SCHEMA=dbo  USER="ripley-bi"  
	PASSWORD="biripley00"; 

		DATA _null_;
	    dated1 = input(put(intnx('month',today(),0,'begin'),date9. ),$10.) ;	
		Call symput("fechad1", dated1);
		RUN;
	%put &fechad1;

PROC SQL;
   CREATE TABLE pwa_consumo AS 

 select  INPUT((SUBSTR(rut,1,(LENGTH(rut)-1))),BEST.)as rut,
        INPUT(t1.Montoliquido,best.) as monto,
        'consumo' as  PRODUCTO,
		t1.NumeroOperacion,
		CASE WHEN UPCASE(t1.DISPOSITIVO) LIKE'%APP%' then 'APP'
		     WHEN UPCASE(t1.DISPOSITIVO) is null then 'APP'

else upcase(t1.DISPOSITIVO) end as  canal,
datepart(FECHACURSE) FORMAT=date9. AS FECHA,
*
		
FROM libbehb.PersonalLoanView t1
WHERE datepart(FechaCurse)>="&fechad1"D 

;
QUIT;

proc export data=pwa_consumo outfile="/sasdata/users94/user_bi/TRASPASO_DOCS/pwa_consumo.csv" DBMS=CSV REPLACE;
RUN;

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
SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_DIGITAL';
SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PPFF_PM_CONSUMO';
SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SUBG_BI';
SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
SELECT EMAIL into :DEST_7 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JUAN_PABLO_DONOSO';
SELECT EMAIL into :DEST_8 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JOSE_VALDEBENITO';

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;	
%put &=DEST_6;	%put &=DEST_7;	%put &=DEST_8;

/*	SEGUNDO MAIL PARA CALL INTERNO	*/
data _null_;
FILENAME OUTBOX EMAIL
FROM 	= ("&EDP_BI")
TO 		= ("&DEST_3","&DEST_4","&DEST_7","&DEST_8","&DEST_5")
CC 		= ("&DEST_1","&DEST_2","&DEST_6")
ATTACH	= "/sasdata/users94/user_bi/TRASPASO_DOCS/pwa_consumo.csv"
SUBJECT = ("MAIL_AUTOM: Proceso VENTAS_MES_PWA_CONSUMO");
FILE OUTBOX;
 PUT "Estimados:";
 put "        Proceso VENTAS_MES_PWA_CONSUMO, ejecutado con fecha: &fechaeDVN";   
 PUT ;
 PUT '        Se adjunta archivo: PWA_CONSUMO.csv';
 PUT ;
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

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
