/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	TRANSACCIONES_MCD.sas	================================*/

/* CONTROL DE VERSIONES
/* 		2021-08-30 -- V5 -- David V. -- Actualización a password para segcom_new
/* 		2021-05-07 -- V4 -- Pedro Muñoz -- Nueva Versión
/* 		2021-02-23 -- V3 -- Pedro Muñoz -- Nueva Versión
/* 		2021-02-16 -- V2 -- Pedro Muñoz -- Nueva Versión
/* 		2020-12-29 -- V1 -- Alejandra Mariano -- Nueva Versión Automática Equipo Datos y Procesos BI

Descripción:
En este proyecto se traen las transacciones realizadas con la MCD tanto en tienda como SPOS.	

`MODELAMIENTO`

(IN) Tablas requeridas o conexiones a BD:
- MPDT.MPDT013 CONTRATO de Tarjeta
- BOPERS.BOPERS_MAE_IDE
- MPDT.MPDT007  CONTRATO
- MPDT.MPDT009 Tarjeta 
- MPDT.MPDT004 Transacciones

(OUT) Tablas de Salida o resultado:
- PUBLICIN.SPOS_MCD_AAAAMM
- PUBLICIN.TDA_MCD_AAAAMM
- CORREO AUTOMATICO

*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio = %sysfunc(datetime()); /* inicio del proceso de conteo*/
%let LIB=PUBLICIN;

