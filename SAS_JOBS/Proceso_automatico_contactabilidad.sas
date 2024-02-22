proc import datafile='/sasdata/users94/user_bi/TRASPASO_DOCS/Clientes_Fidelizacion/contactabilidad.xlsx'
   DBMS = xlsx
   replace
   out=work.base_inicial;
   getnames=yes;
run;

PROC SQL noprint;   
select max(anomes) as Max_anomes_SegR
into :Max_anomes_SegR
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

%let Max_anomes_SegR=&Max_anomes_SegR;
%put &Max_anomes_SegR;


proc sql;
create table base_final as
select t1.rut,
t2.primer_nombre as Nombre,
t2.paterno as Apellido,
t3.telefono,
t6.email,
t4.segmento,
t5.edad,
t5.sexo 
from base_inicial t1
left join publicin.base_nombres t2 on t1.rut=t2.rut
left join publicin.fonos_movil_final t3 on t1.rut=t3.clirut
left join publicin.segmento_comercial t4 on t1.rut=t4.rut
left join publicin.demo_BASKET_&Max_anomes_SegR. t5 on t1.rut=t5.rut
left join publicin.base_trabajo_email t6 on t1.rut=t6.rut
;quit;

/*	EXPORT --> Generación archivo CSV */
PROC EXPORT DATA = base_final
OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/Clientes_Fidelizacion/contactabilidad_salida.xlsx"
DBMS = xlsx REPLACE;
PUTNAMES=YES;
RUN;
