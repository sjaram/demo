/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	FORMAS DE PAGO TDA   		================================*/

/* CONTROL DE VERSIONES
/* 2022-12-05 -- v11-- Sergio J. -- Cuando hay tablas bulk, solo se debe exportar el periodo actual.
/* 2022-11-03 -- v10-- Sergio J. -- Se actualizar export a AWS, según nuevas definiciones a RAW y lógica del proceso.
/* 2022-10-28 -- V9 -- Esteban P. -- Se añade nueva sentencia include para borrar y exportar a RAW.
/* 2022-08-25 -- V8 -- Sergio J. -- Se añade sentencia include para borrar y exportar a RAW
/* 2022-07-12 -- V7 -- Sergio J. -- Se agrega código de exportación para migración
/* 2021-11-04 -- V6 -- Pedro M. -- 
/* 2021-01-26 -- V5 -- Pedro M. -- 
/* 2020-11-09 -- V4 -- David V. --  
				-- Versión Original
/* INFORMACIÓN:
(IN) Tablas requeridas o conexiones a BD:
- CREDITO
- FISA
- CAMP


(OUT) Tablas de Salida o resultado:
- RESULT.evolutivo_forma_pago
- ORACLOUD
*/

/*	VARIABLE LIBRERÍA			*/
%let libreria=RESULT;


%macro MDP_NEW(n,libreria);


	%put==================================================================================================;
	%put [00.00] Macro fechas;
	%put==================================================================================================;

	DATA _null_;
		periodo = input(put(intnx('month',today(),-&n.,'end'),yymmn6. ),$10.);
		INI_FISA = put(intnx('month',today(),-&n.,'begin'),ddmmyy10.);
		FIN_FISA = put(intnx('month',today(),-&n.,'end'),ddmmyy10.);
		INI = put(intnx('month',today(),-&n.,'begin'),date9.);
		FIN = put(intnx('month',today(),-&n.,'end'),date9.);
		INI_num = put(intnx('month',today(),-&n.,'begin'),yymmddn8.);
		FIN_num = put(intnx('month',today(),-&n.,'end'),yymmddn8.);
		Call symput("periodo", periodo);
		Call symput("INI_FISA", INI_FISA);
		Call symput("FIN_FISA", FIN_FISA);
		Call symput("INI", INI);
		Call symput("FIN", FIN);
		Call symput("INI_num", INI_num);
		Call symput("FIN_num", FIN_num);
	RUN;

	%put &periodo;
	%put &INI_FISA;
	%put &FIN_FISA;
	%put &INI;
	%put &FIN;
	%put &INI_NUM;
	%put &FIN_num;
	%put==================================================================================================;
	%put [01.01] informacion de credito retail &periodo;
	%put==================================================================================================;




	%put==================================================================================================;
	%put [01.04] Apertura blando y duro &periodo;
	%put==================================================================================================;

PROC SQL;
CREATE TABLE compras4 AS
SELECT
mdy(mod(int(fecha/100),100),mod(fecha,100),int(fecha/10000)) format=date9. as fecha ,
SUCURSAL,
BOLETA,
Mto	,
CAPITAL	,
BLANDO_DURO,
case when MARCA_TIPO_TR in (
'DEBITO RIPLEY',
'MCD RIPLEY',
'CUENTA CORRIENTE RIPLEY') then 'DEBITO RIPLEY'

when MARCA_TIPO_TR='T_CREDITO' then 'CREDITO'
when MARCA_TIPO_TR='OTRAS DEBITO' then 'DEBITO'
when marca_tipo_TR='OTRA' then 'OTROS'
when marca_tipo_TR='CHECK' then 'CHEK'
else MARCA_TIPO_TR end as MARCA_TIPO_TR


FROM result.uso_tr_marca_&periodo. 
;
QUIT;

