/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*================================= 	MODELO_PERFIL_INTERNET		================================*/
/* CONTROL DE VERSIONES
/* 2021-06-02 -- V4 -- Sergio J. -- Nueva Versi�n Autom�tica Equipo Datos y Procesos BI
					-- Llamado de variables user y password
/* 2020-02-06 -- V3 -- EDMUNDO P. -- Nueva Versi�n Autom�tica Equipo Datos y Procesos BI
								  -- Modificaciones realizadas por Edmundo
/* 2020-01-06 -- V2 -- EDMUNDO P. -- Nueva Versi�n Autom�tica Equipo Datos y Procesos BI
								  -- Se agrega la declaraci�n noprint

/* 2020-01-05 -- V1 -- EDMUNDO P. -- Nueva Versi�n Autom�tica Equipo Datos y Procesos BI
					-- 
*/

ods _all_ close;

/*	DECLARACI�N VARIABLE TIEMPO		*/
%let tiempo_inicio = %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*	Llamado de user y password		*/
proc sql noprint;                              
SELECT USUARIO into :USER 
	FROM sasdyp.user_pass WHERE SCHEMA = 'SFRIES_ADM';
SELECT PASSWORD into :PASSWORD 
	FROM sasdyp.user_pass WHERE SCHEMA = 'SFRIES_ADM';
quit;
%put &USER;
%put &PASSWORD;
/*=========*/


    %let mz_connect_HB = CONNECT TO ORACLE as hbpri_adm(USER='RIPLEYC' PASSWORD='ri99pley'
	PATH="  (DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))
	(CONNECT_DATA = (SID = ripleyc)))");


LIBNAME ORACLOUD ORACLE sql_functions=all  READBUFF=1000  INSERTBUFF=1000  PATH="REPORTSAS.WORLD"  SCHEMA=SAS_ADM authdomain=DBOracleCloud_Auth;
 
