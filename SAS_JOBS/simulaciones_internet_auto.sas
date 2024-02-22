/*logeos mes internet */
DATA _null_;
date0 = input(put(intnx('month',today(),0,'same'),yymmn6. ),$10.);
Call symput("fecha0", date0);
RUN;


%let mz_connect_HB = CONNECT TO ORACLE as hbpri_adm(USER='RIPLEYC' PASSWORD='ri99pley'
PATH="  (DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))
(CONNECT_DATA = (SID = ripleyc)))");

/*Construcción de los funnel*/
		
proc sql ;
&mz_connect_HB;
CREATE TABLE publicin.simulaciones_sav_av_&fecha0 as
SELECT
INPUT(LEFT(SUBSTR(LEFT(COMPRESS(COMPRESS(ENLOG_COC_NOM_USR,'.'),'-')),1,LENGTH(LEFT(COMPRESS(COMPRESS(ENLOG_COC_NOM_USR,'.'),'-')))-1)),BEST.) AS RUT,
 
          input(put(datepart(t1.ENLOG_FCH_CRC),date9.),date9.) format=date9. as fecha, 
          t1.ENLOG_NOM_URL
from  connection to hbpri_adm(
select		
y.enlog_coc_nom_usr
,ENLOG_FCH_CRC,ENLOG_NOM_URL
FROM HBPRI_LOG_ENT_LOG Y 
WHERE  TO_NUMBER(TO_CHAR(ENLOG_FCH_CRC,'YYYYMM')) = &fecha0
and ENLOG_NOM_URL LIKE '%/avanceYsuperAvance/%'

)t1

;QUIT;


proc sql ;
&mz_connect_HB;
CREATE TABLE publicin.consumo_simulaciones_&fecha0 as
SELECT
INPUT(LEFT(SUBSTR(LEFT(COMPRESS(COMPRESS(ENLOG_COC_NOM_USR,'.'),'-')),1,LENGTH(LEFT(COMPRESS(COMPRESS(ENLOG_COC_NOM_USR,'.'),'-')))-1)),BEST.) AS RUT,
 
          input(put(datepart(t1.ENLOG_FCH_CRC),date9.),date9.) format=date9. as fecha, 
          t1.ENLOG_NOM_URL
from  connection to hbpri_adm(
select		
y.enlog_coc_nom_usr
,ENLOG_FCH_CRC,ENLOG_NOM_URL
FROM HBPRI_LOG_ENT_LOG Y 
WHERE  TO_NUMBER(TO_CHAR(ENLOG_FCH_CRC,'YYYYMM')) = &fecha0
and ENLOG_NOM_URL LIKE '%/creditos/deConsumo/simulaciones/home.xhtml%'

)t1

;QUIT;
