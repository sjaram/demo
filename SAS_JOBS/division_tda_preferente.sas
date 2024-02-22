/*#####################################################################################*/
/*Indicador de Division Preferente*/
/*#####################################################################################*/

/*********************************** Comenzar Proceso **********************************/
%macro division_preferente(n);

%let n=1;

/*PARAMETROS::*/
%let Parametros_RFM=%nrstr('R:0.50|F:0.35|M:0.15'); /*Parametros para ponderacion RFM*/
%let Base_Entregable=%nrstr('publicin.DIVISION_PREFERENTE'); /*Base entregable con mayuscilas*/
/*:::::::::::::::::::::::*/

options cmplib=sbarrera.funcs;

%put==========================================================================================;
%put [00] Definir Perido a Utilizar;
%put==========================================================================================;

DATA _null_;
periodo = input(put(intnx('month',today(),-&n.,'same'),yymmn6. ),$10.);
Call symput("periodo", periodo);
RUN;

%put &periodo;/*fecha fin actual ok trx-pagos tda 01MAY2019*/

%put==========================================================================================;
%put [01] Extraer Base de ventas tienda para ventana de tiempo;
%put==========================================================================================;

proc sql;
create table base_retail
(periodo num,
rut num,
COD_DEPTO char(4),
monto num,
SI_TAR num)
;QUIT;

%macro extraer_data_retaiL(n);

%do i=&n. %to &n.+12;

DATA _null_;
periodo_paso = input(put(intnx('month',today(),-&i.,'same'),yymmn6. ),$10.);
Call symput("periodo_paso", periodo_paso);
RUN;

%put &periodo_paso;/*fecha fin actual ok trx-pagos tda 01MAY2019*/


proc sql;
insert into base_retail
select 
&periodo_paso. as periodo,
RUT_CPD as rut,
COD_DEPTO,
mto as monto,
case when MARCA_TIPO_TR='TR' then 1 else 0 end as SI_TAR

from result.uso_tr_marca_&periodo_paso.
where RUT_CPD>1000000
and  RUT_CPD<50000000
and  RUT_CPD not in (22222222,55555555,11111111,22000000,88888888,99999999,22212000,33333333,44444444,66666666,77777777,1111111,2222222) 
and mto>1
;QUIT;

%end;  

%mend extraer_data_retaiL;

%extraer_data_retaiL(&n.);

%put==========================================================================================;
%put [02] Asignar clasificacion de Division segun Dpto;
%put==========================================================================================;

%put---------------------------------------------------------------------------------------;
%put [02.1] Crear Tabla de asignacion de de Division;
%put---------------------------------------------------------------------------------------;

proc import datafile = '/sasdata/users94/user_bi/TRASPASO_DOCS/DEPTO_DIV_RETAIL.csv'
out = DEPTO_DIV_RETAIL
dbms = dlm
replace;
delimiter =';';
run;

%put---------------------------------------------------------------------------------------;
%put [02.2] Pegar Division;
%put---------------------------------------------------------------------------------------;

proc sql;
create table work.Vta_TDA as
SELECT 
a.*,
coalesce(b.Division,'Otros') as Division 
from work.base_retail as a 
left join work.DEPTO_DIV_RETAIL as b 
on (a.COD_DEPTO=b.cod_depto)
;quit;

%put==========================================================================================;
%put [03] Agrupar a Nivel de rut-Categoria trayendo variables relevantes;
%put==========================================================================================;

proc sql;
create table work.Vta_TDA2 as 
select * 
from (
select 
Division as Categoria,
rut,
count(distinct Periodo) as F,
12*floor(&periodo./100)+(&periodo.-100*floor(&periodo./100))-
12*floor(max(Periodo)/100)+(max(Periodo)-100*floor(max(Periodo)/100))as R,
sum(Monto)/(count(distinct Periodo)+0.001) as M 
from work.Vta_TDA 
group by 
Division,
rut 

outer union corr 

select 
case when SI_TAR=1 then 'TAR' else 'OMP' end as Categoria,
rut,
count(distinct Periodo) as F,
12*floor(&periodo./100)+(&periodo.-100*floor(&periodo./100))-
12*floor(max(Periodo)/100)+(max(Periodo)-100*floor(max(Periodo)/100)) as R,
sum(Monto)/(count(distinct Periodo)+0.001) as M 
from work.Vta_TDA 
group by 
calculated Categoria,
rut 

outer union corr 

select 
'TMP_TDA' as Categoria,
rut,
count(distinct Periodo) as F,
12*floor(&periodo./100)+(&periodo.-100*floor(&periodo./100))-
12*floor(max(Periodo)/100)+(max(Periodo)-100*floor(max(Periodo)/100)) as R,
sum(Monto)/(count(distinct Periodo)+0.001) as M 
from work.Vta_TDA 
group by 
rut 

) as x 
;quit;

