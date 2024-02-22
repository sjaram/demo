/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	CODIGOS_OPEX_TDA				 ===============================*/
/* CONTROL DE VERSIONES
/* 2023-08-25 -- v02 -- David V. 	-- Actualización a correos de personas equipo SPOS
/* 2021-05-04 -- v01 -- David V. 	-- Versión Original

/* INFORMACIÓN:
	.Toma desde SFTP archivo depositado por Retail, los códigos de OPEX históricos y vigentes en tienda, y genera
	tabla en SAS con la información.

	(IN) Tablas requeridas o conexiones a BD:
	- /sasdata/users94/user_bi/TRASPASO_DOCS/OPEX_TDA/Historico_Promociones_OPEX.xlsx

	(OUT) Tablas de Salida o resultado:
	- PUBLICIN.CODIGOS_OPEX

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

%LET ARCH='/sasdata/users94/user_bi/TRASPASO_DOCS/OPEX_TDA/Historico_Promociones_OPEX.xlsx';
%put==================================================================================================;
%put 01.MACRO DE CARGA DEL ARCHIVO;
%put==================================================================================================;

%macro PROCESO_CARGA_ARCHIVO(ARCH);
%if %sysfunc(fileexist(&ARCH.)) %then %do;

%put==================================================================================================;
%put A.SE CARGARA EL ARCHIVO SOLICITADO;
%put==================================================================================================;

/*Si existe tabla se elimina*/
	proc import datafile='/sasdata/users94/user_bi/TRASPASO_DOCS/OPEX_TDA/Historico_Promociones_OPEX.xlsx'
		   DBMS = xlsx replace
		   out = PUBLICIN.CODIGOS_OPEX_2;  
           getnames = yes; 
		   sheet='OPEX'  
	;quit; 
%end;
%else %do;

%put==================================================================================================;
%put B.NO EXISTE ARCHIVO EN LA RUTA;
%put==================================================================================================;

%end;
%mend PROCESO_CARGA_ARCHIVO;
%PROCESO_CARGA_ARCHIVO(&ARCH);

/*	QUITA REGISTROS NULOSO VACÍOS DE LA TABLA DE SALIDA */
proc sql;
delete * from PUBLICIN.CODIGOS_OPEX_2
where codigo=.;
quit;

/*	QUITA LA COLUMNA J QUE NO TENÍA DATOS	*/
PROC SQL;
   CREATE TABLE PUBLICIN.CODIGOS_OPEX AS 
   SELECT t1.Codigo, 
          t1.Nombre_Promocion, 
          t1.Tipo_Prom, 
          t1.Desde, 
          t1.Hasta, 
          t1.Estado, 
          t1.Mes_creacion, 
          t1.Depto, 
          t1.Division
      FROM PUBLICIN.CODIGOS_OPEX_2 t1;
QUIT;

PROC SQL;
DROP TABLE PUBLICIN.CODIGOS_OPEX_2
;QUIT;

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/

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
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
quit;

%put &=EDP_BI;		%put &=DEST_1;		%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;

data _null_;
FILENAME OUTBOX EMAIL
FROM	= ("&EDP_BI")
TO 		= ("jsantamaria@bancoripley.com","adiazse@bancoripley.com")
CC 		= ("&DEST_1", "&DEST_2","&DEST_3", "&DEST_4")
SUBJECT = ("MAIL_AUTOM: Proceso CODIGOS_OPEX_TDA");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "        Proceso CODIGOS_OPEX_TDA, ejecutado automáticamente con fecha: &fechaeDVN";  
 PUT ;
 PUT '          Disponible información en SAS:';
 PUT '             PUBLICIN.CODIGOS_OPEX';
 PUT ;
 PUT '          Tomado desde archivo:';
 PUT '             Historico_Promociones_OPEX.xlsx';
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 02'; 
 PUT ;
 PUT ;
PUT 'Atte.';
PUT 'Equipo Arquitectura de Datos y Automatización BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

