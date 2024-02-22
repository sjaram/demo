/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*================================= 	LOGUEOS_INTERNET_AUTOM_CIERRE	================================*/
/* CONTROL DE VERSIONES
/* 2023-06-01 -- V4 -- Esteban P.	-- Se añade sentencia export a S3.
/* 2021-04-14 -- V3 -- Lucas
					-- Cambio en BD de origen, apuntando a CAMREPORT
/* 2021-04-14 -- V2 -- SYSTEMA
					-- Se apunta a nueva columna por cambio en el origen
/* 2020-01-05 -- V1 -- EDMUNDO P. -- Nueva Versión Automática Equipo Datos y Procesos BI
					-- 
*/


/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio = %sysfunc(datetime()); /* inicio del proceso de conteo*/

	%let mz_connect_HB = CONNECT TO ORACLE as hbpri_adm(USER='RIPLEYC' PASSWORD='ri99pley'
PATH="  (DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))
(CONNECT_DATA = (SID = ripleyc)))");

DATA _null_;
date1 = input(put(intnx('month',today(),-1,'same'),yymmn6. ),$10.);
Call symput("fecha1", date1);
RUN;
%put &fecha1;

 PROC SQL;

CONNECT TO ORACLE AS GESTION (PATH="QANEW.WORLD" USER='ripleyc' PASSWORD='ri99pley');
CREATE TABLE LOGEO_INT_FISA_GESTION AS 
SELECT 
INPUT(LEFT(SUBSTR(LEFT(COMPRESS(COMPRESS(ENLOG_COC_NOM_USR,'.'),'-')),1,LENGTH(LEFT(COMPRESS(COMPRESS(ENLOG_COC_NOM_USR,'.'),'-')))-1)),BEST.) AS RUT,
ENLOG_FCH_CRC as Fecha_Logueo,
PUT(datepart(ENLOG_FCH_CRC),date9.) as fecha,
Tipo_Logueo,
                   PUT(datepart(ENLOG_FCH_CRC),day.) as dia,
	               PUT(datepart(ENLOG_FCH_CRC),month.) as mes,
	               PUT(datepart(ENLOG_FCH_CRC),year.) as anio
FROM CONNECTION TO GESTION(
SELECT 
ENLOG_COC_NOM_USR, 
ENLOG_FCH_CRC, 
case 
when enlog_coc_cnl = '85' then 'APP'
when ENLOG_COC_NOM_USR IS NOT NULL 
AND  ENLOG_GLS_STC_ERR_K IS NULL 
and  ENLOG_NOM_URL LIKE ('%login.handler%') then 'HB' 
end as Tipo_Logueo 
FROM HBPRI_LOG_ENT_LOG 
where TO_NUMBER(TO_CHAR(ENLOG_FCH_CRC,'YYYYMM'))=&fecha1
and (
enlog_coc_cnl = '85' or 
(
ENLOG_COC_NOM_USR IS NOT NULL and 
ENLOG_GLS_STC_ERR_K IS NULL and 
ENLOG_NOM_URL LIKE ('%login.handler%')
)
)
) as A 

;QUIT;

 PROC SQL;
CONNECT TO ORACLE AS CAMREPORT (PATH="BRTEFGESTIONP.WORLD" USER='CAMP_COMERCIAL' PASSWORD='ccomer2409');
CREATE TABLE LOGEO_INT_FISA_CAMREPORT AS 
SELECT 
INPUT(LEFT(SUBSTR(LEFT(COMPRESS(COMPRESS(ENLOG_COC_NOM_USR,'.'),'-')),1,LENGTH(LEFT(COMPRESS(COMPRESS(ENLOG_COC_NOM_USR,'.'),'-')))-1)),BEST.) AS RUT,
ENLOG_FCH_CRC as Fecha_Logueo,
PUT(datepart(ENLOG_FCH_CRC),date9.) as fecha,
Tipo_Logueo,
                   PUT(datepart(ENLOG_FCH_CRC),day.) as dia,
	               PUT(datepart(ENLOG_FCH_CRC),month.) as mes,
	               PUT(datepart(ENLOG_FCH_CRC),year.) as anio
FROM CONNECTION TO CAMREPORT(
SELECT 
ENLOG_COC_NOM_USR, 
ENLOG_FCH_CRC, 
case 
when enlog_coc_cnl = '85' then 'APP'
when ENLOG_COC_NOM_USR IS NOT NULL 
AND  ENLOG_GLS_STC_ERR_K IS NULL 
and  ENLOG_NOM_URL LIKE ('%login.handler%') then 'HB' 
end as Tipo_Logueo 
FROM HBPRI_LOG_ENT_LOG 
where TO_NUMBER(TO_CHAR(ENLOG_FCH_CRC,'YYYYMM'))=&fecha1
and (
enlog_coc_cnl = '85' or 
(
ENLOG_COC_NOM_USR IS NOT NULL and 
ENLOG_GLS_STC_ERR_K IS NULL and 
ENLOG_NOM_URL LIKE ('%login.handler%')
)
)
) as A 

;QUIT;

