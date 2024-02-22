/*proc printto log='/sasdata/users94/ougarte/logs/log_Maestra_Clientes.txt';
*/
options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de PROC SQL noprint */

PROC SQL noprint  outobs=1 noprint;   

select SB_Ahora('DD/MM/AAAA_HH:MM') as Fecha_Proceso
into :Fecha_Proceso
from sbarrera.SB_Status_Tablas_IN

;QUIT;


PROC SQL noprint ;   
 
select put(max(anomes), best6.) as Max_anomes_Contratos
into :Max_SEGMENTOS_RPTOS
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'PUBLICIN.SEGMENTOS_RPTOS_%' 
and length(Nombre_Tabla)=length('PUBLICIN.SEGMENTOS_RPTOS_AAAAMM') 
) as x
 
;QUIT;

PROC SQL noprint ;   
 
select put(max(anomes), best6.) as Max_anomes_Contratos
into :Max_ACT_TR
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'PUBLICIN.ACT_TR_%' 
and length(Nombre_Tabla)=length('PUBLICIN.ACT_TR_AAAAMM') 
) as x
 
;QUIT;

PROC SQL noprint ;   
 
select put(max(anomes), best6.) as Max_anomes_Contratos
into :Max_DEMO_BASKET
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'PUBLICIN.DEMO_BASKET_%' 
and length(Nombre_Tabla)=length('PUBLICIN.DEMO_BASKET_AAAAMM') 
) as x
 
;QUIT;

PROC SQL noprint ;   
 
select put(max(anomes), best6.) as Max_anomes_Contratos
into :Max_SUC_PREF
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'PUBLICIN.SUC_PREF_%' 
and length(Nombre_Tabla)=length('PUBLICIN.SUC_PREF_AAAAMM') 
) as x
 
;QUIT;
/*
data _null_;
Max_SEGMENTOS_RPTOS = compress(input(&Max_SEGMENTOS_RPTOS,$6.));
&Max_ACT_TR
&Max_DEMO_BASKET
&Max_SUC_PREF.
Call symput("Max_SEGMENTOS_RPTOS",Max_SEGMENTOS_RPTOS);
run;
*/
PROC SQL noprint ; 

CREATE TABLE RESULT.MAESTRA_CLIENTES as 
select "&Fecha_Proceso." as Fecha_Proceso, 
A.RUT, CASE WHEN A.SEGMENTO='R_GOLD' THEN 'GOLD'
       WHEN A.SEGMENTO='R_SILVER' THEN 'SILVER'
       WHEN A.SEGMENTO='RIPLEY_BAJA' THEN 'GAMA_BAJA'
       ELSE 'BRONCE' END AS SEGMENTO, 
     C.EMAIL, 
     CASE WHEN C.RUT IS NOT MISSING THEN 1 ELSE 0 END AS T_EMAIL,
  D.TELEFONO,
    CASE WHEN D.CLIRUT IS NOT MISSING THEN 1 ELSE 0 END AS T_TELEFONO,
     E.PRIMER_NOMBRE as NOMBRE, 
  CASE WHEN E.RUT IS NOT MISSING THEN 1 ELSE 0 END AS T_NOMBRE,
  E.PATERNO as A_PATERNO,
  E.MATERNO as A_MATERNO, 
     G.ACTIVIDAD_TR,
     CASE WHEN G.MARCA_BASE IN ("ITF","CREDITO_2000") THEN "TR" ELSE "TAM" END AS TIPO_TARJETA,
     CASE WHEN H.RUT IS NOT MISSING THEN 1 ELSE 0 END AS LNEGRO_CAR,
     CASE WHEN I.RUT IS NOT MISSING THEN 1 ELSE 0 END AS LNEGRO_SMS,
     CASE WHEN N.RUT IS NOT MISSING THEN 1 ELSE 0 END AS INHIBIDOS,
  case when L.RUT is not MISSING then 1 else 0 end as MORA_CAR ,
  case when M.RUT is not MISSING then 1 else 0 end as MORA_SINACOFI ,
     J.REGION,
  J.COMUNA,
     K.TIPO_ACTIVIDAD,
  K.SEXO,
  K.EDAD,
  K.GSE,
  O.SUC as SUCURSAL_PREF 
 FROM PUBLICIN.SEGMENTOS_RPTOS_&Max_SEGMENTOS_RPTOS.  A
 LEFT JOIN PUBLICIN.BASE_TRABAJO_EMAIL   C ON A.RUT=C.RUT
 LEFT JOIN PUBLICIN.FONOS_MOVIL_FINAL  D ON A.RUT=D.CLIRUT  
 LEFT JOIN PUBLICIN.BASE_NOMBRES    E ON A.RUT=E.RUT
 LEFT JOIN PUBLICIN.ACT_TR_&Max_ACT_TR. G ON A.RUT=G.RUT
 LEFT JOIN PUBLICIN.LNEGRO_CAR    H ON A.RUT=H.RUT
 LEFT JOIN PUBLICIN.LNEGRO_SMS    I ON A.RUT=I.RUT
 LEFT JOIN PUBLICIN.DIRECCIONES    J ON A.RUT=J.RUT
 LEFT JOIN PUBLICIN.DEMO_BASKET_&Max_DEMO_BASKET. K ON A.RUT=K.RUT
 left join PUBLICIN.MORA_CAR     L on A.RUT=L.RUT
 left join PUBLICIN.MORA_SINACOFI   M on A.RUT=M.RUT
 left join CNAVAR.INHIBIDOS    N on A.RUT=N.RUT
 left join PUBLICIN.SUC_PREF_&Max_SUC_PREF. O on A.RUT=O.RUT 
;

quit; 


