/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	simulaciones_internet_auto_cierre	========================*/
/* CONTROL DE VERSIONES
/* 2023-06-11 -- v04 -- Esteban P. -- Se cambian credenciales de conexión GEDCRE.
/* 2023-03-01 -- V3 -- Esteban P.
					-- Se quita el user de Malvaradou, y se ponen credenciales ocultas via sql.
/* 2021-04-14 -- V2 -- Lucas
					-- Cambio en BD de origen, apuntando a CAMREPORT + Tiempo de ejecución
*/

%let mz_connect_HB = CONNECT TO ORACLE as hbpri_adm(USER='RIPLEYC' PASSWORD='ri99pley'
PATH="  (DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))
(CONNECT_DATA = (SID = ripleyc)))");
LIBNAME MPDT ORACLE  READBUFF=1000  INSERTBUFF=1000  dbmax_text=7025  PATH="REPORITF.WORLD"  SCHEMA=GETRONICS  USER='MALVARADOU' PASSWORD='MALV#_1212';
LIBNAME BOPERS ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=BOPERS_ADM  USER='MALVARADOU' PASSWORD='MALV#_1212';
LIBNAME CAMP ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="BRTEFGESTIONP.WORLD"  SCHEMA=CAMP_ADM  USER=CAMP_COMERCIAL  PASSWORD='ccomer2409';
LIBNAME credito ODBC  DATASRC=creditoprd  SCHEMA=GEDCRE_CREDITO  USER=CONSULTA_CREDITO  PASSWORD='crdt#0806';
/*LIBNAME FIDENS ORACLE  PATH=FIDENS  SCHEMA=FIDENSUSR  USER=msotoau  PASSWORD='mayo2016' ;*/
LIBNAME PSFC1 ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH=PSFC1  SCHEMA=GETRONICS  USER=amarinaoc  PASSWORD='amarinaoc2017' ;
LIBNAME QANEW ORACLE  INSERTBUFF=1000  READBUFF=1000  PATH="QANEW.WORLD"  SCHEMA=RIPLEYC  USER=RIPLEYC  PASSWORD='ri99pley' ;
LIBNAME QANEWHB ORACLE  PATH="QANEW.WORLD"  SCHEMA=HBPRI_ADM  USER=RIPLEYC  PASSWORD='ri99pley';
LIBNAME SFRIES ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=SFRIES_ADM  USER='MALVARADOU' PASSWORD='MALV#_1212';

DATA _null_;
date0 = input(put(intnx('month',today(),0,'same'),yymmn6. ),$10.);
date1 = input(put(intnx('month',today(),-1,'same'),yymmn6. ),$10.);
date2 = input(put(intnx('month',today(),-2,'same'),yymmn6. ),$10.);
date3 = input(put(intnx('month',today(),-3,'same'),yymmn6. ),$10.);
date4 = input(put(intnx('month',today(),-4,'same'),yymmn6. ),$10.);
date5 = input(put(intnx('month',today(),-5,'same'),yymmn6. ),$10.);
datew0 = input(put(intnx('month',today(),0,'same'),date9. ),date9.);
datew1 = input(put(intnx('month',today(),-1,'same'),date9. ),date9.);
datew2 = input(put(intnx('month',today(),-2,'same'),date9. ),date9.);
datew3 = input(put(intnx('month',today(),-3,'same'),date9. ),date9.);
datew4 = input(put(intnx('month',today(),-4,'same'),date9. ),date9.);
datew5 = input(put(intnx('month',today(),-5,'same'),date9. ),date9.);
date6 = input(put(intnx('month',today(),-6,'same'),yymmn6. ),$10.);
date7 = input(put(intnx('month',today(),-7,'same'),yymmn6. ),$10.);
date8 = input(put(intnx('month',today(),-8,'same'),yymmn6. ),$10.);
date9 = input(put(intnx('month',today(),-9,'same'),yymmn6. ),$10.);
date10 = input(put(intnx('month',today(),-10,'same'),yymmn6. ),$10.);
date11 = input(put(intnx('month',today(),-11,'same'),yymmn6. ),$10.);
date12 = input(put(intnx('month',today(),-12,'same'),yymmn6. ),$10.);
date13 = input(put(intnx('month',today(),-13,'same'),yymmn6. ),$10.);

date0x = input(put(intnx('month',today(),0,'same'),date9. ),$10.);
date2x = input(put(intnx('month',today(),-1,'begin'),date9.  ),$10.);
date0xa = input(put(intnx('month',today(),-12,'end'),date9. ),$10.);
date0xaf = input(put(intnx('day',intnx('month',today(),-12,'same'),-1,'same'),date9. ),$10.);
datexxx = input(put(intnx('month',today(),-11,'end'),date9. ),$10.);
date2xa = input(put(intnx('month',today(),-13,'begin'),date9.  ),$10.);