%macro spos_aut(periodo,libreria);
	/****************************************************************************************************************/
	/****************************************************************************************************************/
	/****************************************************************************************************************/
	/****************************************************************************************************************/
	/****************************************************************************************************************/
	/****************************************************************************************************************/
	%put==================================================================================================;
	%put [01] DETALLE MPDT004  TD;
	%put==================================================================================================;

	PROC SQL NOERRORSTOP;
		CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
		create table cuentas  as 
			select * 
				from connection to ORACLE( 
					SELECT 
						cast(a2.PEMID_GLS_NRO_DCT_IDE_K as INT)  RUT,
						a.CODENT, 
						a.CENTALTA, 
						a.CUENTA,
						a1.producto, 
						a.codpais, 
						a.localidad, 
						a.fectrn, 
						a.hortrn, 
						cast(REPLACE(a.fectrn, '-') as INT) cod_fecha, 
						a.CODACT,  
						a.CODCOM, 
						a.CODCOM  Codigo_Comercio_ant, 
						a.NOMCOM, 
						sum(a.imptrn)  VENTA_TARJETA, 
						a.Tipfran, 
						a.totcuotas, 
						a.porint, 
						a.PAN, 
						SUBSTR(a.PAN,13,4) PAN2,
						a.tipofac, 
						a.IMPCCA, 
						a.CLAMONCCA, 
						a.IMPDIV,
						substr(a.MODENTDAT,1,2)  Ind_Online,
						a.NUMAUT,
						a3.DESACT  RUBRO
					from GETRONICS.MPDT004  a 
						INNER JOIN GETRONICS.MPDT007 a1 /*CONTRATO*/
							ON (A.CODENT=a1.CODENT) AND (A.CENTALTA=a1.CENTALTA) AND (A.CUENTA=a1.CUENTA) 
						INNER JOIN BOPERS_MAE_IDE a2 ON 
							A1.IDENTCLI=a2.PEMID_NRO_INN_IDE
						inner join GETRONICS.MPDT039 a3
							on(a.CODACT = a3.CODACT)
						where a.codrespu = '000' 
							and a.tipfran <> 1004 
							and cast(REPLACE(a.fectrn, '-') as INT)>=100*&periodo.+01 
							and cast(REPLACE(a.fectrn, '-') as INT)<=100*&periodo.+31 
							and  SUBSTR(a.PAN,1,6)='525384'  
						group by 
							a.CODENT, 
							a.CENTALTA, 
							a.cuenta,  
							a.codpais, 
							a.localidad, 
							a.fectrn, 
							a.hortrn,
							a.CODACT,  
							a.CODCOM, 
							a.NOMCOM, 
							a.Tipfran, 
							a.totcuotas, 
							a.porint, 
							a.PAN,
							a.tipofac,
							a.IMPCCA,
							a.CLAMONCCA,
							a.IMPDIV,
							substr(a.MODENTDAT,1,2),
							a.NUMAUT,
							cast(a2.PEMID_GLS_NRO_DCT_IDE_K as INT),
							a3.DESACT,
							SUBSTR(a.PAN,13,4),
							a1.producto
							) A
		;
	QUIT;

	%put==================================================================================================;
	%put [02] DATA INCOMING;
	%put==================================================================================================;
	%let path_ora           = '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=192.168.84.167)(PORT=1521))(CONNECT_DATA=(SERVER=dedicated)(SID=SEGCOM)))';
	%let user_ora           = 'VMARTINEZF';
	%let pass_ora           = 'VMAR09072021';
	%let conexion_ora       = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.;
	%put &conexion_ora.;

	PROC SQL  NOERRORSTOP;
		CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );
		create table data_IMP_DATA as

		select * from connection to ORACLE

			(

		select  
			fecha,
			END_POINT,
			DE42_CARD_ACCEPTOR_ID_CODE,
			DE38_CODIGO_DE_APROBACION ,
			de12_FECHA_HORA_TRANSACCION,
			DE2_NUMERO_DE_TARJETA

		from IPM_DATA
			where 20*1000000 +floor(de12_FECHA_HORA_TRANSACCION/1000000) between 100*&periodo.+01
				and 100*&periodo.+31

				);
		disconnect from ORACLE;
	QUIT;

	proc sql;
		create table data_IMP_DATA2 as 
			select 
				*,
				substr(DE2_NUMERO_DE_TARJETA,length(DE2_NUMERO_DE_TARJETA)-3,4) as auto,
				input('20'||substr(compress(put(de12_FECHA_HORA_TRANSACCION,32.)),1,6),best.) as fec_num,
				substr(compress(put(de12_FECHA_HORA_TRANSACCION,32.)),7,2)||':'||substr(compress(put(de12_FECHA_HORA_TRANSACCION,32.)),9,2)||':'||substr(compress(put(de12_FECHA_HORA_TRANSACCION,32.)),11,2) as hora
			from data_IMP_DATA
		;
	QUIT;

	proc sql;
		create table cuentas as 
			select monotonic() as ind,
				* from cuentas
		;
	QUIT;

	proc sql;
		create table cruce as 
			select 
				a.*,
				input(b.DE42_CARD_ACCEPTOR_ID_CODE,best32.) as codigo_comercio 

			from   cuentas as a 
				left join data_IMP_DATA2 as b
					on(a.cod_fecha=b.fec_num) 
					and (a.NUMAUT=b.DE38_CODIGO_DE_APROBACION) and (a.PAN2=b.auto)
		;
	QUIT;

	%put==================================================================================================;
	%put [03] TIPO DE Actividad;
	%put==================================================================================================;

	proc sql;
		create table BASE_TOTAL_FIN as 
			select 
				*,
			CASE 
				WHEN UPPER(NOMCOM) LIKE 'RIPLEY %' THEN 'TIENDA' 
				ELSE 'SPOS' 
			END 
		AS LUGAR,
			CASE 
				WHEN SUBSTR(PAN,1,6) IN('628156') THEN 'TR'
				WHEN SUBSTR(PAN,1,6) IN('549070')AND INPUT(LEFT(SUBSTR(PAN,1,7)),BEST.) >=5490702 THEN 'TAM' /*TAM CHIP*/
		WHEN SUBSTR(PAN,1,6) IN('549070')AND INPUT(LEFT(SUBSTR(PAN,1,7)),BEST.) <5490702 THEN 'TAM'
		WHEN SUBSTR(PAN,1,6) in ('525384') THEN 'MCD'
		WHEN SUBSTR(PAN,1,4) IN('6392') THEN 'DEBITO'
		ELSE 'TR' END AS Tipo_Tarjeta

		from cruce

		;
	QUIT;

	%put==================================================================================================;
	%put [04] TABLA SPOS resumida;
	%put==================================================================================================;

	proc sql;
		create table &libreria..spos_MCD_&periodo.  as 
			select 
				X.COD_FECHA as Fecha, 
				X.hortrn AS Hora,
				floor(X.COD_FECHA/100) as Periodo, 
				input(X.codigo_comercio_ant,best32.) as codigo_comercio_ant,
				x.codigo_comercio, 
				X.NOMCOM as Nombre_Comercio, 
				X.RUBRO as Actividad_Comercio, 
				X.RUT, 
				X.VENTA_TARJETA, 
				x.codpais, 
				X.TOTCUOTAS,
				X.PAN,
				X.CODACT,
				X.PORINT,
				X.CODENT,
				X.CENTALTA,
				X.CUENTA,
				X.Tipo_Tarjeta,
			(LEFT(SUBSTR(X.PAN,13,4))) as PAN2, 
				CAT(X.CODENT,X.CENTALTA,X.CUENTA,calculated PAN2) as CONTRATO_PAN,
			case 
				when x.Ind_Online in ('81','10') then 1 
				else 0 
			end 
		as si_digital,
			Ind_Online as Ind_PAN,
			X.Producto,
			X.tipofac,x.NUMAUT
		from BASE_TOTAL_FIN as x
			where LUGAR='SPOS'
		;
	QUIT;

	%put==================================================================================================;
	%put [04] TABLA SPOS resumida;
	%put==================================================================================================;

	proc sql;
		create table &libreria..TDA_MCD_&periodo.  as 
			select 
				X.COD_FECHA as Fecha, 
				X.hortrn AS Hora,
				floor(X.COD_FECHA/100) as Periodo, 
				input(X.codigo_comercio_ant,best32.) as codigo_comercio_ant,
				x.codigo_comercio, 
				X.NOMCOM as Nombre_Comercio, 
				X.RUBRO as Actividad_Comercio, 
				X.RUT, 
				X.VENTA_TARJETA, 
				x.codpais, 
				X.TOTCUOTAS,
				X.PAN,
				X.CODACT,
				X.PORINT,
				X.CODENT,
				X.CENTALTA,
				X.CUENTA,
				X.Tipo_Tarjeta,
			(LEFT(SUBSTR(X.PAN,13,4))) as PAN2, 
				CAT(X.CODENT,X.CENTALTA,X.CUENTA,calculated PAN2) as CONTRATO_PAN,
			case 
				when x.Ind_Online in ('81','10') then 1 
				else 0 
			end 
		as si_digital,
			Ind_Online as Ind_PAN,
			X.Producto,
			X.tipofac,x.NUMAUT
		from BASE_TOTAL_FIN as x
			where LUGAR='TIENDA'
		;
	QUIT;

	%put==================================================================================================;
	%put [05] BORRADO DE TABLAS;
	%put==================================================================================================;

	proc sql;
		drop table cuentas;
		drop table data_IMP_DATA;
		drop table data_IMP_DATA2;
		drop table cruce;
		drop table BASE_TOTAL_FIN;
		;
	QUIT;

