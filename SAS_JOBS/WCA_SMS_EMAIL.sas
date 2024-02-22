/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================    EAD_SEGUIMIENTO_PROCESOS	================================*/
/* CONTROL DE VERSIONES
/* 2022-11-03 -- v02 -- Sergio J.-- Se actualizar export a AWS, según nuevas definiciones a RAW.


/*	--------------------	FILTRO PARA PRE-ENVÍO DE EMAILS  	-------------------------  */
PROC SQL;
	CREATE TABLE WORK.CAR_EMAIL AS
	SELECT DISTINCT T1.RUT,
			T2.EMAIL
	FROM PUBLICIN.LNEGRO_CAR T1
		INNER JOIN RESULT.EMAIL_UNIDOS T2 ON (T1.RUT=T2.RUT)
		WHERE t1.TIPO_INHIBICION IN 
           ('SERNAC','SERNAC_BCO','AURIS') 
AND t1.CANAL_RECLAMO IN ('AURIS','SERNAC','SERNAC_BCO')
	
;QUIT;
/*	206.228	  
553
14140 14142*/

PROC SQL;
	CREATE TABLE WORK.EMAIL_TODOS AS
	SELECT T1.RUT,
		UPCASE(COMPRESS(t1.EMAIL)) AS EMAIL
	FROM PUBLICIN.LNEGRO_EMAIL T1
	 WHERE t1.MOTIVO IN 
           (
           'AURIS',
           'SERNAC',
           'SERNAC_BCO',
           'SERNAC_CAR',
           'SERNAC_ECCSA',
           'SERNAC_ECSSA',
           'SERNAC_SEG',
           'SERNAC_SEGUROS',
		   'NO_COMUNICACION'
           )
UNION
	SELECT T2.RUT,
		UPCASE(COMPRESS(t2.EMAIL)) AS EMAIL
	FROM WORK.CAR_EMAIL T2
;QUIT;
/*	224.574	*/

/*-------*/
PROC SQL;
	CREATE TABLE WORK.NUEVOS AS
	SELECT DISTINCT EMAIL
	FROM WORK.EMAIL_TODOS
/*	WHERE UPCASE(COMPRESS(EMAIL)) NOT IN (SELECT UPCASE(COMPRESS(EMAIL)) FROM RESULT.EMAIL_INHIBIR_WCA2)*/
;QUIT;

/*PROC SQL;*/
/*	CREATE TABLE WORK.EMAIL_INHIBIR_WCA2 as*/
/*	SELECT **/
/*	FROM RESULT.EMAIL_INHIBIR_WCA2*/
/*;QUIT;*/

PROC SQL;
CREATE TABLE EMAIL_INHIBIR_WCA2 as 
	SELECT *
	FROM WORK.NUEVOS
;QUIT;

PROC SQL;
   CREATE TABLE WORK.HC AS 
   SELECT t1.EMAIL,
          CASE WHEN t1.EMAIL LIKE ('%@%') THEN 1 ELSE 0 END AS HC
      FROM EMAIL_INHIBIR_WCA2 t1
	  HAVING HC=1
;QUIT;
/*10349*/
PROC SQL;
	CREATE TABLE RESULT.EMAIL_INHIBIR_WCA2 AS
	SELECT DISTINCT EMAIL
	FROM WORK.HC
;QUIT;

/*	--------------------	FILTRO PARA PRE-ENVÍO DE SMS	-------------------------  */
PROC SQL;
   CREATE TABLE WORK.REPO AS 
   SELECT t1.RUT, t1.TELEFONO
      FROM PUBLICIN.REPOSITORIO_TELEFONOS t1
      WHERE t1.TELEFONO >= 900000000
      GROUP BY t1.RUT;
QUIT;

PROC SQL;
   CREATE TABLE WORK.CAR_REPO AS 
   SELECT DISTINCT t1.RUT, 
          56000000000+t1.TELEFONO AS TELEFONO
      FROM WORK.REPO t1
           INNER JOIN PUBLICIN.LNEGRO_CAR t2 ON (t1.RUT = t2.RUT)
