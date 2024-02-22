/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================    INP_IDNOW_Proceso_Unificado	 	 ===============================*/
/* CONTROL DE VERSIONES
/* 2023-08-25 -- v03	-- David V.		--  Cambio en orden, dispositivos al final.
/* 2022-08-09 -- v02	-- David V.		--  Corrección para que tome los días donde antecede un número cero, 01, 02, etc.
/* 2022-07-28 -- v01	-- David V.		--  Versión Original

/* INFORMACIÓN:
	Proceso unificado que toma información desde AWS, originalmente del proveedor IdNow para el equipo BI

/* VARIABLE TIEMPO - INICIO */
%let tiempo_inicio= %sysfunc(datetime());

options validvarname=any;

DATA _null_;
fgenera = compress(input(put(today()-0,ddmmyy10.),$10.),"/",c);
Call symput("fechaDIA",COMPRESS(fgenera));
%let libreria=PUBLICIN;

/*==================================================================================================*/
/*==============================    INP_IDNOW_reporteTransacciones	 ===============================*/

RUN;
%put &fechaDIA;
%put &libreria;
%let ruta = /sasdata/users94/user_bi/IN_ARCHIVOS_IDNOW/reporteTransacciones&fechaDIA..csv;
%put &ruta;


DATA WORK.reporteTransacciones;
    LENGTH
        Institucion      $ 12
        'Id Transaccion'n $ 36
        Cliente          $ 9
        'Nombre Completo Cliente'n $ 46
        Canal            $ 11
        'Nombre Transaccion'n $ 20
        'Fecha Inicio'n    8
        'Hora Inicio'n     8
        'Fecha Autorizacion'n   8
        'Hora Autorizacion'n   8
        'Metodo Aplicado'n $ 16
        'Sistema Operativo'n $ 7
        Estado           $ 2
        Monto              8
        Recurrente       $ 1
        'Sub Tipo Transaccion'n $ 30
        'Nivel de Riesgo'n $ 5
        Monetaria          8
        Autenticador     $ 16
        'Fecha Autenticador'n   8
        'Hora Autenticador'n   8
        'Estado Autenticador'n $ 2
        Accion           $ 9
        'Nombre Regla'n  $ 28
        'Codigo Estado'n   8
        'Descripcion Estado'n $ 28
        'Autenticador Disponible'n $ 16
        F28              $ 1 ;
    FORMAT
        Institucion      $CHAR12.
        'Id Transaccion'n $CHAR36.
        Cliente          $CHAR9.
        'Nombre Completo Cliente'n $CHAR46.
        Canal            $CHAR11.
        'Nombre Transaccion'n $CHAR20.
        'Fecha Inicio'n  DDMMYY10.
        'Hora Inicio'n   TIME8.
        'Fecha Autorizacion'n DDMMYY10.
        'Hora Autorizacion'n TIME8.
        'Metodo Aplicado'n $CHAR16.
        'Sistema Operativo'n $CHAR7.
        Estado           $CHAR2.
        Monto            DOLLARX11.2
        Recurrente       $CHAR1.
        'Sub Tipo Transaccion'n $CHAR30.
        'Nivel de Riesgo'n $CHAR5.
        Monetaria        BEST1.
        Autenticador     $CHAR16.
        'Fecha Autenticador'n DDMMYY10.
        'Hora Autenticador'n TIME8.
        'Estado Autenticador'n $CHAR2.
        Accion           $CHAR9.
        'Nombre Regla'n  $CHAR28.
        'Codigo Estado'n BEST3.
        'Descripcion Estado'n $CHAR28.
        'Autenticador Disponible'n $CHAR16.
        F28              $CHAR1. ;
    INFORMAT
        Institucion      $CHAR12.
        'Id Transaccion'n $CHAR36.
        Cliente          $CHAR9.
        'Nombre Completo Cliente'n $CHAR46.
        Canal            $CHAR11.
        'Nombre Transaccion'n $CHAR20.
        'Fecha Inicio'n  DDMMYY10.
        'Hora Inicio'n   TIME11.
        'Fecha Autorizacion'n DDMMYY10.
        'Hora Autorizacion'n TIME11.
        'Metodo Aplicado'n $CHAR16.
        'Sistema Operativo'n $CHAR7.
        Estado           $CHAR2.
        Monto            DOLLARX11.
        Recurrente       $CHAR1.
        'Sub Tipo Transaccion'n $CHAR30.
        'Nivel de Riesgo'n $CHAR5.
        Monetaria        BEST1.
        Autenticador     $CHAR16.
        'Fecha Autenticador'n DDMMYY10.
        'Hora Autenticador'n TIME11.
        'Estado Autenticador'n $CHAR2.
        Accion           $CHAR9.
        'Nombre Regla'n  $CHAR28.
        'Codigo Estado'n BEST3.
        'Descripcion Estado'n $CHAR28.
        'Autenticador Disponible'n $CHAR16.
        F28              $CHAR1. ;
    INFILE "&ruta."
        MISSOVER
        DSD 
		delimiter=';'
		firstobs=2;
    INPUT
        Institucion      : $CHAR12.
        'Id Transaccion'n : $CHAR36.
        Cliente          : $CHAR9.
        'Nombre Completo Cliente'n : $CHAR46.
        Canal            : $CHAR11.
        'Nombre Transaccion'n : $CHAR20.
        'Fecha Inicio'n  : ?? DDMMYY10.
        'Hora Inicio'n   : ?? TIME8.
        'Fecha Autorizacion'n : ?? DDMMYY10.
        'Hora Autorizacion'n : ?? TIME8.
        'Metodo Aplicado'n : $CHAR16.
        'Sistema Operativo'n : $CHAR7.
        Estado           : $CHAR2.
        Monto            : ?? DOLLARX11.
        Recurrente       : $CHAR1.
        'Sub Tipo Transaccion'n : $CHAR30.
        'Nivel de Riesgo'n : $CHAR5.
        Monetaria        : ?? BEST1.
        Autenticador     : $CHAR16.
        'Fecha Autenticador'n : ?? DDMMYY10.
        'Hora Autenticador'n : ?? TIME8.
        'Estado Autenticador'n : $CHAR2.
        Accion           : $CHAR9.
        'Nombre Regla'n  : $CHAR28.
        'Codigo Estado'n : ?? BEST3.
        'Descripcion Estado'n : $CHAR28.
        'Autenticador Disponible'n : $CHAR16.
        F28              : $CHAR1. ;
