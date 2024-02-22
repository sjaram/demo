/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	SERNAC_INHIB_PARTE_3		================================*/
/* CONTROL DE VERSIONES

/* 2023-06-13 -- V14 -- Sergio J. -- Se agrega exportación a AWS

/* 2022-12-27 -- V13 -- Andrea S. -- Se añade export base Libro negro email

/* 2022-11-07 -- V12 -- Sergio J. -- Se añade sentencia Lock para bloquear la tabla PUBLICIN.NOTCALL

/* 2020-10-26 -- V11 -- Sergio J. -- Versión actualizada
				    -- ARREGLO VARIABLE FECHAS EN CORREO

/* 2020-10-23 -- V10 -- Sergio J. -- Versión actualizada
					-- ARREGLO DE IMPORTACION y EXPORTACION, BASE NOTCALL

/* 2020-10-20 -- V9 -- Sergio J. -- Versión actualizada
					-- Ordena las vistas por FECHA_INGRESO DESCENDENTEMENTE (DESC)
					-- Ordena las vistas por FECHA_INHIBICION DESCENDENTEMENTE (DESC)

/* 2020-10-16 -- V8 -- Sergio J. -- Versión actualizada
					-- Se cambia ruta ftp por la de Osvaldo en forma temporal

/* 2020-10-16 -- V7 -- Sergio J. -- Versión actualizada
					-- Comentarios tablas IN y OUT al inicio

/* 2020-10-16 -- V6 -- Sergio J. -- Versión actualizada
					-- Se actualiza ruta en FTP a user_bi
                 	-- Genera correos automaticos para:
          "CAROLINA_VILLARROEL",'JAIME_MARTINEZ','JHON_BAEZA', "ERIK_SANHUEZA"

/* INFORMACIÓN:
	Diariamente toma las Bases NOTCALL Y LNEGRO_CALL, actualizadas por el Proceso SERNAC1 y SERNAC2 
	y las distribuye a los FTP de: 
 		- RUC (Carolina Villaroel y Jaime Martinez)
		- Control y gestión (Erik Sanhueza y Jhon BAeza)
		- Contac Center (Rodrigo Bugeño, Cristian Echeverria, Marta Gonzalez y Michael Cubillos).  

/* Tablas, archivos o BD requeridas (IN):
	- PUBLICIN.LNEGRO_CAR
	- PUBLICIN.NOTCALL
	- PUBLICIN.LNEGRO_CALL
	- result.EDP_BI_DESTINATARIOS

 /* Tablas o archivos que genera (OUT): 
	- PUBLICIN.NOTCALL
	- PUBLICIN.NOTCALL_RUT
	- PUBLICIN.NOTCALL_FONO
	- RESULT.NOTCALL_NOVEDADES_&mes_actual
 	
*/
/*==================================================================================================*/


/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio = %sysfunc(datetime()); /* inicio del proceso de conteo*/



/*2.898.352*/
/*NUEVOS EN LNEGRO_CAR*/
PROC SQL;
	CREATE TABLE WORK.CAR AS
	SELECT RUT,
			. AS AREA,
			. AS FONO,
			TIPO_INHIBICION,
			CANAL_RECLAMO,
			FECHA_INGRESO
	FROM PUBLICIN.LNEGRO_CAR
/*	WHERE TIPO_INHIBICION IN ('LISTA_NEGRA_CAR','SERNAC','SERNAC_BCO','LISTA_NEGRA_BCO','CALL','L_NEGRO_CAR', 'FALLECIDOS', 'FALLECIDO')*/
	WHERE RUT NOT IN (SELECT RUT FROM PUBLICIN.NOTCALL)
;QUIT;

PROC SQL;
CREATE TABLE work.NOTCALL4 as
	SELECT *
	FROM PUBLICIN.NOTCALL
;QUIT;
PROC SQL;
INSERT INTO work.NOTCALL4
	SELECT *
	FROM WORK.CAR
;QUIT;


/*NUEVOS EN LNEGRO_CALL*/
PROC SQL;
CREATE TABLE WORK.CALL AS
	SELECT T1.RUT,
			T1.AREA,
			T1.FONO,
			T1.TIPO_INHIBICION,
			T1.CANAL_RECLAMO,
			T1.FECHA_INGRESO AS FECHA_SOLICITUD
	FROM PUBLICIN.LNEGRO_CALL T1