datea = input(put(intnx('year',today(),0,'begin'),date9. ),$10.);
dateb = input(put(intnx('day',today(),-1,'same'),date9. ),$10.);
date2b = input(put(intnx('day',today(),-2,'same'),date9. ),$10.);
dateba = input(put(intnx('month',today(),-12,'begin'),date9. ),$10.);
datebf = input(put(intnx('month',today(),-12,'end'),date9. ),$10.);
datec = input(put(intnx('month',today(),-1,'begin'),date9. ),$10.);
dateca = input(put(intnx('month',today(),-13,'begin'),date9. ),$10.);
datecf = input(put(intnx('month',today(),-13,'end'),date9. ),$10.);
dated = input(put(intnx('month',today(),0,'begin'),date9. ),$10.);
datee = input(put(intnx('year',today(),-1,'begin'),date9. ),$10.);
dateF = input(put(intnx('DAY',intnx('month',today(),-1,'same'),-1,'same'),date9. ),$10.);
datexx = input(put(intnx('month',today(),-2,'begin'),date9. ),$10.);
date6x = input(put(intnx('month',today(),-3,'begin'),date9. ),$10.);
dateg = input(put(intnx('month',today(),-1,'end'),date9. ),$10.);
dateh = input(put(intnx('month',today(),0,'same'),date9. ),$10.);
datei = input(put(intnx('month',today(),-6,'begin'),date9. ),$10.);
datew = input(put(intnx('day',today(),-1,'same'),day. ),$10.);
ano=year(today());

Call symput("fecha0", date0);
Call symput("fecha1", date1);
Call symput("fecha2", date2);
Call symput("fecha3", date3);
Call symput("fecha4", date4);
Call symput("fecha5", date5);
Call symput("fechaw0", datew0);
Call symput("fechaw1", datew1);
Call symput("fechaw2", datew2);
Call symput("fechaw3", datew3);
Call symput("fechaw4", datew4);
Call symput("fechaw5", datew5);
Call symput("fecha6", date6);
Call symput("fecha7", date7);
Call symput("fecha8", date8);
Call symput("fecha9", date9);
Call symput("fecha10", date10);
Call symput("fecha11", date11);
Call symput("fecha12", date12);
Call symput("fecha13", date13);
Call symput("year", ano);

Call symput("fechaa", datea);
Call symput("fechab", dateb);
Call symput("fecha2b", date2b);
Call symput("fechaba", dateba);
Call symput("fechabf", datebf);
Call symput("fechac", datec);
Call symput("fechaca", dateca);
Call symput("fechacf", datecf);
Call symput("fechad", dated);
Call symput("fechae", datee);

Call symput("fechaf", datef);
Call symput("fechag", dateg);
Call symput("fechai", datei);
Call symput("fechaxx", datexx);
Call symput("fechaxxx", datexXx);
Call symput("fecha6x", date6x);
Call symput("fecha0x", date0x);
Call symput("fecha0xaf", date0xaf);
Call symput("fecha2x", date2x);
Call symput("fecha0xa", date0xa);
Call symput("fecha2xa", date2xa);
Call symput("fechaw", datew);
RUN;



proc sql ;
&mz_connect_HB;
create table publicin.simulaciones_sav_av_&fecha1 as
SELECT
INPUT(LEFT(SUBSTR(LEFT(COMPRESS(COMPRESS(ENLOG_COC_NOM_USR,'.'),'-')),1,LENGTH(LEFT(COMPRESS(COMPRESS(ENLOG_COC_NOM_USR,'.'),'-')))-1)),BEST.) AS RUT,
 
          input(put(datepart(t1.ENLOG_FCH_CRC),date9.),date9.) format=date9. as fecha, 
          t1.ENLOG_NOM_URL
from  connection to hbpri_adm(
select		
y.enlog_coc_nom_usr
,ENLOG_FCH_CRC,ENLOG_NOM_URL
FROM HBPRI_LOG_ENT_LOG Y 
WHERE  TO_NUMBER(TO_CHAR(ENLOG_FCH_CRC,'YYYYMM'))= &fecha1
and ENLOG_NOM_URL LIKE '%/avanceYsuperAvance/%'

)t1

;QUIT;


 proc sql ;
&mz_connect_HB;
create table publicin.consumo_simulaciones_&fecha1 as
SELECT
INPUT(LEFT(SUBSTR(LEFT(COMPRESS(COMPRESS(ENLOG_COC_NOM_USR,'.'),'-')),1,LENGTH(LEFT(COMPRESS(COMPRESS(ENLOG_COC_NOM_USR,'.'),'-')))-1)),BEST.) AS RUT,
 
          input(put(datepart(t1.ENLOG_FCH_CRC),date9.),date9.) format=date9. as fecha, 
          t1.ENLOG_NOM_URL
from  connection to hbpri_adm(
select		
y.enlog_coc_nom_usr
,ENLOG_FCH_CRC,ENLOG_NOM_URL
FROM HBPRI_LOG_ENT_LOG Y 
WHERE  TO_NUMBER(TO_CHAR(ENLOG_FCH_CRC,'YYYYMM')) = &fecha1
and ENLOG_NOM_URL LIKE '%/creditos/deConsumo/simulaciones/home.xhtml%'

)t1

;QUIT;