LIBNAME R_sfries ORACLE PATH='REPORITF.world' SCHEMA='SFRIES_ADM' USER=&user. PASSWORD=&password.;

	LIBNAME MPDT ORACLE  READBUFF=1000  INSERTBUFF=1000  dbmax_text=7025  PATH="REPORITF.WORLD"  SCHEMA=GETRONICS  USER=&user. PASSWORD=&password.;
	LIBNAME BOPERS ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=BOPERS_ADM  USER=&user. PASSWORD=&password.;
	LIBNAME CAMP ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="BRTEFGESTIONP.WORLD"  SCHEMA=CAMP_ADM  USER=CAMP_COMERCIAL  PASSWORD='ccomer2409';
	LIBNAME credito ODBC  DATASRC=creditoprd  SCHEMA=GEDCRE_CREDITO  USER=CONSULTA_CREDITO  PASSWORD='CONSULTA_CREDITO';
	LIBNAME PSFC1 ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH=PSFC1  SCHEMA=GETRONICS  USER=amarinaoc  PASSWORD='amarinaoc2017' ;
	LIBNAME QANEW ORACLE  INSERTBUFF=1000  READBUFF=1000  PATH="QANEW.WORLD"  SCHEMA=RIPLEYC  USER=RIPLEYC  PASSWORD='ri99pley' ;
	LIBNAME QANEWHB ORACLE  PATH="QANEW.WORLD"  SCHEMA=HBPRI_ADM  USER=RIPLEYC  PASSWORD='ri99pley';
	LIBNAME SFRIES ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=SFRIES_ADM  USER=&user. PASSWORD=&password.;

		DATA _null_;
		datemy0 = input(put(intnx('month',today(),0,'BEGIN'),yymmn6. ),$10.);
		datemy1 = input(put(intnx('month',today(),-1,'BEGIN'),yymmn6. ),$10.);
		datemy2 = input(put(intnx('month',today(),-2,'BEGIN'),yymmn6. ),$10.);
		datemy3 = input(put(intnx('month',today(),-3,'BEGIN'),yymmn6. ),$10.);
		datemy4 = input(put(intnx('month',today(),-4,'BEGIN'),yymmn6. ),$10.);
		datemy5 = input(put(intnx('month',today(),-5,'BEGIN'),yymmn6. ),$10.);
		datemy6 = input(put(intnx('month',today(),-6,'BEGIN'),yymmn6. ),$10.);
		datemy7 = input(put(intnx('month',today(),-7,'BEGIN'),yymmn6. ),$10.);
		datemy8 = input(put(intnx('month',today(),-8,'BEGIN'),yymmn6. ),$10.);
		datemy9 = input(put(intnx('month',today(),-9,'BEGIN'),yymmn6. ),$10.);
		datemy10 = input(put(intnx('month',today(),-10,'BEGIN'),yymmn6. ),$10.);
		datemy11 = input(put(intnx('month',today(),-11,'BEGIN'),yymmn6. ),$10.);
		datemy12 = input(put(intnx('month',today(),-12,'BEGIN'),yymmn6. ),$10.);
		datemy13 = input(put(intnx('month',today(),-13,'BEGIN'),yymmn6. ),$10.);
	    dated0 = input(put(intnx('month',today(),0,'SAME'),date9. ),$10.) ;
	    dated00 = input(put(intnx('month',today(),0,'BEGIN'),date9. ),$10.) ;
	    dated1 = input(put(intnx('month',today(),-1,'BEGIN'),date9. ),$10.) ;
	    dated2 = input(put(intnx('month',today(),-2,'BEGIN'),date9. ),$10.) ;
	    dated12 = input(put(intnx('month',today(),-13,'BEGIN'),date9. ),$10.) ;
		datey1 = input(put(intnx('month',today(),-1,'BEGIN'),year. ),best.)  ;

		Call symput("fechamy0", datemy0);
			Call symput("fechamy1", datemy1);
				Call symput("fechamy2", datemy2);
					Call symput("fechamy3", datemy3);
						Call symput("fechamy4", datemy4);
							Call symput("fechamy5", datemy5);
								Call symput("fechamy6", datemy6);
									Call symput("fechamy7", datemy7);
										Call symput("fechamy8", datemy8);
											Call symput("fechamy9", datemy9);
												Call symput("fechamy10", datemy10);
													Call symput("fechamy11", datemy11);
														Call symput("fechamy12", datemy12);
														     Call symput("fechamy13", datemy13);


		
		Call symput("fechad0", dated0);
		Call symput("fechad00", dated00);
		Call symput("fechad1", dated1);
		Call symput("fechad2", dated2);
		     Call symput("fechad12", dated12);
		     Call symput("fechad13", dated13);
		RUN;

		%put &fechamy0;
		%put &fechad1;
		%put &fechad0;
		%put &fechad12;
		%put &fechamy13;
		%put &fechamy12;



/*	Apilo los logueos de todos los periodos en una tabla*/

proc sql inobs= 100;
create table LOGs  as

select  RUT, fecha_LOGUEO FORMAT=DATE9. as fecha from publicin.LOGEO_INT_&fechamy1 union
select  RUT, fecha_LOGUEO FORMAT=DATE9. as fecha from publicin.LOGEO_INT_&fechamy2 union
select  RUT, fecha_LOGUEO FORMAT=DATE9. as fecha from publicin.LOGEO_INT_&fechamy3 union
select  RUT, fecha_LOGUEO FORMAT=DATE9. as fecha from publicin.LOGEO_INT_&fechamy4  union
select  RUT, fecha_LOGUEO FORMAT=DATE9. as fecha from publicin.LOGEO_INT_&fechamy5  union
select  RUT, fecha_LOGUEO FORMAT=DATE9. as fecha from publicin.LOGEO_INT_&fechamy6  union
select  RUT, fecha_LOGUEO FORMAT=DATE9. as fecha from publicin.LOGEO_INT_&fechamy7  union
select  RUT, fecha_LOGUEO FORMAT=DATE9. as fecha from publicin.LOGEO_INT_&fechamy8  union
select  RUT, fecha_LOGUEO FORMAT=DATE9. as fecha from publicin.LOGEO_INT_&fechamy9  union
select  RUT, fecha_LOGUEO FORMAT=DATE9. as fecha from publicin.LOGEO_INT_&fechamy10  union
select  RUT, fecha_LOGUEO FORMAT=DATE9. as fecha from publicin.LOGEO_INT_&fechamy11  union
select  RUT, fecha_LOGUEO FORMAT=DATE9. as fecha from publicin.LOGEO_INT_&fechamy12       
;quit;



	/* -------------------------------------------------------------------------------------------------*/

	/* CALCULO DE LA INTENSIDAD DE USO DE LAS PLATAFORMAS DIGITALES*/
	 
	   /*  horizonte de evaluaci�n= 1 a�o m�vil sin considerar el mes en curso*/
	/* -------------------------------------------------------------------------------------------------*/


	/*a01. se toman los cierres desde logueos mensuales, se consolidan y se trabajan las fechas para calcular Rec y Frec */


		proc sql ;
		   create table logueos_CUENTA as 
		   select t1.RUT,
		             input(put(t1.fecha,yymmn6.),best.) as FECHA,
					 input(put(t1.fecha,yymmddn8.),best.) as FECHA_DIA,
					 12-(intck('month',  fecha,"&fechad1"d)) AS RECENCIA
					
		      from WORK.LOGs t1 

		;
		quit;


	/*a03.se calculan las trx de pago epu*/


