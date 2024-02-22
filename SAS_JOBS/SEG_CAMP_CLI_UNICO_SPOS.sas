/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	SEG_CAMP_CLI_UNICO_SPOS		================================*/

/* CONTROL DE VERSIONES
/* 2022-08-25 -- V03 -- Sergio J. 
					 -- Se añade sentencia include para borrar y exportar a RAW

/* 2022-07-12 -- V02 -- Sergio J. 
					 -- Se agrega código de exportación para alimentar a Tableau

/* 2021-11-04 -- V01 -- Pedro M. -- 
			      	 -- Versión Original
/* INFORMACIÓN:
		Genera un dashboard de clientes unicos de los últimos 12 meses de campañas de SPOS, 
	aperturado por lógica comercial.
*/
%let libreria=RESULT;
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

PROC SQL outobs=1 noprint;
	select max(Periodo_Campana) as Periodo_Proceso /*Sacar Ultimo periodo disponible en esa tabla*/
		into :Periodo_Proceso 
			from result.CodCom_Camps_SPOS /*Base de Comercios que manda SPOS en excel (asegurarse de que este buena: sin blancos, sin duplicados, otros)*/
		;
QUIT;

%let periodo_proceso=&periodo_proceso;

/*::::::::::::::::::::::::::*/
%let Periodo=&Periodo_Proceso; /*periodo de campañas a considerar de archivo de campañas*/
%let ventana_tiempo=17; /*ventana de tiempo hacia atras para ver*/

/*::::::::::::::::::::::::::*/
%put ########################campañas  &periodo.   ######################################;

proc sql;
	create table work.CodCom_Camps_SPOS_Periodo as 
		select 
			Codigo_Comercio,
			max(Marca_Campana) as Marca_Campana,
			MAX(Detalle_Comercio) AS Detalle_Comercio
		from result.CodCom_Camps_SPOS /*Base de Comercios que manda SPOS en excel (asegurarse de que este buena: sin blancos, sin duplicados, otros)*/
	where Periodo_Campana=&Periodo. 
		and coalesce(Codigo_Comercio,0)>0 
	group by /*se agrupa para asegurar de que quede a nivel de codigo UNICO*/
	Codigo_Comercio,Detalle_Comercio

	;
quit;

%put ########################venta tc+mcd  &periodo. +17M   ######################################;

proc sql;
	create table Vta_SPOS_TC (
		periodo num,
		Fecha num ,
		Codigo_Comercio num,
		Nombre_Comercio char(99),
		Actividad_Comercio char(99),
		rut num,
		VENTA_TARJETA num,
		Tipo_Tarjeta char(10)
		)
	;
QUIT;

proc sql inobs=1 noprint;
	select 
		mdy(mod(int((&Periodo_Proceso.*100+01)/100),100),mod((&Periodo_Proceso.*100+01),100),int((&Periodo_Proceso.*100+01)/10000)) format=date9. as pasito
	into
		:pasito
	from pmunoz.codigos_capta_cdp
	;
QUIT;

%macro APILAR(i,f);
	%let periodo_iteracion=&i;

	%do %while(&periodo_iteracion<=&f); /*inicio del while*/
		%put ############### &periodo_iteracion ################################;

		DATA _NULL_;
			paso = put(intnx('month',"&pasito"d,-&periodo_iteracion.,'end'),yymmn6.);
			Call symput("paso",paso);
		run;

		%put ############### &paso ################################;

		%if (&paso.<202006) %then
			%do;

				proc sql;
					insert into Vta_SPOS_TC
						select
							&paso. as periodo, 
							a.Fecha,
							a.Codigo_Comercio,
							a.Nombre_Comercio,
							a.Actividad_Comercio,
							a.rut,
							a.VENTA_TARJETA,
							a.Tipo_Tarjeta

						from publicin.SPOS_AUT_&paso. as a 

					;
				QUIT;

			%end;
		%else
			%do;

				proc sql;
					insert into Vta_SPOS_TC
						select
							&paso. as periodo, 
							a.Fecha,
							a.Codigo_Comercio,
							a.Nombre_Comercio,
							a.Actividad_Comercio,
							a.rut,
							a.VENTA_TARJETA,
							a.Tipo_Tarjeta
						from publicin.SPOS_AUT_&paso. as a 

					;
				QUIT;

				proc sql;
					insert into Vta_SPOS_TC
						select
							&paso. as periodo, 
							a.Fecha,
							a.Codigo_Comercio,
							a.Nombre_Comercio,
							a.Actividad_Comercio,
							a.rut,
							a.VENTA_TARJETA,
							a.Tipo_Tarjeta
						from publicin.SPOS_MCD_&paso. as a 

					;
				QUIT;

			%end;

		%let periodo_iteracion=%sysevalf(&periodo_iteracion. +1);

	%end; /*final del while*/
