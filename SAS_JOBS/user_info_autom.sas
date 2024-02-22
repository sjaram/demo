/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	user_info_autom					 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-07-01 -- V03 -- David V.	-- Actualización password nuevo backend pwa + correo area digital bi
   26-05-2022 -- V02 -- Esteban P.	-- Se modifica el nombre del campo EmailNuevo por email, debido a que 
									   otro proceso lo necesita	con ese nombre (EMAIL_AUTOM).
   24-05-2022 -- V01 -- Sergio  J.	-- Modificación aagregando query de validación al correo. 
   20-05-2022 -- V00 -- Esteban P.	-- Modificación original
*/

/* INFORMACIÓN:
	Programa que tiene como objetivo rescatar la información de la tabla "UpdateUserInfo" 
	y de la vista "UpdateUserInfoView", que se encuentra en data-logs-prod, 
	bajo el esquema de "dbo" para finalmente almacenarla en..

 */

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

options validvarname=any;

/* --- Asignamos la librería en la que almacenaremos la información. --- */
%let libreria=RESULT;
/* --- String de conexión a la BD y asignamos librería. --- */
LIBNAME libbehb ODBC DATASRC="BR-BACKENDHB" SCHEMA=dbo USER="ripley-bi" PASSWORD="biripley00";

/* --- Rescatamos la información de la tabla y la vista con la información de USER INFO. --- */
proc sql;
connect to ODBC as myconn (user="ripley-bi" password="biripley00" DATASRC="BR-BACKENDHB");
create table USER_INFO_TABLA as
select * from libbehb.UpdateUserInfo;
disconnect from myconn;
quit;

proc sql;
connect to ODBC as myconn (user="ripley-bi" password="biripley00" DATASRC="BR-BACKENDHB");
create table USER_INFO_VISTA as
select * from libbehb.UpdateUserInfoView;
disconnect from myconn;
quit;

PROC SQL;
CREATE TABLE WORK.USER_INFO_AYER AS
SELECT /* Cantidad_Registros */
(COUNT(RUT)) AS Cantidad_Registros,
/* Fecha_Maxima */
(MAX(CreatedAt)) AS Fecha_Maxima
FROM RESULT.USER_INFO
;QUIT;

proc sql;
create table &libreria..USER_INFO as
SELECT B.ID, B.RUT AS RUT LENGTH=12, B.EMAILNUEVO as email LENGTH=50 , B.TOKEN AS TOKEN LENGTH=32,
B.DISPOSITIVO AS DISPOSITIVO LENGTH=10,
A.CREATED_AT, put(datepart(A.CREATED_AT), YYMMDD10.) as CreatedAt,
put(datepart(B.FECHAACTUALIZACION), YYMMDD10.) as UpdatedAT
FROM USER_INFO_TABLA A
INNER JOIN USER_INFO_VISTA B
ON (A.ID=B.ID);
quit;

PROC SQL;
CREATE TABLE WORK.USER_INFO_HOY AS
SELECT /* Cantidad_Registros */
(COUNT(RUT)) AS Cantidad_Registros,
/* Fecha_Maxima */
(MAX(CreatedAt)) AS Fecha_Maxima
FROM RESULT.USER_INFO;
QUIT;

PROC SQL;
CREATE TABLE QUERY_FOR_USER_INFO AS
SELECT * FROM WORK.USER_INFO_AYER
OUTER UNION CORR
SELECT * FROM WORK.USER_INFO_HOY;
QUIT;

/*==================================================================================================*/
/*==================================    EQUIPO DATOS Y PROCESOS     ================================*/
/*  VARIABLE TIEMPO - FIN   */
data _null_;
    dur = datetime() - &tiempo_inicio;
    put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;
/*==================================    FECHA DEL PROCESO           ================================*/
data _null_;
    execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
    Call symput("fechaeDVN", execDVN);
RUN;
%put &fechaeDVN;
/*==================================    EMAIL CON CASILLA VARIABLE  ================================*/
proc sql noprint;
    SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
    SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
    SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CONTACTABILIDAD';
quit;
%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;

data _null_;
    FILENAME output EMAIL
        FROM = ("&EDP_BI")
        TO = ("&DEST_4")
		CC = ("&DEST_1", "&DEST_2", "&DEST_3")
        SUBJECT = ("MAIL_AUTOM: Proceso user_info_autom")
CT= "text/html" /* Required for HTML output */ ;
	FILENAME mail EMAIL 
 	SUBJECT="HTML OUTPUT" CONTENT_TYPE="text/html";
	ODS LISTING CLOSE;
	ODS HTML  path="/sasdata/users94/user_bi" file = "USER_INFO_AUTOM.lst" (URL=none) BODY=output STYLE=sasweb;
	TITLE JUSTIFY=left;
PROC PRINT DATA=WORK.QUERY_FOR_USER_INFO NOOBS;
RUN;
ODS HTML CLOSE;
ODS LISTING;
