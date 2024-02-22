/*==================================================================================================*/
/*==================================	EQUIPO ARQ.DATOS Y AUTOM.		============================*/
/*==================================	SPOS_AUTOM						============================*/
/* CONTROL DE VERSIONES
/* 2023-02-13 -- V02	-- Sergio J. -- Se quita exportación a AWS, se obtendrá la data directamente de CC
para job refactorizado en Redshift. 
/* 2023-01-26 -- V01	-- David V. 	-- Se quita SPOS_CREDITO_Periodo de Publicin + versionamiento. 
/* 0000-00-00 -- V00 	-- Original
*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*==================================================================================================*/

DATA _null_;
	datex = put(intnx('month',today(),-1,'end'),yymmn6.);
	fecha_sn = compress(input(put(today(),yymmdd10.),$10.),"-","");
	exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	fecha = tranwrd(datex, "-", "");
	ARCHIVO=COMPRESS(CAT('/sasdata/users94/user_bi/TRASPASO_DOCS/','SPOS_CREDITO_',datex,'.txt'));
	Call symput("fechax", datex);
	Call symput("fechae",exec);
	call symput("fecha_sn",fecha_sn);
	call symput("ARCHIVO",ARCHIVO);

	/*date9i = put(intnx('month',today(),-1,'begin'),date9.);*/
RUN;

%put &fechae;
%put &fechax;
%put &fecha_sn;
%LET ARCHIVO="&ARCHIVO";
%put &ARCHIVO;
filename server ftp "SPOS_CREDITO_&fechax..txt" CD='/'
	HOST='192.168.82.171' user='118732448' pass='118732448' PORT=21;

data _null_;
	infile server;
	file &ARCHIVO;
	input;
	put _infile_;
run;

DATA work.SPOS_CREDITO_&fechax;
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile &ARCHIVO delimiter=';' MISSOVER DSD lrecl=32767 firstobs=2 ;     /*modificar ftp de origen*/
	LENGTH
		PERIODO            8
		RUT_CLIENTE        8
		TIPO_PRODUCTO    $ 16
		COD_FACTURA        8
		TIPO_FACTURA     $ 30
		COD_COMPRA         8
		TIPO_COMPRA      $ 25
		COD_COMERCIO     $ 15
		COMERCIO         $ 1
		MONTO              8
		FECHA              8
		CUOTAS             8
		INTERES            8
		MARGEN_FINANCIERO   8
		VENTA_FINANCIADA   8
		COD_PAIS           8
		COD_PRODUCTO       8;
	FORMAT
		PERIODO          BEST6.
		RUT_CLIENTE      BEST8.
		TIPO_PRODUCTO    $CHAR16.
		COD_FACTURA      BEST4.
		TIPO_FACTURA     $CHAR30.
		COD_COMPRA       BEST2.
		TIPO_COMPRA      $CHAR25.
		COD_COMERCIO     $CHAR15.
		COMERCIO         $CHAR1.
		MONTO            BEST7.
		FECHA            YYMMDD10.
		CUOTAS           BEST2.
		INTERES          BEST8.
		MARGEN_FINANCIERO BEST7.
		VENTA_FINANCIADA BEST7.
		COD_PAIS         BEST3.
		COD_PRODUCTO     BEST1.;
	INFORMAT
		PERIODO          BEST6.
		RUT_CLIENTE      BEST8.
		TIPO_PRODUCTO    $CHAR16.
		COD_FACTURA      BEST4.
		TIPO_FACTURA     $CHAR30.
		COD_COMPRA       BEST2.
		TIPO_COMPRA      $CHAR25.
		COD_COMERCIO     $CHAR15.
		COMERCIO         $CHAR1.
		MONTO            BEST7.
		FECHA            YYMMDD10.
		CUOTAS           BEST2.
		INTERES          BEST8.
		MARGEN_FINANCIERO BEST7.
		VENTA_FINANCIADA BEST7.
		COD_PAIS         BEST3.
		COD_PRODUCTO     BEST1.;
	INPUT
		PERIODO          : ?? BEST6.
		RUT_CLIENTE      : ?? BEST8.
		TIPO_PRODUCTO    : $CHAR16.
		COD_FACTURA      : ?? BEST4.
		TIPO_FACTURA     : $CHAR30.
		COD_COMPRA       : ?? BEST2.
		TIPO_COMPRA      : $CHAR25.
		COD_COMERCIO     : $CHAR15.
		COMERCIO         : $CHAR1.
		MONTO            : ?? BEST7.
		FECHA            : ?? YYMMDD10.
		CUOTAS           : ?? BEST2.
		INTERES          : ?? COMMAX8.
		MARGEN_FINANCIERO : ?? BEST7.
		VENTA_FINANCIADA : ?? BEST7.
		COD_PAIS         : ?? BEST3.
		COD_PRODUCTO     : ?? BEST1.;

	if _ERROR_ then
		call symputx('_EFIERR_',1);

	/* set ERROR              
	   ! detection macro variable */
