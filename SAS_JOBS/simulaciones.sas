/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	simulaciones					 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-07-01 -- V03 -- David V.	-- Actualización password nuevo backend pwa + correo area digital bi
/* 2022-02-21 -- V02 -- Sergio J.	-- Modificación de librerías y correos
/* 2022-02-21 -- V01 -- Pedro M.	-- Versión Original
*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio = %sysfunc(datetime()); /* inicio del proceso de conteo*/

options validvarname=any;

%macro ejecutar(cierre);

%if %eval(&cierre.=0) %then %do;
DATA _null_;
periodo_actual = put(intnx('month',today(),0,'end'),yymmn6.);
periodo_siguiente = input(put(intnx('month',today(),1,'end'),yymmn6.),$10.);
primer_dia= put(intnx('month',today(),0,'begin'),yymmdd10.);
ultimo_dia= put(intnx('month',today(),0,'end'),yymmdd10.);

Call symput("periodo_actual", periodo_actual);
Call symput("periodo_siguiente", periodo_siguiente);
Call symput("primer_dia", primer_dia);
Call symput("ultimo_dia", ultimo_dia);
RUN;

%put &periodo_actual;
%put &periodo_siguiente;
%put &primer_dia;
%put &ultimo_dia;
%end;

%else %do;
DATA _null_;
periodo_actual = put(intnx('month',today(),0-1,'end'),yymmn6.);
periodo_siguiente = input(put(intnx('month',today(),1-1,'end'),yymmn6.),$10.);
primer_dia= put(intnx('month',today(),0-1,'begin'),yymmdd10.);
ultimo_dia= put(intnx('month',today(),0-1,'end'),yymmdd10.);

Call symput("periodo_actual", periodo_actual);
Call symput("periodo_siguiente", periodo_siguiente);
Call symput("primer_dia", primer_dia);
Call symput("ultimo_dia", ultimo_dia);
RUN;

%put &periodo_actual;
%put &periodo_siguiente;
%put &primer_dia;
%put &ultimo_dia;


%end;


/*oferta sav*/

%if (%sysfunc(exist(jaburtom.sav_fin_&periodo_siguiente.))) %then %do;

proc sql;
create table oferta_sav as 
select 
rut_real as rut
from jaburtom.sav_fin_&periodo_actual.
union 
select 
rut_real as rut
from jaburtom.sav_fin_&periodo_siguiente.
where rut_real not in (select rut_real from jaburtom.sav_fin_&periodo_actual.)
;QUIT;
 %end;
%else %do;
proc sql;
create table oferta_sav as 
select 
rut_real as rut
from jaburtom.sav_fin_&periodo_actual.
;QUIT;
%end;


proc sql;
connect to ODBC as myconn (user="ripley-bi" password="biripley00"
DATASRC="BR-BACKENDHB"
);
create table SIMULATIONAVSAVPWA as 
select 
Rut,
FechaSimulación,
Producto,
MontoSimulado,
Cuotas,
InteresMensual

from connection to myconn
(SELECT  *
from SIMULATIONAVSAVVIEW
where FechaSimulación BETWEEN %str(%')&primer_dia.%str(%') AND %str(%')&ultimo_dia.%str(%')
);

disconnect from myconn;
quit;

proc sql;
connect to ODBC as myconn (user="ripley-bi" password="biripley00" DATASRC="BR-BACKENDHB");
create table SIMULACION_CONSUMO_PWA as 
select * 
from connection to myconn
(SELECT
Rut,
Producto,
MontoLiquido,
FechaSimulacion,
Cuotas,
InteresMensual
FROM SimulationPersonalLoanView
where FechaSimulacion BETWEEN %str(%')&primer_dia.%str(%') AND %str(%')&ultimo_dia.%str(%') 
);
disconnect from myconn
;QUIT;


proc sql;
create table base_simulacion as 
select 
input(substr(rut,1,length(rut)-1),best.) as rut,
substr(rut,length(rut)-1,1) as dv,
producto,
MontoSimulado,
Cuotas,
 InteresMensual,