PROC SQL;
   CREATE TABLE WORK.pagos_fuera AS 
   SELECT t1.RUT, INPUT((substr(t1.FECFAC,9,2)||'-'||substr(t1.FECFAC,6,2)||'-'||substr(t1.FECFAC,1,4)),DDMMYY10.)  AS FECHA
FROM EPIELH.PAGOS_DIGITALES_&fechamy1 t1   WHERE t1.TIPO IN    ( 'HB_SERV',  'KIPHU')
union

   SELECT t1.RUT, INPUT((substr(t1.FECFAC,9,2)||'-'||substr(t1.FECFAC,6,2)||'-'||substr(t1.FECFAC,1,4)),DDMMYY10.)  AS FECHA
FROM EPIELH.PAGOS_DIGITALES_&fechamy2 t1   WHERE t1.TIPO IN       ( 'HB_SERV',  'KIPHU')
union

   SELECT t1.RUT, INPUT((substr(t1.FECFAC,9,2)||'-'||substr(t1.FECFAC,6,2)||'-'||substr(t1.FECFAC,1,4)),DDMMYY10.)  AS FECHA
FROM EPIELH.PAGOS_DIGITALES_&fechamy3 t1   WHERE t1.TIPO IN       ( 'HB_SERV',  'KIPHU')
union

   SELECT t1.RUT, INPUT((substr(t1.FECFAC,9,2)||'-'||substr(t1.FECFAC,6,2)||'-'||substr(t1.FECFAC,1,4)),DDMMYY10.)  AS FECHA
FROM EPIELH.PAGOS_DIGITALES_&fechamy4 t1   WHERE t1.TIPO IN      ( 'HB_SERV',  'KIPHU')
union

   SELECT t1.RUT, INPUT((substr(t1.FECFAC,9,2)||'-'||substr(t1.FECFAC,6,2)||'-'||substr(t1.FECFAC,1,4)),DDMMYY10.)  AS FECHA
FROM EPIELH.PAGOS_DIGITALES_&fechamy5 t1   WHERE t1.TIPO IN       ( 'HB_SERV',  'KIPHU')
union

   SELECT t1.RUT, INPUT((substr(t1.FECFAC,9,2)||'-'||substr(t1.FECFAC,6,2)||'-'||substr(t1.FECFAC,1,4)),DDMMYY10.)  AS FECHA
FROM EPIELH.PAGOS_DIGITALES_&fechamy6 t1   WHERE t1.TIPO IN       ( 'HB_SERV',  'KIPHU')
union

   SELECT t1.RUT, INPUT((substr(t1.FECFAC,9,2)||'-'||substr(t1.FECFAC,6,2)||'-'||substr(t1.FECFAC,1,4)),DDMMYY10.)  AS FECHA
FROM EPIELH.PAGOS_DIGITALES_&fechamy7 t1   WHERE t1.TIPO IN       ( 'HB_SERV',  'KIPHU')
union

   SELECT t1.RUT, INPUT((substr(t1.FECFAC,9,2)||'-'||substr(t1.FECFAC,6,2)||'-'||substr(t1.FECFAC,1,4)),DDMMYY10.)  AS FECHA
