/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================      KPI_INTERNET_CONSOLIDACIÓN  	 ===============================*/
/* CONTROL DE VERSIONES
/* 2023-03-07 -- V05 -- Nicolás V. -- Cambio de libreria venta historica
/* 2022-10-26 -- V04 -- Sergio J.  -- Nueva forma de exportar a AWS
/* 2022-08-30 -- V03 -- Sergio J.  -- Se agrega sentencia include para borrar y exportar a AWS
/* 2022-08-10 -- V02 -- Sergio J.  -- Se agrega exportación a aws
/* 2022-08-10 -- V01 -- Nicolás V. -- Versión original.

*/

options validvarname=any;

%let libreria=result;


LIBNAME libbehb ODBC  DATASRC="BR-BACKENDHB"  SCHEMA=dbo  USER="ripley-bi"  
PASSWORD="biripley00"; 




%let mz_connect_HB = CONNECT TO ORACLE as hbpri_adm(USER='RIPLEYC' PASSWORD='ri99pley'
PATH="  (DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))
(CONNECT_DATA = (SID = ripleyc)))");


/*matriz de variables macro*/

%LET N=0;

DATA _null_;
dated2 = input(put(intnx('month',today(),-2-&N.,'begin'),yymmn6. ),$10.) ;
dated1 = input(put(intnx('month',today(),-1-&N.,'begin'),date9. ),$10.) ;
dated0 = input(put(intnx('day',today(),-1-&N.,'same'),date9. ),$10.) ;	
dated_act = input(put(intnx('month',today(),0-&N.,'same'),yymmn6. ),$10.) ;	
dated_ant = input(put(intnx('month',today(),-1-&N.,'same'),yymmn6. ),$10.) ;
ini_mes = input(put(intnx('month',today(),0-&N.,'begin'),date9. ),$10.) ;	
Call symput("fechad0", dated0);
Call symput("fechad1", dated1);
Call symput("fechad2", dated2);
Call symput("dated_act", dated_act);
Call symput("dated_ant", dated_ant);
Call symput("ini_mes", ini_mes);
RUN;

%put &fechad1;
%put &fechad0;
%put &fechad2;
%put &dated_act;
%put &dated_ant;
%put &ini_mes;


/*OFERTA NORMAL DE AVANCE ultimos 3 meses */

%put ######################################################;
%put ####  base de oferta de AV de los ultimos 3 meses ####;
%put ######################################################;

proc sql;
create table work.OFERTA_NORMAL_AV_2  as
select *
from pmunoz.OFERTA_NORMAL_AV_2
where  avance_final>=50000
and periodo>= &fechad2.
;quit;

%put ######################################################;
%put ####  base de oferta de SAV de APROBADOS          ####;
%put ######################################################;

/*proc sql;*/
/*create table work.oferta_APROBADOS_SAV_1 as*/
/*select **/
/*from EPIELH.oferta_APROBADOS_SAV_1*/
/*where periodo>=year("&fechad1"D)*100+month("&fechad1"D)*/
/*;quit;*/

proc sql;
create table work.oferta_APROBADOS_SAV_2 as
select *
from pmunoz.oferta_APROBADOS_SAV_2
where periodo>=year("&fechad1"D)*100+month("&fechad1"D)
;quit;

%put ######################################################;
%put ####  base de oferta de consumo ultimos 2 meses   ####;
%put ######################################################;

/*oferta a nivel de clientek, nace de def comercial y se carga campañas */
/*revisar como sacar de campañas directo*/ 

PROC SQL;
CREATE TABLE &libreria..OFERTA_CONS_ONLINE AS 
SELECT t1.RUT, 
t1.MONTO_OFERTA,
&dated_act. as periodo
FROM JABURTOM.OFERTA_CONS_ONLINE_&dated_act. t1
union 
select 
RUT ,
OFERTA_CONSUMO_APROBADO as MONTO_OFERTA,

202108 as periodo 
from publicri.base_increm_cons_aprob_202108

union
SELECT t1.RUT, 
t1.MONTO_OFERTA,
&dated_ant. as periodo
FROM JABURTOM.OFERTA_CONS_ONLINE_&dated_ant. t1
;QUIT;

%put ######################################################;
%put ####  base de clientes logueados el mes actual    ####;
%put ######################################################;
	
proc sql;
create table WORK.LOG_TOTAL  as
select  RUT as SESSIONRUT, 
FECHA_LOGUEO FORMAT=DATE9. AS CREATED_AT,
upcase(DISPOSITIVO) as DEVICE, 
year(FECHA_LOGUEO) as anio,
month(FECHA_LOGUEO) as mes,
year(FECHA_LOGUEO)*100+ month(FECHA_LOGUEO) as periodo
from publicin.LOGEO_INT_&dated_act.
;quit;


%put ############################################################;
%put ####  Separación por tipo de combinatorias de logueo    ####;
%put ############################################################;
	

PROC SQL;
CREATE TABLE &libreria..log_mix_pwa AS 
SELECT t1.SESSIONRUT, 
t1.CREATED_AT, 
t1.DEVICE, 
t1.anio, 
t1.mes, 
t1.periodo
FROM WORK.LOG_TOTAL t1
union
SELECT t1.SESSIONRUT, 
t1.CREATED_AT, 
'MIX' AS DEVICE, 
t1.anio, 
t1.mes, 
t1.periodo
FROM WORK.LOG_TOTAL t1
union
SELECT t1.SESSIONRUT, 
t1.CREATED_AT, 
'PWA_MIX' AS DEVICE, 
t1.anio, 
t1.mes, 
t1.periodo
FROM WORK.LOG_TOTAL t1
WHERE t1.DEVICE IN ('DESKTOP', 'MOBILE')
;QUIT;


proc sql;
create table &libreria..log_mix_pwa as 
select 
t1.*,
coalesce(t3.TRAMOS_DECIL_PD,'21.NO APLICA') as TRAMOS_DECIL_PD,
coalesce(t3.marca_monto,'NO APLICA') as marca_monto
from &libreria..log_mix_pwa as t1
	  left join work.oferta_APROBADOS_SAV_2 T3 
ON (t1.SESSIONRUT=t3.rut AND T1.PERIODO=T3.PERIODO)
;QUIT;


/*creacion de indices para los cruces*/

PROC SQL;
CREATE INDEX SESSIONRUT ON LOG_TOTAL (SESSIONRUT); /* modificar ultimo periodo */
QUIT; 


PROC SQL;
CREATE INDEX SESSIONRUT ON &libreria..log_mix_pwa (SESSIONRUT); /* modificar ultimo periodo */
QUIT; 


%put ############################################################;
%put ####  vouchers de PWA   (REVISAR POR QUE HISTORICO)     ####;
%put ############################################################;


LIBNAME ORACLOUD ORACLE sql_functions=all  READBUFF=1000  INSERTBUFF=1000  PATH="REPORTSAS.WORLD"  SCHEMA=SAS_ADM authdomain=DBOracleCloud_Auth;
 

PROC SQL;
CREATE TABLE pwa AS 

select  INPUT((SUBSTR(rut,1,(LENGTH(rut)-1))),BEST.)as rut,
t1.MONTOLIQUIDO as monto,
t1.PRODUCTO,
t1.numoperacion, 
CASE WHEN UPCASE(t1.DISPOSITIVO) LIKE'%APP%' then 'APP'
WHEN UPCASE(t1.DISPOSITIVO) is null then 'APP'

else upcase(t1.DISPOSITIVO) end as  canal, numoperacion,
datepart(FECHACURSE) FORMAT=date9. AS FECHA

FROM libbehb.AVSAVVOUCHERVIEW t1
WHERE datepart(FECHACURSE)>="01jan2021"D

;QUIT;



%put ############################################################;
%put ####  PWA CONSUMO  (REVISAR POR QUE HISTORICO)     ####;
%put ############################################################;



PROC SQL;
CREATE TABLE pwa_consumo AS 

select  INPUT((SUBSTR(rut,1,(LENGTH(rut)-1))),BEST.)as rut,
INPUT(t1.Montoliquido,best.) as monto,
'consumo' as  PRODUCTO,
t1.NumeroOperacion,
CASE WHEN UPCASE(t1.DISPOSITIVO) LIKE'%APP%' then 'APP'
WHEN UPCASE(t1.DISPOSITIVO) is null then 'APP'

else upcase(t1.DISPOSITIVO) end as  canal,
datepart(FECHACURSE) FORMAT=date9. AS FECHA ,
t1.SeguroDesgravamen, 
t1.SeguroVida

FROM libbehb.PersonalLoanView t1
WHERE datepart(FechaCurse)>="20dec2020"D 

;QUIT;




%put ############################################################;
%put ####  UNIFICACION de CONSUMO (REVISAR POR QUE HISTORICO)####;
%put ############################################################;

PROC SQL;
CREATE TABLE &libreria..VENTA_INTERNET_ANIO_MOV AS 
select *
FROM pwa_consumo t1
WHERE FECHA>="01sep2020"D
OUTER UNION CORR
select *
FROM pwa t1
WHERE FECHA>="01sep2020"D
OUTER UNION CORR
select *
FROM &libreria..VENTA_INTERNET_ANIO_MOV_HIST 
WHERE FECHA<"01sep2020"D
;QUIT;