%mend APILAR;

%APILAR (0,&ventana_tiempo.);
%put #########################VENTA SPOS MAESTRO#######################;

proc sql;
	create table Vtas_SPOS_TD (
		periodo num,
		Fecha num ,
		Codigo_Comercio num,
		Nombre_Comercio char(99),
		Actividad_Comercio char(99),
		rut num,
		VENTA_TARJETA num,
		Tipo_Tarjeta char(10)
		)
	;
QUIT;

proc sql inobs=1 noprint;
	select 
		mdy(mod(int((&Periodo_Proceso.*100+01)/100),100),mod((&Periodo_Proceso.*100+01),100),int((&Periodo_Proceso.*100+01)/10000)) format=date9. as pasito
	into
		:pasito
	from pmunoz.codigos_capta_cdp
	;
QUIT;

%macro APILAR2(i,f);
	%let periodo_iteracion=&i;

	%do %while(&periodo_iteracion<=&f); /*inicio del while*/
		%put ############### &periodo_iteracion ################################;

		DATA _NULL_;
			paso = put(intnx('month',"&pasito"d,-&periodo_iteracion.,'end'),yymmn6.);
			Call symput("paso",paso);
		run;

		%put ############### &paso ################################;

		proc sql;
			insert into Vtas_SPOS_TD
				select
					&paso. as periodo, 
					a.Fecha,
					a.Codigo_Comercio,
					a.Nombre_Comercio,
					a.Actividad_Comercio,
					a.rut,
					a.VENTA_TARJETA,
					a.Tipo_Tarjeta

				from publicin.SPOS_MAESTRO_&paso. as a 

			;
		QUIT;

		%let periodo_iteracion=%sysevalf(&periodo_iteracion. +1);

	%end; /*final del while*/
%mend APILAR2;

%APILAR2 (0,&ventana_tiempo.);
%put ########################codigos campaña &periodo.  ######################################;

PROC SQL;
	CREATE TABLE WORK.codigos AS 
		SELECT Distinct compress(upper(Marca_Campana),',,,') as marca_campana
			FROM RESULT.CODCOM_CAMPS_SPOS t1
				WHERE  periodo_campana=&periodo.


	;
QUIT;

PROC SQL;
	CREATE TABLE WORK.codigos AS 
		SELECT  monotonic() as IND,*
			FROM codigos
	;
QUIT;

proc sql;
	create table codigos_fin as 
		select 
			b.IND,
			compress(upper(a.Marca_Campana),',,,') as marca_campana,
			a.codigo_comercio
		from result.codcom_camps_spos as a 
			left join codigos as b
				on (compress(upper(a.Marca_Campana),',,,')=b.marca_campana) 
			where a.periodo_campana=&periodo.
	;
QUIT;

proc sql noprint;
	select 
		max(ind) as stop 
	into :stop
		from codigos_fin
	;
QUIT;

%let stop=&stop;

proc sql;
	create table venta as 
		select 
			periodo	,
			CODIGO_COMERCIO,
			Actividad_Comercio,
			VENTA_TARJETA,
			Tipo_Tarjeta,
			RUT
		from vtas_spos_td
			outer union corr
				select 
					periodo	,
					CODIGO_COMERCIO,
					Actividad_Comercio,
					VENTA_TARJETA,
					Tipo_Tarjeta,
					RUT
				from vta_spos_TC
	;
QUIT;

PROC SQL;
	CREATE INDEX CODIGO_COMERCIO ON work.venta (CODIGO_COMERCIO)
	;
QUIT;

%if (%sysfunc(exist(&libreria..cliente_unico_spos_test))) %then
	%do;
	%end;
%else
	%do;

		proc sql;
			create table &libreria..cliente_unico_spos_test (
				ejecucion char(99),
				periodo_tableau date, 
				periodo num, 
				periodo_camada_tableau date, 
				periodo_camada num, 
				CAMPANA char(99), 
				CLIENTES num, 
				N_TRX num, 
				VENTA_TARJETA num, 
				AR_AC num, 
				AR_NC num, 
				NR_NC_AS num, 
				NR_NC_NS num)
			;
		QUIT;

	%end;