run;

/*%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";*/
/*%DELETE_INCREM_PER_DIARIO(sas_spos_credito,raw,sasdata,-1);*/
/*Exportación a AWS*/
/*%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";*/
/*%INCREM_PER_DIARIO(sas_spos_credito,publicin.SPOS_CREDITO_&fechax.,raw,sasdata,-1);*/
/* REALIZA EL CIERRE DE SPOS APARTIR DEL SPOS_CREDITO (ARCHIVO) */
DATA null_;
	datex = put(intnx('month',today(),-1,'end'),yymmn6.);
	fecha_sn = compress(input(put(today(),yymmdd10.),$10.),"-","");
	exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	fecha = tranwrd(datex, "-", "");
	Call symput("fechax", datex);
	Call symput("fechae",exec);
	call symput("fecha_sn",fecha_sn);

	/*date9i = put(intnx('month',today(),-1,'begin'),date9.);*/
RUN;

%put &fechae;
%put &fechax;
%put &fecha_sn;

/* CARGA SPOS_YYYYMM (MENSUAL) desde el archivo SPOS_CREDITO */
proc sql;
	CREATE TABLE PUBLICIN.SPOS_&fechax AS
		SELECT    t1.RUT_CLIENTE,
			t1.TIPO_PRODUCTO,
			t1.COD_FACTURA,
			t1.TIPO_FACTURA,
			t1.COD_COMPRA,
			t1.TIPO_COMPRA,
			INPUT(t1.COD_COMERCIO, 15.) AS COD_COMERCIO,
			t1.MONTO AS VENTA_TARJETA,
			INPUT(input(put(intnx('month',t1.FECHA,0,'same'),yymmddn8.),$10.), BEST.) as COD_FECHA,
			t1.FECHA format=date9. as FECHA_TRUNC,  
			t1.CUOTAS AS PLAZO,
			t1.INTERES,
			t1.MARGEN_FINANCIERO,
			t1.VENTA_FINANCIADA,
			t1.COD_PAIS AS PAIS,
			t1.COD_PRODUCTO,
			1 AS CANTIDAD_TRX,
		CASE 
			WHEN t1.COD_PRODUCTO = 7  THEN 'TAM_CHIP'
			WHEN t1.COD_PRODUCTO in(5,6) THEN 'TAM'
			WHEN t1.COD_PRODUCTO in(1,3) THEN 'ITF'
		END 
	AS MARCA_BASE,
		&fechae as FEC_EX,
		&fechax as PERIODO
	FROM work.SPOS_CREDITO_&fechax t1
	;
quit;

/**/
/*%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";*/
/*%DELETE_INCREM_PER_DIARIO(sas_spos,raw,sasdata,-1);*/

/*Exportación a AWS*/
/*%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";*/
/*%INCREM_PER_DIARIO(sas_spos,PUBLICIN.SPOS_&fechax.,raw,sasdata,-1);*/

PROC SQL;
	CREATE TABLE VALIDA_SPOS AS
		SELECT SUM(VENTA_TARJETA) FORMAT=BESTx32. AS VENTA, COUNT(RUT_CLIENTE) FORMAT=BESTx32. AS TRXS
			FROM publicin.SPOS_&fechax.;
QUIT;

/*==================================================================================================*/

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
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;

FILENAME output EMAIL
SUBJECT="MAIL_AUTOM: PROCESO SPOS_AUTOM"
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_2", "&DEST_3")
CT= "text/html"  ;
ODS HTML 
BODY=output 
style=sasweb; 
ods escapechar='~'; 

title1  "Estimados:";
title2 font='helvetica/italic' height=10pt 
		" Proceso SPOS_AUTOM, ejecutado con fecha: &fechaeDVN 
		  Tabla resultante en Athena: sas_spos
		~n 
		~n
		  Proceso Vers. 02
		~n 
		~n
		Atte.
		Equipo Arquitectura de Datos y Automatización BI
		~n
";
PROC REPORT DATA=WORK.VALIDA_SPOS NOWD
STYLE(REPORT)=[PREHTML="<hr>"] /*Inserts a rule between title & body*/;
RUN;
ODS HTML CLOSE;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
