%let libreria=RESULT;



%let path_ora = '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=10.0.148.31)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=GESBICORP)))';
%let user_ora = 'gesbicl_usr';
%let pass_ora = 'gesbicl_usr';
%let conexion_ora = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.;
%put &conexion_ora.;

/*OPCION 1 FUNCIONA*/
PROC SQL NOERRORSTOP ;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );
create table GST_MAESUCURS_ORA as
select * from connection to ORACLE
(
select *
FROM
(
select * from gesbicl_adm.DG_CYBER_VENTA
) sgo
);
disconnect from ORACLE;
QUIT;

PROC SQL;
CREATE TABLE TIENDA AS
SELECT t1.VENTA,
t1.TIPO,
t1.FECHA_15MIN,
t1.FORMA_PAGO,
t1.CANAL,
t1.RUT
FROM WORK.GST_MAESUCURS_ORA t1
WHERE t1.ESTADO_VENTA = 'CONFIRMADO' AND
t1.FECHA_15MIN >= '2022-05-30 00:00'
;
QUIT;


proc sql;
create table resumen  as 
select 
input(compress(substr(FECHA_15MIN,1,10),'-'),best.) as fecha,
input(substr(FECHA_15MIN,12,2),best.) as hora,

sum(case when FORMA_PAGO='Tarjeta Ripley' then venta end)/
sum(venta) as metrica,
sum(case when FORMA_PAGO='Tarjeta Ripley' then venta end) as venta_ripley,
sum(venta) as venta_total
from TIENDA
group by 
calculated fecha,
calculated hora
;QUIT;


proc sql;
create table &libreria..USO_CYBER_TDA_202205 as 
select 
case when 20220530 then 1 
when 20220531 then 2 
when 20220601 then 3  end as llave_benjita,
dhms(mdy(mod(int(fecha/100),100),mod(fecha,100),int(fecha/10000)), hora, 0, 0) format=datetime. as fecha_tableau,
datepart(calculated fecha_tableau ) format=date9. as fecha,
hour(calculated fecha_tableau ) as hora,
metrica,
venta_ripley,
venta_total
from resumen
;QUIT;



LIBNAME ORACLOUD ORACLE sql_functions=all  READBUFF=1000  INSERTBUFF=1000  PATH="REPORTSAS.WORLD"  SCHEMA=SAS_ADM authdomain=DBOracleCloud_Auth;

%if (%sysfunc(exist(oracloud.USO_CYBER_TDA_202205 ))) %then %do;
 
%end;
%else %do;
proc sql;
connect using oracloud;
create table  oracloud.USO_CYBER_TDA_202205 (
llave_benjita num,
fecha_tableau date,
fecha date,
hora num,
metrica num ,
venta_ripley num,
venta_total num
);
disconnect from oracloud;run;
%end;



proc sql;
connect using oracloud;
execute by oracloud ( delete  from     USO_CYBER_TDA_202205    );
disconnect from oracloud;
;quit;


proc sql; 
connect using oracloud;
insert into   oracloud.USO_CYBER_TDA_202205 (
llave_benjita,
fecha_tableau ,
fecha ,
hora,
metrica ,
venta_ripley ,
venta_total )

select 
llave_benjita*1 ,
fecha_tableau ,
fecha ,
hora*1 ,
metrica ,
venta_ripley ,
venta_total
from &libreria..USO_CYBER_TDA_202205
 ; 
disconnect from oracloud;run;

/*borrar todas las tablas del work, tener cuidado con tablas internas si no borrara toda la libreria*/
proc datasets library=WORK kill noprint;
run;
quit;