FROM EPIELH.PAGOS_DIGITALES_&fechamy8 t1   WHERE t1.TIPO IN       ( 'HB_SERV',  'KIPHU')
union

   SELECT t1.RUT, INPUT((substr(t1.FECFAC,9,2)||'-'||substr(t1.FECFAC,6,2)||'-'||substr(t1.FECFAC,1,4)),DDMMYY10.)  AS FECHA
FROM EPIELH.PAGOS_DIGITALES_&fechamy9 t1   WHERE t1.TIPO IN    (  'SANTANDER',  'SERVIPAG_internet',   'UNIRED')
union

   SELECT t1.RUT, INPUT((substr(t1.FECFAC,9,2)||'-'||substr(t1.FECFAC,6,2)||'-'||substr(t1.FECFAC,1,4)),DDMMYY10.)  AS FECHA
FROM EPIELH.PAGOS_DIGITALES_&fechamy10 t1   WHERE t1.TIPO IN    (  'SANTANDER',  'SERVIPAG_internet',   'UNIRED')
union

   SELECT t1.RUT, INPUT((substr(t1.FECFAC,9,2)||'-'||substr(t1.FECFAC,6,2)||'-'||substr(t1.FECFAC,1,4)),DDMMYY10.)  AS FECHA
FROM EPIELH.PAGOS_DIGITALES_&fechamy11 t1   WHERE t1.TIPO IN    (  'SANTANDER',  'SERVIPAG_internet',   'UNIRED')
union

   SELECT t1.RUT, INPUT((substr(t1.FECFAC,9,2)||'-'||substr(t1.FECFAC,6,2)||'-'||substr(t1.FECFAC,1,4)),DDMMYY10.)  AS FECHA
FROM EPIELH.PAGOS_DIGITALES_&fechamy12 t1   WHERE t1.TIPO IN    (  'SANTANDER',  'SERVIPAG_internet',   'UNIRED')



; QUIT;



	PROC SQL;
	   CREATE TABLE transaccionalidad_pagos_epu AS
select rut , count(x.rut) as trx_epu

from
( 
	   SELECT distinct t1.rut, month(fecha) as mes
	      FROM EPIELH.pagos_epu t1) x
GROUP BY x.rut
	      ;
	QUIT;

	PROC SQL;
   CREATE TABLE WORK.aux_frec AS 
   SELECT t1.RUT, 
            (COUNT(DISTINCT(t1.FECHA))) AS LOGUEOS_TOTALES, 
          /* COUNT_DISTINCT_of_FECHA */
            (COUNT(DISTINCT(t1.FECHA))) AS LOG_MESES_distinct, 
          /* COUNT_DISTINCT_of_FECHA_DIA */
            (COUNT(DISTINCT(t1.FECHA_DIA))) AS LOG_DIas_distinct
      FROM WORK.LOGUEOS_CUENTA t1
      GROUP BY t1.RUT;