WHERE t2.TIPO_INHIBICION IN 
           ('SERNAC','SERNAC_BCO','AURIS')
AND t2.CANAL_RECLAMO IN ('AURIS','SERNAC','SERNAC_BCO')
;
QUIT;

PROC SQL;
   CREATE TABLE WORK.CAR_FONOS AS 
   SELECT DISTINCT t1.RUT,
          56900000000+t2.TELEFONO AS TELEFONO
   FROM PUBLICIN.LNEGRO_CAR t1
   		INNER JOIN PUBLICIN.FONOS_MOVIL_FINAL_SE t2 ON (t1.RUT = t2.CLIRUT)
	WHERE T2.TIPO = 'CE' and t1.TIPO_INHIBICION IN 
           ('SERNAC','SERNAC_BCO','AURIS')
AND t1.CANAL_RECLAMO IN ('AURIS','SERNAC','SERNAC_BCO')
;QUIT;

PROC SQL;
	CREATE TABLE WORK.FONOS_CAR AS
	SELECT RUT,
		TELEFONO
	FROM WORK.CAR_FONOS T1
UNION
	SELECT RUT,
		TELEFONO
	FROM WORK.CAR_REPO T2
;QUIT;

PROC SQL;
	CREATE TABLE WORK.LNSMS AS
	SELECT RUT,
			56900000000+T1.FONO AS TELEFONO
	FROM PUBLICIN.LNEGRO_SMS T1
;QUIT;

PROC SQL;
	CREATE TABLE WORK.FONOS_INHIBIR_SMS AS
	SELECT *
	FROM WORK.FONOS_CAR
UNION
	SELECT *
	FROM WORK.LNSMS
;QUIT;
/*243233*/
PROC SQL;
	CREATE TABLE RESULT.FONOS_INHIBIR_SMS2 AS
	SELECT *
	FROM WORK.FONOS_INHIBIR_SMS
;QUIT;

/** archivos a revisar */
proc export data=RESULT.EMAIL_INHIBIR_WCA2
 OUTFILE="/sasdata/users94/user_bi/unica/input/INPUT-EMAIL_WCA_REV-AUT.CSV"
 dbms=dlm REPLACE;
 delimiter=',';
 PUTNAMES=yes;
RUN;


%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(input_lnegro_email,pre-raw,oracloud/campaign,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(input_lnegro_email,result.email_inhibir_wca2,pre-raw,oracloud/campaign,0);

/* archivos a revisar */
proc export data=RESULT.FONOS_INHIBIR_SMS2
 OUTFILE="/sasdata/users94/user_bi/unica/input/INPUT-FONOS_SMS_REV-AUT.CSV"
 dbms=dlm REPLACE;
 delimiter=',';
 PUTNAMES=yes;
RUN;


%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(input_lnegro_sms,pre-raw,oracloud/campaign,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(input_lnegro_sms,result.fonos_inhibir_sms2,pre-raw,oracloud/campaign,0);



/*ENVIO DE EMAIL DE AVISO PROCESO TERMINADO*/

/*	Fecha ejecución del proceso	*/
data _null_;
execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechaeDVN", execDVN) ;
RUN;
%put &fechaeDVN;/*fecha ejecucion proceso */



data _null_;
FILENAME OUTBOX EMAIL
FROM = ("sjaram@bancoripley.com")
TO = ("sjaram@bancoripley.com","dvasquez@bancoripley.com","solivas@bancoripley.com")
SUBJECT="MAIL_AUTOM: PROCESO WCA_SMS_EMAIL  %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso Bases FONOS_INHIBIR_SMS_REV.CSV Y EMAIL_INHIBIR_WCA_REV.CSV se encuentran cargadas en FTP , ejecutado con fecha: &fechaeDVN";  
 put ; 
 put ; 
 put ; 
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