proc sql;
create table venta_bol as 
select 
'BLANDO' as METRICA,
case when sucursal=39 then 'R.COM' else 'PRESENCIAL' end as SUBMETRICA,
case when MARCA_TIPO_TR='CHEK' then	'05'
when MARCA_TIPO_TR='CREDITO' then	'03'
when MARCA_TIPO_TR='DEBITO' then	'02'
when MARCA_TIPO_TR='DEBITO RIPLEY' then	'04'
when MARCA_TIPO_TR='EFECTIVO' then	'06'
when MARCA_TIPO_TR='OTROS' then	'07'
when MARCA_TIPO_TR='TR' then	'01' end as correlativo,
MARCA_TIPO_TR as variable,

mdy(mod(int((&periodo.*100+01)/100),100),mod((&periodo.*100+01),100),int((&periodo.*100+01)/10000)) format=date9. as fecha_tableau,
&periodo. ,
fecha as dia,
sum(mto) as monto

from compras4
where BLANDO_DURO='BLANDO'
group by calculated correlativo,
calculated SUBMETRICA,
variable,
fecha

union 
select 
'BLANDO' as METRICA,
'TOTAL' as SUBMETRICA,
case when MARCA_TIPO_TR='CHEK' then	'05'
when MARCA_TIPO_TR='CREDITO' then	'03'
when MARCA_TIPO_TR='DEBITO' then	'02'
when MARCA_TIPO_TR='DEBITO RIPLEY' then	'04'
when MARCA_TIPO_TR='EFECTIVO' then	'06'
when MARCA_TIPO_TR='OTROS' then	'07'
when MARCA_TIPO_TR='TR' then	'01' end as correlativo,
MARCA_TIPO_TR as variable,

mdy(mod(int((&periodo.*100+01)/100),100),mod((&periodo.*100+01),100),int((&periodo.*100+01)/10000)) format=date9. as fecha_tableau,
&periodo. ,
fecha as dia,
sum(mto) as monto

from compras4
where BLANDO_DURO='BLANDO'
group by calculated correlativo,
variable,
fecha


union 

select 
'DURO' as METRICA,
case when sucursal=39 then 'R.COM' else 'PRESENCIAL' end as SUBMETRICA,
case when MARCA_TIPO_TR='CHEK' then	'05'
when MARCA_TIPO_TR='CREDITO' then	'03'
when MARCA_TIPO_TR='DEBITO' then	'02'
when MARCA_TIPO_TR='DEBITO RIPLEY' then	'04'
when MARCA_TIPO_TR='EFECTIVO' then	'06'
when MARCA_TIPO_TR='OTROS' then	'07'
when MARCA_TIPO_TR='TR' then	'01' end as correlativo,
MARCA_TIPO_TR as variable,

mdy(mod(int((&periodo.*100+01)/100),100),mod((&periodo.*100+01),100),int((&periodo.*100+01)/10000)) format=date9. as fecha_tableau,
&periodo. ,
fecha as dia,
sum(mto) as monto

from compras4
where BLANDO_DURO='DURO'
group by calculated correlativo,
calculated SUBMETRICA,
variable,
fecha

union 
select 
'DURO' as METRICA,
'TOTAL' as SUBMETRICA,
case when MARCA_TIPO_TR='CHEK' then	'05'
when MARCA_TIPO_TR='CREDITO' then	'03'
when MARCA_TIPO_TR='DEBITO' then	'02'
when MARCA_TIPO_TR='DEBITO RIPLEY' then	'04'
when MARCA_TIPO_TR='EFECTIVO' then	'06'
when MARCA_TIPO_TR='OTROS' then	'07'
when MARCA_TIPO_TR='TR' then	'01' end as correlativo,
MARCA_TIPO_TR as variable,

mdy(mod(int((&periodo.*100+01)/100),100),mod((&periodo.*100+01),100),int((&periodo.*100+01)/10000)) format=date9. as fecha_tableau,
&periodo. ,
fecha as dia,
sum(mto) as monto

from compras4
where BLANDO_DURO='DURO'
group by calculated correlativo,
variable,
fecha


