/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	SEG_RUBR_CLI_UNICO_SPOS		================================*/

/* CONTROL DE VERSIONES
/* 2022-08-25 -- V03 -- Sergio J. 
					 -- Se añade sentencia include para borrar y exportar a RAW
/* 2022-07-12 -- V02 -- Sergio J. 
					 -- Se agrega código de exportación para alimentar a Tableau

/* 2021-11-04 -- V01 -- Pedro M. -- 
		-- Versión Original
/* INFORMACIÓN:
Genera un dashboard de clientes unicos de los últimos 12 meses de rubros de SPOS, 
aperturado por lógica comercial.
*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

%let libreria=RESULT;

PROC SQL outobs=1 noprint;
	select year(today())*100+month(today()) as Periodo_Proceso /*Sacar Ultimo periodo disponible en esa tabla*/
		into :Periodo_Proceso 
			from result.CodCom_Camps_SPOS /*Base de Comercios que manda SPOS en excel (asegurarse de que este buena: sin blancos, sin duplicados, otros)*/
		;
QUIT;

%let periodo_proceso=&periodo_proceso;

/*::::::::::::::::::::::::::*/
%let Periodo=&Periodo_Proceso; /*periodo de campañas a considerar de archivo de campañas*/
%let ventana_tiempo=17; /*ventana de tiempo hacia atras para ver*/

/*::::::::::::::::::::::::::*/
%put ########################venta tc+mcd  &periodo. +17M   ######################################;

