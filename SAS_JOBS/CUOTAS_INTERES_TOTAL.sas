/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	PROC_SEGUIMIENTO_PWA 			 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-10-28 -- v05 -- David V.	-- Se actualizar export a AWS, según nuevas definiciones a RAW.
/* 2022-08-25 -- V04 -- Sergio J.   -- Se añade sentencia include para borrar y exportar a RAW
*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*==================================================================================================*/

%let libreria=RESULT;

%macro cuotas_spos(n,libreria);
DATA _null_;
periodo= input(put(intnx('month',today(),-&n.,'begin'),yymmn6. ),$10.) ;

Call symput("periodo", periodo);

RUN;



%put &periodo;



%if %eval(&periodo.<=202206) %then %do;
proc sql;
create table spos_tc as 
select 
monotonic() as ind,
codigo_comercio,
Nombre_Comercio,
Actividad_Comercio,
rut,
VENTA_TARJETA,
Tipo_Tarjeta,
codact,
TOTCUOTAS,
PORINT,
0 as MGFIN

from publicin.spos_aut_&periodo.
;QUIT;
%end;
%else %do;
proc sql;
create table spos_tc as 
select 
monotonic() as ind,
codigo_comercio,
Nombre_Comercio,
Actividad_Comercio,
rut,
VENTA_TARJETA,
Tipo_Tarjeta,
codact,
TOTCUOTAS,
PORINT,
MG_FIN as MGFIN

from publicin.spos_aut_&periodo.
;QUIT;
%end;

proc sql;
create table uso_TC as 
select distinct 
a.ind,
a.codigo_comercio,
a.Nombre_Comercio,
a.Actividad_Comercio,
a.rut,
a.VENTA_TARJETA,
a.codact,
a.Tipo_Tarjeta,
a.TOTCUOTAS,
a.PORINT,
a.mgfin,
coalesce(c.RUBRO_GESTION,'Otros Rubros SPOS') as Rubro,
CASE WHEN calculated RUBRO in ('SERVICIOS','SERVICIOS BASICOS','TRANSPORTE') THEN 'Servicios'
WHEN calculated RUBRO IN  ('OTROS COMERCIOS','Otros Rubros SPOS','BELLEZA') THEN 'Otros Comercios'
WHEN calculated RUBRO IN ('VIAJES','ENTRETENCION') THEN 'Viajes&Entretencion'
WHEN  calculated RUBRO IN ('ALIMENTACION Y FAST FOOD','RESTAURANTES') THEN 'Alimentacion'
WHEN calculated RUBRO IN ('RECAUDACION SECTOR PUBLICO','RECAUDACION','INSTITUCIONES FINANCIERAS') THEN 'Recaudacion&Inst_Finan'
ELSE calculated RUBRO END AS RUBRO2
 
from spos_TC as a 

left join ( select 
COD_ACT,
max(CATEGORIAS_RIPLEY) as RUBRO_GESTION
from sbarrera.TABLA_ARBOL /*Tabla de asignacion de rubros*/
group by 
COD_ACT) as c
on(a.CODACT=c.COD_ACT)
;QUIT;


%if %eval(&periodo.>202206) %then %do;
proc sql;
create table uso_TC2 as 
select 
'CATEGORIA TOTAL' as categoria,
&periodo as periodo,
sum(VENTA_TARJETA) as capital,
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA else 0 end ) as capital_T,
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA else 0 end  ) as capital_SIN_INT,
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA else 0 end ) as capital_con_INT,

/*plazo ponderado*/ 
sum(VENTA_TARJETA*TOTCUOTAS)/sum(VENTA_TARJETA) as plazo,
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA*TOTCUOTAS else 0 end  )/
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA else 0 end  )  as plazo_T,
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA*TOTCUOTAS else 0 end  )/
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA else 0 end  )
as plazo_P_sin_int, 
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA*TOTCUOTAS else 0 end  )/
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA else 0 end  )
as plazo_P_con_int,   


/*tasa ponderado*/ 
sum(VENTA_TARJETA*PORINT)/sum(VENTA_TARJETA) as TASA,
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA*PORINT else 0 end  )/
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA else 0 end  )  as tasa_T,
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA*PORINT else 0 end  )/
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA else 0 end  )
as tasa_P_sin_int,  
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA*PORINT else 0 end  )/
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA else 0 end  )
as tasa_P_con_int,

/*MGFIN*/
sum(MGFIN) as MGFIN,
sum(case when TOTCUOTAS>=2 then MGFIN else 0 end  ) as MGFIN_T,
sum(case when TOTCUOTAS>=2 and PORINT   in (0) then MGFIN else 0 end  ) as MGFIN_SIN_INT,
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then MGFIN else 0 end  ) as MGFIN_con_INT 

