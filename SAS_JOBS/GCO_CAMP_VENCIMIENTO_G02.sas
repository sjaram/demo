/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	GCO_CAMP_VENCIMIENTO_G02	================================*/
/* CONTROL DE VERSIONES
/* 2021-06-08 -- V3 -- David V. --  
					-- Automatización mejorada
/* 2020-12-03 -- V2 -- David V. --  
					-- Automatización
/* 2020-11-11 -- V1 -- David V. --  
					-- Versión Original
/* INFORMACIÓN:
	Campaña INFORMATIVA 02 - Vencimiento Plastico

	(IN) Tablas requeridas o conexiones a BD:
	- RESULT.VENCIMIENTOS_&VdateHOY

	(OUT) Tablas de Salida o resultado:
 	- &libreria..POPINF_C_DETAL_02_CAMP_&fgen
	- &libreria..POPINF_C_ENCAB_02_CAMP_&fgen
*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria 		= RESULT;
%let camp_enc 		= POPCRV_C_ENCAB_02_CAMP_;
%let camp_det 		= POPCRV_C_DETAL_02_CAMP_;
%let grupo			= 2;
%let TIP_PROD		= '12';
%let COND_PRD		= '1202';
%let ARCH_GCO		= GCO_INI_IC00017;			/*	Correglativo desde el 16 al 20 disponibles */
%let codigo_camp	= 'CAMPCRV02';
					/* MAX LARGO11*/
%let desc_camp		= 'CRV - VENCIMIENTO DE PLASTICO - G02';

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/

DATA _null_;
/* Variables Fechas de Ejecución */
datePeriodoActual = input(put(intnx('month',today(),0,'end' ),yymmn6. ),$10.);
datehi	= compress(input(put(intnx('month',today(),0,'begin' ),yymmdd10.	),$20.),"-",c);
datehf	= compress(input(put(intnx('month',today(),0,'end'	),yymmdd10. 	),$20.),"-",c);
exec 	= compress(input(put(today()+1,yymmdd10.),$10.),"-",c);
fgenera	= compress(input(put(today(),yymmdd10.),$10.),"-",c);

Call symput("VdateHOY", datePeriodoActual);
Call symput("fechahi",datehi);
Call symput("fechahf",datehf);
Call symput("fechae",exec);
Call symput("fgen",fgenera);

RUN;
%put &VdateHOY;
%put &fechahi;
%put &fechahf;
%put &fechae;
%put &fgen;

/* FECHAS Y CÓDIGO DE CAMPAÑA	-------				*/	
%let FECHA_INICIO =	&fechae;
%let FECHA_FIN    =	&fechahf;
 
options cmplib=sbarrera.funcs;
options validvarname=any;