PROC SQL;
CREATE TABLE &libreria..VENTA_AGRUPADA AS 
SELECT t1.rut, 
t1.monto, 
t1.PRODUCTO, 
'' as numoperacion,
t1.canal, 
t1.FECHA,
year(t1.FECHA)*100+month(t1.FECHA) as periodo

FROM &libreria..VENTA_INTERNET_ANIO_MOV t1
OUTER UNION CORR

SELECT t1.rut, 
t1.monto, 
t1.PRODUCTO, 
'' as numoperacion,
'MIX' AS canal, 
t1.FECHA,
year(t1.FECHA)*100+month(t1.FECHA) as periodo
FROM &libreria..VENTA_INTERNET_ANIO_MOV t1

OUTER UNION CORR

SELECT t1.rut, 
t1.monto, 
t1.PRODUCTO, 
'' as numoperacion,
'PWA_MIX' AS canal, 
t1.FECHA,
year(t1.FECHA)*100+month(t1.FECHA) as periodo
FROM &libreria..VENTA_INTERNET_ANIO_MOV t1
WHERE t1.CANAL IN ('DESKTOP', 'MOBILE')
;QUIT;


PROC SQL;
CREATE TABLE &libreria..VENTA_AGRUPADA_USO AS 
SELECT t1.rut, 
t1.monto, 
t1.PRODUCTO, 
t1.canal, 
t1.FECHA,
CASE WHEN t1.PRODUCTO='AV' THEN t2.AVANCE_FINAL ELSE t1.monto END AS monto_av,
CASE WHEN t1.PRODUCTO='SAV' THEN t3.monto ELSE t1.monto END  AS monto_sav,
CASE WHEN t1.PRODUCTO='consumo' THEN t4.MONTO_OFERTA ELSE t1.monto END  AS monto_consumo,
coalesce(t3.TRAMOS_DECIL_PD,'21.NO APLICA') as TRAMOS_DECIL_PD,
coalesce(t3.marca_monto,'NO APLICA') as marca_monto
FROM &libreria..VENTA_AGRUPADA t1 
  LEFT JOIN work.OFERTA_NORMAL_AV_2 T2 ON (t1.rut=t2.rut_REGISTRO_CIVIL AND T1.PERIODO=T2.PERIODO)
  LEFT JOIN work.oferta_APROBADOS_SAV_2 T3 ON (t1.rut=t3.rut AND T1.PERIODO=T3.PERIODO)
  LEFT JOIN &libreria..OFERTA_CONS_ONLINE  T4 ON (t1.rut=t4.rut AND T1.PERIODO=T4.PERIODO)
where t1.FECHA>="&fechad1"D
;
QUIT;

PROC SQL;
   CREATE TABLE &libreria..VENTA_AGRUPADA_USO_2 AS 
   SELECT t1.rut, 
          t1.monto, 
          t1.PRODUCTO, 
          t1.canal, 
          t1.fecha, 
          case when t1.monto_av<= t1.monto then t1.monto else t1.monto_av end as monto_av, 
          case when t1.monto_sav <= t1.monto then t1.monto else t1.monto_sav end as monto_sav , 
          case when t1.monto_consumo <= t1.monto then t1.monto else t1.monto_consumo end as monto_consumo,
		  t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
      FROM &libreria..VENTA_AGRUPADA_USO t1;
QUIT;


PROC SQL;
   CREATE TABLE WORK.USO_AV AS 
   SELECT t1.FECHA, 
          /* SUM_of_monto_av */
            (SUM(t1.monto_av)) AS OFERTA_AV,
          t1.canal,
		  t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
      FROM &libreria..VENTA_AGRUPADA_USO_2 t1
	   WHERE t1.PRODUCTO='AV'
      GROUP BY t1.FECHA,
               t1.canal,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto;
QUIT;

PROC SQL;
   CREATE TABLE WORK.USO_SAV AS 
   SELECT t1.FECHA, 
            (SUM(t1.monto_sav)) AS OFERTA_SAV, 
          t1.canal,
		  t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
      FROM &libreria..VENTA_AGRUPADA_USO_2 t1
	  WHERE t1.PRODUCTO='SAV'
      GROUP BY t1.FECHA,
               t1.canal,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto;
QUIT;

PROC SQL;
   CREATE TABLE WORK.USO_consumo AS 
   SELECT t1.FECHA, 
            (SUM(t1.monto_consumo)) AS OFERTA_consumo, 
          t1.canal,
		  t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
      FROM &libreria..VENTA_AGRUPADA_USO_2 t1
	  WHERE t1.PRODUCTO='consumo'
      GROUP BY t1.FECHA,
               t1.canal,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto;
QUIT;



PROC SQL;
CREATE TABLE WORK.VENTA_CONSUMO AS 
SELECT t1.FECHA, 
(SUM(t1.monto)) FORMAT=11. AS MONTO_consumo, 
/* COUNT_of_rut */
(COUNT(t1.rut)) AS TRX_CONSUMO, 
t1.canal, 
t1.PRODUCTO,
t1.TRAMOS_DECIL_PD,

		  t1.marca_monto
FROM &libreria..VENTA_AGRUPADA_USO t1
WHERE UPCASE(t1.PRODUCTO)='CONSUMO'
GROUP BY t1.FECHA,
t1.canal,
t1.PRODUCTO,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto;
QUIT;

PROC SQL;
CREATE TABLE WORK.VENTA_SAV AS 
SELECT t1.FECHA, 
(SUM(t1.monto)) FORMAT=11. AS MONTO_SAV, 
/* COUNT_of_rut */
(COUNT(t1.rut)) AS TRX_SAV, 
t1.canal, 
t1.PRODUCTO,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
FROM &libreria..VENTA_AGRUPADA_USO t1
WHERE t1.PRODUCTO='SAV'
GROUP BY t1.FECHA,
t1.canal,
t1.PRODUCTO,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto;
QUIT;


PROC SQL;
CREATE TABLE WORK.VENTA_AV AS 
SELECT t1.FECHA, 
(SUM(t1.monto)) FORMAT=11. AS MONTO_AV, 
/* COUNT_of_rut */
(COUNT(t1.rut)) AS TRX_AV, 
t1.canal, 
t1.PRODUCTO,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
FROM &libreria..VENTA_AGRUPADA_USO t1
WHERE t1.PRODUCTO='AV'
GROUP BY t1.FECHA,
t1.canal,
t1.PRODUCTO,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto;
QUIT;


PROC SQL;
   CREATE TABLE WORK.MINIMO AS 
   SELECT t1.SESSIONRUT AS RUT, 
          /* MIN_of_CREATED_AT */
            (MIN(t1.CREATED_AT)) FORMAT=DATE9. AS FECHA, 
          t1.anio, 
          t1.mes, 
          t1.periodo, 
          t1.DEVICE
      FROM &libreria..log_mix_pwa t1
	 
      GROUP BY t1.SESSIONRUT,
               t1.anio,
               t1.mes,
               t1.periodo,
               t1.DEVICE;
QUIT;

proc sql;
create table minimo as 
select 
t1.*,
coalesce(t3.TRAMOS_DECIL_PD,'21.NO APLICA') as TRAMOS_DECIL_PD,
coalesce(t3.marca_monto,'NO APLICA') as marca_monto
  FROM minimo t1
	  left join work.oferta_APROBADOS_SAV_2 T3 
ON (t1.rut=t3.rut AND T1.PERIODO=T3.PERIODO)
	  ;QUIT;


PROC SQL;
CREATE TABLE WORK.LOGUEOS_DIARIOS AS 
SELECT t1.CREATED_AT, 
t1.anio, 
t1.mes, 
t1.periodo, 
/* COUNT_DISTINCT_of_SESSIONRUT */
(COUNT(DISTINCT(t1.SESSIONRUT))) AS LOGUEOS_DIARIOS, 
t1.DEVICE,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
FROM &libreria..log_mix_pwa t1
GROUP BY t1.CREATED_AT,
t1.anio,
t1.mes,
t1.periodo,
t1.DEVICE,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto;
QUIT;


PROC SQL;
   CREATE TABLE WORK.MINIMO_SAV AS 
   SELECT t1.RUT, 
   FECHA,
          t1.anio, 
          t1.mes, 
          t1.periodo, 
          t1.DEVICE,
		  t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
      FROM WORK.MINIMO t1 
INNER JOIN work.oferta_APROBADOS_SAV_2 t2 
ON (t1.RUT = t2.rut) AND (t1.periodo= t2.periodo)

;QUIT;

PROC SQL;
CREATE TABLE &libreria..log_mix_pwa_sav AS 
SELECT t1.SESSIONRUT, 
t1.CREATED_AT, 
t1.anio, 
t1.mes, 
t1.periodo, 
t1.DEVICE,
t1.TRAMOS_DECIL_PD
,
		  t1.marca_monto
FROM &libreria..log_mix_pwa t1

INNER JOIN work.oferta_APROBADOS_SAV_2 t2 
ON (t1.SESSIONRUT = t2.rut AND t1.periodo= t2.periodo)
;QUIT;