QUIT;


	/*a04. se consolidan las variables de APP*/
			proc sql;
					   create table VARIABLES_total_1  as 
					   select t1.RUT,  max(recencia) as recencia,
								 min(recencia) as min_recencia
					      from WORK.logueos_CUENTA t1  
					      group by t1.RUT;
					quit;


					proc sql;
					   create table VARIABLES_total  as 
					   select t1.RUT, 
					            t4.LOGUEOS_TOTALES,
								t4.LOG_MESES_distinct,
								t4.LOG_DIas_distinct,
								t1.recencia,
								min_recencia,
								 case when  t3.trx_epu is not null then t3.trx_epu else 0 end as epus_pagos

					      from VARIABLES_total_1 t1  left join   transaccionalidad_pagos_epu t3 on (t1.rut=t3.rut)
						                             left join   aux_frec t4 on (t1.rut=t4.rut)
					      group by t1.RUT,epus_pagos;
					quit;






	PROC SQL;
	   CREATE TABLE recencia_nula AS 
	   SELECT t1.RUT, 
	          t1.LOGUEOS_TOTALES, 
	          t1.LOG_MESES_distinct, 
	          t1.LOG_DIas_distinct, 
	          t1.recencia, 
	          case when min_recencia= 0 then 1 else min_recencia end as min_recencia, 
	          t1.epus_pagos
	      FROM WORK.VARIABLES_total t1;
	QUIT;

	PROC SQL;
	   CREATE TABLE VARIABLES_total AS 
	   SELECT t1.RUT, 
	          t1.LOGUEOS_TOTALES*t1.min_recencia as LOGUEOS_TOTALES, 
	          t1.LOG_MESES_distinct*t1.min_recencia as LOG_MESES_distinct, 
	          t1.LOG_DIas_distinct*t1.min_recencia  as LOG_DIas_distinct, 
	          t1.recencia, 
	          t1.epus_pagos*t1.min_recencia as epus_pagos
	      FROM WORK.RECENCIA_NULA t1;
	QUIT;

	/*a05.Se calculan los perce3ntiles por variable*/
    ods exclude all;
	proc means data=work.VARIABLES_total
	StackODSOutput P5 P10 P25 P50 P75 P90 P95; 
	var 
	LOGUEOS_TOTALES 
	LOG_MESES_distinct 
	LOG_DIas_distinct 
	recencia
	epus_pagos 
	;
	ods output summary=Tabla_Percentiles;
	
	run;
	ods exclude none;

	PROC SQL outobs=1 noprint ;   

	select 
	max(case when Variable='LOGUEOS_TOTALES' then P90 end) as P90_LOGUEOS_TOTALES,
	max(case when Variable='LOG_MESES_distinct' then P90 end) as P90_LOG_MESES_distinct,
	max(case when Variable='LOG_DIas_distinct' then P90 end) as P90_LOG_DIas_distinct,
	max(case when Variable='recencia' then P90 end) as P90_recencia,
	max(case when Variable='epus_pagos' then P90 end) as P90_epus_pagos,
	max(case when Variable='LOGUEOS_TOTALES' then P5 end) as P5_LOGUEOS_TOTALES,
	max(case when Variable='LOG_MESES_distinct' then P5 end) as P5_LOG_MESES_distinct,
	max(case when Variable='LOG_DIas_distinct' then P5 end) as P5_LOG_DIas_distinct,
	max(case when Variable='recencia' then P5 end) as P5_recencia,
	max(case when Variable='epus_pagos' then P5 end) as P5_epus_pagos
	into 
	:P90_LOGUEOS_TOTALES,
	:P90_LOG_MESES_distinct,
	:P90_LOG_DIas_distinct,
	:P90_recencia,
	:P90_epus_pagos,
	:P5_LOGUEOS_TOTALES,
	:P5_LOG_MESES_distinct,
	:P5_LOG_DIas_distinct,
	:P5_recencia,
	:P5_epus_pagos
	from work.Tabla_Percentiles 

	;QUIT;

	/*a06.Se crea la tabla con variables normalizadas para calcular la intensidad de uso de la APP*/

	proc sql;
		create table intensidad as 
	select distinct t1.RUT,
	(t1.LOGUEOS_TOTALES-&P5_LOGUEOS_TOTALES)/(&P90_LOGUEOS_TOTALES-&P5_LOGUEOS_TOTALES) as FREC, 
	(t1.LOG_MESES_distinct-&P5_LOG_MESES_distinct)/(&P90_LOG_MESES_distinct-&P5_LOG_MESES_distinct) as FREC_MES, 
	(t1.LOG_DIas_distinct-&P5_LOG_DIas_distinct)/(&P90_LOG_DIas_distinct-&P5_LOG_DIas_distinct) as FREC_DIAS, 
	(t1.recencia-&P5_recencia)/(&P90_recencia-&P5_recencia) as REC,
	(t1.epus_pagos-&P5_epus_pagos)/(&P90_epus_pagos-&P5_epus_pagos) as epus_pagos

	  from WORK.VARIABLES_total t1 
	  ;quit;


	PROC SQL;
	   CREATE TABLE WORK.mix_INTENSIDAD AS 
	   SELECT t1.RUT, 
	          case when t1.FREC >1 then 1 when t1.FREC between 0 and 1 then t1.FREC else 0 end as FREC, 
	          case when t1.FREC_MES >1 then 1 when t1.FREC_MES between 0 and 1 then t1.FREC_MES else 0 end as FREC_MES, 
	          case when t1.FREC_DIAS >1 then 1 when t1.FREC_DIAS between 0 and 1 then t1.FREC_DIAS else 0 end as FREC_DIAS, 
	          case when t1.REC >1 then 1 when t1.REC between 0 and 1 then t1.REC else 0 end as REC, 
	          case when t1.epus_pagos>1 then 1 when t1.epus_pagos between 0 and 1 then t1.epus_pagos else 0 end as epus_pagos
	      FROM WORK.intensidad t1;
	QUIT;


	PROC SQL outobs=1 noprint;
   SELECT /* AVG_of_FREC */
            (AVG(t1.FREC))/((AVG(t1.FREC))+(AVG(t1.FREC_MES))+(AVG(t1.FREC_DIAS))+(AVG(t1.REC))) AS AVG_of_FREC, 
          /* AVG_of_FREC_MES */
            (AVG(t1.FREC_MES))/((AVG(t1.FREC))+(AVG(t1.FREC_MES))+(AVG(t1.FREC_DIAS))+(AVG(t1.REC))) AS AVG_of_FREC_MES, 
          /* AVG_of_FREC_DIAS */
            (AVG(t1.FREC_DIAS))/((AVG(t1.FREC))+(AVG(t1.FREC_MES))+(AVG(t1.FREC_DIAS))+(AVG(t1.REC))) AS AVG_of_FREC_DIAS, 
          /* AVG_of_REC */
            (AVG(t1.REC))/((AVG(t1.FREC))+(AVG(t1.FREC_MES))+(AVG(t1.FREC_DIAS))+(AVG(t1.REC))) AS AVG_of_REC, 
          /* AVG_of_epus_pagos */
            (AVG(t1.epus_pagos))/((AVG(t1.FREC))+(AVG(t1.FREC_MES))+(AVG(t1.FREC_DIAS))+(AVG(t1.REC))) AS AVG_of_epus_pagos
	into
	:AVG_of_FREC,
	:AVG_of_FREC_MES,
	:AVG_of_FREC_DIAS,
	:AVG_of_REC,
	:AVG_of_epus_pagos
			from (

SELECT DISTINCT t1.rut,t2.*
      FROM epielh.VENTA_INTERNET_ANIO_MOV t1 left join WORK.mix_INTENSIDAD t2 on (t1.rut=t2.rut)
)t1