PROC SQL;
   CREATE TABLE &libreria..&camp_det.&fgen AS	/*	ACTUALIZAR */
   SELECT 3 AS '2'n, 
          &codigo_camp AS COD_CAMP, 
          &FECHA_INICIO AS FEC_INI, 
          &FECHA_FIN AS FEC_TER,
          t1.RUT AS RUT, 
		  SB_DV(T1.RUT) AS DV,
          0 as MTO_OFERTA,									/*	ACTUALIZAR SI CORRESPONDE	*/
          0 as PLZ_MIN, 
          0 as PLZ_MAX, 									/*	ACTUALIZAR SI CORRESPONDE	*/
          0 as TAS_MIN_RIESGO, 								/*	ACTUALIZAR SI CORRESPONDE	*/
          0 as RENTA, 										/*	ACTUALIZAR SI CORRESPONDE	*/
          t1.CODENT 	AS COD_ENTIDAD, 
          t1.CENTALTA 	AS CENTRO_ALTA, 
          t1.CUENTA 	AS CUENTA, 
          0 AS CLASE_PROM, 
          &TIP_PROD. AS TIP_PROD, 
          &COND_PRD. AS COND_PROD, 							/*	ACTUALIZAR SI CORRESPONDE	*/
          0 AS PAGO_MIN, 
          '206' AS ORIGEN_BASE,  
          0 AS ENTIDAD, 
          4 AS CREADOR, 
          1 AS FLAG_CAMP, /*1= se ve  0=no se ve*/
          1 AS ORDEN_PRIO, 
          0 AS EGP, 
          0 AS ECP, 
         '0000'  AS COD_LIN1, 
          0 AS MTO_LIN1, 
          '0000' AS COD_LIN2, 
          0 AS MTO_LIN2, 
          '0000' AS COD_LIN3, 
          0 AS MTO_LIN3, 
          '0000' AS COD_LIN4, 
          0 AS MTO_LIN4, 
          '0000' AS COD_LIN5, 
          0 AS MTO_LIN5, 
         '0000' AS COD_LIN6, 
          0 AS MTO_LIN6, 
          '0000' AS COD_LIN7, 
          0 AS MTO_LIN7, 
          '0000' AS COD_LIN8, 
          0 AS MTO_LIN8, 
          '0000' AS COD_LIN9, 
          0 AS MTO_LIN9, 
          '0000' AS COD_LIN10, 
          0 AS MTO_LIN10, 
          0 AS FILLER1, 
          0 AS FILLER2, 
          0 AS FILLER3, 
          0 AS FILLER4, 
          0 AS FILLER5, 
          0 AS FILLER6, 
          0 AS FILLER7, 
          0 AS FILLER8, 
          0 AS FILLER9, 
          0 AS FILLER10, 
          0 AS FILLER11, 
          0 AS FILLER12, 
          0 AS FILLER13, 
          0 AS FILLER14
		from RESULT.VENCIMIENTOS_&VdateHOY t1
WHERE T1.RUT > 0 AND grupo = &grupo.
/*and t1.rut in (7449754,14156262,17457765,12629828);*/
;QUIT;
 
/*EXPORTAR CSV*/
PROC SQL;
CREATE TABLE &libreria..&camp_enc.&fgen AS
SELECT 1 		AS numero_fila,
&codigo_camp	AS codigo_camapan,
&desc_camp 		AS descripcion_campana,		
&FECHA_INICIO 	AS FECHA_INICIO,
&FECHA_FIN  	AS FECHA_TERMINO,
TIP_PROD,
COND_PROD 
FROM &libreria..&camp_det.&fgen (obs=1)
;QUIT; 
 
/*	COUNT DE REGISTROS	*/
PROC SQL noprint;
      SELECT 
			(COUNT(t1.RUT)) AS COUNT_of_RUT, 
            (COUNT(DISTINCT(t1.RUT))) AS 'COUNT DISTINCT_of_RUT'n
      FROM 	&libreria..&camp_det.&fgen t1;							/*	ACTUALIZAR */
QUIT;

/*==================================================================================================*/
/*==================================	GENERAR ARCHIVO DEFINIDO	================================*/

