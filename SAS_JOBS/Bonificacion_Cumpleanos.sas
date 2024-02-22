/*#######################################################################################*/
/*Bonificacion de Cumpleaños Mensual (equipo Ripley Puntos)*/
/*#######################################################################################*/

/******************************* Validacion Proceso **************************************/

/********************************* Comenzar Proceso **************************************/
%macro principal();
 
%LET NOMBRE_PROCESO = 'Bonifica_Cumpleaños';

	
DATA _null_;

datex = input(put(intnx('month',today(),-1,'end'),yymmn6.),$10.);      /*cambiar 0 a -1 para ver cierre mes anterior*/


Call symput("Fecha", datex);

RUN;

%put &Fecha;

/*Definir Parametros*/
/*:::::::::::::::::::::::*/
/*%let Fecha=201903; */ /*fecha del cumpleaños*/
%let Base_Entregable=%nrstr('result.Bonificacion_Cumple'); /*base entregable (que va a excel)*/
/*:::::::::::::::::::::::*/
options cmplib=sbarrera.funcs;
PROC SQL noprint;   

select compress(put(max(anomes), best.)) as Max_anomes_DemoB
into :Max_anomes_DemoB
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
and length(Nombre_Tabla)=length('PUBLICIN.DEMO_BASKET_201807')
) as x

;QUIT;


proc sql; 

CREATE TABLE WORK.Bonificacion_Cumple1 AS  
SELECT  
a.RUT, 
a.SEGMENTO, 
a.COMUNICADO, 
b.FECH_NAC as Fecha_Nacimiento  
FROM publicin.SEGMENTO_COMERCIAL as a  
left join publicin.DEMO_BASKET_&Max_anomes_DemoB. as b  
on (a.rut=b.rut) 
where a.COMUNICADO=1 
and month(b.FECH_NAC)=(&Fecha.-100*floor(&Fecha./100))

;quit; 




proc sql; 

CREATE TABLE WORK.Bonificacion_Cumple2 AS 
SELECT 
a.rut,
a.fecha as Fecha_Compra,
a.capital as Monto, 
b.SEGMENTO,
b.COMUNICADO,
b.Fecha_Nacimiento 
FROM PUBLICIN.TDA_ITF_&Fecha. as a 
inner join WORK.Bonificacion_Cumple1 as b 
on (a.rut=b.rut)
where a.capital is not null 
order by 
a.RUT,
a.fecha,
a.capital

;quit; 


/*Obtener Fecha del proceso*/
options cmplib=sbarrera.funcs;
PROC SQL outobs=1 noprint;   

select SB_Ahora('DD/MM/AAAA_HH:MM') as Fecha_Proceso
into :Fecha_Proceso
from sbarrera.SB_Status_Tablas_IN

;QUIT;




proc sql; 

create table result.Bonificacion_Cumple as 
select 
"&Fecha_Proceso." as Fecha_Proceso, 
* 
from work.Bonificacion_Cumple2  
order by 
RUT asc, 
Fecha_Compra asc, 
Monto desc 

;quit; 





/*
Limpieza de notas de credito en excel con macro:

El siguiente paso es pasar a excel en entregable en el punto anterior y pegar 
en archivo excel con macro (pegar donde corresponda) para ejecutar macro
que limpia valores de capital negativo (devoluciones) con su respectivo valor 
positivo.
La salida de esa macro es el entregable final-final
*/


proc sql; 

create table result.Bonificacion_Cumple_AGG as 
select 
"&Fecha_Proceso." as Fecha_Proceso, 
rut,
max(SEGMENTO) as SEGMENTO,
sum(case when Monto>0 then 1 else 0 end)-sum(case when Monto<0 then 1 else 0 end) as Nro_TRXs,
sum(Monto) as Mto_TRXs 
from work.Bonificacion_Cumple2  
group by 
RUT 
having sum(Monto)>0 

;quit; 



/*Eliminar tabla de paso*/

PROC SQL noprint;

drop table WORK.Bonificacion_Cumple1

;quit;



proc sql noprint;

drop table WORK.Bonificacion_Cumple2 

;quit;

%if &syserr. > 0 %then %do;
 %goto exit;
	%end;


%exit:
%put &syserr;
%put &FECHA_DETALLE; 
%let error = &syserr;
%put &error;

data _null_;
FECHA_PROCESO=cat((put(intnx('month',TODAY(),0,'same'),yymmdd10.)) ,"  " , (put(intnx('month',timepart(TIME()),0,'same'),hhmm8.2)) );
call symput("FECHA_DETALLE",FECHA_PROCESO);
run;


proc sql ;
select infoerr 
into : infoerr 
from result.TBL_DESC_ERRORES
where error=&error;
quit;

%let FEC_DET = "&FECHA_DETALLE";
%LET DESC = "&infoerr";  


	  proc sql ;
	  INSERT INTO result.tbl_estado_proceso
	  VALUES ( &error, &DESC, &FEC_DET , &NOMBRE_PROCESO );
	  quit;
   %put inserta el valor syserr &syserr y error &error;


%mend;

%principal();