proc sql;
	delete *
		from &libreria..cliente_unico_spos_test

	;
QUIT;

proc sql;
	create table codios_paso as 
		select *
			from codigos_fin
	;
QUIT;

proc sql;
	create table num as select 
		distinct 
			marca_campana 
		from codios_paso
	;
QUIT;

proc sql;
	create table num as 
		select 
			monotonic() as ind,
			*
		from num
	;
QUIT;

proc sql;
	create table  codios_paso as 
		select 
			b.ind, 
			a.*
		from codios_paso as a 
			left join num as b
				on(a.marca_campana=b.marca_campana)
	;
QUIT;

PROC SQL;
	CREATE INDEX CODIGO_COMERCIO ON work.codios_paso (CODIGO_COMERCIO)
	;
QUIT;

%put ###################### &i. primer_cruce#################################;

proc sql;
	create table primer_cruce as 
		select 
			a.*,
		case 
			when a.codigo_comercio=b.codigo_comercio and a.codigo_comercio is not null then 1 
			else 0 
		end 
	as si_comercio,
		case 
			when a.codigo_comercio=b.codigo_comercio and a.codigo_comercio is not null then b.ind 
			else 99999 
		end 
	as marca_campana
		from venta as a
			left join codios_paso as b
				on(a.codigo_comercio=b.codigo_comercio)
	;
quit;

%put ###################### &i. primer_colapso#################################;

proc sql;
	create table primer_colapso as 
		select 
			periodo,
			marca_campana,
			actividad_comercio as rubro,
			rut,
			count( rut) as TRX,
			sum(venta_tarjeta) as venta_tarjeta
		from primer_cruce 
			group by 
				periodo,
				rut,
				rubro,
				marca_campana
	;
QUIT;

PROC SQL;
	CREATE INDEX rut ON work.primer_colapso (rut)
	;
QUIT;

%put ###################### &i. segundo_colapso#################################;

proc sql;
	create table llenado_paso
		(periodo num,
		marca_campana num ,
		clientes num,
		TRX	num,
		venta_tarjeta num,
		NR_NC_NS num,
		NR_NC_AS num,
		AR_AC num,
		AR_NC num
		)
	;
QUIT;

%macro ejecutar;
	%do i=0 %to 13;
		%put ####################CICLO &i.#########################;

		DATA _NULL_;
			periodo_paso = put(intnx('month',today(),-&i.,'begin'),yymmn6.);
			periodo_1 = put(intnx('month',today(),-&i.-1,'begin'),yymmn6.);
			periodo_3 = put(intnx('month',today(),-&i.-3,'begin'),yymmn6.);
			Call symput("periodo_paso",periodo_paso);
			Call symput("periodo_1",periodo_1);
			Call symput("periodo_3",periodo_3);
		run;

		%put &periodo_paso;
		%put &periodo_1;
		%put &periodo_3;

		proc sql;
			create table paso1 as 
				select    
					a.periodo,
					a.rubro,
					a.marca_campana,
					a.rut,
					a.TRX,
					a.venta_tarjeta
				from primer_colapso as a 
					where periodo=&periodo_paso.
			;
		QUIT;

		proc sql;
			create table paso2 as 
				select    
					a.periodo,
					a.rubro,
					a.marca_campana,
					a.rut,
					a.TRX,
					a.venta_tarjeta
				from primer_colapso as a 
					where periodo between &periodo_1. and &periodo_3.
			;
		QUIT;

		proc sql;
			create table cruce as 
				select 
					a.periodo,
					a.marca_campana,
					a.rut,
					sum(a.TRX) as trx,
					sum(a.venta_tarjeta) as venta_tarjeta,
					max
				(case 
					when b.rut is not null then 1 
					else 0 
				end)
			as SI_SPOS_ANT,
				max
			(case 
				when b.rut is not null and a.marca_campana=b.marca_campana then 1 
				else 0 
			end)
		as SI_COMERCIO_ANT,
			max
		(case 
			when b.rut is not null and a.rubro=b.rubro then 1 
			else 0 
		end )
	as SI_RUBRO_ANT
		from paso1 as a 
			left join paso2 as b
				on(a.rut=b.rut)
			group by 
				a.rut,
				a.periodo,
				a.marca_campana
			;
		QUIT;

		proc sql;
			create table colapso_final as 
				select 
					periodo,
					marca_campana,
					count(distinct rut)  as clientes,
					sum(TRX) as TRX	,
					sum(venta_tarjeta) as venta_tarjeta,
					count(distinct 
				case 
					when SI_SPOS_ANT=0 then rut 
				end  )
			as NR_NC_NS,
				count(distinct 
			case 
				when SI_SPOS_ANT=1 and (SI_COMERCIO_ANT=0) and	(SI_RUBRO_ANT=0) then rut 
			end  )
		as NR_NC_AS,
			count(distinct 
		case 
			when  (SI_COMERCIO_ANT=1 and	SI_RUBRO_ANT=1) or  (SI_COMERCIO_ANT=1 and	SI_RUBRO_ANT=0) then rut 
		end )
	as AR_AC,
		count(distinct 
	case 
		when  (SI_COMERCIO_ANT=0) and	SI_RUBRO_ANT=1 then rut 
	end )