/* SE GENERA ESTRUCTURA DE TABLA CON TABLA DE DETALLE */
PROC SQL inobs=0;
	CREATE TABLE WORK.tmp2 AS 
		SELECT 
			put('2'n,best32.) 							as Numero, 
			COD_CAMP									as COD_CAMP, 
			put(FEC_INI, best32.) 						as FEC_INI, 
			put(FEC_TER, best32.) 						as FEC_TER, 
			put(RUT, best32.) 							as RUT,
			DV 											as DV, 
			put(MTO_OFERTA, best32.) 					as MTO_OFERTA , 
			put(PLZ_MIN, best32.)						as PLZ_MIN, 
			put(PLZ_MAX,  best32.) 						as PLZ_MAX ,
			put(TAS_MIN_RIESGO, best32.) 				as TAS_MIN_RIESGO, 
			put(RENTA, best32.) 						as RENTA, 
			put(input(COD_ENTIDAD, best32.),best32.)	as COD_ENTIDAD,
			put(input(CENTRO_ALTA, best32.),best32.) 	as CENTRO_ALTA  , 
			put(input(CUENTA, best32.),best32.) 		as CUENTA, 
			put(CLASE_PROM,best32.) 					as CLASE_PROM, 
			put(input(TIP_PROD, best32.),best32.) 		as TIP_PROD, 
			put(input(COND_PROD, best32.),best32.) 		as COND_PROD, 
			put(PAGO_MIN, best32.) 						as PAGO_MIN, 
			put(input(ORIGEN_BASE, best32.),best32.) 	as ORIGEN_BASE, 
	 		put(ENTIDAD, best32.) 						as  ENTIDAD,  
			put(CREADOR, best32.) 						as CREADOR,
			put(FLAG_CAMP, best32.) 					as FLAG_CAMP ,  
			put(ORDEN_PRIO, best32.) 					as ORDEN_PRIO, 
			put(EGP,best32.) 							as EGP,
			put(ECP, best32.) 							as ECP , 
			put(input(COD_LIN1, best32.),best32.) 		as COD_LIN1, 
			put(MTO_LIN1, best32.) 						as MTO_LIN1,
			put(input(COD_LIN2, best32.),best32.) 		as COD_LIN2, 
			put(MTO_LIN2, best32.) 						as MTO_LIN2, 
			put(input(COD_LIN3, best32.),best32.) 		as COD_LIN3, 
			put(MTO_LIN3,best32.) 						as MTO_LIN3, 
			put(input(COD_LIN4, best32.),best32.) 		as COD_LIN4, 
			put(MTO_LIN4, best32.) 						as MTO_LIN4, 
			put(input(COD_LIN5, best32.),best32.) 		as COD_LIN5, 
			put(MTO_LIN5, best32.) 						as MTO_LIN5, 
			put(input(COD_LIN6, best32.),best32.) 		as COD_LIN6, 
			put(MTO_LIN6, best32.) 						as MTO_LIN6, 
			put(input(COD_LIN7, best32.),best32.) 		as COD_LIN7, 
			put(MTO_LIN7,best32.) 						as MTO_LIN7, 
			put(input(COD_LIN8, best32.),best32.) 		as COD_LIN8, 
			put(MTO_LIN8, best32.) 						as MTO_LIN8, 
			put(input(COD_LIN9, best32.),best32.) 		as COD_LIN9, 
			put(MTO_LIN9, best32.) 						as MTO_LIN9, 
			put(input(COD_LIN10, best32.),best32.) 		as COD_LIN10, 
			put(MTO_LIN10, best32.) 					as MTO_LIN10, 
			put(FILLER1, best32.) 						as FILLER1,
			put(FILLER2,  best32.) 						as FILLER2,
			put(FILLER3,  best32.) 						as FILLER3,
			put(FILLER4,  best32.) 						as FILLER4,
			put(FILLER5,  best32.) 						as FILLER5,
			put(FILLER6,  best32.) 						as FILLER6,
			put(FILLER7,  best32.) 						as FILLER7,
			put(FILLER8,  best32.) 						as FILLER8,
			put(FILLER9,  best32.) 						as FILLER9,
			put(FILLER10,  best32.)						as FILLER10,
			put(FILLER11,  best32.)						as FILLER11,
			put(FILLER12,  best32.)						as FILLER12,
			put(FILLER13,  best32.)						as FILLER13,
			put(FILLER14, best32.) 						as FILLER14
		FROM &libreria..&camp_det.&fgen;
