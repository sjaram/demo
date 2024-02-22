/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	VENTA_SEGUROS_REAL				 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-07-11 -- V04 -- Sergio J. --  
					 -- Se agrega código de exportación para alimentar a Tableau
/* 2022-07-04 -- V03 -- David V.	 
					 -- Actualización password nuevo backend pwa + correo area digital bi
/* 2022-03-31 -- V02 -- Esteban P.-- 
					 -- Se actualizan los correos eliminando a Edmundo de los destinatarios.
/* 2021-04-23 -- V01 -- Edmundo P.--  
					 -- Versión Original

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

LIBNAME libbehb ODBC  DATASRC="BR-BACKENDHB"  SCHEMA=dbo  USER="ripley-bi"  
	PASSWORD="biripley00"; 


	LIBNAME QANEWHB ORACLE  PATH="QANEW.WORLD"  SCHEMA=HBPRI_ADM  USER=RIPLEYC  PASSWORD='ri99pley';


		/*matriz de variables macro*/
		DATA _null_;
		datemy0 = input(put(intnx('month',today(),0,'BEGIN'),yymmn6. ),$10.);
		datemy10 = input(put(intnx('month',today(),-10,'BEGIN'),yymmn6. ),$10.);
		datemy11 = input(put(intnx('month',today(),-11,'BEGIN'),yymmn6. ),$10.);
		datemy12 = input(put(intnx('month',today(),-12,'BEGIN'),yymmn6. ),$10.);
		datemy13 = input(put(intnx('month',today(),-13,'BEGIN'),yymmn6. ),$10.);
	    dated0 = input(put(intnx('month',today(),0,'SAME'),date9. ),$10.) ;
	    dated00 = input(put(intnx('month',today(),0,'BEGIN'),date9. ),$10.) ;
	    dated1 = input(put(intnx('month',today(),-1,'BEGIN'),date9. ),$10.) ;
	    dated2 = input(put(intnx('month',today(),-2,'BEGIN'),date9. ),$10.) ;
	    dated13 = input(put(intnx('month',today(),-14,'BEGIN'),date9. ),$10.) ;
		datey1 = input(put(intnx('month',today(),-1,'BEGIN'),year. ),best.)  ;

		Call symput("fechamy0", datemy0);
			Call symput("fechamy1", datemy1);


		
		Call symput("fechad0", dated0);
		Call symput("fechad00", dated00);
		Call symput("fechad1", dated1);
		Call symput("fechad2", dated2);
		     Call symput("fechad13", dated13);
		RUN;

		%put &fechamy0;
		%put &fechad1;
		%put &fechad0;
		%put &fechamy13;


PROC SQL;
   CREATE TABLE hb_app_antes AS 
   SELECT  INPUT((SUBSTR(HDVOU_NOM_NOM_USR,1,(LENGTH(HDVOU_NOM_NOM_USR)-1))),BEST.) as rut,
           HDVOU_MNT_MNT_PAG as monto,
           
           CASE WHEN  t1.HDVOU_COC_TOP_IDE = 'CASH_ADVANCE' then 'AV'
           WHEN  t1.HDVOU_COC_TOP_IDE = 'SUPER_CASH_ADVANCE' then 'SAV'
           END AS PRODUCTO,
           CASE WHEN t1.HDVOU_COC_CNL NOT LIKE ('85') then 'HB'
           WHEN t1.HDVOU_COC_CNL= '85' then 'APP_1'	
           END AS canal,
		   input(put(datepart(HDVOU_FCH_CPR),date9.),date9.) format=date9. as fecha,
		   0 AS PRECIOSEGURO,
		   10000000+MONOTONIC() AS CORR
      FROM QANEWHB.HBPRI_HIS_DET_VOU t1
WHERE 'x'='x'
and datepart(t1.HDVOU_FCH_CPR) >= "&fechad1"D
having producto is not null

 


;
QUIT;

PROC SQL;
   CREATE TABLE WORK.PWA_AVSAVVOUCHERVIEW AS 
   SELECT   input(substr(t1.RUT,1,length(t1.RUT)-1),best.) AS RUT, 
        t1.Montoliquido as monto,
          t1.PRODUCTO, 
		  
 CASE WHEN t1.DISPOSITIVO ='App' then 'APP' 