RUN;


/*ELIMINACION POSIBLES DUPLICADOS*/
proc sort data=work.reporteTransacciones out=work.reporteTransaccionesIDNOW
noduprecs dupout=malos1; by _all_;
run;

/*	============================================================================================	*/
/*	CREAR TABLA PERIODICA DE - EMAIL	*/
/*	============================================================================================	*/

%MACRO PRUEBA (libreria);

%IF %sysfunc(exist(&libreria..IDNOW_reporteTransacciones)) %then %do;

	PROC SQL;
	INSERT INTO &libreria..IDNOW_reporteTransacciones 
	SELECT *
	FROM  reporteTransaccionesIDNOW;

;RUN; 
%end;
%else %do;

	PROC SQL;
   	CREATE TABLE &libreria..IDNOW_reporteTransacciones AS 
   	SELECT *
   	FROM  reporteTransaccionesIDNOW;

RUN;
%end;

%mend ;
%PRUEBA (&libreria.);

/*ELIMINACION POSIBLES DUPLICADOS*/
proc sort data=&libreria..IDNOW_reporteTransacciones out=&libreria..IDNOW_reporteTransacciones
noduprecs dupout=malos_repTrans; by _all_;
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
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CLIENTES_1';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CONTACTABILIDAD';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
/*TO = ("&DEST_1")*/
TO = ("&DEST_4","&DEST_5","&DEST_6")
CC = ("&DEST_1", "&DEST_2", "&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso INP_IDNOW_reporteTransacciones");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "		Proceso INP_IDNOW_reporteTransacciones, ejecutado con fecha: &fechaeDVN";  
 PUT "  	Información disponible en SAS: &libreria..IDNOW_reporteTransacciones";  
 PUT ;
 PUT ;
 PUT ;
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

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================    INP_IDNOW_reporteEnrolamientos	 ===============================*/