PROC SQL;
CREATE TABLE WORK.OFERTADO_DIARIOS_SAV AS 
SELECT t1.CREATED_AT, 
t1.anio, 
t1.mes, 
t1.periodo, 
/* COUNT_DISTINCT_of_SESSIONRUT */
(COUNT(DISTINCT(t1.SESSIONRUT))) AS OFTA_SAV_DIARIA, 
t1.DEVICE,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
FROM &libreria..log_mix_pwa_sav t1
GROUP BY t1.CREATED_AT,
   t1.anio,
   t1.mes,
   t1.periodo,
   t1.DEVICE,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto;
QUIT;

PROC SQL;
CREATE TABLE WORK.MINIMO_AV_2 AS 
SELECT t1.RUT, 
FECHA,
t1.anio, 
t1.mes, 
t1.periodo, 
t1.DEVICE,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
FROM WORK.MINIMO t1  
INNER JOIN work.OFERTA_NORMAL_AV_2  t2 
ON (t1.RUT=t2.RUT_registro_civil AND t1.periodo= t2.periodo)

;QUIT;

PROC SQL;
CREATE TABLE &libreria..log_mix_pwa_av AS 
SELECT t1.SESSIONRUT, 
t1.CREATED_AT, 
t1.anio, 
t1.mes, 
t1.periodo, 
t1.DEVICE,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
FROM &libreria..log_mix_pwa t1
INNER JOIN work.OFERTA_NORMAL_AV_2 t2 
ON (t1.SESSIONRUT = t2.rut_registro_civil AND t1.periodo= t2.periodo)
;QUIT;

PROC SQL;
CREATE TABLE WORK.OFERTADO_DIARIOS_AV AS 
SELECT t1.CREATED_AT, 
t1.anio, 
t1.mes, 
t1.periodo, 
/* COUNT_DISTINCT_of_SESSIONRUT */
(COUNT(DISTINCT(t1.SESSIONRUT))) AS OFTA_AV_DIARIA, 
t1.DEVICE,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
FROM &libreria..log_mix_pwa_av t1

GROUP BY t1.CREATED_AT,
t1.anio,
t1.mes,
t1.periodo,
t1.DEVICE,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto;
QUIT;


PROC SQL;
CREATE TABLE WORK.MINIMO_CONSUMO_2 AS 
SELECT t1.RUT, 
FECHA,
t1.anio, 
t1.mes, 
t1.periodo, 
t1.DEVICE,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
FROM WORK.MINIMO t1  
INNER JOIN &libreria..OFERTA_CONS_ONLINE t2 
ON (t1.RUT=t2.RUT AND t1.periodo= t2.periodo)
;QUIT;

PROC SQL;
CREATE TABLE &libreria..log_mix_pwa_CONSUMO AS 
SELECT t1.SESSIONRUT, 
t1.CREATED_AT, 
t1.anio, 
t1.mes, 
t1.periodo, 
t1.DEVICE,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
FROM &libreria..log_mix_pwa t1

INNER JOIN &libreria..OFERTA_CONS_ONLINE t2
ON (t1.SESSIONRUT = t2.rut AND t1.periodo= t2.periodo)

;
QUIT;

PROC SQL;
CREATE TABLE WORK.OFERTADO_DIARIOS_CONSUMO AS 
SELECT t1.CREATED_AT, 
t1.anio, 
t1.mes, 
t1.periodo, 
/* COUNT_DISTINCT_of_SESSIONRUT */
(COUNT(DISTINCT(t1.SESSIONRUT))) AS OFTA_CONSUMO_DIARIA, 
t1.DEVICE,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
FROM &libreria..log_mix_pwa_CONSUMO t1

GROUP BY t1.CREATED_AT,
t1.anio,
t1.mes,
t1.periodo,
t1.DEVICE,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto;
QUIT;


PROC SQL;
CREATE TABLE WORK.logueos_acumulados AS 
SELECT t1.FECHA, 
t1.DEVICE AS CANAL,
t1.TRAMOS_DECIL_PD,
(COUNT(DISTINCT(t1.RUT))) AS logueos_acumulados,
		  t1.marca_monto 
FROM WORK.MINIMO t1
GROUP BY t1.FECHA,
t1.DEVICE,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
;
QUIT;

PROC SQL;
CREATE TABLE WORK.sav_acumulados AS 
SELECT t1.FECHA, 
t1.DEVICE AS CANAL, 
t1.TRAMOS_DECIL_PD,
(COUNT(DISTINCT(t1.RUT))) AS oferta_sav,
		  t1.marca_monto
FROM WORK.MINIMO_SAV t1
GROUP BY t1.FECHA,
t1.DEVICE,
t1.TRAMOS_DECIL_PD,
		  t1.marca_monto;
QUIT;

PROC SQL;
CREATE TABLE WORK.av_acumulados AS 
SELECT t1.FECHA, 
t1.DEVICE  AS CANAL, 
t1.TRAMOS_DECIL_PD,
(COUNT(DISTINCT(t1.RUT))) AS oferta_av,
		  t1.marca_monto
FROM WORK.MINIMO_AV_2 t1
GROUP BY t1.FECHA,
t1.DEVICE,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto;
QUIT;

PROC SQL;
CREATE TABLE WORK.CONSUMO_acumulados AS 
SELECT t1.FECHA, 
t1.DEVICE  AS CANAL, t1.TRAMOS_DECIL_PD,
(COUNT(DISTINCT(t1.RUT))) AS oferta_CONSUMO,
		  t1.marca_monto
FROM WORK.MINIMO_CONSUMO_2 t1
GROUP BY t1.FECHA,
   t1.DEVICE,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto;
QUIT;

 

LIBNAME ORACLOUD ORACLE sql_functions=all  READBUFF=1000  INSERTBUFF=1000  PATH="REPORTSAS.WORLD"  SCHEMA=SAS_ADM authdomain=DBOracleCloud_Auth;

PROC SQL;
CREATE TABLE WORK.sims_consumo AS 
SELECT INPUT((SUBSTR(t1.rut,1,(LENGTH(t1.rut)-1))),BEST.) as rut, 
datepart(FechaSimulacion) format=date9. as fecha,
dispositivo  AS CANAL,
'CONSUMO' AS PRODUCTO
FROM libbehb.SimulationPersonalLoanView t1 
 left join &libreria..OFERTA_CONS_ONLINE t2
on (INPUT((SUBSTR(t1.rut,1,(LENGTH(t1.rut)-1))),BEST.)=t2.rut
and year(datepart(FechaSimulacion))*100+month(datepart(FechaSimulacion))=t2.periodo)
where  INPUT((SUBSTR(t1.rut,1,(LENGTH(t1.rut)-1))),BEST.)=t2.rut
and year(datepart(FechaSimulacion))*100+month(datepart(FechaSimulacion))=t2.periodo
;
QUIT;



/*este se demora un kilo*/


proc sql;

connect to ODBC as myconn (user="ripley-bi" password="biripley00"
DATASRC="BR-BACKENDHB"
);
create table SIMULATIONAVSAVVIEW as 
select * ,  "&fechad0"d  format=date9. as fecha_r
from connection to myconn
( SELECT  *
from SIMULATIONAVSAVVIEW

);

disconnect from myconn;
quit;


PROC SQL;
CREATE TABLE WORK.sims_pwa_final AS 
SELECT INPUT((SUBSTR(rut,1,(LENGTH(rut)-1))),BEST.)as rut,
upcase(t1.Producto) as producto, 
t1.Dispositivo, 
datepart(t1.'FechaSimulación'n) format=date9. as fecha,
month(datepart(t1.'FechaSimulación'n)) format=best. as mes,
year(datepart(t1.'FechaSimulación'n)) format=best. as anio
FROM WORK.SIMULATIONAVSAVVIEW t1
where year(datepart(t1.'FechaSimulación'n))*100+month(datepart(t1.'FechaSimulación'n))=&dated_act.
;
QUIT;



PROC SQL;
CREATE TABLE &libreria..SIMULACIONES_ALL AS 
SELECT rut, 
t1.fecha format=date9. as fecha,
MONTH(t1.fecha) as mes,
YEAR(t1.fecha)  as anio,
CASE WHEN upcase(t1.DISPOSITIVO) like '%APP%' then 'APP' else upcase(t1.DISPOSITIVO) end as  DISPOSITIVO,
'SAV' AS PRODUCTO
FROM sims_pwa_final t1
where producto='SAV'

UNION

SELECT rut, 
t1.fecha format=date9. as fecha,
MONTH(t1.fecha) as mes,
YEAR(t1.fecha)  as anio,
CASE WHEN upcase(t1.DISPOSITIVO) like '%APP%' then 'APP' else upcase(t1.DISPOSITIVO) end as  DISPOSITIVO,
'AV' AS PRODUCTO
FROM sims_pwa_final t1
where producto='AV'


;
QUIT;

PROC SQL;
CREATE TABLE &libreria..SIMULACIONES_ALL  AS 
SELECT t1.RUT, 
t1.fecha, 
t1.mes, 
t1.anio, 
t1.DISPOSITIVO AS CANAL, 
t1.PRODUCTO
FROM &libreria..SIMULACIONES_ALL t1
union 
SELECT t1.RUT, 
t1.fecha, 
t1.mes, 
t1.anio, 
'PWA_MIX'  AS CANAL, 
t1.PRODUCTO
FROM &libreria..SIMULACIONES_ALL t1
where t1.DISPOSITIVO in ('DESKTOP', 'MOBILE')
union
select t1.rut, 
t1.fecha format=date9. as fecha, 
month(t1.fecha) as mes,
year(t1.fecha) as anio,
canal, 
t1.PRODUCTO
FROM WORK.SIMS_CONSUMO t1;
QUIT;