datepart(FechaSimulación) format=date9. as fecha_simulacion,
timepart(FechaSimulación) format=time. as hora_simulacion
from SIMULATIONAVSAVPWA
outer union corr 
select 
input(substr(rut,1,length(rut)-1),best.) as rut,
substr(rut,length(rut)-1,1) as dv,
producto,
MontoLiquido as MontoSimulado,
Cuotas,
input(InteresMensual,best.) as InteresMensual,
datepart(FechaSimulacion) format=date9. as fecha_simulacion,
timepart(FechaSimulacion) format=time. as hora_simulacion
from SIMULACION_CONSUMO_PWA
;QUIT;

proc sql;
create table base_simulacion2 as 
select a.*,
case when b.rut is not null then 1 else 0 end as oferta_sav
from base_simulacion as a 
left join oferta_sav as b
on(a.rut=b.rut)
;QUIT;

%if %eval(&cierre.=0) %then %do;
proc sql noprint;
select distinct today() format=yymmddn8. as dia
into:dia
from pmunoz.codigos_capta_cdp
;QUIT;

%let dia=&dia;
%put &dia;




PROC EXPORT DATA=base_simulacion2

OUTFILE= "/sasdata/users94/user_bi/simulaciones_ppff_&dia..txt"
dbms=dlm replace;
delimiter=';';
;RUN;


Filename myEmail EMAIL	
    Subject = "Simulaciones ppff &dia."
    From    = ("equipo_datos_procesos_bi@bancoripley.com") 
    To      = ("rmontecinos@rmpconsultoria.cl","ediazl@bancoripley.com")
    CC      = ("pmunozc@bancoripley.com","dvasquez@bancoripley.com","sjaram@bancoripley.com")
	attach =("/sasdata/users94/user_bi/simulaciones_ppff_&dia..txt")
    Type    = 'Text/Plain';

Data _null_; File myEmail; 
PUT "Estimados,";
PUT "Se adjuntan simulaciones hasta el &dia.";
PUT;
PUT;
put 'Proceso Vers. 03';
PUT;
PUT;
PUT 'Atte.';
PUT 'Equipo Arquitectura de Datos y Automatización BI';
;RUN;

%end;
%else %do;

proc sql noprint;
select distinct today()-1 format=yymmddn8. as dia
into:dia
from pmunoz.codigos_capta_cdp
;QUIT;

%let dia=&dia;
%put &dia;




PROC EXPORT DATA=base_simulacion2

OUTFILE= "/sasdata/users94/user_bi/simulaciones_ppff_&dia..txt"
dbms=dlm replace;
delimiter=';';
;RUN;


Filename myEmail EMAIL	
    Subject = "Simulaciones ppff cierre &dia."
    From    = ("equipo_datos_procesos_bi@bancoripley.com") 
    To      = ("rmontecinos@rmpconsultoria.cl","ediazl@bancoripley.com")
    CC      = ("pmunozc@bancoripley.com","dvasquez@bancoripley.com","sjaram@bancoripley.com")
	attach =("/sasdata/users94/user_bi/simulaciones_ppff_&dia..txt")
    Type    = 'Text/Plain';

Data _null_; File myEmail; 
PUT "Estimados,";
PUT "Se adjuntan simulaciones hasta el &dia.";
PUT;
PUT;
put 'Proceso Vers. 03';
PUT;
PUT;
PUT 'Atte.';
PUT 'Equipo Arquitectura de Datos y Automatización BI';
;RUN;

%end;

filename myfile "/sasdata/users94/user_bi/simulaciones_ppff_&dia..txt" ;
data _null_;

rc=fdelete("myfile");

;run;
filename myfile clear;


%mend ejecutar;


proc sql noprint inobs=1; 
select 
case when mdy(month(today()), 1, year(today()))=today() then 1 else 0 end  as PRIMER_DIA_MES
into
:PRIMER_DIA_MES
from pmunoz.codigos_capta_cdp
;QUIT;

%let PRIMER_DIA_MES=&PRIMER_DIA_MES;
%put &PRIMER_DIA_MES;

%ejecutar(&PRIMER_DIA_MES.);


/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 