%let ruta3 = /sasdata/users94/user_bi/IN_ARCHIVOS_IDNOW/reporteEnrolamientos&fechaDIA..csv;
%put &ruta3;

DATA WORK.reporteEnrolamientos;
    LENGTH
        Institucion      $ 12
        'Identificador Enrolamiento'n $ 58
        'Tipo Usuario'n  $ 2
        'Identificador Usuario'n $ 9
        'Nombre Completo Cliente'n $ 45
        'Inicio Enrolamiento'n   8
        'Hora Inicio'n     8
        'Sistema Operativo'n $ 7
        'Estado Dispostivo'n $ 1
        'Nombre Paso'n   $ 22
        'Estado Paso'n   $ 1
        'Score Paso'n      8
        Aplicacion       $ 12
        'Estado Final'n  $ 2
        'Score Final'n     8
        'Fin Enrolamiento'n   8
        'Hora Fin'n        8
        'Tipo Enrolamiento'n $ 16
        'Codigo Estado'n   8
        'Descripcion Estado'n $ 29
        F21              $ 1 ;
    FORMAT
        Institucion      $CHAR12.
        'Identificador Enrolamiento'n $CHAR58.
        'Tipo Usuario'n  $CHAR2.
        'Identificador Usuario'n $CHAR9.
        'Nombre Completo Cliente'n $CHAR45.
        'Inicio Enrolamiento'n DDMMYY10.
        'Hora Inicio'n   TIME8.
        'Sistema Operativo'n $CHAR7.
        'Estado Dispostivo'n $CHAR1.
        'Nombre Paso'n   $CHAR22.
        'Estado Paso'n   $CHAR1.
        'Score Paso'n    BEST5.
        Aplicacion       $CHAR12.
        'Estado Final'n  $CHAR2.
        'Score Final'n   BEST3.
        'Fin Enrolamiento'n DDMMYY10.
        'Hora Fin'n      TIME8.
        'Tipo Enrolamiento'n $CHAR16.
        'Codigo Estado'n BEST3.
        'Descripcion Estado'n $CHAR29.
        F21              $CHAR1. ;
    INFORMAT
        Institucion      $CHAR12.
        'Identificador Enrolamiento'n $CHAR58.
        'Tipo Usuario'n  $CHAR2.
        'Identificador Usuario'n $CHAR9.
        'Nombre Completo Cliente'n $CHAR45.
        'Inicio Enrolamiento'n DDMMYY10.
        'Hora Inicio'n   TIME11.
        'Sistema Operativo'n $CHAR7.
        'Estado Dispostivo'n $CHAR1.
        'Nombre Paso'n   $CHAR22.
        'Estado Paso'n   $CHAR1.
        'Score Paso'n    BEST5.
        Aplicacion       $CHAR12.
        'Estado Final'n  $CHAR2.
        'Score Final'n   BEST3.
        'Fin Enrolamiento'n DDMMYY10.
        'Hora Fin'n      TIME11.
        'Tipo Enrolamiento'n $CHAR16.
        'Codigo Estado'n BEST3.
        'Descripcion Estado'n $CHAR29.
        F21              $CHAR1. ;
    INFILE "&ruta3."
        MISSOVER
        DSD 
		delimiter=';'
		firstobs=2;
    INPUT
        Institucion      : $CHAR12.
        'Identificador Enrolamiento'n : $CHAR58.
        'Tipo Usuario'n  : $CHAR2.
        'Identificador Usuario'n : $CHAR9.
        'Nombre Completo Cliente'n : $CHAR45.
        'Inicio Enrolamiento'n : ?? DDMMYY10.
        'Hora Inicio'n   : ?? TIME8.
        'Sistema Operativo'n : $CHAR7.
        'Estado Dispostivo'n : $CHAR1.
        'Nombre Paso'n   : $CHAR22.
        'Estado Paso'n   : $CHAR1.
        'Score Paso'n    : ?? COMMA5.
        Aplicacion       : $CHAR12.
        'Estado Final'n  : $CHAR2.
        'Score Final'n   : ?? BEST3.
        'Fin Enrolamiento'n : ?? DDMMYY10.
        'Hora Fin'n      : ?? TIME8.
        'Tipo Enrolamiento'n : $CHAR16.
        'Codigo Estado'n : ?? BEST3.
        'Descripcion Estado'n : $CHAR29.
        F21              : $CHAR1. ;