QUIT;

 
/*INSERTA NOMBRE DATOS DE TABLA CABECERA*/
proc sql inobs=1 noprint;
insert into tmp2
	select 
		compress(put(numero_fila,best23.))		as numero, 
		codigo_camapan 							as COD_CAMP, 
		descripcion_campana 					as FEC_INI, 
		COMPRESS(put(FECHA_INICIO, BEST32.))  	as FEC_TER, 
		COMPRESS(put(FECHA_TERMINO, BEST32.)) 	as RUT, 
		TIP_PROD 								as DV ,
		COND_PROD  								as MTO_OFERTA ,
		"" as PLZ_MIN, 
		"" as PLZ_MAX, 
		"" as TAS_MIN_RIESGO, 
		"" as RENTA, 
		"" as COD_ENTIDAD, 
		"" as CENTRO_ALTA , 
		"" as CUENTA, 
		"" as CLASE_PROM, 
		"" as TIP_PROD, 
		"" as COND_PROD, 
		"" as PAGO_MIN, 
		"" as ORIGEN_BASE, 
		"" as ENTIDAD, 
		"" as CREADOR, 
		"" as FLAG_CAMP, 
		"" as ORDEN_PRIO, 
		"" as EGP, 
		"" as ECP, 
		"" as COD_LIN1, 
		"" as MTO_LIN1, 
		"" as COD_LIN2, 
		"" as MTO_LIN2, 
		"" as COD_LIN3, 
		"" as MTO_LIN3, 
		"" as COD_LIN4, 
		"" as MTO_LIN4, 
		"" as COD_LIN5, 
		"" as MTO_LIN5, 
		"" as COD_LIN6, 
		"" as MTO_LIN6, 
		"" as COD_LIN7, 
		"" as MTO_LIN7, 
		"" as COD_LIN8, 
		"" as MTO_LIN8, 
		"" as COD_LIN9, 
		"" as MTO_LIN9, 
		"" as COD_LIN10, 
		"" as MTO_LIN10, 
		"" as FILLER1, 
		"" as FILLER2, 
		"" as FILLER3, 
		"" as FILLER4, 
		"" as FILLER5, 
		"" as FILLER6, 
		"" as FILLER7, 
		"" as FILLER8, 
		"" as FILLER9, 
		"" as FILLER10, 
		"" as FILLER11, 
		"" as FILLER12, 
		"" as FILLER13, 
		"" as FILLER14 
	from &libreria..&camp_enc.&fgen
	;
quit;


/*INSERTA NOMBRE DE CAMPOS TABLA DETALLE*/
proc sql inobs=1 noprint;
insert into tmp2
		select 
			"2"					as 	numero, 
			"COD_CAMP" 			as 	COD_CAMP, 
			"FEC_INI"			as 	FEC_INI, 
			"FEC_TER" 			as 	FEC_TER, 
			"RUT" 				as 	RUT, 
			"DV" 				as  DV,
			"MTO_OFERTA " 		as  MTO_OFERTA ,
			"PLZ_MIN" 			as  PLZ_MIN, 
			"PLZ_MAX" 			as  PLZ_MAX , 
			"TAS_MIN_RIESGO" 	as  TAS_MIN_RIESGO, 
			"RENTA" 			as  RENTA, 
			"COD_ENTIDAD" 		as  COD_ENTIDAD, 
			"CENTRO_ALTA" 		as  CENTRO_ALTA , 
			"CUENTA" 			as  CUENTA, 
			"CLASE_PROM" 		as  CLASE_PROM, 
			"TIP_PROD" 			as  TIP_PROD, 
			"COND_PROD" 		as  COND_PROD, 
			"PAGO_MIN"			as  PAGO_MIN, 
			"ORIGEN_BASE" 		as  ORIGEN_BASE, 
			"ENTIDAD" 			as  ENTIDAD, 
			"CREADOR" 			as  CREADOR, 
			"FLAG_CAMP" 		as  FLAG_CAMP, 
			"ORDEN_PRIO" 		as  ORDEN_PRIO, 
			"EGP" 				as  EGP, 
			"ECP"				as  ECP , 
			"COD_LIN1" 			as  COD_LIN1, 
			"MTO_LIN1" 			as  MTO_LIN1, 
			"COD_LIN2" 			as  COD_LIN2, 
			"MTO_LIN2" 			as  MTO_LIN2, 
			"COD_LIN3" 			as  COD_LIN3, 
			"MTO_LIN3" 			as  MTO_LIN3, 
			"COD_LIN4" 			as  COD_LIN4, 
			"MTO_LIN4" 			as  MTO_LIN4, 
			"COD_LIN5" 			as  COD_LIN5, 
			"MTO_LIN5" 			as  MTO_LIN5, 
			"COD_LIN6" 			as  COD_LIN6, 
			"MTO_LIN6"			as  MTO_LIN6, 
			"COD_LIN7" 			as  COD_LIN7, 
			"MTO_LIN7" 			as  MTO_LIN7, 
			"COD_LIN8" 			as  COD_LIN8, 
			"MTO_LIN8" 			as  MTO_LIN8, 
			"COD_LIN9" 			as  COD_LIN9, 
			"MTO_LIN9" 			as  MTO_LIN9, 
			"COD_LIN10" 		as  COD_LIN10, 
			"MTO_LIN10" 		as  MTO_LIN10, 
			"FILLER1" 			as  FILLER1, 
			"FILLER2" 			as  FILLER2, 
			"FILLER3" 			as  FILLER3, 
			"FILLER4" 			as  FILLER4, 
			"FILLER5" 			as  FILLER5, 
			"FILLER6" 			as  FILLER6, 
			"FILLER7" 			as  FILLER7, 
			"FILLER8" 			as  FILLER8, 
			"FILLER9" 			as  FILLER9, 
			"FILLER10" 			as  FILLER10, 
			"FILLER11" 			as  FILLER11, 
			"FILLER12" 			as  FILLER12, 
			"FILLER13" 			as  FILLER13, 
			"FILLER14" 			as  FILLER14 
		from &libreria..&camp_det.&fgen
	;