/*Eliminar tablas de paso*/
proc sql; drop table work.Vta_TDA 
;quit;

%put===========================================================================================;
%put [04] Normalizar Variables R F M ;
%put===========================================================================================;

%put-------------------------------------------------------------------------------------------;
%put [04.1] Calcular percentiles de cada categoria Monto;
%put-------------------------------------------------------------------------------------------;

/*
proc means data=work.Vta_TDA2 StackODSOutput  Mean Min P5 P10 P25 P50 P75 P90 P95 Max; 
CLASS Categoria;
var M;
ods output summary=work.Vta_TDA2_Perc;
run;
*/

ods exclude all;
proc means data=work.Vta_TDA2 StackODSOutput P10 P90; 
CLASS Categoria;
var M;
ods output summary=work.Vta_TDA2_Perc;
run;
ods exclude none;

%put-------------------------------------------------------------------------------------------;
%put [04.2] Calcular Variables Normalizadas;
%put-------------------------------------------------------------------------------------------;

%macro calculo_INTERPOLADO(C,X1,X2,Y1,Y2,
C_1,X1_1,X2_1,Y1_1,Y2_1,
C_2,Y1_2,Y2_2);

proc sql;
create table work.Vta_TDA2 as 
select 
a.*,
case when &C=0 then 0
when &X2>&X1  and a.R>&X2 then &Y2
when &X2>&X1 and a.R<&X1 then &Y1
when &X2<&X1 and a.R>&X1 then &Y1
when &X2<&X1 and a.R<&X2 then &Y2
else &Y1+((&Y2-&Y1)/((&X2**&C)-(&X1**&C)))*((a.R**&C)-(&X1**&C)) end as R2,

case when &C_1=0 then 0
when &X2_1>&X1_1 and a.F>&X2_1 then &Y2_1
when &X2_1>&X1_1 and a.F<&X1_1 then &Y1_1
when &X2_1<&X1_1 and a.F>&X1_1 then &Y1_1
when &X2_1<&X1_1 and a.F<&X2_1 then &Y2_1
else &Y1_1+((&Y2_1-&Y1_1)/((&X2_1**&C_1)-(&X1_1**&C_1)))*((a.F**&C_1)-(&X1_1**&C_1)) end as F2,

case when &C_2=0 then 0
when b.P90>b.P10 and a.M>b.P90 then &Y2_2
when b.P90>b.P10 and a.M<b.P10 then &Y1_2
when b.P90<b.P10 and a.M>b.P10 then &Y1_2
when b.P90<b.P10 and a.M<b.P90 then &Y2_2
else &Y1_2+((&Y2_2-&Y1_2)/((b.P90**&C_2)-(b.P10**&C_2)))*((a.M**&C_2)-(b.P10**&C_2)) end as M2

from work.Vta_TDA2 as a 
left join work.Vta_TDA2_Perc as b 
on (a.Categoria=b.Categoria)
;quit;

%mend calculo_INTERPOLADO;

%calculo_INTERPOLADO(1,12,0,0,1,
1,0,12,0,1,
1,0,1);

/*Eliminar tablas de paso*/
proc sql; drop table work.Vta_TDA2_Perc 
;quit;

%put===========================================================================================;
%put [05] Calcular RFM segun peso de cada Variable ;
%put===========================================================================================;

%put-------------------------------------------------------------------------------------------;
%put [05.1] Rescatar desde Parametros valores de RFM;
%put-------------------------------------------------------------------------------------------;

PROC SQL outobs=1;
select 
input(substr(&Parametros_RFM,03,04),best.) as Peso_R,
input(substr(&Parametros_RFM,10,04),best.) as Peso_F,
input(substr(&Parametros_RFM,17,04),best.) as Peso_M 
into 
:Peso_R,
:Peso_F,
:Peso_M 
from sashelp.vmember 
;QUIT;

%put-------------------------------------------------------------------------------------------;
%put [05.2] Calcular RFM;
%put-------------------------------------------------------------------------------------------;

proc sql;
create table work.Vta_TDA2 as 
select 
*,
&Peso_R*R2+&Peso_F*F2+&Peso_M*M2 as RFM 
from work.Vta_TDA2  
;quit;

%put===========================================================================================;
%put [06] Pivotear Tabla con variables relevantes;
%put===========================================================================================;