from uso_TC

outer union corr 
select
rubro2 as categoria,
&periodo as periodo,
sum(VENTA_TARJETA) as capital,
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA else 0 end ) as capital_T,
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA else 0 end  ) as capital_SIN_INT,
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA else 0 end ) as capital_con_INT,

/*plazo ponderado*/ 
sum(VENTA_TARJETA*TOTCUOTAS)/sum(VENTA_TARJETA) as plazo,
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA*TOTCUOTAS else 0 end  )/
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA else 0 end  )  as plazo_T,
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA*TOTCUOTAS else 0 end  )/
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA else 0 end  )
as plazo_P_sin_int, 
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA*TOTCUOTAS else 0 end  )/
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA else 0 end  )
as plazo_P_con_int,   


/*tasa ponderado*/ 
sum(VENTA_TARJETA*PORINT)/sum(VENTA_TARJETA) as TASA,
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA*PORINT else 0 end  )/
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA else 0 end  )  as tasa_T,
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA*PORINT else 0 end  )/
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA else 0 end  )
as tasa_P_sin_int,  
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA*PORINT else 0 end  )/
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA else 0 end  )
as tasa_P_con_int,

/*MGFIN*/
sum(MGFIN) as MGFIN,
sum(case when TOTCUOTAS>=2 then MGFIN else 0 end  ) as MGFIN_T,
sum(case when TOTCUOTAS>=2 and PORINT   in (0) then MGFIN else 0 end  ) as MGFIN_SIN_INT,
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then MGFIN else 0 end  ) as MGFIN_con_INT 
from uso_TC group by rubro2
;QUIT;
%end;
%else %do;

proc sql;
create table uso_TC2 as 
select 
'CATEGORIA TOTAL' as categoria,
&periodo as periodo,
sum(VENTA_TARJETA) as capital,
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA else 0 end ) as capital_T,
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA else 0 end  ) as capital_SIN_INT,
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA else 0 end ) as capital_con_INT,

/*plazo ponderado*/ 
sum(VENTA_TARJETA*TOTCUOTAS)/sum(VENTA_TARJETA) as plazo,
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA*TOTCUOTAS else 0 end  )/
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA else 0 end  )  as plazo_T,
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA*TOTCUOTAS else 0 end  )/
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA else 0 end  )
as plazo_P_sin_int, 
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA*TOTCUOTAS else 0 end  )/
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA else 0 end  )
as plazo_P_con_int,   


/*tasa ponderado*/ 
sum(VENTA_TARJETA*PORINT)/sum(VENTA_TARJETA) as TASA,
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA*PORINT else 0 end  )/
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA else 0 end  )  as tasa_T,
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA*PORINT else 0 end  )/
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA else 0 end  )
as tasa_P_sin_int,  
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA*PORINT else 0 end  )/
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA else 0 end  )
as tasa_P_con_int

from uso_TC
outer union corr 
select 
'CATEGORIA TOTAL' as categoria,
&periodo as periodo,
sum(MARGEN_FINANCIERO) as MGFIN,
sum(case when PLAZO>=2 then MARGEN_FINANCIERO else 0 end  ) as MGFIN_T,
sum(case when PLAZO>=2 and coalesce(INTERES,0)   in (0) then MARGEN_FINANCIERO else 0 end  ) as MGFIN_SIN_INT,
sum(case when PLAZO>=2 and coalesce(INTERES,0)  not in (0) then MARGEN_FINANCIERO else 0 end  ) as MGFIN_con_INT
from publicin.spos_&periodo.
outer union corr 

select
rubro2 as categoria,
&periodo as periodo,
sum(VENTA_TARJETA) as capital,
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA else 0 end ) as capital_T,
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA else 0 end  ) as capital_SIN_INT,
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA else 0 end ) as capital_con_INT,

/*plazo ponderado*/ 
sum(VENTA_TARJETA*TOTCUOTAS)/sum(VENTA_TARJETA) as plazo,
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA*TOTCUOTAS else 0 end  )/
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA else 0 end  )  as plazo_T,
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA*TOTCUOTAS else 0 end  )/
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA else 0 end  )
as plazo_P_sin_int, 
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA*TOTCUOTAS else 0 end  )/
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA else 0 end  )
as plazo_P_con_int,   


/*tasa ponderado*/ 
sum(VENTA_TARJETA*PORINT)/sum(VENTA_TARJETA) as TASA,
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA*PORINT else 0 end  )/
sum(case when TOTCUOTAS>=2 then VENTA_TARJETA else 0 end  )  as tasa_T,
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA*PORINT else 0 end  )/
sum(case when TOTCUOTAS>=2 and PORINT  in (0) then VENTA_TARJETA else 0 end  )
as tasa_P_sin_int,  
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA*PORINT else 0 end  )/
sum(case when TOTCUOTAS>=2 and PORINT  not in (0) then VENTA_TARJETA else 0 end  )
as tasa_P_con_int
from uso_TC group by rubro2
;QUIT;