else upcase(t1.DISPOSITIVO) end as  CANAL,

          datepart(t1.FECHACURSE) format=date9. as fecha, 
          t1.PRECIOSEGURO,
MONOTONIC() AS CORR
      FROM libbehb.AVSAVVOUCHERVIEW t1
where t1.FECHACURSE >= "&fechad1"d ;
QUIT;


PROC SQL;
   CREATE TABLE work.VENTA_INTERNET_ANIO_MOV AS 
 select *
FROM hb_app_antes t1

OUTER UNION CORR

 select *
FROM PWA_AVSAVVOUCHERVIEW t1




;
QUIT;


/*OFERTA AVANCE*/

PROC SQL;
CREATE TABLE work.avance AS
SELECT A.RUT_REGISTRO_CIVIL,A.CODENT,A.CENTALTA,A.CUENTA,a.DISP_51_FINAL AS MONTO_OFERTA_AV

FROM kmartine.avance_&fechamy0 as a

		
;QUIT;



/* OFERTA SUPER AVANCE*/

PROC SQL;
CREATE TABLE SAV_CAR_&fechamy0 AS
SELECT RUT_REAL,MONTO_PARA_CANON
FROM JABURTOM.SAV_CAR_&fechamy0
WHERE SAV_APROBADO_FINAL =1

; 
QUIT;



PROC SQL;
   CREATE TABLE PUBLICIN.VENTA_CRUCE_SEGUROS AS 
   SELECT A.*,
   B.MONTO_PARA_CANON AS MONTO_SAV,
   C.MONTO_OFERTA_AV AS MONTO_AV,
   CASE WHEN A.RUT = B.RUT_REAL THEN 1 ELSE 0 END AS SAV_&fechamy0,
   CASE WHEN A.RUT = C.RUT_REGISTRO_CIVIL THEN 1 ELSE 0 END AS AV_&fechamy0

      FROM work.VENTA_INTERNET_ANIO_MOV AS A 
	  LEFT JOIN SAV_CAR_&fechamy0 AS B ON (A.RUT = B.RUT_REAL)
      LEFT JOIN work.avance AS C  ON (A.RUT = C.RUT_REGISTRO_CIVIL)
;QUIT;

/* export data csv */
proc export data=publicin.VENTA_CRUCE_SEGUROS
outfile="/sasdata/users94/user_bi/ORACLOUD/SGRS_VENTA_CRUCE_SEGUROS.csv"
dbms=dlm
replace;
delimiter="|";
quit;


proc sql NOPRINT;
 connect using oracloud; 
 execute by oracloud ( drop table epielh_VENTA_CRUCE_SEGUROS ); 
disconnect from oracloud;
run;
 
 
proc sql NOPRINT; 
connect using oracloud; 
create table oracloud.epielh_VENTA_CRUCE_SEGUROS as 
select * from PUBLICIN.VENTA_CRUCE_SEGUROS;  
disconnect from oracloud;
run;


/* S3 */
/*PROC S3 config="/sasdata/users94/user_bi/TRASPASO_DOCS/.tks3.conf";*/
/*PUT "/sasdata/users_BI/PUBLICA_IN/VENTA_CRUCE_SEGUROS.sas7bdat" "s3://br-dm-prod-us-east-1-837538682169-sas-backup/bigdata/sas/VENTA_CRUCE_SEGUROS.sas7bdat";*/
/*LIST "s3://br-dm-prod-us-east-1-837538682169-sas-backup/bigdata/sas/";*/
/*run;*/

/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
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
SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_DIGITAL';
SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_DIGITAL_1';
SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SUBGERENT_CNL_DIGITAL';
SELECT EMAIL into :DEST_7 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SUBG_BI';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;
%put &=DEST_6;	%put &=DEST_7;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO 	 = ("&DEST_4", "&DEST_5","&DEST_6","&DEST_7")
CC 	 = ("&DEST_1", "&DEST_2","&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso VENTA_SEGUROS_REAL");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "        Proceso VENTA_SEGUROS_REAL, ejecutado con fecha: &fechaeDVN";  
 PUT "        Información disponible en Oracloud y SAS: PUBLICIN.VENTA_CRUCE_SEGUROS";  
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

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