proc sql;
create table work.Vta_TDA3 as 
select 
rut,
count(distinct case when Categoria not in ('TAR','OMP','TMP_TDA') then Categoria end) as Nro_Divisiones,
max(case when Categoria='TMP_TDA' then R end) as R_TMP_TDA,
max(case when Categoria='TMP_TDA' then F end) as F_TMP_TDA,
max(case when Categoria='TMP_TDA' then M end) as M_TMP_TDA,
max(case when Categoria='TAR' then R end) as R_TAR,
max(case when Categoria='TAR' then F end) as F_TAR,
max(case when Categoria='TAR' then M end) as M_TAR,
max(case when Categoria='OMP' then R end) as R_OMP,
max(case when Categoria='OMP' then F end) as F_OMP,
max(case when Categoria='OMP' then M end) as M_OMP,
max(case when Categoria='BELLEZA' then R end) as R_BELLEZA,
max(case when Categoria='BELLEZA' then F end) as F_BELLEZA,
max(case when Categoria='BELLEZA' then M end) as M_BELLEZA,
max(case when Categoria='CALZADO Y ACCESORIOS' then R end) as R_CALZADO_ACCESORIOS,
max(case when Categoria='CALZADO Y ACCESORIOS' then F end) as F_CALZADO_ACCESORIOS,
max(case when Categoria='CALZADO Y ACCESORIOS' then M end) as M_CALZADO_ACCESORIOS,
max(case when Categoria='DECOHOGAR' then R end) as R_DECOHOGAR,
max(case when Categoria='DECOHOGAR' then F end) as F_DECOHOGAR,
max(case when Categoria='DECOHOGAR' then M end) as M_DECOHOGAR,
max(case when Categoria='DEPORTE' then R end) as R_DEPORTE,
max(case when Categoria='DEPORTE' then F end) as F_DEPORTE,
max(case when Categoria='DEPORTE' then M end) as M_DEPORTE,
max(case when Categoria='ELECTRONICA' then R end) as R_ELECTRONICA,
max(case when Categoria='ELECTRONICA' then F end) as F_ELECTRONICA,
max(case when Categoria='ELECTRONICA' then M end) as M_ELECTRONICA,
max(case when Categoria='HOMBRE' then R end) as R_HOMBRE,
max(case when Categoria='HOMBRE' then F end) as F_HOMBRE,
max(case when Categoria='HOMBRE' then M end) as M_HOMBRE,
max(case when Categoria='INFANTIL' then R end) as R_INFANTIL,
max(case when Categoria='INFANTIL' then F end) as F_INFANTIL,
max(case when Categoria='INFANTIL' then M end) as M_INFANTIL,
max(case when Categoria='MUJER' then R end) as R_MUJER,
max(case when Categoria='MUJER' then F end) as F_MUJER,
max(case when Categoria='MUJER' then M end) as M_MUJER,
max(case when Categoria='MASCOTAS' then R end) as R_MASCOTAS,
max(case when Categoria='MASCOTAS' then F end) as F_MASCOTAS,
max(case when Categoria='MASCOTAS' then M end) as M_MASCOTAS,

max(case when Categoria='MEJORAMIENTO DEL HOG' then R end) as R_MHOGAR,
max(case when Categoria='MEJORAMIENTO DEL HOG' then F end) as F_MHOGAR,
max(case when Categoria='MEJORAMIENTO DEL HOG' then M end) as M_MHOGAR,

max(case when Categoria='TECNOLOGIA' then R end) as R_TECNOLOGIA,
max(case when Categoria='TECNOLOGIA' then F end) as F_TECNOLOGIA,
max(case when Categoria='TECNOLOGIA' then M end) as M_TECNOLOGIA,
max(case when Categoria in ('Otros','OTROS NEGOCIOS') then R end) as R_Otros,
max(case when Categoria in ('Otros','OTROS NEGOCIOS') then F end) as F_Otros,
max(case when Categoria in ('Otros','OTROS NEGOCIOS') then M end) as M_Otros,
max(case when Categoria in ('Otros','OTROS NEGOCIOS') then RFM end) as RFM_TMP_TDA,
max(case when Categoria='TAR' then RFM end) as RFM_TAR,
max(case when Categoria='OMP' then RFM end) as RFM_OMP,
max(case when Categoria='BELLEZA' then RFM end) as RFM_BELLEZA,
max(case when Categoria='CALZADO Y ACCESORIOS' then RFM end) as RFM_CALZADO_ACCESORIOS,
max(case when Categoria='DECOHOGAR' then RFM end) as RFM_DECOHOGAR,
max(case when Categoria='DEPORTE' then RFM end) as RFM_DEPORTE,
max(case when Categoria='ELECTRONICA' then RFM end) as RFM_ELECTRONICA,
max(case when Categoria='HOMBRE' then RFM end) as RFM_HOMBRE,
max(case when Categoria='INFANTIL' then RFM end) as RFM_INFANTIL,
max(case when Categoria='MUJER' then RFM end) as RFM_MUJER,
max(case when Categoria='MASCOTAS' then RFM end) as RFM_MASCOTAS,
max(case when Categoria='MEJORAMIENTO DEL HOG' then RFM end) as RFM_MHOGAR,
max(case when Categoria='TECNOLOGIA' then RFM end) as RFM_TECNOLOGIA,
max(case when Categoria in ('Otros','OTROS NEGOCIOS') then RFM end) as RFM_Otros 
from work.Vta_TDA2 
group by 
rut 
;quit;