quit;

/*INSERTA DATOS DE LA TABLA DETALLE*/
proc sql noprint;
insert into tmp2
		select 
			compress(put("2"N,best32.) )		as numero, 
			COD_CAMP 							as COD_CAMP, 
			COMPRESS(PUT(FEC_INI,BEST32.))		as FEC_INI, 
			COMPRESS(PUT(FEC_TER,BEST32.))  	as FEC_TER, 
			compress(PUT(RUT,BEST32.)) 			as RUT, 
			DV 									as  DV,
			COMPRESS(PUT(MTO_OFERTA,BEST32.))  		as  MTO_OFERTA ,
			COMPRESS(PUT(PLZ_MIN,BEST32.)) 			as  PLZ_MIN, 
			COMPRESS(PUT(PLZ_MAX,BEST32.)) 			as  PLZ_MAX , 
			COMPRESS(PUT(TAS_MIN_RIESGO,BEST32.)) 	as  TAS_MIN_RIESGO, 
			COMPRESS(PUT(RENTA,BEST32.))			as  RENTA, 
			COD_ENTIDAD							as  COD_ENTIDAD, 
			CENTRO_ALTA 						as  CENTRO_ALTA , 
			CUENTA 								as  CUENTA, 
			COMPRESS(PUT(CLASE_PROM,BEST32.)) 	as  CLASE_PROM, 
			TIP_PROD 							as  TIP_PROD, 
			COND_PROD 							as  COND_PROD, 
			COMPRESS(PUT(PAGO_MIN,BEST32.))		as  PAGO_MIN, 
			ORIGEN_BASE 						as  ORIGEN_BASE, 
			COMPRESS(PUT(ENTIDAD,BEST32.)) 		as  ENTIDAD, 
			COMPRESS(PUT(CREADOR,BEST32.)) 		as  CREADOR, 
			COMPRESS(PUT(FLAG_CAMP,BEST32.)) 	as  FLAG_CAMP, 
			COMPRESS(PUT(ORDEN_PRIO,BEST32.)) 	as  ORDEN_PRIO, 
			COMPRESS(PUT(EGP,BEST32.)) 			as  EGP, 
			COMPRESS(PUT(ECP ,BEST32.))			as  ECP , 
			COD_LIN1 							as  COD_LIN1, 
			COMPRESS(PUT(MTO_LIN1,BEST32.)) 	as  MTO_LIN1, 
			COD_LIN2 							as  COD_LIN2, 
			COMPRESS(PUT(MTO_LIN2,BEST32.)) 	as  MTO_LIN2, 
			COD_LIN3 							as  COD_LIN3, 
			COMPRESS(PUT(MTO_LIN3,BEST32.)) 	as  MTO_LIN3, 
			COD_LIN4 							as  COD_LIN4, 
			COMPRESS(PUT( MTO_LIN4,BEST32.)) 	as  MTO_LIN4, 
			COD_LIN5 							as  COD_LIN5, 
			COMPRESS(PUT( MTO_LIN5,BEST32.)) 	as  MTO_LIN5, 
			COD_LIN6 							as  COD_LIN6, 
			COMPRESS(PUT(  MTO_LIN6,BEST32.))	as  MTO_LIN6, 
			COD_LIN7 							as  COD_LIN7, 
			COMPRESS(PUT( MTO_LIN7,BEST32.)) 	as  MTO_LIN7, 
			COD_LIN8 							as  COD_LIN8, 
			COMPRESS(PUT( MTO_LIN8,BEST32.)) 	as  MTO_LIN8, 
			COD_LIN9 							as  COD_LIN9, 
			COMPRESS(PUT(MTO_LIN9,BEST32.)) 	as  MTO_LIN9, 
			COD_LIN10 							as  COD_LIN10, 
			COMPRESS(PUT(MTO_LIN10,BEST32.)) 	as  MTO_LIN10, 
			COMPRESS(PUT(FILLER1,BEST32.)) 		as  FILLER1, 
			COMPRESS(PUT(FILLER2,BEST32.)) 		as  FILLER2, 
			COMPRESS(PUT(FILLER3,BEST32.)) 		as  FILLER3, 
			COMPRESS(PUT(FILLER4,BEST32.)) 		as  FILLER4, 
			COMPRESS(PUT(FILLER5,BEST32.)) 		as  FILLER5, 
			COMPRESS(PUT(FILLER6,BEST32.)) 		as  FILLER6, 
			COMPRESS(PUT(FILLER7,BEST32.)) 		as  FILLER7, 
			COMPRESS(PUT(FILLER8,BEST32.)) 		as  FILLER8, 
			COMPRESS(PUT(FILLER9,BEST32.)) 		as  FILLER9, 
			COMPRESS(PUT(FILLER10,BEST32.)) 	as  FILLER10, 
			COMPRESS(PUT(FILLER11,BEST32.)) 	as  FILLER11, 
			COMPRESS(PUT(FILLER12,BEST32.)) 	as  FILLER12, 
			COMPRESS(PUT(FILLER13,BEST32.)) 	as  FILLER13, 
			COMPRESS(PUT(FILLER14,BEST32.)) 	as  FILLER14
		from &libreria..&camp_det.&fgen
	;