PROC SQL;
CREATE TABLE &libreria..SIMULACIONES_ALL  AS 
select 
t1.*,
coalesce(t3.TRAMOS_DECIL_PD,'21.NO APLICA') as TRAMOS_DECIL_PD,
coalesce(t3.marca_monto,'NO APLICA') as marca_monto
  FROM &libreria..SIMULACIONES_ALL t1
	  left join work.oferta_APROBADOS_SAV_2 T3 
ON (t1.rut=t3.rut AND year(t1.fecha)*100+month(t1.fecha)=T3.PERIODO)
;QUIT;

PROC SQL;
CREATE TABLE WORK.SIMULACIONES_DIARIAS_AV AS 
SELECT t1.fecha, 
/* COUNT_DISTINCT_of_RUT */
(COUNT(DISTINCT(t1.RUT))) AS SIMS_AV, 
upcase(t1.CANAL) as canal, 
t1.PRODUCTO,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
FROM &libreria..SIMULACIONES_ALL t1
WHERE  t1.PRODUCTO='AV'
GROUP BY t1.fecha,
t1.CANAL,
t1.PRODUCTO,TRAMOS_DECIL_PD,
		  t1.marca_monto

UNION

SELECT t1.fecha, 
/* COUNT_DISTINCT_of_RUT */
(COUNT(DISTINCT(t1.RUT))) AS SIMS_AV, 
'MIX' AS CANAL, 
t1.PRODUCTO,TRAMOS_DECIL_PD,
		  t1.marca_monto
FROM &libreria..SIMULACIONES_ALL t1
WHERE  t1.PRODUCTO='AV'
GROUP BY t1.fecha,TRAMOS_DECIL_PD,
		  t1.marca_monto

;
QUIT;


PROC SQL;
CREATE TABLE WORK.SIMULACIONES_DIARIAS_SAV AS 
SELECT t1.fecha, 
/* COUNT_DISTINCT_of_RUT */
(COUNT(DISTINCT(t1.RUT))) AS SIMS_SAV, 
upcase(t1.CANAL) as canal, 
t1.PRODUCTO,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
FROM &libreria..SIMULACIONES_ALL t1
WHERE  t1.PRODUCTO='SAV'
GROUP BY t1.fecha,
t1.CANAL,
t1.PRODUCTO,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto

UNION

SELECT t1.fecha, 
/* COUNT_DISTINCT_of_RUT */
(COUNT(DISTINCT(t1.RUT))) AS SIMS_SAV, 
'MIX' AS CANAL, 
t1.PRODUCTO,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
FROM &libreria..SIMULACIONES_ALL t1
WHERE  t1.PRODUCTO='SAV'
GROUP BY t1.fecha,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto


;
QUIT;




PROC SQL;
   CREATE TABLE WORK.SIMULACIONES_DIARIAS_CONS AS 
   SELECT t1.fecha, 
          /* COUNT_DISTINCT_of_RUT */
            (COUNT(DISTINCT(t1.RUT))) AS SIMS_CONS, 
         upcase(t1.CANAL) as canal, 
          t1.PRODUCTO,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
      FROM &libreria..SIMULACIONES_ALL t1
	  WHERE  t1.PRODUCTO='CONSUMO'
      GROUP BY t1.fecha,
               t1.CANAL,
               t1.PRODUCTO,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto

			   UNION

   SELECT t1.fecha, 
          /* COUNT_DISTINCT_of_RUT */
            (COUNT(DISTINCT(t1.RUT))) AS SIMS_CONS, 
          'MIX' AS CANAL, 
          t1.PRODUCTO,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
      FROM &libreria..SIMULACIONES_ALL t1
	  	  WHERE  t1.PRODUCTO='CONSUMO'
      GROUP BY t1.fecha,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto


;
QUIT;


PROC SQL;
   CREATE TABLE WORK.SIMULACIONES_AV_INC AS 
SELECT X.MIN_of_fecha,

       COUNT(DISTINCT(X.RUT)) AS SIMS_AV,
	   X.CANAL,x.TRAMOS_DECIL_PD,
		  x.marca_monto

FROM
(
SELECT t1.RUT, 
          /* MIN_of_fecha */
            (MIN(t1.fecha)) FORMAT=DATE9. AS MIN_of_fecha, 
          t1.mes, 
          t1.anio, 
          t1.CANAL,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
      FROM &libreria..SIMULACIONES_ALL t1
      WHERE t1.PRODUCTO = 'AV'
      GROUP BY t1.RUT,
               t1.mes,
               t1.anio,
               t1.CANAL,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
) X

GROUP BY X.MIN_of_fecha, X.CANAL,X.TRAMOS_DECIL_PD,
		  x.marca_monto

UNION

SELECT X.MIN_of_fecha,
       COUNT(DISTINCT(X.RUT)) AS SIMS_AV,
	   X.CANAL,x.TRAMOS_DECIL_PD,
		  x.marca_monto

FROM
(
SELECT t1.RUT, 
          /* MIN_of_fecha */
            (MIN(t1.fecha)) FORMAT=DATE9. AS MIN_of_fecha, 
          t1.mes, 
          t1.anio, 
          'MIX' AS CANAL,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
      FROM &libreria..SIMULACIONES_ALL t1
      WHERE t1.PRODUCTO = 'AV'
      GROUP BY t1.RUT,
               t1.mes,
               t1.anio,
               t1.CANAL,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
) X

GROUP BY X.MIN_of_fecha, X.CANAL,x.TRAMOS_DECIL_PD,
		  x.marca_monto

;
QUIT;



PROC SQL;
   CREATE TABLE WORK.SIMULACIONES_SAV_INC AS 
SELECT X.MIN_of_fecha,
       COUNT(DISTINCT(X.RUT)) AS SIMS_SAV,
	   X.CANAL,x.TRAMOS_DECIL_PD,
		  x.marca_monto

FROM
(
SELECT t1.RUT, 
          /* MIN_of_fecha */
            (MIN(t1.fecha)) FORMAT=DATE9. AS MIN_of_fecha, 
          t1.mes, 
          t1.anio, 
          t1.CANAL,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
      FROM &libreria..SIMULACIONES_ALL t1
      WHERE t1.PRODUCTO = 'SAV'
      GROUP BY t1.RUT,
               t1.mes,
               t1.anio,
               t1.CANAL,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
) X

GROUP BY X.MIN_of_fecha, X.CANAL,x.TRAMOS_DECIL_PD,
		  x.marca_monto

UNION

SELECT X.MIN_of_fecha,
       COUNT(DISTINCT(X.RUT)) AS SIMS_SAV,
	   X.CANAL,x.TRAMOS_DECIL_PD,
		  x.marca_monto

FROM
(
SELECT t1.RUT, 
          /* MIN_of_fecha */
            (MIN(t1.fecha)) FORMAT=DATE9. AS MIN_of_fecha, 
          t1.mes, 
          t1.anio, 
          'MIX' AS CANAL,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
      FROM &libreria..SIMULACIONES_ALL t1
      WHERE t1.PRODUCTO = 'SAV'
      GROUP BY t1.RUT,
               t1.mes,
               t1.anio,
               t1.CANAL,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
) X

GROUP BY X.MIN_of_fecha, X.CANAL,x.TRAMOS_DECIL_PD,
		  x.marca_monto

;
QUIT;




PROC SQL;
   CREATE TABLE WORK.SIMS_CONSUMO AS 
   SELECT distinct  t1.rut, 
          t1.fecha format=date9. as fecha,
          month(t1.fecha) as mes,
          year(t1.fecha) as anio, 
          t1.CANAL, 
          t1.PRODUCTO,coalesce(t3.TRAMOS_DECIL_PD,'21.NO APLICA') as TRAMOS_DECIL_PD,
		  coalesce(t3.marca_monto,'NO APLICA') as marca_monto
      FROM WORK.SIMS_CONSUMO t1

	  left join work.oferta_APROBADOS_SAV_2 T3 
ON (t1.rut=t3.rut AND year(t1.fecha)*100+month(t1.fecha)=T3.PERIODO)
;
QUIT;


PROC SQL;
   CREATE TABLE WORK.SIMULACIONES_CONS_INC AS 
SELECT X.MIN_of_fecha,
       COUNT(DISTINCT(X.RUT)) AS SIMS_CONS,
	   X.CANAL,x.TRAMOS_DECIL_PD,
		  x.marca_monto

FROM
(
SELECT t1.RUT, 
          /* MIN_of_fecha */
            (MIN(t1.fecha)) FORMAT=DATE9. AS MIN_of_fecha, 
          t1.mes, 
          t1.anio, 
          t1.CANAL,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
      FROM work.SIMS_CONSUMO t1
      WHERE t1.PRODUCTO = 'CONSUMO'
      GROUP BY t1.RUT,
               t1.mes,
               t1.anio,
               t1.CANAL,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
) X

GROUP BY X.MIN_of_fecha, X.CANAL,x.TRAMOS_DECIL_PD,
		  x.marca_monto

UNION

SELECT X.MIN_of_fecha,
       COUNT(DISTINCT(X.RUT)) AS SIMS_CONS,
	   X.CANAL,x.TRAMOS_DECIL_PD,
		  x.marca_monto