union 

select 
'TOTAL' as METRICA,
case when sucursal=39 then 'R.COM' else 'PRESENCIAL' end as SUBMETRICA,
case when MARCA_TIPO_TR='CHEK' then	'05'
when MARCA_TIPO_TR='CREDITO' then	'03'
when MARCA_TIPO_TR='DEBITO' then	'02'
when MARCA_TIPO_TR='DEBITO RIPLEY' then	'04'
when MARCA_TIPO_TR='EFECTIVO' then	'06'
when MARCA_TIPO_TR='OTROS' then	'07'
when MARCA_TIPO_TR='TR' then	'01' end as correlativo,
MARCA_TIPO_TR as variable,

mdy(mod(int((&periodo.*100+01)/100),100),mod((&periodo.*100+01),100),int((&periodo.*100+01)/10000)) format=date9. as fecha_tableau,
&periodo. ,
fecha as dia,
sum(mto) as monto

from compras4
group by calculated correlativo,
calculated SUBMETRICA,
variable,
fecha

union 
select 
'TOTAL' as METRICA,
'TOTAL' as SUBMETRICA,
case when MARCA_TIPO_TR='CHEK' then	'05'
when MARCA_TIPO_TR='CREDITO' then	'03'
when MARCA_TIPO_TR='DEBITO' then	'02'
when MARCA_TIPO_TR='DEBITO RIPLEY' then	'04'
when MARCA_TIPO_TR='EFECTIVO' then	'06'
when MARCA_TIPO_TR='OTROS' then	'07'
when MARCA_TIPO_TR='TR' then	'01' end as correlativo,
MARCA_TIPO_TR as variable,

mdy(mod(int((&periodo.*100+01)/100),100),mod((&periodo.*100+01),100),int((&periodo.*100+01)/10000)) format=date9. as fecha_tableau,
&periodo. ,
fecha as dia,
sum(mto) as monto

from compras4
group by calculated correlativo,
variable,
fecha

;
QUIT;


	%put==================================================================================================;
	%put [08.01] apertura tipo plastico Tda Itf &periodo;
	%put==================================================================================================;

	proc sql;
		create table tda_ITF as 
			SELECT  
				case 
					when substr(pan,1,6)='549070' then 'TAM' 
					else 'TR' 
				end 
			as TIPO_PLASTICO, 
				case 
					when sucursal=39 then 'DIGITAL' 
					else 'PRESENCIAL' 
				end 
			as TIPO, 
				sum(capital) as monto, 
				count
			(case 
				when capital>0 then rut 
			end )
			-count
		(case 
			when capital<0 then rut 
		end)
	as trx 
		FROM publicin.TDA_ITF_&periodo. 
			GROUP BY  
				calculated tipo_plastico, 
				calculated tipo 
		;
	QUIT;

	%put==================================================================================================;
	%put [09.01] Existencia de tablas finales en sas &periodo;
	%put==================================================================================================;

	%if (%sysfunc(exist(&libreria..apertura_tda_MDP))) %then
		%do;
		%end;
	%else
		%do;

			PROC  SQL;
				CREATE TABLE &libreria..apertura_tda_MDP 
					(
					Periodo num,
					TIPO_PLASTICO char(99),
					TIPO char(99),
					monto num,
					trx num)
				;
			quit;

		%end;

	%if (%sysfunc(exist(&libreria..evolutivo_forma_pago_new))) %then
		%do;
		%end;
	%else
		%do;

			PROC  SQL;
				CREATE TABLE &libreria..evolutivo_forma_pago_new 
					(
					METRICA	char(99),
					SUBMETRICA char(99),
					correlativo	char(99),
					VARIABLE	char(99),
					fecha_tableau date,
					periodo num,
					dia	date,
					monto num)
				;
			quit;

		%end;

	%put==================================================================================================;
	%put [09.02] GUARDADO EN DURO MDP en sas &periodo;
	%put==================================================================================================;

	proc sql;
		delete *
			from &libreria..evolutivo_forma_pago_new 
				where periodo=&periodo.
		;
	QUIT;

	proc sql;
		insert into  &libreria..evolutivo_forma_pago_new 
			select *
				from venta_bol
		;
	QUIT;

	proc sql;
		create table &libreria..evolutivo_forma_pago_new  as
			select 
				*
			from &libreria..evolutivo_forma_pago_new 
		;
	QUIT;

	%put==================================================================================================;
	%put [09.03] GUARDADO EN DUROTDA_ITF en sas &periodo;
	%put==================================================================================================;

	proc sql;
		delete *
			from &libreria..apertura_tda_MDP 
				where periodo=&periodo.
		;
	QUIT;

	proc sql;
		insert into  &libreria..apertura_tda_MDP 
			select &periodo. as periodo, *
				from tda_ITF
		;
	QUIT;

	proc sql;
		create table &libreria..apertura_tda_MDP  as
			select 
				*
			from &libreria..apertura_tda_MDP 
		;
	QUIT;

	%put==================================================================================================;
	%put [09.04] BORRADO de tablas  &periodo;
	%put==================================================================================================;