;
QUIT;



PROC SQL;
   CREATE TABLE work.cluster_digital_in AS 
   SELECT t1.RUT, 
          CASE WHEN (t1.FREC*&AVG_of_FREC+ 
          t1.FREC_MES*&AVG_of_FREC_MES+ 
          t1.FREC_DIAS*&AVG_of_FREC_DIAS+ 
          t1.REC*&AVG_of_REC+ 
          t1.epus_pagos*&AVG_of_epus_pagos) >1 THEN 1 ELSE (t1.FREC*&AVG_of_FREC+ 
          t1.FREC_MES*&AVG_of_FREC_MES+ 
          t1.FREC_DIAS*&AVG_of_FREC_DIAS+ 
          t1.REC*&AVG_of_REC+ 
          t1.epus_pagos*&AVG_of_epus_pagos) END  as cluster_digital_in
		
      FROM WORK.MIX_INTENSIDAD t1;
QUIT;


	PROC SQL;
	   CREATE TABLE publicin.cluster_digital_in_&fechamy1 AS 
	   SELECT t1.RUT, t1.*,
	          CASE WHEN t1.CLUSTER_DIGITAL_IN < 0.1              THEN 'NO_DGL'
			       WHEN t1.CLUSTER_DIGITAL_IN >= 0.5                                        THEN 'FULL_DGL'
				   WHEN t1.CLUSTER_DIGITAL_IN BETWEEN 0.1 AND 0.2999999999999999999999999999 THEN 'BAJO_DGL'
				   WHEN t1.CLUSTER_DIGITAL_IN BETWEEN 0.3  AND  0.499999999999999999999999     THEN'MEDIO_DGL' 

END AS DIGITALIZACION_IN, 
          x1.LOG_MESES_distinct as frec_mes_12, 
          x1.recencia as rec_mes, 
          x1.epus_pagos

	      FROM work.cluster_digital_in t1 left join WORK.VARIABLES_TOTAL x1 on (t1.rut=x1.rut)

	;QUIT;

	
/*	UTILIZACI�N VARIABLE TIEMPO	/ CUANTO SE DEMOR�	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACI�N TOTAL:' dur time13.2 / 30*'-';
run; 