FROM
(
SELECT t1.RUT, 
          /* MIN_of_fecha */
            (MIN(t1.fecha)) FORMAT=DATE9. AS MIN_of_fecha, 
          t1.mes, 
          t1.anio, 
          'MIX' AS CANAL,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
      FROM work.SIMS_CONSUMO t1
      WHERE t1.PRODUCTO = 'CONSUMO'
      GROUP BY t1.RUT,
               t1.mes,
               t1.anio,
               t1.CANAL,t1.TRAMOS_DECIL_PD,
		  t1.marca_monto
) X

GROUP BY X.MIN_of_fecha, X.CANAL,x.TRAMOS_DECIL_PD,
		  x.marca_monto

;
QUIT;




PROC SQL;
   CREATE TABLE WORK.PWA_AVSAVVOUCHERVIEW AS 
   SELECT DISTINCT t1.RUT, 
          t1.NUMOPERACION, 
          t1.PRODUCTO, 
          datepart(t1.FECHACURSE) format=date9. as fecha, 
          t1.PRECIOSEGURO,
		  
 CASE WHEN t1.DISPOSITIVO ='App' then 'APP' else upcase(t1.DISPOSITIVO) end as  DISPOSITIVO
      FROM libbehb.AVSAVVOUCHERVIEW t1
where t1.FECHACURSE >= "&fechad1"D ;
QUIT;


PROC SQL;
CREATE TABLE WORK.PWA_AVSAVVOUCHERVIEW AS 
select 
t1.*,
coalesce(t3.TRAMOS_DECIL_PD,'21.NO APLICA') as TRAMOS_DECIL_PD,
coalesce(t3.marca_monto,'NO APLICA') as marca_monto
FROM WORK.PWA_AVSAVVOUCHERVIEW t1

left join work.oferta_APROBADOS_SAV_2 T3 
ON (INPUT((SUBSTR(t1.rut,1,(LENGTH(t1.rut)-1))),BEST.)=t3.rut AND year(t1.fecha)*100+month(t1.fecha)=T3.PERIODO)
;QUIT;


PROC SQL;
   CREATE TABLE WORK.seguros_av AS 


SELECT FECHA,
      COUNT(RUT) AS SEGUROS,
	  CANAL,TRAMOS_DECIL_PD,marca_monto

	  FROM

(SELECT fecha FORMAT=date9. as fecha ,
          t1.RUT, 
          t1.PRECIOSEGURO,
		  DISPOSITIVO AS CANAL,TRAMOS_DECIL_PD,marca_monto
      FROM WORK.PWA_AVSAVVOUCHERVIEW t1
WHERE t1.PRODUCTO='AV'
AND t1.PRECIOSEGURO >=1 

)

GROUP BY FECHA, CANAL,TRAMOS_DECIL_PD,marca_monto

union
SELECT FECHA,
      COUNT(RUT) AS SEGUROS,
	  CANAL,TRAMOS_DECIL_PD,marca_monto

	  FROM

(SELECT fecha FORMAT=date9. as fecha ,
          t1.RUT, 
          t1.PRECIOSEGURO,
		  'PWA_MIX' AS CANAL,TRAMOS_DECIL_PD,marca_monto
      FROM WORK.PWA_AVSAVVOUCHERVIEW t1
WHERE t1.PRODUCTO='AV'
AND t1.PRECIOSEGURO >=1 
AND DISPOSITIVO<>'APP'

)

GROUP BY FECHA, CANAL,TRAMOS_DECIL_PD,marca_monto



union
SELECT FECHA,
      COUNT(RUT) AS SEGUROS,
	  CANAL,TRAMOS_DECIL_PD,marca_monto

	  FROM

(SELECT fecha FORMAT=date9. as fecha ,
          t1.RUT, 
          t1.PRECIOSEGURO,
		  'MIX' AS CANAL,TRAMOS_DECIL_PD,marca_monto
      FROM WORK.PWA_AVSAVVOUCHERVIEW t1
WHERE t1.PRODUCTO='AV'
AND t1.PRECIOSEGURO >=1 

)

GROUP BY FECHA, CANAL,TRAMOS_DECIL_PD,marca_monto
;
;
QUIT;


PROC SQL;
   CREATE TABLE WORK.SEGUROS_AV AS 
   SELECT t1.fecha, 
          t1.SEGUROS, 
          case when t1.CANAL is null then 'OTRO' 
		  when t1.CANAL=''  then 'OTRO' 

else  t1.CANAL  

           end as CANAL,TRAMOS_DECIL_PD,marca_monto
      FROM WORK.SEGUROS_AV t1;
QUIT;

PROC SQL;
   CREATE TABLE WORK.SEGUROS_AV AS 
   SELECT t1.fecha, 
          /* MAX_of_SEGUROS */
            (MAX(t1.SEGUROS)) AS SEGUROS, 
          t1.CANAL,TRAMOS_DECIL_PD,marca_monto
      FROM WORK.SEGUROS_AV t1
      GROUP BY t1.fecha,
               t1.CANAL,TRAMOS_DECIL_PD,marca_monto;
QUIT;



PROC SQL;
   CREATE TABLE WORK.seguros_sav AS 



   SELECT DISTINCT FECHA,
      COUNT(RUT) AS SEGUROS,
	  CANAL,TRAMOS_DECIL_PD,marca_monto
FROM
(SELECT FECHA FORMAT=date9. as fecha ,
          t1.RUT, 
		  DISPOSITIVO AS CANAL,TRAMOS_DECIL_PD,marca_monto
      FROM WORK.PWA_AVSAVVOUCHERVIEW t1
WHERE t1.PRODUCTO='SAV'
AND t1.PRECIOSEGURO >=1 )

GROUP BY FECHA, CANAL,TRAMOS_DECIL_PD,marca_monto

UNION

   SELECT FECHA,
      COUNT(RUT) AS SEGUROS,
	  CANAL,TRAMOS_DECIL_PD,marca_monto
FROM
(SELECT FECHA  FORMAT=date9. as fecha ,
          t1.RUT, 
		  'PWA_MIX' AS CANAL,TRAMOS_DECIL_PD,marca_monto
      FROM WORK.PWA_AVSAVVOUCHERVIEW t1
WHERE t1.PRODUCTO='SAV'
AND DISPOSITIVO<>'APP'
AND t1.PRECIOSEGURO >=1 )

GROUP BY FECHA, CANAL,TRAMOS_DECIL_PD,marca_monto
 
UNION

   SELECT FECHA,
      COUNT(RUT) AS SEGUROS,
	  CANAL,TRAMOS_DECIL_PD,marca_monto
FROM
(SELECT FECHA FORMAT=date9. as fecha ,
          t1.RUT, 
		  'MIX' AS CANAL,TRAMOS_DECIL_PD,marca_monto
      FROM WORK.PWA_AVSAVVOUCHERVIEW t1
WHERE t1.PRODUCTO='SAV'
AND t1.PRECIOSEGURO >=1 )


GROUP BY FECHA, CANAL,TRAMOS_DECIL_PD,marca_monto
;
QUIT;

PROC SQL;
   CREATE TABLE WORK.SEGUROS_SAV AS 
   SELECT DISTINCT t1.fecha, 
          t1.SEGUROS, 
          case when t1.CANAL is null then 'OTRO' 
		  when t1.CANAL=''  then 'OTRO' 

else  t1.CANAL  

           end as CANAL,TRAMOS_DECIL_PD,marca_monto
      FROM WORK.SEGUROS_SAV t1;
QUIT;


PROC SQL;
   CREATE TABLE WORK.SEGUROS_SAV AS 
   SELECT t1.fecha, 
          /* MAX_of_SEGUROS */
            (MAX(t1.SEGUROS)) AS SEGUROS, 
          t1.CANAL,TRAMOS_DECIL_PD,marca_monto
      FROM WORK.SEGUROS_SAV t1
      GROUP BY t1.fecha,
               t1.CANAL,TRAMOS_DECIL_PD,marca_monto;
QUIT;



PROC SQL;
   CREATE TABLE WORK.seguros_consumo AS 



   SELECT fecha FORMAT=date9. AS FECHA,
      COUNT(RUT) AS SEGUROS,
	  CANAL,TRAMOS_DECIL_PD,marca_monto
FROM
(SELECT datepart(FECHACURSE)  FORMAT=date9. as fecha ,
          t1.RUT, 
		  t1.dISPOSITIVO  as canal,
coalesce(t3.TRAMOS_DECIL_PD,'21.NO APLICA') as TRAMOS_DECIL_PD,marca_monto
      FROM libbehb.PersonalLoanView t1
	  left join work.oferta_APROBADOS_SAV_2 T3 
ON (INPUT((SUBSTR(t1.rut,1,(LENGTH(t1.rut)-1))),BEST.)=t3.rut AND year(datepart(FechaCurse))*100+month(datepart(FechaCurse))=T3.PERIODO)

WHERE datepart(FechaCurse)>="14dec2020"D 
AND (t1.SeguroDesgravamen >=1 or t1.SeguroVida >=1) )

GROUP BY fecha , CANAL,TRAMOS_DECIL_PD,marca_monto

UNION

   SELECT FECHA,
      COUNT(RUT) AS SEGUROS,
	  CANAL,TRAMOS_DECIL_PD,marca_monto