proc sql;
	create table Vta_SPOS_TC (
		periodo num,
		Fecha num ,
		CODACT num,
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
							a.CODACT,
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
							a.CODACT,
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
							a.CODACT,
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

/*venta debito maestro*/
proc sql;
	create table Vta_SPOS_TD(
		periodo num,
		Fecha num ,
		CODACT num,
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
			insert into Vta_SPOS_TD
				select
					&paso. as periodo, 
					a.Fecha,
					a.CODACT,
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
%put ########################UNION DE VENTA &periodo.  ######################################;

proc sql;
	create table venta as 
		select 
			periodo	,
			CODACT,
			VENTA_TARJETA,
			Tipo_Tarjeta,
			RUT
		from Vta_SPOS_TD
			outer union corr
				select 
					periodo	,
					CODACT,
					VENTA_TARJETA,
					Tipo_Tarjeta,
					RUT
				from vta_spos_TC
	;
QUIT;

PROC SQL;
	CREATE INDEX CODACT ON work.venta (CODACT)
	;
QUIT;

%if (%sysfunc(exist(&libreria..cliente_unico_spos_rubro))) %then
	%do;
	%end;
%else
	%do;

		proc sql;
			create table &libreria..cliente_unico_spos_rubro (
				ejecucion char(99), 
				periodo_tableau date, 
				periodo num, 
				periodo_camada_tableau date, 
				periodo_camada num , 
				rubro char(99), 
				TENENCIA_TARJETA char(99), 
				TIPO_CLIENTE char(99), 
				clientes num, 
				TRX num, 
				venta_tarjeta num, 
				TRX_TC num, 
				venta_tarjeta_TC num, 
				TRX_TD num, 
				venta_tarjeta_TD num)
			;
		QUIT;

	%end;

proc sql;
	delete *
		from &libreria..cliente_unico_spos_rubro

	;
QUIT;

%put ##################################### RUBROS ###############################;

proc sql;
	create table TABLA_ARBOL as  
		select distinct 
			'credito' as tipo,
			COD_ACT as cod_rubro,
			max(CATEGORIAS_RIPLEY) as RUBRO_GESTION,
		CASE 
			WHEN CATEGORIAS_RIPLEY in ('SERVICIOS','SERVICIOS BASICOS','TRANSPORTE') THEN 'Servicios'
			WHEN CATEGORIAS_RIPLEY IN  ('OTROS COMERCIOS','Otros Rubros SPOS','BELLEZA') THEN 'Otros Comercios'
			WHEN CATEGORIAS_RIPLEY IN ('VIAJES','ENTRETENCION') THEN 'Viajes&Entretencion'
			WHEN  CATEGORIAS_RIPLEY IN ('ALIMENTACION Y FAST FOOD','RESTAURANTES') THEN 'Alimentacion'
			WHEN CATEGORIAS_RIPLEY IN ('RECAUDACION SECTOR PUBLICO','RECAUDACION','INSTITUCIONES FINANCIERAS') THEN 'Recaudacion&Inst_Finan'
			ELSE CATEGORIAS_RIPLEY 
		END 
	AS RUBRO2
		from sbarrera.TABLA_ARBOL /*Tabla de asignacion de rubros*/
	group by 
		COD_ACT
	outer union corr 
		select distinct
			'TD' as TIPO, 
			input(COD_RUB,best.) as cod_rubro,
			max(CATEGORIAS_RIPLEY) as RUBRO_GESTION,
		CASE 
			WHEN CATEGORIAS_RIPLEY in ('SERVICIOS','SERVICIOS BASICOS','TRANSPORTE') THEN 'Servicios'
			WHEN CATEGORIAS_RIPLEY IN  ('OTROS COMERCIOS','Otros Rubros SPOS','BELLEZA') THEN 'Otros Comercios'
			WHEN CATEGORIAS_RIPLEY IN ('VIAJES','ENTRETENCION') THEN 'Viajes&Entretencion'
			WHEN  CATEGORIAS_RIPLEY IN ('ALIMENTACION Y FAST FOOD','RESTAURANTES') THEN 'Alimentacion'
			WHEN CATEGORIAS_RIPLEY IN ('RECAUDACION SECTOR PUBLICO','RECAUDACION','INSTITUCIONES FINANCIERAS') THEN 'Recaudacion&Inst_Finan'
			ELSE CATEGORIAS_RIPLEY 
		END 
	AS RUBRO2 
		from sbarrera.TABLA_ARBOL /*Tabla de asignacion de rubros*/
	group by 
		COD_RUB
	;
QUIT;

proc sql;
	create table num as select 
		distinct 
			RUBRO2

		from TABLA_ARBOL
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
	create table  TABLA_ARBOL as 
		select distinct 
			b.ind, 
			a.*
		from TABLA_ARBOL as a 
			left join num as b
				on(a.RUBRO2=b.RUBRO2)
	;
QUIT;

PROC SQL;
	CREATE INDEX cod_rubro ON work.TABLA_ARBOL (cod_rubro)
	;
QUIT;

%put ###################### &i. primer_cruce#################################;

proc sql inobs=1 noprint;
	select 
		ind
		into:ind
	from tabla_arbol 
		where 
			RUBRO2='Otros Comercios'
	;
QUIT;

%let ind=&ind;

proc sql;
	create table primer_cruce as 
		select 
			a.*,
		case 
			when (a.CODACT=b.cod_rubro and a.tipo_tarjeta in ('TR','TAM','MCD') and b.tipo='credito')
			or (a.CODACT=b.cod_rubro and a.tipo_tarjeta in ('MAESTRO') and b.tipo='TD')  then b.ind 
			else &ind. 
		end 
	as marca_RUBRO
		from venta as a
			left join TABLA_ARBOL as b
				on(a.CODACT=b.cod_rubro)
	;
quit;

%put ###################### &i. primer_colapso#################################;

proc sql;
	create table primer_colapso as 
		select 
			periodo,
			marca_rubro as rubro,
			rut,
			count(rut) as TRX,
			sum(venta_tarjeta) as venta_tarjeta,
			count
		(case 
			when Tipo_Tarjeta in ('MAESTRO','MCD') then rut 
		end  )
	as TRX_TD,
		sum
	(case 
		when Tipo_Tarjeta in ('MAESTRO','MCD') then venta_tarjeta 
	end  )
as monto_TD,
	count
(case 
	when Tipo_Tarjeta in ('TR','TAM') then rut 
end  )
as TRX_TC,
sum
(case 
when Tipo_Tarjeta in ('TR','TAM') then venta_tarjeta 
end  )
as monto_TC
from primer_cruce 
group by 
	periodo,
	rut,
	marca_rubro
	;
QUIT;

PROC SQL;
	CREATE INDEX rut ON work.primer_colapso (rut)
	;
QUIT;

%put ###################### &i. segundo_colapso#################################;

%if (%sysfunc(exist(tabla_paso_fin))) %then
	%do;
	%end;
%else
	%do;

		proc sql;
			create table tabla_paso_fin (  
				periodo_camada num, 
				rubro num , 
				TENENCIA_TARJETA char(99), 
				TIPO_CLIENTE char(99), 
				clientes num, 
				TRX num , 
				venta_tarjeta num, 
				TRX_TC num, 
				venta_tarjeta_TC num , 
				TRX_TD num, 
				venta_tarjeta_TD num )
			;
		QUIT;

	%end;

/*contratos actuales*/
PROC SQL NOERRORSTOP;
	CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
	create table cuentas  as 
		select * 
			from connection to ORACLE( 
				select 
					cast(B.PEMID_GLS_NRO_DCT_IDE_K as INT)  RUT,
					a.FECALTA  FECALTA_CTTO,
					a.FECBAJA  FECBAJA_CTTO,
					a.INDBLQOPE
				from MPDT007 a
					INNER JOIN BOPERS_MAE_IDE B 
						ON A.IDENTCLI=B.PEMID_NRO_INN_IDE
						) A
	;
QUIT;

%let path_ora      = '(DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SID = ripleyc)))';
%let user_ora      = 'RIPLEYC';
%let pass_ora      = 'ri99pley';
%let conexion_ora  = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.;
%put &conexion_ora.;
LIBNAME DBLIBORA     &conexion_ora. insertbuff=10000 readbuff=10000;

PROC SQL  NOERRORSTOP;
	CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );
	create table cuentas_TD  as
		select * from connection to ORACLE
			( 
		SELECT 
			CAST(SUBSTR(a.cli_identifica,1,length(a.cli_identifica)-1) AS INT)  rut,
			SUBSTR(a.cli_identifica,length(a.cli_identifica),1)  dv,
			/*b.vis_pro,*/
			b.vis_numcue  cuenta, 
			/*b.VIS_TIP  TIPO_PRODUCTO,*/
			/*b.vis_fechape,*/
			cast(TO_CHAR( b.vis_fechape,'YYYYMMDD') as INT) as FECHA_APERTURA,
			/*b.VIS_FECHCIERR,*/
			cast(TO_CHAR( b.VIS_FECHCIERR,'YYYYMMDD') as INT) as FECHA_CIERRE,
			/*b.vis_status  estado,*/
		CASE 
			WHEN b.VIS_PRO=4 THEN 'CUENTA_VISTA'
			WHEN b.VIS_PRO=40 THEN 'LCA' 
		END  
		DESCRIP_PRODUCTO,
	CASE 
		WHEN b.vis_status ='9' THEN 'cerrado' 
		when b.vis_status ='2' then 'vigente' 
	end 
as estado_cuenta,
	/*c.DES_CODTAB,*/
	c.DES_CODIGO COD_CIERRE_CONTRATO,
	c.DES_DESCRIPCION DESC_CIERRE_CONTRATO,
	d.STA_DESCRIPCION desc_est_cuenta
from  tcap_vista  b 
	inner join  tcli_persona   a
		on(a.cli_codigo=b.vis_codcli) 
	left join tgen_desctabla  c
		on(b.VIS_CODTAB=c.DES_CODTAB) and 	(b.VIS_CAUCIERR=c.DES_CODIGO)
	left join tgen_status d
		on(b.vis_status=d.STA_CODIGO) and (d.STA_MOD=4)
	where 
		b.vis_mod=4
		and (b.VIS_PRO=4 or b.VIS_PRO=40)
		and b.vis_tip=1  
		/*AND (b.vis_status='2' or b.vis_status='9') */
			);
	disconnect from ORACLE;
QUIT;

%macro cortar;
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
					a.rut,
					a.TRX,
					a.venta_tarjeta,
					a.TRX_TD,
					a.monto_TD,
					a.TRX_TC,
					a.monto_TC
				from primer_colapso as a 
					where periodo=&periodo_paso.
			;
		QUIT;

		proc sql;
			create table paso2 as 
				select    
					a.periodo,
					a.rubro,
					a.rut
				from primer_colapso as a 
					where periodo between &periodo_1. and &periodo_3.
			;
		QUIT;

		proc sql;
			create table cruce as 
				select 
					a.periodo,
					a.rubro,
					a.rut,
					a.TRX,
					a.venta_tarjeta,
					a.TRX_TD,
					a.monto_TD,
					a.TRX_TC,
					a.monto_TC,
					max
				(case 
					when b.rut is not null then 1 
					else 0 
				end)
			as USO_SPOS,
				max
			(case 
				when b.rut is not null and a.rubro=b.rubro then 1 
				else 0 
			end)
		as USO_RUBRO_ANT
			from paso1 as a 
				left join paso2 as b
					on(a.rut=b.rut)
				group by 
					a.rubro,
					a.rut,
					a.TRX,
					a.venta_tarjeta,
					a.periodo,
					a.TRX_TD,
					a.monto_TD,
					a.TRX_TC,
					a.monto_TC
			;
		QUIT;

		%if (%sysfunc(exist(publicin.act_tr_&periodo.))) %then
			%do;

				PROC SQL NOERRORSTOP;
					create table vu_tc as 
						SELECT 
							rut from publicin.act_tr_&periodo.
						where vu_riesgo=1
					;
				QUIT;

			%end;
		%else
			%do;

				PROC SQL NOERRORSTOP;
					create table vu_tc as 
						SELECT distinct 
							rut from cuentas 
						where 
							input(compress(FECALTA_CTTO,'-'),best.)<=100*&periodo.+31 
							and (FECBAJA_CTTO='0001-01-01' or input(compress(FECBAJA_CTTO,'-'),best.)>100*&periodo.+31 )
							and INDBLQOPE='N'
					;
				QUIT;

			%end;

		proc sql;
			create table vu_td as 
				select 
					distinct rut 
						from cuentas_td
							where 
								FECHA_APERTURA<=100*&periodo.+31 and 
								(FECHA_CIERRE is null or fecha_cierre>100*&periodo.+31 )
			;
		QUIT;

		proc sql;
			create table cruce2 as 
				select 
					a.*,
				case 
					when b.rut is not null or a.TRX_TC>0 then 1 
					else 0 
				end 
			as TENENCIA_TC,
				case 
					when c.rut is not null or a.TRX_TD>0 then 1 
					else 0 
				end 
			as TENENCIA_TD
				from cruce as a 
					left join vu_tc as b
						on(a.rut=b.rut)
					left join vu_td as c
						on(a.rut=c.rut)
			;
		QUIT;

		proc sql;
			create table colapso_final as 
				select 
					periodo,
					rubro,
				case 
					when TENENCIA_TC=1 and TENENCIA_TD=0 then 'TC'
					when TENENCIA_TC=0 and TENENCIA_TD=1 then 'TD'
					when TENENCIA_TC=1 and TENENCIA_TD=1 then 'TD+TC' 
				end 
			as TENENCIA_TARJETA,
				case 
					when USO_SPOS=1 and USO_RUBRO_ANT=0 then 'NR AS '
					when USO_SPOS=1 and 	USO_RUBRO_ANT=1 then 'AR'
					when USO_SPOS=0 and 	USO_RUBRO_ANT=0 then 'NR NS' 
				end 
			as TIPO_CLIENTE,
				count(distinct rut ) as clientes,
				sum(TRX) as TRX	,
				sum(venta_tarjeta) as venta_tarjeta,
				sum(TRX_TC) as TRX_TC	,
				sum(monto_TC) as venta_tarjeta_TC,
				sum(TRX_TD) as TRX_TD	,
				sum(monto_TD) as venta_tarjeta_TD
			from cruce2  
				group by 
					periodo,
					rubro,
					calculated tenencia_tarjeta,
					calculated tipo_cliente
			;
		QUIT;

		proc sql;
			insert into tabla_paso_fin
				select 
					*
				from colapso_final
			;
		QUIT;

		proc sql;
			drop table paso1;
			drop table paso2;
			drop table cruce;
			drop table vu_tc;
			drop table VU_TD;
			drop table cruce2;
			drop table colapso_final;
			;
		QUIT;

	%end;
%mend cortar;

%cortar;
%put ###################### &i. colapso_final#################################;

proc sqL noprint;
	create table final as 
		select distinct 
			put(today() ,ddmmyy10.) as ejecucion, 
			mdy(mod(int((&periodo.*100+01)/100),100),mod((&periodo.*100+01),100),int((&periodo.*100+01)/10000)) format=date9. as periodo_tableau,
			&periodo. as periodo,
			mdy(mod(int((a.periodo_camada*100+01)/100),100),mod((a.periodo_camada*100+01),100),int((a.periodo_camada*100+01)/10000)) format=date9. as periodo_camada_tableau,
			a.periodo_camada,
		case 
			when b.ind is not null then upcase(b.rubro2)  
			else 'OTROS' 
		end 
	as rubro,
		TENENCIA_TARJETA,
		TIPO_CLIENTE,
		coalesce(clientes,0) as  clientes,
		coalesce(TRX, 0) as TRX,
		coalesce(venta_tarjeta,0) as venta_tarjeta,
		coalesce(TRX_TC, 0) as TRX_TC,
		coalesce(venta_tarjeta_TC,0) as venta_tarjeta_TC,
		coalesce(TRX_TD, 0) as TRX_TD,
		coalesce(venta_tarjeta_TD,0) as venta_tarjeta_TD
	from tabla_paso_fin as a 
		left join TABLA_ARBOL as b
			on(a.rubro=b.ind)
	;
QUIT;

proc sql;
	insert into &libreria..cliente_unico_spos_rubro 
		select *
			from final
	;
QUIT;

proc sql;
	create table &libreria..cliente_unico_spos_rubro  as 
		select *
			from &libreria..cliente_unico_spos_rubro 
	;
QUIT;

proc sql;
	drop table CUENTAS;
	drop table FINAL;
	drop table NUM;
	drop table primer_colapso;
	drop table TABLA_ARBOL;
	drop table PRIMER_CRUCE;
	drop table tabla_paso_fin;
	drop table venta;
	drop table vta_spos_tc;
	drop table vtas_spos_TD;
	drop table cuetas_TD;
	;
QUIT;

%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_DELETE.sas";
%borrarOracleRaw(SPOS_CLIENTE_UNICO_RUBRO);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS_ORACLOUD/AWS_RAW_ORACLOUD_EXPORT.sas";
%ExportacionOracleRaw(SPOS_CLIENTE_UNICO_RUBRO,RESULT.cliente_unico_spos_rubro);

data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */

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
		SUBJECT="MAIL_AUTOM: CLIENTE UNICO SPOS POR RUBRO %sysfunc(date(),yymmdd10.)";
	FILE OUTBOX;
	PUT 'Estimados:';
	put "	Proceso CLIENTE UNICO SPOS POR RUBRO, ejecutado con fecha: &fechaeDVN";
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
