/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
%let libreria 	= RESULT;

/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	datePeriodoActual = input(put(intnx('month',today(),0,'end' ),yymmn6. ),$10.);
	Call symput("fechaeDVN", execDVN) ;
	Call symput("VdateHOY", datePeriodoActual);
RUN;
	%put &fechaeDVN;
	%put &VdateHOY;

/*==================================	COUNT DE LOS REGISTROS CARGADOS	============================*/
proc sql noprint;
	select SUM(input(CANTIDAD, best11.)) INTO :CANTIDAD
	from &libreria..GCO_CAMP_DVN_CR_&VdateHOY.;
quit;

%put &=CANTIDAD;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';
SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PATRICIO_QUINTERO';
SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_SEGMENTOS_1';
SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_SEGMENTOS_2';
SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_SEGMENTOS';

quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4; %put &=DEST_5;

FILENAME	output EMAIL
FROM 	= ("&DEST_1")
TO		= ("BR_Produccion@bancoripley.com")
CC 		= ("&DEST_1","&DEST_2","jarcep@bancoripley.com","&DEST_3","&DEST_4","&DEST_5")
SUBJECT	= "MAIL_AUTOM: Carga Campañas ambiente producción" CONTENT_TYPE="text/html"	
CT		= "text/html";
ODS LISTING CLOSE;
ODS HTML path	= "/sasdata/users94/user_bi" file = "GCO_CAMP_VENCIMIENTO_G02.lst" (URL=none) BODY=output STYLE=sasweb;
TITLE height=10pt J=left color=black;
TITLE color = black 
		"Estimados:";
TITLE2 height=10pt color=black	
		"	Favor considerar la ejecución del proceso carga de campañas con fecha de hoy &fechaeDVN";
TITLE3 height=10pt color=black 
		" 	Archivos depositados en ftpcamp";
TITLE4 height=10pt color=blue	
		"	Total de registros: &CANTIDAD. ";
TITLE5 height=10pt color=blue	
		" ";
TITLE6 height=10pt color=blue	
		" ";
TITLE7 height=10pt color=black	
		"Objetivo: Carga de campañas de renovación TC en canales presenciales (TV, PC y Movil)";


footnote "Gracias, Saludos, David Vásquez N.";

PROC PRINT DATA=&libreria..GCO_CAMP_DVN_CR_&VdateHOY NOOBS;
RUN;
FILENAME OUTBOX CLEAR;
ODS HTML CLOSE;
ODS LISTING;