FROM
(SELECT datepart(FECHACURSE)  FORMAT=date9. as fecha ,
          t1.RUT, 
		  'PWA_APP_MIX' AS CANAL
       ,
coalesce(t3.TRAMOS_DECIL_PD,'21.NO APLICA') as TRAMOS_DECIL_PD,marca_monto
      FROM libbehb.PersonalLoanView t1
	  left join work.oferta_APROBADOS_SAV_2 T3 
ON (INPUT((SUBSTR(t1.rut,1,(LENGTH(t1.rut)-1))),BEST.)=t3.rut AND year(datepart(FechaCurse))*100+month(datepart(FechaCurse))=T3.PERIODO)

WHERE datepart(FechaCurse)>="14dec2020"D 
AND (t1.SeguroDesgravamen >=1 or t1.SeguroVida >=1) )


GROUP BY fecha, CANAL,TRAMOS_DECIL_PD,marca_monto
UNION

   SELECT FECHA,
      COUNT(RUT) AS SEGUROS,
	  CANAL,TRAMOS_DECIL_PD,marca_monto
FROM
(SELECT datepart(FECHACURSE)  FORMAT=date9. as fecha ,
          t1.RUT, 
		  'MIX' AS CANAL,
coalesce(t3.TRAMOS_DECIL_PD,'21.NO APLICA') as TRAMOS_DECIL_PD,marca_monto
      FROM libbehb.PersonalLoanView t1
	  left join work.oferta_APROBADOS_SAV_2 T3 
ON (INPUT((SUBSTR(t1.rut,1,(LENGTH(t1.rut)-1))),BEST.)=t3.rut AND year(datepart(FechaCurse))*100+month(datepart(FechaCurse))=T3.PERIODO)

WHERE datepart(FechaCurse)>="14dec2020"D 
AND (t1.SeguroDesgravamen >=1 or t1.SeguroVida >=1) )


GROUP BY fecha, CANAL,TRAMOS_DECIL_PD,marca_monto
;
QUIT;

PROC SQL;
   CREATE TABLE WORK.CAPTA_SALIDA_TR AS 
   SELECT t1.RUT_CLIENTE AS CLIENTE, 
          t1.PRODUCTO, 
          t1.FECHA,
		  YEAR(t1.FECHA)*100+MONTH(t1.FECHA) AS PERIODO,
		  'MIX' AS CANAL
      FROM RESULT.CAPTA_SALIDA t1
      WHERE t1.COD_SUCURSAL = 39
      AND t1.via = 'HOMEBAN'
	  AND t1.PRODUCTO='TR'
;
QUIT;

proc sql;
create table  CAPTA_SALIDA_TR as 
select 
t1.*,
coalesce(t3.TRAMOS_DECIL_PD,'21.NO APLICA') as TRAMOS_DECIL_PD,
coalesce(t3.marca_monto,'NO APLICA') as marca_monto
from CAPTA_SALIDA_TR t1
	  left join work.oferta_APROBADOS_SAV_2 T3 
ON (t1.CLIENTE=t3.rut AND t1.PERIODO=T3.PERIODO)
;QUIT;

PROC SQL;
   CREATE TABLE WORK.CAPTA_SALIDA_TAM AS 
   SELECT t1.RUT_CLIENTE AS CLIENTE, 
          t1.PRODUCTO, 
          t1.FECHA,
		  YEAR(t1.FECHA)*100+MONTH(t1.FECHA) AS PERIODO,
		  'MIX' AS CANAL
      FROM RESULT.CAPTA_SALIDA t1
      WHERE t1.COD_SUCURSAL = 39
      AND t1.via = 'HOMEBAN'
	  AND t1.PRODUCTO='TAM'
;
QUIT;

proc sql;
create table  CAPTA_SALIDA_TAM as 
select 
t1.*,
coalesce(t3.TRAMOS_DECIL_PD,'21.NO APLICA') as TRAMOS_DECIL_PD,
coalesce(t3.marca_monto,'NO APLICA') as marca_monto
from CAPTA_SALIDA_TAM t1
	  left join work.oferta_APROBADOS_SAV_2 T3 
ON (t1.CLIENTE=t3.rut AND t1.PERIODO=T3.PERIODO)
;QUIT;

PROC SQL;
   CREATE TABLE WORK.CAPTA_SALIDA_VISTA AS 
   SELECT t1.RUT_CLIENTE AS CLIENTE, 
          t1.PRODUCTO, 
          t1.FECHA,
		  YEAR(t1.FECHA)*100+MONTH(t1.FECHA) AS PERIODO,
		  'MIX' AS CANAL
      FROM RESULT.CAPTA_SALIDA t1
      WHERE t1.COD_SUCURSAL = 39
      AND t1.via = 'HOMEBAN'
      AND t1.PRODUCTO  ='CUENTA VISTA'
;
QUIT;

proc sql;
create table  CAPTA_SALIDA_VISTA as 
select 
t1.*,
coalesce(t3.TRAMOS_DECIL_PD,'21.NO APLICA') as TRAMOS_DECIL_PD,
coalesce(t3.marca_monto,'NO APLICA') as marca_monto
from CAPTA_SALIDA_VISTA t1
	  left join work.oferta_APROBADOS_SAV_2 T3 
ON (t1.CLIENTE=t3.rut AND t1.PERIODO=T3.PERIODO)
;QUIT;

PROC SQL;
   CREATE TABLE WORK.CAPTA_SALIDA_MINIMO_TAM AS 
   SELECT t1.CLIENTE, 
          t1.PRODUCTO, 
          /* MIN_of_FECHA */
            (MIN(t1.FECHA)) FORMAT=DATE9. AS FECHA, 
          t1.PERIODO, 
          t1.CANAL,TRAMOS_DECIL_PD,marca_monto
      FROM WORK.CAPTA_SALIDA_TAM t1
      GROUP BY t1.CLIENTE,
               t1.PRODUCTO,
               t1.PERIODO,
               t1.CANAL,TRAMOS_DECIL_PD,marca_monto;
QUIT;

PROC SQL;
   CREATE TABLE WORK.CAPTA_SALIDA_MINIMO_TR AS 
   SELECT t1.CLIENTE, 
          t1.PRODUCTO, 
          /* MIN_of_FECHA */
            (MIN(t1.FECHA)) FORMAT=DATE9. AS FECHA, 
          t1.PERIODO, 
          t1.CANAL,TRAMOS_DECIL_PD,marca_monto
      FROM WORK.CAPTA_SALIDA_TR t1
      GROUP BY t1.CLIENTE,
               t1.PRODUCTO,
               t1.PERIODO,
               t1.CANAL,TRAMOS_DECIL_PD,marca_monto;
QUIT;


PROC SQL;
   CREATE TABLE WORK.CAPTA_SALIDA_MINIMO_VISTA AS 
   SELECT t1.CLIENTE, 
          t1.PRODUCTO, 
          /* MIN_of_FECHA */
            (MIN(t1.FECHA)) FORMAT=DATE9. AS FECHA, 
          t1.PERIODO, 
          t1.CANAL,TRAMOS_DECIL_PD,marca_monto
      FROM WORK.CAPTA_SALIDA_VISTA t1
      GROUP BY t1.CLIENTE,
               t1.PRODUCTO,
               t1.PERIODO,
               t1.CANAL,TRAMOS_DECIL_PD,marca_monto;
QUIT;


PROC SQL;
   CREATE TABLE WORK.CUENTA_TAM AS 
   SELECT t1.FECHA, 
          /* COUNT_DISTINCT_of_CLIENTE */
            (COUNT(DISTINCT(t1.CLIENTE))) AS CAPTAS_TAM, 
          t1.PRODUCTO,
		  'MIX' AS CANAL,TRAMOS_DECIL_PD,marca_monto
      FROM WORK.CAPTA_SALIDA_MINIMO_TAM t1
      GROUP BY t1.FECHA,
               t1.PRODUCTO,TRAMOS_DECIL_PD,marca_monto;
QUIT;

PROC SQL;
   CREATE TABLE WORK.CUENTA_TR AS 
   SELECT t1.FECHA, 
          /* COUNT_DISTINCT_of_CLIENTE */
            (COUNT(DISTINCT(t1.CLIENTE))) AS CAPTAS_TR, 
          t1.PRODUCTO,
		  'MIX' AS CANAL,TRAMOS_DECIL_PD,marca_monto
      FROM WORK.CAPTA_SALIDA_MINIMO_TR t1
      GROUP BY t1.FECHA,
               t1.PRODUCTO,TRAMOS_DECIL_PD,marca_monto;
QUIT;

PROC SQL;
   CREATE TABLE WORK.CUENTA_VISTA AS 
   SELECT t1.FECHA, 
          /* COUNT_DISTINCT_of_CLIENTE */
            (COUNT(DISTINCT(t1.CLIENTE))) AS CAPTAS_VISTA, 
          t1.PRODUCTO,
		  'MIX' AS CANAL,TRAMOS_DECIL_PD,marca_monto
      FROM WORK.CAPTA_SALIDA_MINIMO_VISTA t1
      GROUP BY t1.FECHA,
               t1.PRODUCTO,TRAMOS_DECIL_PD,marca_monto;
QUIT;





