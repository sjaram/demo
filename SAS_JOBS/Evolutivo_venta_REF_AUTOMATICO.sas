/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	Evolutivo_venta_REF_AUTOMATICO	============================*/

/* CONTROL DE VERSIONES
/* 2022-10-28 -- V05 -- Esteban P.
					 -- Se añade nueva sentencia include para borrar y exportar data a RAW que reemplaza la anterior.
/* 2022-08-24 -- V04 -- Sergio J. 
					 -- Se añade sentencia include para borrar y exportar data a RAW
/* 2022-07-11 -- V03 -- Sergio J. --  
					 -- Se agrega código de exportación para alimentar a Tableau
/* 2021-08-25 -- V02 -- David V. --  
		             -- Versión Original + código para automatizar en server SAS
/* 2021-08-24 -- V01 -- Karina M. --  
	                 -- Versión Original
/* INFORMACIÓN:
Programa que...

(IN) Tablas requeridas o conexiones a BD:
- 

(OUT) Tablas de Salida o resultado:
- 

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria=RESULT;

/*
------------------------------
 DURACIÓN TOTAL:   0:00:16.65
------------------------------
*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
/*#########################################################################################*/
/* RESUMEN VENTA REFINANCIAMIENTO */
/*#########################################################################################*/
/*=========================================================================================*/
/*[01]  Parametros de fechas */
/*=========================================================================================*/
DATA _NULL_;
	date0 = input(put(intnx('month',today(),0,'same'),yymmn6. ),$10.);
	date1 = input(put(intnx('month',today(),-1,'same'),yymmn6. ),$10.);
	Call symput("PERIODO_MES", date0);
	Call symput("PERIODO_MES_ANT", date1);
run;

%put &PERIODO_MES;
%put &PERIODO_MES_ANT;

/*=========================================================================================*/
/*[02] Ejecutar Automaticamente todos los periodos de analisis*/
/*=========================================================================================*/
options cmplib=sbarrera.funcs;

proc sql;
	create table venta_mes as 
		select 
			VIA,   
			INPUT((substr(FECFAC,9,2)||'-'||substr(FECFAC,6,2)||'-'||substr(FECFAC,1,4)),DDMMYY10.) FORMAT=DDMMYY10. AS FECHA, 
			count(*) as Nro_TRXs,  
			SB_TRamificar(capital,500000,5000,2500000,'') as Tramo_Monto_Venta,
			sum(capital) as Mto_TRXs, 
			sum(INTERES) as Mto_Intereses, 
			sum(capital*TOTCUOTAS) as SUM_Cuotas_x_Venta, 
			sum(capital*TASA_CAR) as SUM_Tasa_x_Venta, 
			sum(case when VIA in ('SUCURSAL') then capital end) as Mto_TRXs_Prec,  
			sum(case when VIA in ('INTERNET') then capital end) as Mto_TRXs_Dig,   
			sum(case when VIA in ('CALL CENTER') then capital end) as Mto_TRXs_Call, 
			sum(capital*TOTCUOTAS)/sum(capital) as Plazo, 
			sum(capital*TASA_CAR)/sum(capital) as Tasa  
		from ( SELECT  
			RUT, 
			FECFAC,
			capital, 
			TOTCUOTAS, 
			TASA AS TASA_CAR,  
			INTERES,  
		CASE WHEN  SUCURSAL  IN (60,61,801,802) THEN 'CALL CENTER'  
			WHEN SUCURSAL = 120 THEN 'INTERNET'  
			ELSE 'SUCURSAL' END AS VIA      
		FROM publicin.TRX_REF_&PERIODO_MES)   
			group by  
				VIA,FECFAC,Tramo_Monto_Venta
	;
quit;

options cmplib=sbarrera.funcs;

