/*#################################################################################*/
/*Validacion de Procesos: CAPTA SALIDA*/
/*#################################################################################*/

/*
proc sql;

create table work.revision_procesos as 
select * 
from sbarrera.VALIDACION_PROCESOS

;quit; 
*/



options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/

%put==========================================================================================;
%put [00] Setear Primeras Variables;
%put==========================================================================================;


%put------------------------------------------------------------------------------------------;
%put [00.1] Rescatar Fechas de Ahora ;
%put------------------------------------------------------------------------------------------;


PROC SQL outobs=1 noprint;   

select 
SB_Ahora('DD/MM/AAAA_HH:MM:SS_dia') as Fecha_Proceso,
input(SB_Ahora('AAAAMMDD'),best.) as Fecha_Ahora,
floor(SB_mover_anomesdia(input(SB_Ahora('AAAAMMDD'),best.),-1)/100) as Periodo_dia_anterior  
into 
:Fecha_Proceso,
:Fecha_Ahora, 
:Periodo_dia_anterior
from sashelp.vmember

;QUIT;
%let Fecha_Proceso="&Fecha_Proceso";


%put------------------------------------------------------------------------------------------;
%put [00.2] Definir Descripcion del Proceso ;
%put------------------------------------------------------------------------------------------;

%let Nombre_Proceso=%nrstr('TRXs de AV'); 
%let Descripcion_Proceso=%nrstr('TRXs de Avance por periodo'); 
%let Tabla_Entregable=%nrstr('PUBLICIN.TRX_AV_AAAAMM'); 


%put==========================================================================================;
%put [01] Validador 1 ;
%put==========================================================================================;

%let Criterio_Validador1=%nrstr('Maxima Fecha dentro de Ultima Tabla'); 


%put------------------------------------------------------------------------------------------;
%put [01.1] Obtener Cifra ;
%put------------------------------------------------------------------------------------------;



PROC SQL noprint;   

select max(anomes) as Max_Periodo_Tabla  
into :Max_Periodo_Tabla  
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'PUBLICIN.TRX_AV_%' 
and length(nombre_tabla)=length('PUBLICIN.TRX_AV_AAAAMM')
) as x

;QUIT;


