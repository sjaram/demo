/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================      BASE_NOMBRES				  	 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-11-16 -- V03 -- Sergio J.  -- Cambio en nombre de la tabla en AWS a sas_ctbl_base_nombres
/* 2022-11-04 -- V02 -- Sergio J.  -- Nueva forma de exportar a AWS
*/

%macro principal();
 
%LET NOMBRE_PROCESO = 'Base_Nombres';

%let mz_connect_borlg=CONNECT TO ORACLE as borlg(USER='ruc' PASSWORD='rucrip1311'
PATH=" 
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = reporteslegales-bd.bancoripley.cl)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = borlg)
      (INSTANCE_NAME = borlg)
    )
  )
");



proc sql; 
&mz_connect_borlg; 
create table BASE_NOMBRES_SINACOFI as 
select   RUT,
(UPPER(SUBSTR(NOMBRE,ANYALPHA(NOMBRE),INDEX(SUBSTR(NOMBRE,ANYALPHA(NOMBRE)),' ')))) AS PRIMER_NOMBRE, 
(UPPER(NOMBRE)) AS NOMBRES, 
(UPPER(AP_PATERNO)) AS PATERNO, 
(UPPER(AP_MATERNO)) AS MATERNO,
FECH_NAC, 
 GENERO
from  connection to borlg(
select * from VERGARAM.data_sinacofi)
;QUIT;


%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SQL;
CREATE TABLE CALCULA_DV AS
SELECT *,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),1,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),1,1),BEST32.) END AS DIG1,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),2,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),2,1),BEST32.) END AS DIG2,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),3,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),3,1),BEST32.) END AS DIG3,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),4,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),4,1),BEST32.) END AS DIG4,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),5,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),5,1),BEST32.) END AS DIG5,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),6,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),6,1),BEST32.) END AS DIG6,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),7,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),7,1),BEST32.) END AS DIG7,
CASE WHEN INPUT(SUBSTR(put(a.rut,best8.),8,1),BEST32.)=. THEN 0 
      ELSE INPUT(SUBSTR(put(a.rut,best8.),8,1),BEST32.) END AS DIG8
FROM BASE_NOMBRES_SINACOFI A
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SQL;
CREATE TABLE SINACOFI_DV AS
SELECT RUT,
CASE 
WHEN 11-(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)-
            (INT(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)/11)*11))=11 THEN '0'
WHEN 11-(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)-
            (INT(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)/11)*11))=10 THEN 'K'
ELSE PUT(11-(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)-
            (INT(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)/11)*11)),BEST1.) END AS DV,
			PRIMER_NOMBRE,
			NOMBRES,
			PATERNO,
			MATERNO
FROM CALCULA_DV;
QUIT;


%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SQL;
CONNECT TO ORACLE as itf(PATH='REPORITF.WORLD' USER='SAS_USR_BI' PASSWORD='SAS_23072020'/*USER='EPIELH' PASSWORD= 'EPIE#_1116'*/);
   CREATE TABLE NOM_ITF AS 
   select  * from connection to itf (
   SELECT CAST(A.PEMID_GLS_NRO_DCT_IDE_K AS INT) AS RUT, 
          A.PEMID_DVR_NRO_DCT_IDE AS DV, 
          B.PEMNB_GLS_NOM_PEL AS NOMBRES,
          B.PEMNB_GLS_APL_PAT AS PATERNO, 
          B.PEMNB_GLS_APL_MAT AS MATERNO,
              A.PEMID_NRO_INN_IDE AS ID
      FROM BOPERS_MAE_IDE A 
 INNER JOIN BOPERS_MAE_NAT_BSC B ON A.PEMID_NRO_INN_IDE = B.PEMID_NRO_INN_IDE_K
 WHERE  B.PEMNB_GLS_APL_PAT NOT IN ('REGISTRADO''V','X','x','.','LL','PROBE',
'PROBE','PROBE','PROBE','PRUEBA','CUENTA','A','AA','AAA','AAAA','ŽŽŽ') 
AND B.PEMNB_GLS_APL_MAT NOT IN ('X','XX')
AND B.PEMNB_GLS_APL_MAT NOT LIKE ('%XX%')
 AND B.PEMNB_GLS_NOM_PEL NOT IN('Xxx','XXX','XxX''SEBASTI¿N','xx','x','xxx','XXXX','ZZZZZZZZZZZZZZZZZZZ',
'.','XXXXX','xd','SFBFGR','XMAGDALENA','Nombre/Razon Soci','SS','?','¿','KLKLZ','BB','CCC','FD','VV',
'XMARIA','XLINDA','XD''z','XZ','ZX','AA PATRICIA','AALEJANDRA','AALVARO','ABD¿N REN¿','PRUEBA','AA PATRICIA','ZXXZZXZX',
'ZZZZZZZZZZZZZZZZZZZ','PRUEBAS','SEGUROS','PRUEBAII','RUT PRUEBA2','RUT PRUEBA1','CCC','ZXZXZX','EE','SSS',
'A','AA','AAA','AAAA','500MARIO','ZX','ZXXZZXZX','ŽŽ','ZZZ','.','AAAAAAAAAAAAAAAA','FJ?L?','SERCOM','FJ?L?','INTERNET',
'ELBA ESMERITA','.AIDA ALEJANDRA','.ANA MYRIAM','.EDITH DE LAS MER','500MARIO','AAAAAAAAAAAAAAAA','NOMBRE RAZON SOCI',
 'NOMBRE/RAZON SOCI', 'RAZON', 'NOMBRE/RAZON SOCI')
)A
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_SINACOFI_DV AS 
   SELECT t1.RUT, 
          t1.DV, 
		  t1.PRIMER_NOMBRE,
          t1.NOMBRES, 
          t1.PATERNO, 
          t1.MATERNO
      FROM WORK.SINACOFI_DV t1
UNION 
   SELECT t2.RUT, 
          t2.DV, 
		  (UPPER(SUBSTR(t2.NOMBRES,ANYALPHA(t2.NOMBRES),INDEX(SUBSTR(t2.NOMBRES,ANYALPHA(t2.NOMBRES)),' ')))) AS PRIMER_NOMBRE,
          t2.NOMBRES, 
          t2.PATERNO, 
          t2.MATERNO
      FROM NOM_ITF T2 WHERE t2.RUT NOT IN (SELECT RUT FROM WORK.SINACOFI_DV)
;
QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;

PROC SQL;
	CREATE TABLE publicin.BASE_NOMBRES AS
	SELECT *
	FROM WORK.QUERY_FOR_SINACOFI_DV
;QUIT;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


%exit:

%put &syserr;
%put &FECHA_DETALLE; 
%let error = &syserr;
%put &error;

data _null_;
FECHA_PROCESO=cat((put(intnx('month',TODAY(),0,'same'),yymmdd10.)) ,"  " , (put(intnx('month',timepart(TIME()),0,'same'),hhmm8.2)) );
call symput("FECHA_DETALLE",FECHA_PROCESO);
run;


proc sql ;
select infoerr 
into : infoerr 
from result.TBL_DESC_ERRORES
where error=&error;
quit;


%let FEC_DET = "&FECHA_DETALLE";
%LET DESC = "&infoerr";  


	  proc sql ;
	  INSERT INTO result.tbl_estado_proceso
	  VALUES ( &error, &DESC, &FEC_DET , &NOMBRE_PROCESO );
	  quit;
   %put inserta el valor syserr &syserr y error &error;


%mend;

%principal();

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(sas_ctbl_base_nombres,raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(sas_ctbl_base_nombres,publicin.BASE_NOMBRES,raw,sasdata,0);