LIBNAME ORACLOUD ORACLE sql_functions=all  READBUFF=1000  INSERTBUFF=1000  PATH="REPORTSAS.WORLD"  SCHEMA=SAS_ADM authdomain=DBOracleCloud_Auth;
  

PROC SQL;
   CREATE TABLE &libreria..RESUMEN_KPI_INTERNET_y_v3 AS 
   SELECT DISTINCT 
t1.TRAMOS_DECIL_PD,t1.marca_monto,
t1.CREATED_AT FORMAT=DATE9. as fecha, 
          t1.DEVICE as canal,
          t2.logueos_acumulados,
		  t3.oferta_sav,
		  t4.oferta_av,
		  t4c.oferta_consumo,
		  X.OFERTA_av as oferta_av_acumulada,
		  XT.OFERTA_Sav as oferta_sav_acumulada,
		  Xc.OFERTA_consumo as oferta_cons_acumulada,
		  X1.MONTO_AV,
		  X1.TRX_AV,
		  X2.MONTO_SAV,
		  X2.TRX_SAV,
		  XC2.MONTO_CONSUMO,
		  XC2.TRX_CONSUMO,
		  t1.LOGUEOS_DIARIOS, 
		  t5.OFTA_SAV_DIARIA,
		  t6.OFTA_AV_DIARIA,
		  t6c.OFTA_CONSUMO_DIARIA,
P.SIMS_AV AS SIMULACIONES_AV,
O.SIMS_SAV AS SIMULACIONES_SAV,
Pco.SIMS_CONS AS SIMULACIONES_CONS,
O2.SIMS_SAV AS SIMS_SAV_DIARIAS,
P2.SIMS_AV AS SIMS_AV_DIARIAS,
PX2.SIMS_CONS AS SIMS_CONS_DIARIAS,
bX.SEGUROS AS Seguros_Av,
bH.SEGUROS AS Seguros_Sav,
		  TTT.CAPTAS_TAM,
		  XXX.CAPTAS_TR,
		  VVV.CAPTAS_VISTA
,bcH.SEGUROS AS Seguros_consumo
         
      FROM WORK.LOGUEOS_DIARIOS t1 
left join WORK.logueos_acumulados t2 on (t1.CREATED_AT=t2.fecha and UPCASE(t1.DEVICE)=UPCASE(t2.canal)) and (t1.TRAMOS_DECIL_PD=t2.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(t2.marca_monto,'NO APLICA'))
left join WORK.sav_acumulados t3 on (t1.CREATED_AT=t3.fecha and UPCASE(t1.DEVICE)=UPCASE(t3.canal)) and (t1.TRAMOS_DECIL_PD=t3.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(t3.marca_monto,'NO APLICA'))
left join WORK.av_acumulados t4 on (t1.CREATED_AT=t4.fecha and UPCASE(t1.DEVICE)=UPCASE(t4.canal)) and  (t1.TRAMOS_DECIL_PD=t4.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(t4.marca_monto,'NO APLICA'))
left join WORK.consumo_acumulados t4c on (t1.CREATED_AT=t4c.fecha and UPCASE(t1.DEVICE)=UPCASE(t4c.canal))  and (t1.TRAMOS_DECIL_PD=t4c.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(t4c.marca_monto,'NO APLICA'))
left join WORK.OFERTADO_DIARIOS_sAV t5 on (t1.CREATED_AT=t5.CREATED_AT and UPCASE(t1.DEVICE)=UPCASE(t5.DEVICE)) and (t1.TRAMOS_DECIL_PD=t5.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(t5.marca_monto,'NO APLICA'))
left join WORK.OFERTADO_DIARIOS_AV t6 on (t1.CREATED_AT=t6.CREATED_AT and UPCASE(t1.DEVICE)=UPCASE(t6.DEVICE)) and (t1.TRAMOS_DECIL_PD=t6.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(t6.marca_monto,'NO APLICA'))
left join WORK.OFERTADO_DIARIOS_consumo t6c on (t1.CREATED_AT=t6c.CREATED_AT and UPCASE(t1.DEVICE)=UPCASE(t6c.DEVICE)) and  (t1.TRAMOS_DECIL_PD=t6c.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(t6c.marca_monto,'NO APLICA'))
left join &libreria..VENTA_AGRUPADA_USO t7 on (t1.CREATED_AT=t7.fecha and UPCASE(t1.DEVICE)=UPCASE(t7.canal)) and (t1.TRAMOS_DECIL_PD=t7.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(t7.marca_monto,'NO APLICA'))
left join WORK.SIMULACIONES_SAV_INC O ON (t1.CREATED_AT=O.MIN_of_fecha AND UPCASE(t1.DEVICE)=UPCASE(O.canal )) and (t1.TRAMOS_DECIL_PD=o.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(o.marca_monto,'NO APLICA'))
left join WORK.SIMULACIONES_AV_INC P ON (t1.CREATED_AT=P.MIN_of_fecha AND UPCASE(t1.DEVICE)=UPCASE(P.canal )) and (t1.TRAMOS_DECIL_PD=p.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(p.marca_monto,'NO APLICA'))
left join WORK.SIMULACIONES_CONS_INC Pco ON (t1.CREATED_AT=Pco.MIN_of_fecha AND UPCASE(t1.DEVICE)=UPCASE(Pco.canal )) and (t1.TRAMOS_DECIL_PD=pco.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(pco.marca_monto,'NO APLICA'))
left join WORK.SIMULACIONES_DIARIAS_SAV O2 ON (t1.CREATED_AT=O2.FECHA AND UPCASE(t1.DEVICE)=UPCASE(O2.canal) ) and (t1.TRAMOS_DECIL_PD=o2.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(o2.marca_monto,'NO APLICA'))
left join WORK.SIMULACIONES_DIARIAS_AV P2 ON (t1.CREATED_AT=P2.FECHA AND UPCASE(t1.DEVICE)=UPCASE(P2.canal )) and (t1.TRAMOS_DECIL_PD=p2.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(p2.marca_monto,'NO APLICA'))
left join WORK.SIMULACIONES_DIARIAS_CONS PX2 ON (t1.CREATED_AT=PX2.FECHA AND UPCASE(t1.DEVICE)=UPCASE(PX2.canal )) and (t1.TRAMOS_DECIL_PD=px2.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(px2.marca_monto,'NO APLICA'))
left join WORK.seguros_av bX ON (bX.FECHA=t1.CREATED_AT AND UPCASE(bX.canal)=UPCASE(t1.DEVICE )) and (t1.TRAMOS_DECIL_PD=bx.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(bx.marca_monto,'NO APLICA'))
left join WORK.seguros_sav bH ON (bH.FECHA=t1.CREATED_AT AND UPCASE(bH.canal)=UPCASE(t1.DEVICE )) and (t1.TRAMOS_DECIL_PD=bh.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(bh.marca_monto,'NO APLICA'))
left join WORK.seguros_consumo bCH ON (bCH.FECHA=t1.CREATED_AT AND UPCASE(bCH.canal)=UPCASE(t1.DEVICE )) and (t1.TRAMOS_DECIL_PD=bch.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(bch.marca_monto,'NO APLICA'))
left join WORK.USO_AV X ON (X.FECHA=t1.CREATED_AT AND UPCASE(X.canal)=UPCASE(t1.DEVICE )) and (t1.TRAMOS_DECIL_PD=x.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(x.marca_monto,'NO APLICA'))
left join WORK.USO_SAV XT ON (XT.FECHA=t1.CREATED_AT AND UPCASE(XT.canal)=UPCASE(t1.DEVICE )) and (t1.TRAMOS_DECIL_PD=xt.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(xt.marca_monto,'NO APLICA'))
left join WORK.USO_consumo Xc ON (Xc.FECHA=t1.CREATED_AT AND UPCASE(Xc.canal)=UPCASE(t1.DEVICE )) and (t1.TRAMOS_DECIL_PD=xc.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(xc.marca_monto,'NO APLICA'))
left join WORK.VENTA_AV X1 ON (X1.FECHA=t1.CREATED_AT AND UPCASE(X1.canal)=UPCASE(t1.DEVICE )) and (t1.TRAMOS_DECIL_PD=x1.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(x1.marca_monto,'NO APLICA'))
left join WORK.VENTA_SAV X2 ON (X2.FECHA=t1.CREATED_AT AND UPCASE(X2.canal)=UPCASE(t1.DEVICE )) and (t1.TRAMOS_DECIL_PD=x2.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(x2.marca_monto,'NO APLICA'))
left join WORK.VENTA_CONSUMO Xc2 ON (Xc2.FECHA=t1.CREATED_AT AND UPCASE(Xc2.canal)=UPCASE(t1.DEVICE )) and (t1.TRAMOS_DECIL_PD=xc2.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(xc2.marca_monto,'NO APLICA'))
left join WORK.CUENTA_TAM TTT ON (TTT.FECHA=t1.CREATED_AT AND UPCASE(TTT.canal)=UPCASE(t1.DEVICE )) and (t1.TRAMOS_DECIL_PD=ttt.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(ttt.marca_monto,'NO APLICA'))
left join WORK.CUENTA_TR XXX ON (XXX.FECHA=t1.CREATED_AT AND UPCASE(XXX.canal)=UPCASE(t1.DEVICE )) and (t1.TRAMOS_DECIL_PD=xxx.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(xxx.marca_monto,'NO APLICA'))
left join WORK.CUENTA_VISTA VVV ON (VVV.FECHA=t1.CREATED_AT AND UPCASE(VVV.canal)=UPCASE(t1.DEVICE )) and (t1.TRAMOS_DECIL_PD=vvv.TRAMOS_DECIL_PD) and (t1.marca_monto=coalesce(vvv.marca_monto,'NO APLICA'))

