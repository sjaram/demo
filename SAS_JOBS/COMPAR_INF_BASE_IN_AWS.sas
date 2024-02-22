/*==================================================================================================*/
/*==================================	EQUIPO ARQ.DATOS Y AUTOM.		============================*/
/*==================================	COMPAR_INF_BASE_IN_AWS			============================*/
/* CONTROL DE VERSIONES
/* 2022-05-17 ---- V01 -- David V. -- Original
 */

/*==================================================================================================*/
/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

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
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_PPFF';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_3';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SUBG_BI';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;
%put &=DEST_5;

/*	MAIL */
data _null_;
FILENAME OUTBOX EMAIL
FROM 	= ("&EDP_BI")
TO 		= ("mjimenezc@bancoripley.com","oleiva@bancoripley.com","yriverat@bancoripley.com")
CC 		= ("&DEST_1","&DEST_2","&DEST_3","&DEST_4","&DEST_5")
ATTACH	= "/sasdata/users94/user_bi/IN_ARCHIVO_DOTACION/output/BASE_IN_AWS.txt"
SUBJECT = ("MAIL_AUTOM: Proceso COMPAR_INF_BASE_IN_AWS");
	FILE OUTBOX;
	PUT "Estimados:";
	put "		Proceso COMPAR_INF_BASE_IN_AWS, ejecutado con fecha: &fechaeDVN";
	put "		Se adjunta archivo: BASE_IN_AWS.txt";
	PUT;
	PUT;
	put 'Proceso Vers. 01';
	PUT;
	PUT;
	PUT 'Atte.';
	Put 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;
FILENAME OUTBOX CLEAR;


/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 