quit;

/*genera fecha del día*/
data _nuul_;
call symput('fecha',compress(tranwrd(put(today(),ddmmyy10.),"/","")));
run;

%put FECHA &fecha;

/*EXPORTA TABLA  TXT */
PROC EXPORT DATA=tmp2
   OUTFILE="/sasdata/users94/user_bi/CAMPANAS_CORE/&ARCH_GCO._&fecha..txt"
   DBMS=dlm;
   delimiter=';';
   PUTNAMES=NO;
RUN;

/* EXPORTAR DE SAS A UN FTP O SFTP  - VALIDADO OK */ 
	filename server ftp "&ARCH_GCO._&fecha..txt" CD='/ftpcamp' 
    HOST='192.168.84.65' user='dvasquez' pass='ripley2019' PORT=21;

data _null_;
       infile "/sasdata/users94/user_bi/CAMPANAS_CORE/&ARCH_GCO._&fecha..txt";
       file server;
       input;
       put _infile_;
run;

proc sql noprint;
	select count(RUT) INTO :COUNT_ruts
	from &libreria..&camp_det.&fgen;
quit;

%put &=COUNT_ruts;

/* INSERT A LA TABLA PARA RESUMENY ENVÍO DE EMAIL POSTERIOR */
proc sql noprint;
	insert into &libreria..GCO_CAMP_DVN_CR_&VdateHOY 
		values("&ARCH_GCO._&fecha..txt","&COUNT_ruts.")
;quit;


/*==================================================================================================*/
/*==================================	TIEMPO Y ENVÍO DE EMAIL		================================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/