proc datasets library=WORK kill noprint;
run;
quit;



%mend MDP_NEW;

%macro evaluar;

	proc sql noprint;
		select distinct day(today()) as dia
			into:dia
		from &libreria..apertura_tda_MDP
		;
	QUIT;
	%let dia=&dia;
	%put &dia;

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";

/*RAW ORACLOUD*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";


	%if %eval(&dia.<=5) %then
		%do;
			%MDP_NEW(1,&libreria.);

			%MDP_NEW(0,&libreria.);
			%DELETE_BULK(tnda_evol_mdp_new,raw,oracloud,0);
			%EXPORTACION(tnda_evol_mdp_new,&libreria..evolutivo_forma_pago_new,raw,oracloud,0);
			%DELETE_BULK(tnda_apertura_tda_mdp,raw,oracloud,0);
			%EXPORTACION(tnda_apertura_tda_mdp,&libreria..apertura_tda_MDP,raw,oracloud,0);


		%end;
	%else
		%do;
			%MDP_NEW(0,&libreria.);
			%DELETE_BULK(tnda_evol_mdp_new,raw,oracloud,0);
			%EXPORTACION(tnda_evol_mdp_new,&libreria..evolutivo_forma_pago_new,raw,oracloud,0);
			%DELETE_BULK(tnda_apertura_tda_mdp,raw,oracloud,0);
			%EXPORTACION(tnda_apertura_tda_mdp,&libreria..apertura_tda_MDP,raw,oracloud,0);

		%end;
%mend evaluar;

%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

%evaluar;


data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;

/*salida del proceso indicando el tiempo total */
/*	Fecha ejecución del proceso	*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN);
RUN;

%put &fechaeDVN;

/*fecha ejecucion proceso 


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
	SELECT EMAIL into :DEST_4
		FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'LIVIA_HERNANDEZ';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;

data _null_;
	FILENAME OUTBOX EMAIL
		FROM = ("&EDP_BI")
		TO = ("&DEST_4","eb_vfriasc@bancoripley.com","jsantamaria@bancoripley.com",
"adiazse@bancoripley.com")
		CC = ("&DEST_1", "&DEST_2","&DEST_3")
		SUBJECT = ("MAIL_AUTOM: Proceso FORMAS DE PAGO TDA");
	FILE OUTBOX;
	PUT "Estimados:";
	put "  Proceso Proceso FORMAS DE PAGO TDA, ejecutado con fecha: &fechaeDVN";
	put;
	put;
	PUT;
	PUT;
	PUT;
	PUT;
	PUT;
	put 'Proceso Vers. 11';
	PUT;
	PUT;
	PUT 'Atte.';
	Put 'Equipo Datos y Procesos BI';
	PUT;
	PUT;
	PUT;
RUN;

FILENAME OUTBOX CLEAR;
