/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	RUC_LNEGRO_EMAIL         	================================*/
/* CONTROL DE VERSIONES
/* 2020-12-10 -- V2 -- Sergio.J -- Nueva Versión Automática Equipo Datos y Procesos BI
 								-- Filtro de emails en blanco

/* 2020-11-11 -- V1 -- Sergio.J -- Nueva Versión Automática Equipo Datos y Procesos BI

/* Descripcion del proceso: 

Toma los EMAILS de PUBLICIN.LNEGRO_EMAIL y los comparte al siguiente FTP RUC.


/* INPUT: 
- PUBLICIN.LNEGRO_EMAIL

/* OUTPUT: 
- Exportación lista negra emails a ftp ruc*/


Proc sql;
create table lnegro_email as
select email
from publicin.lnegro_email;
quit;

proc sort data=lnegro_email out=lnegro_limpio noduprecs dupout=malos; 
by _all_;
run;

proc sql;
delete * 
from lnegro_limpio
where email="";
quit;

proc export data=work.lnegro_limpio
  OUTFILE="/sasdata/users94/ougarte/temp/LNEGRO_EMAIL.CSV"
 dbms=dlm REPLACE;
 delimiter=',';
 PUTNAMES=yes;
RUN;

/* EXPORTAR DE SAS A UN FTP O SFTP */ 
       filename server ftp 'LIBRONEGRO_EMAIL.CSV' CD='/inhibir-correo//' 
       HOST='192.168.10.155' user='ruc' pass='Bripley.2018' PORT=5560;

data _null_;
       infile '/sasdata/users94/ougarte/temp/LNEGRO_EMAIL.CSV';
       file server;
       input;
       put _infile_;
run;


/*	Fecha ejecución del proceso	*/
data _null_;
execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechaeDVN", execDVN) ;
RUN;
%put &fechaeDVN;/*fecha ejecucion proceso */



data _null_;
FILENAME OUTBOX EMAIL
FROM = ("sjaram@bancoripley.com")
TO = ("eb_aarancibias@bancoripley.com","jrmartinez@bancoripley.com","dvasquez@bancoripley.com","sjaram@bancoripley.com")
SUBJECT="MAIL_AUTOM: PROCESO LISTANEGRA_EMAIL %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Proceso Base LISTANEGRA_EMAIL se encuentra cargada en FTP/RUC , ejecutado con fecha: &fechaeDVN";  
 put ; 
 put ; 
 put ; 
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI V2';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