as AR_NC
	from cruce 
		where marca_campana<9999
			group by 
				periodo,
				marca_campana
			;
		QUIT;

		proc sql;
			insert into llenado_paso 
				select 
					*
				from colapso_final
			;
		QUIT;

		proc sql;
			drop table paso1;
			drop table paso2;
			drop table cruce;
			drop table colapso_final;
			;
		QUIT;

	%end;
%mend ejecutar;

%ejecutar;
%put ###################### &i. colapso_final#################################;

proc sqL noprint;
	create table final as 
		select distinct 
			put(today() ,ddmmyy10.) as ejecucion, 
			mdy(mod(int((&periodo.*100+01)/100),100),mod((&periodo.*100+01),100),int((&periodo.*100+01)/10000)) format=date9. as periodo_tableau,
			&periodo. as periodo,
			mdy(mod(int((a.periodo*100+01)/100),100),mod((a.periodo*100+01),100),int((a.periodo*100+01)/10000)) format=date9. as periodo_camada_tableau,
			a.periodo as periodo_camada,
			b.marca_campana as  CAMPANA,
			a.CLIENTES,
			a.TRX as N_TRX,
			a.VENTA_TARJETA,
			a.AR_AC,
			a.AR_NC,
			a.NR_NC_AS,
			a.NR_NC_NS
		from llenado_paso as a 
			left join codios_paso as b
				on(a.marca_campana=b.ind)
	;
QUIT;

proc sql;
	insert into &libreria..cliente_unico_spos_test 
		select *
			from final
	;
QUIT;

proc sql;
	create table  &libreria..cliente_unico_spos_test  as 
		select *
			from &libreria..cliente_unico_spos_test
	;
QUIT;

proc sql;
	drop table codios_paso;
	drop table primer_cruce;
	drop table segundo_cruce;
	drop table primer_colapso;
	drop table segundo_colapso;
	drop table colapso_final;
	drop table final;
	;
QUIT;

data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */

proc sql;
	drop table CodCom_Camps_SPOS_Periodo;
	drop table Vta_SPOS_TC;
	drop table cuentas;
	drop table Vtas_SPOS_TD;
	drop table codigos;
	drop table codigos_fin;
	drop table venta;
	;
QUIT;

%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_DELETE.sas";
%borrarOracleRaw(SPOS_CLIENTE_UNICO_SPOS);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_EXPORT.sas";
%ExportacionOracleRaw(SPOS_CLIENTE_UNICO_SPOS,RESULT.cliente_unico_spos_test);

%put==================================================================================================;
%put EMAIL AUTOMATICO;
%put==================================================================================================;

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
		FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';
	SELECT EMAIL into :DEST_3
		FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;

data _null_;
	FILENAME OUTBOX EMAIL
		FROM = ("&EDP_BI")
		TO = ("crachondode@bancoripley.com")
		CC = ("&DEST_1","&DEST_2","&DEST_3") 
		SUBJECT="MAIL_AUTOM:  CLIENTE UNICO SPOS %sysfunc(date(),yymmdd10.)";
	FILE OUTBOX;
	PUT 'Estimados:';
	put "	Proceso CLIENTE UNICO SPOS, ejecutado con fecha: &fechaeDVN";
	put;
	put;
	put 'Proceso Vers. 03';
	put;
	PUT;
	PUT;
	PUT;
	PUT 'Atte.';
	PUT 'Equipo Datos y Procesos BI';
	PUT;
RUN;

FILENAME OUTBOX CLEAR;