RUN;


/*ELIMINACION POSIBLES DUPLICADOS*/
proc sort data=work.reporteEnrolamientos out=work.reporteEnrolamientosIDNOW
noduprecs dupout=malos3; by _all_;
run;

/*	============================================================================================	*/
/*	CREAR TABLA PERIODICA DE - EMAIL	*/
/*	============================================================================================	*/

%MACRO PRUEBA (libreria);

%IF %sysfunc(exist(&libreria..IDNOW_reporteEnrolamientos)) %then %do;

	PROC SQL;
	INSERT INTO &libreria..IDNOW_reporteEnrolamientos 
	SELECT *
	FROM  reporteEnrolamientosIDNOW;

;RUN; 
%end;
%else %do;

	PROC SQL;
   	CREATE TABLE &libreria..IDNOW_reporteEnrolamientos AS 
   	SELECT *
   	FROM  reporteEnrolamientosIDNOW;

RUN;
%end;

%mend ;
%PRUEBA (&libreria.);

/*ELIMINACION POSIBLES DUPLICADOS*/
proc sort data=&libreria..IDNOW_reporteEnrolamientos out=&libreria..IDNOW_reporteEnrolamientos
noduprecs dupout=malos_repEnrol; by _all_;
run;

/* VARIABLE TIEMPO - FIN */
data _null_;
dur = datetime() - &tiempo_inicio;
put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4","&DEST_5","&DEST_6")
CC = ("&DEST_1", "&DEST_2", "&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso INP_IDNOW_reporteEnrolamientos");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "		Proceso INP_IDNOW_reporteEnrolamientos, ejecutado con fecha: &fechaeDVN";  
 PUT "  	Información disponible en SAS: &libreria..IDNOW_reporteEnrolamientos";  
 PUT ;
 PUT ;
 PUT ;
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

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================    INP_IDNOW_reporteDispositivos	 ===============================*/

%let ruta2 = /sasdata/users94/user_bi/IN_ARCHIVOS_IDNOW/reporteDispositivos&fechaDIA..csv;
%put &ruta2;

