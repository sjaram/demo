
/*generación de macro de extraccion de informacion*/

%macro envios(n,nombre);


DATA _null_;
fec	= input(put(intnx('month',today(),-&n.,'end'	),yymmn6.   ),$10.);
Call symput("periodo",fec);
RUN;

%put &periodo; 


proc sql;
create table resumen as 
select distinct 
min(fecha) as fecha,
mailing_id,
 mailing_name
from LIBCOMUN.output_email_&periodo. 
group by 
mailing_id,
 mailing_name
;QUIT;
 

proc sql;
create table resumen2 as 
select
*,
upcase(mailing_name) as MAILINGNAME
from resumen
;QUIT;

proc sql;
create table nombre_unico as 
select 
case when MAILINGNAME like '% A %' then substr(MAILINGNAME,1, index(MAILINGNAME, ' A ') -1)
when MAILINGNAME like '% B %' then substr(MAILINGNAME,1, index(MAILINGNAME, ' B ') -1)
when MAILINGNAME like '% C %' then substr(MAILINGNAME,1, index(MAILINGNAME, ' C ') -1)
when MAILINGNAME like '% REMAINDER %' then substr(MAILINGNAME,1, index(MAILINGNAME, ' REMAINDER ') -1)
when MAILINGNAME like '%_IP%' then substr(MAILINGNAME,1, index(MAILINGNAME, '_IP') -1)
else MAILINGNAME end as nombre_agrupado,
*
from resumen2
;QUIT;



proc sql;
create table work.&nombre. as 
select
&periodo. as  PERIODO,
fecha as FECHA_ENVIO,
fecha-floor(fecha/100)*100 as DIA_ENVIO,
nombre_agrupado,
mailing_id as MAILINGID,
MAILINGNAME,
substr(nombre_agrupado,9,3) as area,
case when substr(nombre_agrupado,9,3)='OPX' then 'TIENDA'
when substr(nombre_agrupado,9,3)='SPS' then 'SPOS' end as PRODUCTO
from nombre_unico 
where substr(nombre_agrupado,9,3) in ('OPX','SPS')
and substr(nombre_agrupado,1,6)="&periodo."
order by fecha,nombre_agrupado

;QUIT;

proc sql noprint;
drop table resumen;
drop table resumen2;
drop table nombre_unico;
;QUIT;

%mend envios; 

%envios(0,Mes_actual);
%envios(1,Mes_anterior);

proc sql;
create table base_enviar as 
select 
*
from mes_actual
union 
select 
*
from mes_anterior
;QUIT;


DATA _null_;
fec	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.);
Call symput("periodo",fec);
RUN;

%put &periodo; 

PROC EXPORT DATA=work.base_enviar
DBMS=xlsx 
OUTFILE= "/sasdata/users94/user_bi/ENVIOS_TDA_SPOS_&periodo..xlsx"
  replace
;RUN;


data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
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
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'CONI_ACUNA';

SELECT EMAIL into :DEST_5
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'MAGDA_BENTJERODT';

SELECT EMAIL into :DEST_6
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'LIVIA_HERNANDEZ';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;
%put &=DEST_5;
%put &=DEST_6;

Filename myEmail EMAIL	
    Subject = "MAIL_AUTOM TEST:Envios EMAIL Tda/Spos &periodo."
    From    = ("&EDP_BI.") 
    To      = ("&DEST_3.","&DEST_4.","&DEST_5.","&DEST_6.","bjordanas@bancoripley.com","socampot@bancoripley.com")
    CC      = ("&DEST_2.","&DEST_1.")
	attach =("/sasdata/users94/user_bi/ENVIOS_TDA_SPOS_&periodo..xlsx" content_type="excel")
    Type    = 'Text/Plain';

Data _null_; File myEmail; 
PUT "Estimados,";
PUT "Adjunto resumen de envios email Tda/Spos del &periodo. con fecha: &fechaeDVN.";
PUT "Saludos.";
PUT " ";
PUT " ";
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
;RUN;


proc sql noprint;
drop table base_enviar;
drop table Mes_actual;
drop table Mes_anterior;
;QUIT;

filename myfile "/sasdata/users94/user_bi/ENVIOS_TDA_SPOS_&periodo..xlsx" ;
data _null_;

rc=fdelete("myfile");

;run;
filename myfile clear;