;
QUIT;



PROC SQL;
   CREATE TABLE &libreria..RESUMEN_KPI_INTERNET_X_v4 AS 
   SELECT  t1.TRAMOS_DECIL_PD,t1.marca_monto,
t1.fecha, 
          t1.canal, 
          t1.logueos_acumulados, 
          t1.oferta_sav, 
          t1.oferta_av, 
          t1.oferta_CONSUMO, 
          t1.oferta_av_acumulada, 
          t1.oferta_sav_acumulada, 
          t1.oferta_cons_acumulada, 
          t1.MONTO_AV, 
          t1.TRX_AV, 
          t1.MONTO_SAV, 
          t1.TRX_SAV, 
          t1.MONTO_consumo, 
          t1.TRX_CONSUMO, 
          t1.LOGUEOS_DIARIOS, 
          t1.OFTA_SAV_DIARIA, 
          t1.OFTA_AV_DIARIA, 
          t1.OFTA_CONSUMO_DIARIA, 
          t1.SIMULACIONES_AV, 
          t1.SIMULACIONES_SAV, 
          t1.SIMULACIONES_CONS, 
          t1.SIMS_SAV_DIARIAS, 
          t1.SIMS_AV_DIARIAS, 
          t1.SIMS_CONS_DIARIAS, 
          t1.Seguros_Av, 
          t1.Seguros_Sav,
		  CAPTAS_TAM,
		  CAPTAS_TR,
		  CAPTAS_VISTA
, Seguros_consumo
      FROM &libreria..RESUMEN_KPI_INTERNET_y_v3 t1
	  	  where fecha>="&ini_mes."d 

	  union

   SELECT 
 TRAMOS_DECIL_PD,marca_monto,
t1.fecha, 
          t1.canal, 
          t1.logueos_acumulados, 
          t1.oferta_sav, 
          t1.oferta_av, 
		  oferta_CONSUMO, 
          t1.oferta_av_acumulada, 
          t1.oferta_sav_acumulada, 
		  oferta_cons_acumulada,
          t1.MONTO_AV, 
          t1.TRX_AV, 
          t1.MONTO_SAV, 
          t1.TRX_SAV,
          MONTO_consumo, 
          TRX_CONSUMO, 
          t1.LOGUEOS_DIARIOS, 
          t1.OFTA_SAV_DIARIA, 
          t1.OFTA_AV_DIARIA, 
          OFTA_CONSUMO_DIARIA, 
          t1.SIMULACIONES_AV, 
          t1.SIMULACIONES_SAV, 
		  SIMULACIONES_CONS,
          t1.SIMS_SAV_DIARIAS, 
          t1.SIMS_AV_DIARIAS, 
		  SIMS_CONS_DIARIAS,
          t1.Seguros_Av, 
          t1.Seguros_Sav,
		  CAPTAS_TAM,
		  CAPTAS_TR,
		  CAPTAS_VISTA,
		  Seguros_consumo
      FROM  &libreria..RESUMEN_KPI_INTERNET_X_v4 t1
	  where fecha <"&ini_mes."d 
	  AND t1.canal<>''
	  and t1.canal in (

	  'APP_1','APP',
'HB',
'MIX',
'PWA_APP_MIX',
'DESKTOP',
'MOBILE',
'PWA_MIX')

;
QUIT;


PROC SQL;
   CREATE TABLE &libreria..VISTAS_KPI AS 
   SELECT t1.fecha, 
          t1.canal, 
          /* logueos_acumulados */
            (SUM(t1.logueos_acumulados)) AS logueos_acumulados, 
          /* oferta_sav */
            (SUM(t1.oferta_sav)) AS oferta_sav, 
          /* oferta_av */
            (SUM(t1.oferta_av)) AS oferta_av, 
          /* oferta_CONSUMO */
            (SUM(t1.oferta_CONSUMO)) AS oferta_CONSUMO, 
          /* oferta_av_acumulada */
            (SUM(t1.oferta_av_acumulada)) AS oferta_av_acumulada, 
          /* oferta_sav_acumulada */
            (SUM(t1.oferta_sav_acumulada)) AS oferta_sav_acumulada, 
          /* oferta_cons_acumulada */
            (SUM(t1.oferta_cons_acumulada)) AS oferta_cons_acumulada, 
          /* MONTO_AV */
            (SUM(t1.MONTO_AV)) FORMAT=11. AS MONTO_AV, 
          /* TRX_AV */
            (SUM(t1.TRX_AV)) AS TRX_AV, 
          /* MONTO_SAV */
            (SUM(t1.MONTO_SAV)) FORMAT=11. AS MONTO_SAV, 
          /* TRX_SAV */
            (SUM(t1.TRX_SAV)) AS TRX_SAV, 
          /* MONTO_consumo */
            (SUM(t1.MONTO_consumo)) FORMAT=11. AS MONTO_consumo, 
          /* TRX_CONSUMO */
            (SUM(t1.TRX_CONSUMO)) AS TRX_CONSUMO, 
          /* LOGUEOS_DIARIOS */
            (SUM(t1.LOGUEOS_DIARIOS)) AS LOGUEOS_DIARIOS, 
          /* OFTA_SAV_DIARIA */
            (SUM(t1.OFTA_SAV_DIARIA)) AS OFTA_SAV_DIARIA, 
          /* OFTA_AV_DIARIA */
            (SUM(t1.OFTA_AV_DIARIA)) AS OFTA_AV_DIARIA, 
          /* OFTA_CONSUMO_DIARIA */
            (SUM(t1.OFTA_CONSUMO_DIARIA)) AS OFTA_CONSUMO_DIARIA, 
          /* SIMULACIONES_AV */
            (SUM(t1.SIMULACIONES_AV)) AS SIMULACIONES_AV, 
          /* SIMULACIONES_SAV */
            (SUM(t1.SIMULACIONES_SAV)) AS SIMULACIONES_SAV, 
          /* SIMULACIONES_CONS */
            (SUM(t1.SIMULACIONES_CONS)) AS SIMULACIONES_CONS, 
          /* SIMS_SAV_DIARIAS */
            (SUM(t1.SIMS_SAV_DIARIAS)) AS SIMS_SAV_DIARIAS, 
          /* SIMS_AV_DIARIAS */
            (SUM(t1.SIMS_AV_DIARIAS)) AS SIMS_AV_DIARIAS, 
          /* SIMS_CONS_DIARIAS */
            (SUM(t1.SIMS_CONS_DIARIAS)) AS SIMS_CONS_DIARIAS, 
          /* Seguros_Av */
            (SUM(t1.Seguros_Av)) AS Seguros_Av, 
          /* Seguros_Sav */
            (SUM(t1.Seguros_Sav)) AS Seguros_Sav, 
          /* CAPTAS_TAM */
            (SUM(t1.CAPTAS_TAM)) AS CAPTAS_TAM, 
          /* CAPTAS_TR */
            (SUM(t1.CAPTAS_TR)) AS CAPTAS_TR, 
          /* CAPTAS_VISTA */
            (SUM(t1.CAPTAS_VISTA)) AS CAPTAS_VISTA, 
          /* Seguros_consumo */
            (SUM(t1.Seguros_consumo)) AS Seguros_consumo
      FROM &libreria..RESUMEN_KPI_INTERNET_X_V4 t1
      GROUP BY t1.fecha,
               t1.canal;
QUIT;


proc sql;
create table &libreria..resumen_kpi_internet as 
select * from &libreria..VISTAS_KPI 
;quit;

/*== Export a AWS para tableau ==== EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(DGTL_RESUMEN_KPI_INTERNET,raw,oracloud,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(DGTL_RESUMEN_KPI_INTERNET,result.resumen_kpi_internet,raw,oracloud,0);



/*==============================    	EXPORTAR A AWS - END		 ===============================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

PROC EXPORT DATA=&libreria..RESUMEN_KPI_INTERNET_X_v4
DBMS=xlsx 
OUTFILE= "/sasdata/users94/user_bi/TRASPASO_DOCS/RESUMEN_KPI_INTERNET_X_v4.xlsx"
  replace
;RUN;

proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
quit;

%put &=EDP_BI;

data _null_;
FILENAME OUTBOX EMAIL
SUBJECT="MAIL_AUTOM: Actualización result.RESUMEN_KPI_INTERNET_X  %sysfunc(date(),yymmdd10.)"
FROM = ("&EDP_BI")
TO = ("pmunozc@bancoripley.com","rarcosm@bancoripley.com","tpiwonkas@bancoripley.com")
 CC      = ("nverdejog@bancoripley.com")
	attach =("/sasdata/users94/user_bi/TRASPASO_DOCS/RESUMEN_KPI_INTERNET_X_v4.xlsx" content_type="excel") 
	  Type    = 'Text/Plain';

FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Data actualizada &libreria..RESUMEN_KPI_INTERNET_X_v4";  
 put ; 
 put ; 
 PUT ;
PUT 'Atte.';
Put ' Equipo Arquitectura de Datos y Automatización BI ';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;










