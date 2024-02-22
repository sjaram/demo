/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS			================================*/
/*==================================    SKU_PTO_COM_IMPORT				================================*/

/* CONTROL DE VERSIONES
/* 2022-10-18 -- v04 -- David V. 	-- Actualización a tamaño de columnas en base a primeros 5MM de registros
/* 2022-10-18 -- v03 -- David V. 	-- Corrección delete archivo
/* 2022-10-17 -- v02 -- David V. 	-- Corrección en la parte de eliminado del archivo
/* 2022-10-14 -- v01 -- David V. 	-- Versión Original

/* INFORMACIÓN:


*/

/*============================================================================================	*/
/*	IMPORTAR ARCHIVO */
/*	============================================================================================	*/
/* VARIABLE TIEMPO - INICIO */
%let tiempo_inicio 	= %sysfunc(datetime());
%let libreria 		= result;
options validvarname=any;

DATA _null_;
	dateMES	= input(put(intnx('month',today(),-0,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
	dateDIA	= compress(input(put(today()-0,yymmdd10.),$10.),"-",c);
	Call symput("fechaMES", dateMES);
	Call symput("fechaDIA", dateDIA);
RUN;

%put &libreria;
%put &fechaMES;
%put &fechaDIA;

/* Variable ruta */
data _null_;
	VAR = COMPRESS('/sasdata/users94/user_bi/IN_SQL_DWH/SKU_Pto_com_'||&fechaMES.||'.csv'," ",);
	call symput("ruta",VAR);
run;

%PUT &ruta;

DATA WORK.SKU_Pto_com_&fechaMES.;
	LENGTH
		PERIODO            8
		Fecha              8
		sku                8
		listprice          8
		offerPrice         8
		cardprice          8
		T_Oferta         $ 13;
	FORMAT
		PERIODO          BEST6.
		Fecha            YYMMDD10.
		sku              BEST13.
		listprice        BEST9.
		offerPrice       BEST8.
		cardprice        BEST7.
		T_Oferta         $CHAR13.;
	INFORMAT
		PERIODO          BEST6.
		Fecha            YYMMDD10.
		sku              BEST13.
		listprice        BEST9.
		offerPrice       BEST8.
		cardprice        BEST7.
		T_Oferta         $CHAR13.;
	INFILE "&ruta."
		delimiter = ','
		firstobs=2
		MISSOVER
		DSD;
	INPUT
		PERIODO          : ?? BEST6.
		Fecha            : ?? YYMMDD8.
		sku              : ?? BEST13.
		listprice        : ?? BEST9.
		offerPrice       : ?? BEST8.
		cardprice        : ?? BEST7.
		T_Oferta         : $CHAR13.;
RUN;

%MACRO VALIDACION (libreria);
	%IF %sysfunc(exist(&libreria..SKU_Pto_com_&fechaMES.)) %then
		%do;

			PROC SQL;
				INSERT INTO &libreria..SKU_Pto_com_&fechaMES. 
					SELECT *
						FROM  WORK.SKU_Pto_com_&fechaMES.;
				;
			RUN;

		%end;
	%else
		%do;

			PROC SQL;
				CREATE TABLE &libreria..SKU_Pto_com_&fechaMES. AS 
					SELECT *
						FROM  WORK.SKU_Pto_com_&fechaMES.;
			RUN;

		%end;
%mend;

%VALIDACION (&libreria.);

/*ELIMINACION POSIBLES DUPLICADOS*/
proc sort data=&libreria..SKU_Pto_com_&fechaMES. out=&libreria..SKU_Pto_com_&fechaMES.
	noduprecs dupout=malos_repetidos;
	by _all_;
run;


data _null_;
	VAR_2 = COMPRESS('/sasdata/users94/user_bi/IN_SQL_DWH/procesado_SKU_Pto_com_'||&fechaDIA.||'.csv'," ",);
	call symput("archivo_renombrado",VAR_2);
run;

%PUT &archivo_renombrado;

/*======= INI . Para hacer la copia del archivo, con el nuevo nombre procesado =======*/
options msglevel=i;
filename src "&ruta.";
filename dest "&archivo_renombrado.";

/*data _null_;*/
/*   file src;*/
/*   do i=1, 2105, 300312, 400501;*/
/*      put i:words256.;*/
/*   end;*/
/*run;*/
data _null_;
	length msg $ 384;
	rc=fcopy('src', 'dest');

	if rc=0 then
		put 'Copiado el archivo OK';
	else
		do;
			msg=sysmsg();
			put rc= msg=;
		end;
run;
/*======= FIN . Para hacer la copia del archivo, con el nuevo nombre procesado =======*/
/*		########################################################################	  */

/*======= INI . Para ver si existe el archivo =======*/
%macro check(dir= );
   %if %sysfunc(fileexist(&dir)) %then
   %do; 
      %put Error.. El archivo aun existe, por lo que estamos duplicando; 
   %end; 
   %else %do; 
      %put OK, El archivo anterior ha sido eliminado!; 
   %end; 
%mend;

%check(dir="&ruta."); 
/*======= FIN . Para ver si existe el archivo =======*/
/*		########################################################################	  */


/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/

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
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_PPFF';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_2';

quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1")
/*TO = ("&DEST_4","&DEST_5")*/
/*CC = ("&DEST_1","&DEST_2", "&DEST_3")*/
SUBJECT="MAIL_AUTOM: PROCESO SKU_PTO_COM_IMPORT" ;
FILE OUTBOX;
PUT 'Estimados:';
 PUT "Proceso SKU_PTO_COM_IMPORT, ejecutado con fecha: &fechaeDVN";  
 PUT ; 
 PUT "Tabla resultante en SAS: &libreria..SKU_Pto_com_&fechaMES.";
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


/*======= INI . Para Eliminar un archivo =======*/
filename DEL "&ruta.";

data _null_;
	RC2=fdelete("DEL");

	if RC2=0 then
		put "Nota: Archivos eliminados con éxito.";
	else put "Nota: Los archivos no se pueden eliminar.";
Run;
/*======= FIN . Para Eliminar un archivo =======*/
/*		########################################################################	  */



data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