%put===========================================================================================;
%put [07] Calcular Primeras 3 Divisiones mas fuertes y 3 Divisiones mas debiles;
%put===========================================================================================;

%put-------------------------------------------------------------------------------------------;
%put [07.1] Generar tabla de paso ordenada;
%put-------------------------------------------------------------------------------------------;

proc sql;
create table work.Top_Divisiones as 
select 
rut,
Categoria,
RFM 
from work.Vta_TDA2 
where Categoria not in ('TMP_TDA','TAR','OMP','Otros') 
order by 
rut,
RFM
;quit;

/*Eliminar tablas de paso*/
proc sql; drop table work.Vta_TDA2 
;quit;

%put-------------------------------------------------------------------------------------------;
%put [07.2] Asignar Correlativo segun dicho orden;
%put-------------------------------------------------------------------------------------------;

/*Asignar orden (base debe estar previamente ordenada)*/
data Top_Divisiones2;
  set Top_Divisiones ;
  by rut RFM;
  if first.rut then orden=1 ;
  else orden+1 ;
run;

/*Corregir correlativo (mejor con valor 1)*/
proc sql;
create table work.Top_Divisiones2 as 
select 
a.rut,
a.Categoria,
a.RFM,
a.orden as orden_peor,
b.Max_Orden-a.orden+1 as orden_mejor 
from work.Top_Divisiones2 as a 
left join (
select 
rut,
max(orden) as Max_Orden 
from work.Top_Divisiones2 
group by 
rut 
) as b 
on (a.rut=b.rut) 
order by 
a.rut desc,
a.RFM desc 
;quit;

/*Eliminar tablas de paso*/
proc sql; drop table work.Top_Divisiones
;quit;

%put-------------------------------------------------------------------------------------------;
%put [07.3] Pivotear Tabla;
%put-------------------------------------------------------------------------------------------;

proc sql;
create table work.Top_Divisiones3 as 
select 
rut,
max(case when orden_mejor=1 then Categoria end) as Division_Fuerte1,
max(case when orden_mejor=2 then Categoria end) as Division_Fuerte2,
max(case when orden_mejor=3 then Categoria end) as Division_Fuerte3,
max(case when orden_peor=1 then Categoria end) as Division_Debil1,
max(case when orden_peor=2 then Categoria end) as Division_Debil2,
max(case when orden_peor=3 then Categoria end) as Division_Debil3 
from work.Top_Divisiones2 
group by 
rut
;quit;

/*Eliminar tablas de paso*/
proc sql; drop table work.Top_Divisiones2
;quit;

%put-------------------------------------------------------------------------------------------;
%put [07.4] Pegar info en tabla global;
%put-------------------------------------------------------------------------------------------;

proc sql;
create table work.Vta_TDA3 as 
select 
a.*,
b.Division_Fuerte1,
b.Division_Fuerte2,
b.Division_Fuerte3,
b.Division_Debil1,
b.Division_Debil2,
b.Division_Debil3  
from work.Vta_TDA3 as a 
left join work.Top_Divisiones3 as b 
on (a.rut=b.rut) 
;quit; 

/*Eliminar tablas de paso*/
proc sql; drop table work.Top_Divisiones3
;quit;

%put===========================================================================================;
%put [08] Guardar resultados en tabla entregable ;
%put===========================================================================================;

DATA _NULL_;
Call execute(
cat('
proc sql; 

create table ',&Base_Entregable,'_',&Periodo,' as 
SELECT * 
from work.Vta_TDA3  

;quit;
')
);
run;

/*Eliminar tablas de paso*/
proc sql; drop table work.Vta_TDA3
;quit;

proc datasets library=WORK kill noprint;
run;
quit;

%mend division_preferente;

%division_preferente(1);