DATA _NULL_;
Call execute(
cat('
proc sql noprint; 

select max(input(cats(substr(FECFAC,1,4),substr(FECFAC,6,2),substr(FECFAC,9,2)),best.)) as Cifra_Validador1 
into :Cifra_Validador1  
from PUBLICIN.TRX_AV_',&Max_Periodo_Tabla,'    

;quit; 
')
);
run;


%put------------------------------------------------------------------------------------------;
%put [01.2] Validar Ok de Cifra ;
%put------------------------------------------------------------------------------------------;



proc sql outobs=1 noprint;

select 
case when SB_dias_entre(&Cifra_Validador1,&Fecha_Ahora)<=1 then 1 else 0 end as Ok_Validador1  
into :Ok_Validador1 
from sashelp.vmember

;quit;



%put==========================================================================================;
%put [02] Validador 2 ;
%put==========================================================================================;

%let Criterio_Validador2=%nrstr('Suma de Mto dentro de Ultima Fecha'); 


%put------------------------------------------------------------------------------------------;
%put [02.1] Obtener Cifra ;
%put------------------------------------------------------------------------------------------;


DATA _NULL_;
Call execute(
cat('
proc sql noprint; 

select sum(capital) as Cifra_Validador2 
into :Cifra_Validador2 
from PUBLICIN.TRX_AV_',&Max_Periodo_Tabla,'    
where input(cats(substr(FECFAC,1,4),substr(FECFAC,6,2),substr(FECFAC,9,2)),best.)=',&Cifra_Validador1,' 

;quit; 
')
);
run;



%put------------------------------------------------------------------------------------------;
%put [02.2] Validar Ok de Cifra ;
%put------------------------------------------------------------------------------------------;



proc sql outobs=1 noprint;

select 
case when &Cifra_Validador2>=100 then 1 else 0 end as Ok_Validador2 
into :Ok_Validador2 
from sashelp.vmember

;quit;


%put==========================================================================================;
%put [03] Validador 3 ;
%put==========================================================================================;

%let Criterio_Validador3=%nrstr('Nro de Filas de Ultima Fecha'); 


%put------------------------------------------------------------------------------------------;
%put [03.1] Obtener Cifra ;
%put------------------------------------------------------------------------------------------;


DATA _NULL_;
Call execute(
cat('
proc sql noprint; 

select count(*) as Cifra_Validador3  
into :Cifra_Validador3 
from PUBLICIN.TRX_AV_',&Max_Periodo_Tabla,'    
where input(cats(substr(FECFAC,1,4),substr(FECFAC,6,2),substr(FECFAC,9,2)),best.)=',&Cifra_Validador1,' 

;quit; 
')
);
run;


%put------------------------------------------------------------------------------------------;
%put [03.2] Validar Ok de Cifra ;
%put------------------------------------------------------------------------------------------;


proc sql outobs=1 noprint;

select 
case when &Cifra_Validador3>0 then 1 else 0 end as Ok_Validador3 
into :Ok_Validador3  
from sashelp.vmember

;quit;



%put==========================================================================================;
%put [04] Calular Validador Final ;
%put==========================================================================================;

proc sql outobs=1 noprint;

select 
case when &Ok_Validador1=1 and &Ok_Validador2=1 and &Ok_Validador3=1 then 1 else 0 end as Ok_Validador_TOTAL
into :Ok_Validador_TOTAL  
from sashelp.vmember

;quit;



%put==========================================================================================;
%put [05] Imputar resultados en Tabla Final ;
%put==========================================================================================;



/**/
proc sql noprint;
create table VALIDACION_TRX_AV
(
Fecha char(99), 
Nombre_Proceso char(99),
Descripcion_Proceso char(99), 
Tabla_Entregable char(99), 
Criterio_Validador1 char(99), 
Cifra_Validador1 num,
Ok_Validador1 num,
Criterio_Validador2 char(99), 
Cifra_Validador2 num, 
Ok_Validador2 num, 
Criterio_Validador3 char(99),
Cifra_Validador3 num,
Ok_Validador3 num, 
Ok_Validador_TOTAL num
)
;quit;
/**/


proc sql noprint;

insert into VALIDACION_TRX_AV 
values(
&Fecha_Proceso,
&Nombre_Proceso,
&Descripcion_Proceso,
&Tabla_Entregable,
&Criterio_Validador1,
&Cifra_Validador1,
&Ok_Validador1,
&Criterio_Validador2,
&Cifra_Validador2,
&Ok_Validador2,
&Criterio_Validador3,
&Cifra_Validador3,
&Ok_Validador3,
&Ok_Validador_TOTAL 
)

;quit;


/*Fecha Inicial de la etapa*/
PROC SQL outobs=1 noprint;   
select 
infoerr as temp_error
into :temp_error
from result.tbl_estado_proceso
order by fecha desc
;QUIT;

%put &temp_error;


%macro mensaje_correo(error) ;
	   	
	FILENAME output EMAIL
	SUBJECT= "Ejecución de Proceso TRX_AV"
	FROM= "OUGARTED@BANCORIPLEY.com"
	to=("ougarted@bancoripley.com")
	/*TO= ("OUGARTED@BANCORIPLEY.com","kmartinez@ripley.com", "dvasquez@bancoripley.com", "mguzmans@bancoripley.com")*/
	CT= "text/html" /* Required for HTML output */ ;
	/*ODS HTML BODY=output STYLE=sasweb;
	TITLE JUSTIFY=left
	&temp_error;
	PROC REPORT DATA=VALIDACION_TRX_AV NOWD
	STYLE(REPORT)=[PREHTML="<hr>"] 
	RUN;
	ODS HTML CLOSE; 
	*/

	FILENAME mail EMAIL TO="erik.tilanus@planet.nl"
 	SUBJECT="HTML OUTPUT" CONTENT_TYPE="text/html";
	ODS LISTING CLOSE;
	ODS HTML  path="/sasdata/users94/user_bi" file = "Validador_TRX_AV.lst" (URL=none) BODY=output STYLE=sasweb;
	TITLE JUSTIFY=left
	&temp_error;
	PROC PRINT DATA=VALIDACION_TRX_AV  NOOBS;
	RUN;
	ODS HTML CLOSE;
	ODS LISTING;





%mend mensaje_correo;

%mensaje_correo;