;QUIT;

PROC SQL;
	CREATE TABLE WORK.TODO_NOTCALL AS
	SELECT *
	FROM work.NOTCALL4/*PUBLICIN.NOTCALL*/
UNION
	SELECT *
	FROM WORK.CALL
ORDER BY FECHA_SOLICITUD
;QUIT;

PROC SQL;
CREATE TABLE WORK.NOTCALL AS
	SELECT DISTINCT RUT,AREA,FONO,TIPO_INHIBICION,CANAL_RECLAMO,
	       MIN(FECHA_SOLICITUD) FORMAT=DATE9. AS FECHA_SOLICITUD
	FROM WORK.TODO_NOTCALL
	GROUP BY RUT,FONO,TIPO_INHIBICION,CANAL_RECLAMO
	ORDER BY FECHA_SOLICITUD
;QUIT;
/*quitar*/

lock PUBLICIN.NOTCALL; /*Bloquear la tabla*/
PROC SQL;
	CREATE TABLE PUBLICIN.NOTCALL AS
	SELECT *
	FROM WORK.NOTCALL
;QUIT;

lock PUBLICIN.NOTCALL clear;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(sas_ctbl_notcall,raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(sas_ctbl_notcall,publicin.NOTCALL,raw,sasdata,0);

/*NO REPETIR MISMO NUMERO/RUT CON DIF TIPO_INHIBICION ? (CAR/BANCO) */

/* 	------------------ SEPARADO - MEJORAR ------------------- */
PROC SQL;
	CREATE TABLE PUBLICIN.NOTCALL_RUT/*publicin.NOTCALL_RUT*/ AS
	SELECT T1.RUT
	FROM PUBLICIN.NOTCALL T1
	WHERE RUT IS NOT MISSING /*AND T1.FONO = '.'*/
;QUIT;


PROC SQL;
   CREATE TABLE PUBLICIN.NOTCALL_FONO/*publicin.NOTCALL_FONO*/ AS 
   SELECT cats(t1.AREA, t1.FONO) AS FONO
      FROM PUBLICIN.NOTCALL t1
      WHERE t1.FONO NOT  = . /*MISSING NOT = '.'*/;
QUIT;

/*-----------  EXPORTAR ARCHIVO -----------------*/

/* archivos a revisar */
proc export data=PUBLICIN.NOTCALL
OUTFILE="/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SERNAC_PARTE_3/NOTCALL.CSV"
 dbms=dlm REPLACE;
 delimiter=',';
 PUTNAMES=yes;
RUN;

proc export data=PUBLICIN.NOTCALL_RUT
  OUTFILE="/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SERNAC_PARTE_3/NOTCALL_RUT.CSV"
 dbms=dlm REPLACE;
 delimiter=',';
 PUTNAMES=yes;
RUN;

proc export data=PUBLICIN.NOTCALL_FONO
  OUTFILE="/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SERNAC_PARTE_3/NOTCALL_FONO.CSV"
 dbms=dlm REPLACE;
 delimiter=',';
 PUTNAMES=yes;
RUN;



/*__________________________________________________________________*/

/*------------------------------- 	MACRO FECHAS	 ------------------------------		*/
DATA _null_;
V_inicioActual  = input(put(intnx('month',today(),0,'begin' ),DATE9.),$10.);
V_terminoActual = input(put(today()-1,Date9.),$10.);
mes_actual  = input(put(intnx('month',today(),0,'end' ),yymmn6.),$10.);
iniciomes_dt  = compress(input(put(intnx('month',today(),0,'begin' ),date9.),$20.),"-",c);

Call symput("inimes",iniciomes_dt);
Call symput("iniciomes",V_inicioActual);
Call symput("finmes",V_terminoActual);
Call symput("mes_actual",mes_actual);
RUN;

%put &iniciomes; 
%put &finmes;
%put &mes_actual;
%put &inimes;
RUN;
DATA _null_;
date = put(today(),date10.);
Call symput("fecha", date);
RUN;
%put &fecha;
proc sql;
create table NOTCALL_NOVEDADES_&mes_actual as
select t1.*
from publicin.notcall t1
WHERE T1.fecha_solicitud >= "&inimes."d
;quit;



PROC SQL;
   CREATE TABLE RESULT.NOTCALL_NOVEDADES_&mes_actual AS 
   SELECT t1.RUT, 
          t1.AREA, 
          t1.FONO, 
          t1.FECHA_SOLICITUD
      FROM NOTCALL_NOVEDADES_&mes_actual t1;
QUIT;


	 
	  /*-----------  EXPORTAR ARCHIVO -----------------*/

/* archivos a revisar */
proc export data=RESULT.NOTCALL_NOVEDADES_&mes_actual
  OUTFILE="/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SERNAC_PARTE_3/NOTCALL_NOVEDADES_&mes_actual"
/*  OUTFILE="/sasdata/users94/ougarte/temp/NOTCALL_NOVEDADES_&mes_actual"*/
 dbms=dlm REPLACE;
 delimiter=',';
 PUTNAMES=yes;
RUN;

/* archivos a revisar RUC */

/* EXPORTAR DE SAS A UN FTP O SFTP */ 
       filename server ftp 'LISTA_NO_LLAMAR_CALL.CSV' CD='/inhibir-telefonos/' 
       HOST='192.168.10.155' user='ruc' pass='Bripley.2018' PORT=5560;

data _null_;
     infile '/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SERNAC_PARTE_3/NOTCALL.CSV';
       file server;
       input;
       put _infile_;
run;


/* AUTOMATIZACION PARA AREA REA CONTROL Y GESTION DE CLIENTES*/

/* EXPORTAR DE SAS A UN FTP O SFTP */ 
       filename server ftp 'NOTCALL.CSV' CD='.' 
       HOST='192.168.82.170' user='169513333' pass='169513333' PORT=21;

data _null_;
       infile '/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SERNAC_PARTE_3/NOTCALL.CSV';
       file server;
       input;
       put _infile_;
run;
/* EXPORTAR DE SAS A UN FTP O SFTP */ 
       filename server ftp 'NOTCALL_RUT.CSV' CD='.' 
       HOST='192.168.82.170' user='169513333' pass='169513333' PORT=21;

data _null_;
       infile '/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SERNAC_PARTE_3/NOTCALL_RUT.CSV';
/*	   infile '/sasdata/users94/ougarte/temp/NOTCALL_RUT.CSV';*/
       file server;
       input;
       put _infile_;
run;
/* EXPORTAR DE SAS A UN FTP O SFTP */ 
       filename server ftp 'NOTCALL_FONO.CSV' CD='.' 
       HOST='192.168.82.170' user='169513333' pass='169513333' PORT=21;

data _null_;
       infile '/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SERNAC_PARTE_3/NOTCALL_FONO.CSV';
/*       infile '/sasdata/users94/ougarte/temp/NOTCALL_FONO.CSV';*/
       file server;
       input;
       put _infile_;
run;


/* EXPORTAR DE SAS A UN FTP O SFTP */ 
       filename server ftp 'NOTCALL.CSV' CD='/AurisFtp/Archivos/BI_CCR_NOT_CALL' 
       HOST='192.168.80.15' user='aurisftp' pass='ripley2019' PORT=21;

data _null_;
       infile '/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SERNAC_PARTE_3/NOTCALL.CSV';
       file server;
       input;
       put _infile_;
run;


/* archivos a revisar */
proc export data=PUBLICIN.LNEGRO_EMAIL
  OUTFILE="/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SERNAC_PARTE_3/LNEGRO_EMAIL.CSV"
/*  OUTFILE="/sasdata/users94/ougarte/temp/NOTCALL_NOVEDADES_&mes_actual"*/
 dbms=dlm REPLACE;
 delimiter=',';
 PUTNAMES=yes;
RUN;

/* EXPORTAR DE SAS A UN FTP O SFTP */ 
       filename server ftp 'LNEGRO_EMAIL.CSV' CD='/AurisFtp/Archivos/BI_CCR_NOT_CALL' 
       HOST='192.168.80.15' user='aurisftp' pass='ripley2019' PORT=21;

data _null_;
       infile '/sasdata/users94/user_bi/SERNAC_NO_MOLESTAR/SERNAC_PARTE_3/LNEGRO_EMAIL.CSV';
       file server;
       input;
       put _infile_;
run;

/*=========================================================================================*/
/*=======================       FECHA PROCESO Y ENVÍO DE EMAIL      =======================*/

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
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

SELECT EMAIL into :DEST_3 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'RODRIGO_BUGUENO';

SELECT EMAIL into :DEST_4 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'CRISTIAN_ECHEVERRIA';

SELECT EMAIL into :DEST_5 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'MARTA_GONZALEZ';

SELECT EMAIL into :DEST_6 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'MICHAEL_VARGAS';

SELECT EMAIL into :DEST_7 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'RODRIGO_MENA';

SELECT EMAIL into :DEST_8 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'ERIK_SANHUEZA';

SELECT EMAIL into :DEST_9
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'CAROLINA_VILLARROEL';

SELECT EMAIL into :DEST_10
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JAIME_MARTINEZ';

SELECT EMAIL into :DEST_11
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JHON_BAEZA';

SELECT EMAIL into :DEST_12
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CONTACTABILIDAD';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;
%put &=DEST_5;
%put &=DEST_6;
%put &=DEST_7;
%put &=DEST_8;
%put &=DEST_9;
%put &=DEST_10;
%put &=DEST_11;
%put &=DEST_12;


data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO 	 = ("&DEST_3", "&DEST_4","&DEST_5", "&DEST_6")
CC   = ("&DEST_1", "&DEST_2", "&DEST_12")
SUBJECT="MAIL_AUTOM: Base NOTCALL y LNEGRO EMAIL depositados en FTP" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "        Base NOTCALL y LNEGRO EMAIL depositados en FTP, con fecha: &fechaeDVN";  
 put ; 
 PUT "        Rutas: /AurisFtp/Archivos/BI_CCR_NOT_CALL/NOTCALL.csv"; 
 PUT "				 /AurisFtp/Archivos/BI_CCR_NOT_CALL/LNEGRO_EMAIL.csv"; 
put ; 
put ; 
PUT ;
put ; 
PUT 'Saludos Cordiales.';
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;


data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO 	 = ("&DEST_7")
CC   = ("&DEST_1", "&DEST_2", "&DEST_12")
SUBJECT="MAIL_AUTOM: Base NOTCALL actualizada en SAS" ;
FILE OUTBOX;
PUT 'Estimado:';
PUT ; 
 put "        Base NOTCALL actualizada en SAS, con fecha: &fechaeDVN";  
 put ; 
 PUT "        Librería: publicin.LNEGRO_CALL"; 
put ; 
put ; 
PUT ;
put ; 
PUT 'Saludos Cordiales.';
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;


data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO 	 = ("&DEST_9","&DEST_10")
CC   = ("&DEST_1", "&DEST_2", "&DEST_12")
SUBJECT="MAIL_AUTOM: Base LISTA_NO_LLAMAR_CALL actualizada en SAS" ;
FILE OUTBOX;
PUT 'Estimado:';
PUT ; 
 put "        Proceso Base LISTA_NO_LLAMAR_CALL se encuentra cargada en FTP/RUC, con fecha: &fechaeDVN";  
 put ; 
 PUT ;        
put ; 
put ; 
PUT ;
put ; 
PUT 'Saludos Cordiales.';
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT;
RUN;
FILENAME OUTBOX CLEAR;




data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO 	 = ("&DEST_8","&DEST_11")
CC   = ("&DEST_1", "&DEST_2","&DEST_12")
SUBJECT="MAIL_AUTOM: Base NOTCALL actualizada en SAS" ;
FILE OUTBOX;
PUT 'Estimado:';
PUT ; 
 put "        Proceso Bases NOTCALL se encuentran cargadas en FTP , ejecutado con fecha: &fechaeDVN";  
 put ; 
 PUT;         
 put ; 
 put ; 
 PUT ;
 put ; 
PUT 'Saludos Cordiales.';
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 