%mend spos_aut;

%macro ejecutar(A);

	DATA _null_;
		HOY = day(today());
		Call symput("HOY", HOY);
	RUN;

	%put &HOY;

	%if %eval(&HOY.<=5) %then
		%do;

			DATA _null_;
				periodo_ant = input(put(intnx('month',today(),-1,'end'),yymmn6. ),$10.);
				periodo_act = input(put(intnx('month',today(),0,'end'),yymmn6. ),$10.);
				Call symput("periodo_ant", periodo_ant);
				Call symput("periodo_act", periodo_act);
			RUN;

			%put &periodo_ant;
			%put &periodo_act;

			%spos_aut(&periodo_ant.,&lib.);
			%spos_aut(&periodo_act.,&lib.);
		%end;
	%else
		%DO;

			DATA _null_;
				periodo_act = input(put(intnx('month',today(),0,'end'),yymmn6. ),$10.);
				Call symput("periodo_act", periodo_act);
			RUN;

			%put &periodo_act;

			%spos_aut(&periodo_act.,&lib.);
		%end;
%mend ejecutar;

%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

%ejecutar(A);

data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */

/*	Fecha ejecución del proceso	*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN);
RUN;

%put &fechaeDVN;/*fecha ejecucion proceso */

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;
	SELECT EMAIL into :EDP_BI 
		FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 
		FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';
	SELECT EMAIL into :DEST_2 
		FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';
	SELECT EMAIL into :DEST_3 
		FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'ALEJANDRA_MARINAO';
	SELECT EMAIL into :DEST_4
		FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;

data _null_;
	FILENAME OUTBOX EMAIL
		FROM = ("&EDP_BI")
		TO = ("&DEST_1","&DEST_2","&DEST_3","&DEST_4")
		SUBJECT="MAIL_AUTOM: PROCESO MCD %sysfunc(date(),yymmdd10.)";
	FILE OUTBOX;
	PUT 'Estimados:';
	PUT;
	put "Proceso MCD, ejecutado con fecha: &fechaeDVN";
	put;
	put 'Tabla resultante en: PUBLICIN.SPOS_MCD_PERIODO';
	put 'Tabla resultante en: PUBLICIN.TDA_MCD_PERIODO';
	PUT;
	PUT;
	put 'Proceso Vers. 05';
	PUT;
	PUT;
	PUT 'Atte.';
	Put 'Equipo Datos y Procesos BI';
	PUT;
	PUT;
	PUT;
RUN;

FILENAME OUTBOX CLEAR;