PROC SQL;
CREATE TABLE WORK.LOGEO_INT_FISA AS
SELECT * FROM WORK.LOGEO_INT_FISA_GESTION
UNION 
SELECT * FROM WORK.LOGEO_INT_FISA_CAMREPORT
;QUIT;


	LIBNAME libbehb ODBC  DATASRC="BR-BACKENDHB"  SCHEMA=dbo  USER="ripley-bi"  PASSWORD="biripley00"; 
	LIBNAME QANEW ORACLE  INSERTBUFF=1000  READBUFF=1000  PATH="QANEW.WORLD"  SCHEMA=RIPLEYC  USER=RIPLEYC  PASSWORD='ri99pley' ;
	

	/*matriz de variables macro*/
		DATA _null_;
		datemy0 = input(put(intnx('month',today(),-1,'BEGIN'),yymmn6. ),$10.);
		datemy1 = input(put(intnx('month',today(),-1,'BEGIN'),yymmn6. ),$10.);
	    dated0 = input(put(intnx('month',today(),-1,'SAME'),date9. ),$10.) ;
	    dated00 = input(put(intnx('month',today(),-1,'BEGIN'),date9. ),$10.) ;
	    dated01 = input(put(intnx('month',today(),-1,'END'),date9. ),$10.) ;

		Call symput("fechamy0", datemy0);
		Call symput("fechad00", dated00);
		Call symput("fechad01", dated01);
		Call symput("fechamy2", datemy2);
	    Call symput("fechamy3", datemy3);
		RUN;
		%put &fechad00;
		%put &fechad01;

PROC SQL;   
   CREATE TABLE WORK.PWA_LOGIN  AS
   SELECT DISTINCT
   INPUT(LEFT(SUBSTR(LEFT(COMPRESS(COMPRESS(t1.RUT,'.'),'-')),1,LENGTH(LEFT(COMPRESS(COMPRESS(t1.RUT,'.'),'-')))-1)),BEST.) AS SESSIONRUT,
  datepart(T1.CreatedAt) format=date9. AS fecha,
  year(datepart(T1.CreatedAt)) as anio,
  month(datepart(T1.CreatedAt)) as mes,
      case when upcase(T1.dispositivo) like '%APP%' then 'APP'
           when T1.dispositivo is null then 'APP'
else T1.dispositivo end AS DEVICE ,
(100*year(datepart(T1.CreatedAt))+month(datepart(T1.CreatedAt))) as periodo
                  FROM libbehb.LOGINVIEW T1
      WHERE datepart(T1.CreatedAt) BETWEEN "&fechad00"D and "&fechad01"D
;quit;


PROC SQL;  

 
DATA _null_;
date1 = input(put(intnx('month',today(),-1,'same'),yymmn6. ),$10.);
date2 = input(put(intnx('month',today(),0,'same'),yymmn6. ),$10.);
Call symput("fecha1", date1);
Call symput("fecha2", date2);
RUN;
	%put &fecha1;
	%put &fecha2;

PROC SQL;
   CREATE TABLE publicin.LOGEO_INT_&fecha1 AS 
   SELECT t1.RUT AS RUT, 
		  YEAR(input(t1.FECHA,DATE9.))*10000+MONTH(input(t1.FECHA,DATE9.))*100+DAY(input(t1.FECHA,DATE9.)) AS FECHA,
          input(t1.FECHA,DATE9.) FORMAT=DATE9. AS FECHA_LOGUEO,
		  'APP' AS TIPO_LOGUEO,
          'APP_1' AS DISPOSITIVO
      FROM work.LOGEO_INT_FISA t1
           LEFT JOIN WORK.PWA_LOGIN t2 ON (t1.RUT = t2.SESSIONRUT) AND ( input(t1.FECHA,DATE9.) = t2.fecha)
      WHERE t1.TIPO_LOGUEO = 'APP'
	  AND t2.SESSIONRUT IS NULL

	  UNION

   SELECT t1.SESSIONRUT AS RUT, 
          YEAR(t1.FECHA)*10000+MONTH(t1.FECHA)*100+DAY(t1.FECHA) AS FECHA, 
          t1.fecha FORMAT=DATE9. AS FECHA_LOGUEO, 
          CASE WHEN UPCASE(t1.DEVICE) LIKE '%APP%' THEN 'APP' ELSE 'HB' end AS TIPO_LOGUEO ,
          UPCASE(t1.DEVICE) AS DISPOSITIVO 
      FROM WORK.PWA_LOGIN t1

;
QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_INCREMENTAL_DIARIO.sas";
%INCREMENTAL(sas_dgtl_logueo_int,publicin.LOGEO_INT_&fecha1,raw,sasdata,0);


/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
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
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_SPOS_2';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_DIGITAL';
	SELECT EMAIL into :DEST_7 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_DIGITAL_1';
quit;
%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;
%put &=DEST_6;	%put &=DEST_7;

data _null_; 
 FILENAME OUTBOX EMAIL
 FROM 	 = ("&EDP_BI")
 TO	  	 = ("&DEST_4", "&DEST_5", "&DEST_6", "&DEST_7")
 CC   	 = ("&DEST_1", "&DEST_2", "&DEST_3")
 SUBJECT = ("MAIL_AUTOM: Proceso LOGUEOS_INTERNET_AUTOM_CIERRE");
 FILE OUTBOX;
 PUT "Estimados:";
 PUT "        Proceso Logueos internet diarios, ejecutado automáticamente con fecha: &fechaeDVN";  
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 06'; 
 PUT ;
 PUT ;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
PUT ;
RUN;