DATA WORK.reporteDispositivos;
    LENGTH
        Institucion      $ 12
        'Nombre Usuario'n $ 44
        Identificador    $ 9
        'Tipo Usuario'n  $ 2
        Aplicacion       $ 12
        'Autenticador Habilitado'n $ 16
        Notificaciones   $ 1
        Estado           $ 1
        'Version SO'n    $ 17
        'Sistema Operativo'n $ 7
        'UUID Device'n   $ 49
        'Numero de Telefono'n   8
        'Fecha de Registro'n   8
        'Hora de Registro'n   8
        Score              8
        'Tipo de Enrolamiento'n $ 16
        'Nombre Atributo'n $ 12
        'Valor Atributo'n $ 19
        F19              $ 1 ;
    FORMAT
        Institucion      $CHAR12.
        'Nombre Usuario'n $CHAR44.
        Identificador    $CHAR9.
        'Tipo Usuario'n  $CHAR2.
        Aplicacion       $CHAR12.
        'Autenticador Habilitado'n $CHAR16.
        Notificaciones   $CHAR1.
        Estado           $CHAR1.
        'Version SO'n    $CHAR17.
        'Sistema Operativo'n $CHAR7.
        'UUID Device'n   $CHAR49.
        'Numero de Telefono'n BEST11.
        'Fecha de Registro'n DDMMYY10.
        'Hora de Registro'n TIME8.
        Score            BEST3.
        'Tipo de Enrolamiento'n $CHAR16.
        'Nombre Atributo'n $CHAR12.
        'Valor Atributo'n $CHAR19.
        F19              $CHAR1. ;
    INFORMAT
        Institucion      $CHAR12.
        'Nombre Usuario'n $CHAR44.
        Identificador    $CHAR9.
        'Tipo Usuario'n  $CHAR2.
        Aplicacion       $CHAR12.
        'Autenticador Habilitado'n $CHAR16.
        Notificaciones   $CHAR1.
        Estado           $CHAR1.
        'Version SO'n    $CHAR17.
        'Sistema Operativo'n $CHAR7.
        'UUID Device'n   $CHAR49.
        'Numero de Telefono'n BEST11.
        'Fecha de Registro'n DDMMYY10.
        'Hora de Registro'n TIME11.
        Score            BEST3.
        'Tipo de Enrolamiento'n $CHAR16.
        'Nombre Atributo'n $CHAR12.
        'Valor Atributo'n $CHAR19.
        F19              $CHAR1. ;
    INFILE "&ruta2."
        MISSOVER
        DSD 
		delimiter=';'
		firstobs=2;
    INPUT
        Institucion      : $CHAR12.
        'Nombre Usuario'n : $CHAR44.
        Identificador    : $CHAR9.
        'Tipo Usuario'n  : $CHAR2.
        Aplicacion       : $CHAR12.
        'Autenticador Habilitado'n : $CHAR16.
        Notificaciones   : $CHAR1.
        Estado           : $CHAR1.
        'Version SO'n    : $CHAR17.
        'Sistema Operativo'n : $CHAR7.
        'UUID Device'n   : $CHAR49.
        'Numero de Telefono'n : ?? BEST11.
        'Fecha de Registro'n : ?? DDMMYY10.
        'Hora de Registro'n : ?? TIME8.
        Score            : ?? BEST3.
        'Tipo de Enrolamiento'n : $CHAR16.
        'Nombre Atributo'n : $CHAR12.
        'Valor Atributo'n : $CHAR19.
        F19              : $CHAR1. ;
RUN;


/*ELIMINACION POSIBLES DUPLICADOS*/
proc sort data=work.reporteDispositivos out=work.reporteDispositivosIDNOW
noduprecs dupout=malos2; by _all_;
run;

/*	============================================================================================	*/
/*	CREAR TABLA PERIODICA DE - EMAIL	*/
/*	============================================================================================	*/

%MACRO PRUEBA (libreria);

%IF %sysfunc(exist(&libreria..IDNOW_reporteDispositivos)) %then %do;

	PROC SQL;
	INSERT INTO &libreria..IDNOW_reporteDispositivos 
	SELECT *
	FROM  reporteDispositivosIDNOW;

;RUN; 
%end;
%else %do;

	PROC SQL;
   	CREATE TABLE &libreria..IDNOW_reporteDispositivos AS 
   	SELECT *
   	FROM  reporteDispositivosIDNOW;

RUN;
%end;

%mend ;
%PRUEBA (&libreria.);

/*ELIMINACION POSIBLES DUPLICADOS*/
proc sort data=&libreria..IDNOW_reporteDispositivos out=&libreria..IDNOW_reporteDispositivos
noduprecs dupout=malos_repDis; by _all_;
run;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
/*TO = ("&DEST_1")*/
TO = ("&DEST_4","&DEST_5","&DEST_6")
CC = ("&DEST_1", "&DEST_2", "&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso INP_IDNOW_reporteDispositivos");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "		Proceso INP_IDNOW_reporteDispositivos, ejecutado con fecha: &fechaeDVN";  
 PUT "  	Información disponible en SAS: &libreria..IDNOW_reporteDispositivos";  
 PUT ;
 PUT ;
 PUT ;
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