%end;

proc sql;
create table TDA as 
select 
'CATEGORIA TOTAL' as categoria,
&periodo as periodo,
sum(capital) +sum(pie) as MONTO_TOTAL,
sum(capital ) as capital,
sum(case when cuotas>=3 then capital else 0 end ) as capital_T,
sum(case when cuotas>=3 and TASA  in (0.001,0) then capital else 0 end  ) as capital_SIN_INT,
sum(case when cuotas>=3 and TASA  not in (0.001,0) then capital else 0 end ) as capital_con_INT,

/*plazo ponderado*/ 
sum(capital*cuotas)/sum(capital) as plazo,
sum(case when cuotas>=3 then capital*cuotas else 0 end  )/
sum(case when cuotas>=3 then capital else 0 end  )  as plazo_T,
sum(case when cuotas>=3 and TASA  in (0.001,0) then capital*cuotas else 0 end  )/
sum(case when cuotas>=3 and TASA  in (0.001,0) then capital else 0 end  )
as plazo_P_sin_int, 
sum(case when cuotas>=3 and TASA  not in (0.001,0) then capital*cuotas else 0 end  )/
sum(case when cuotas>=3 and TASA  not in (0.001,0) then capital else 0 end  )
as plazo_P_con_int, 

/*tasa ponderado*/ 
sum(capital*TASA)/sum(capital) as TASA,
sum(case when cuotas>=3 then capital*TASA else 0 end  )/
sum(case when cuotas>=3 then capital else 0 end  )  as tasa_T,
sum(case when cuotas>=3 and TASA  in (0.001,0) then capital*TASA else 0 end  )/
sum(case when cuotas>=3 and TASA  in (0.001,0) then capital else 0 end  )
as tasa_P_sin_int,  
sum(case when cuotas>=3 and TASA  not in (0.001,0) then capital*TASA else 0 end  )/
sum(case when cuotas>=3 and TASA  not in (0.001,0) then capital else 0 end  )
as tasa_P_con_int, 

sum(MGFIN) as MGFIN,
sum(case when cuotas>=3 then MGFIN else 0 end  ) as MGFIN_T,
sum(case when cuotas>=3 and TASA  in (0.001,0) then MGFIN else 0 end  ) as MGFIN_SIN_INT,
sum(case when cuotas>=3 and TASA  not in (0.001,0) then MGFIN else 0 end  ) as MGFIN_con_INT 

from publicin.tda_itf_&periodo.
;QUIT;
 
proc sql;
delete * from &libreria..RESUMEN_CUOTAS_COMPRAS 
where periodo=&periodo.
;QUIT;

proc sql;
insert into &libreria..RESUMEN_CUOTAS_COMPRAS   
select 'SPOS' as tipo,*
from uso_TC2
outer union corr select 'TDA' as tipo,
*
from TDA
;QUIT;


proc datasets library=WORK kill noprint;
run;
quit;

%MEND cuotas_spos;

%cuotas_spos(	0,&libreria.	);
%cuotas_spos(	1,&libreria.	);

%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;
/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================        EXPORT_TO_AWS - INI          ===============================*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(spos_cuotas_fin_compras,raw,oracloud,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(spos_cuotas_fin_compras,&libreria..resumen_cuotas_compras,raw,oracloud,0);

/*==============================        EXPORT_TO_AWS - END          ===============================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

proc sql noprint;                              
SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4",'jsantamaria@bancoripley.com','fmunozh@bancoripley.com','mbentjerodts@bancoripley.com',
'bschmidtm@bancoripley.com','crachondode@bancoripley.com')
CC = ("&DEST_1","&DEST_2","&DEST_3")
SUBJECT="MAIL_AUTOM: PROCESO CUOTAS TDA Y SPOS " ;
FILE OUTBOX;
	PUT 'Estimados:';
	PUT ; 
 	PUT "Proceso CUOTAS TDA Y SPOS, ejecutado.";  
	PUT "Para visualizar Dashboard utilizar el siguiente link:"; 
 	PUT "https://tableau1.bancoripley.cl/#/site/BI_Lab/views/Resumendecuotastdayspos/CUOTASCOMPRA?:iid=1";
    PUT;
    PUT;
    put 'Proceso Vers. 05';
    PUT;
    PUT;
    PUT 'Atte.';
    Put 'Equipo Arquitectura de Datos y Automatización BI';
    PUT;
RUN;
FILENAME OUTBOX CLEAR;


/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 


/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