proc sql;
	create table venta_mes_anterior as 
		select 
			VIA,   
			INPUT((substr(FECFAC,9,2)||'-'||substr(FECFAC,6,2)||'-'||substr(FECFAC,1,4)),DDMMYY10.) FORMAT=DDMMYY10. AS FECHA, 
			count(*) as Nro_TRXs,  
			SB_TRamificar(capital,500000,5000,2500000,'') as Tramo_Monto_Venta,
			sum(capital) as Mto_TRXs, 
			sum(INTERES) as Mto_Intereses, 
			sum(capital*TOTCUOTAS) as SUM_Cuotas_x_Venta, 
			sum(capital*TASA_CAR) as SUM_Tasa_x_Venta, 
			sum(case when VIA in ('SUCURSAL') then capital end) as Mto_TRXs_Prec,  
			sum(case when VIA in ('INTERNET') then capital end) as Mto_TRXs_Dig,   
			sum(case when VIA in ('CALL CENTER') then capital end) as Mto_TRXs_Call, 
			sum(capital*TOTCUOTAS)/sum(capital) as Plazo, 
			sum(capital*TASA_CAR)/sum(capital) as Tasa  
		from ( SELECT  
			RUT, 
			FECFAC,
			capital, 
			TOTCUOTAS, 
			TASA AS TASA_CAR,  
			INTERES,  
		CASE WHEN  SUCURSAL  IN (60,61,801,802) THEN 'CALL CENTER'  
			WHEN SUCURSAL = 120 THEN 'INTERNET'  
			ELSE 'SUCURSAL' END AS VIA      
		FROM publicin.TRX_REF_&periodo_mes_ant)   
			group by  
				VIA,FECFAC,Tramo_Monto_Venta
	;
quit;

proc sql;
	create table KM_VENTA_REF as
		select t1.*
			from &libreria..KM_VENTA_REF t1 where t1.periodo not in (&periodo_mes,&periodo_mes_ant)
				outer union corr select &periodo_mes as periodo, a.*
					from venta_mes a
						outer union corr select &periodo_mes_ant as periodo, b.*
							from venta_mes_anterior b
	;
quit;

proc sql;
	create table &libreria..KM_VENTA_REF as 
		select *
			from KM_VENTA_REF 
				order by periodo
	;
quit;

proc sql;
	create table  KMARTINE_VENTA_REF as 
		select 
			case 
				when periodo-floor(periodo/100)*100 between 1 and 9 then 
				cat(floor(periodo/100),'-',
				cat('0',periodo-floor(periodo/100)*100),'-',
				'01')
				else 
				cat(floor(periodo/100),'-',
				periodo-floor(periodo/100)*100,'-',
				'01') 
			end  
		as periodo2, * from &libreria..KM_VENTA_REF;
		quit;

/*exportar csv*/
proc export data=KMARTINE_VENTA_REF
outfile="/sasdata/users94/user_bi/ORACLOUD/PPFF_VENTA_REF.csv"
dbms=dlm
replace;
delimiter="|";
quit;


%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(ppff_venta_ref,raw,oracloud,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(ppff_venta_ref,work.kmartine_venta_ref,raw,oracloud,0);


/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN);
RUN;

%put &fechaeDVN;

/*=========================================================================================*/
/*[05] Envio email aviso actualizacion*/
/*=========================================================================================*/
/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CLIENTES_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_1';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;
Filename myEmail EMAIL
	Subject = "MAIL_AUTOM: Venta Refinanciamiento" /*asunto */
FROM 	= ("&EDP_BI")
TO 		= ("&DEST_3","&DEST_4")
CC 		= ("&DEST_1","&DEST_2")
/*TO 		= ("&DEST_1","&DEST_2")*/
Type    = 'Text/Plain';

Data _null_;
	File myEmail;
	PUT "Estimados:";
	PUT "		Finalizó actualización Venta Refinanciamiento, con fecha: &fechaeDVN";
	PUT;
	PUT "		https://tableau1.bancoripley.cl/#/site/BI_Lab/views/VENTAREFINANCIAMIENTOTARJETA/VentaREF?:iid=2";
	PUT;
	PUT;
	PUT;
	put 'Proceso Vers. 05';
	PUT;
	PUT;
	PUT;
	PUT;
	PUT 'Atte.';
	PUT 'Equipo Datos y Procesos BI';
	PUT;
	;
RUN;

/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;
