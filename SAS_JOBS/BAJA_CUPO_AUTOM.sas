/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================		BAJA_CUPO_AUTOM			================================*/
/* CONTROL DE VERSIONES
/* 2023-07-04 -- V10 -- Sergio J. 	-- Se agrega exportación a AWS
/* 2022-08-25 -- V9 -- Nicole -- Se unifica la carga de email en 1 solo, y se agregar una columna 
                       para distinguir entre mora y dormido con un nombre específico. Esto lo que
					   busca es automatizar la campaña en acustic
/* 2022-03-30 -- V8 -- David 		-- Se quita en correos a Balbontín y se agregan PMs de Segmentos 
/* 2022-01-31 -- V7 -- Sergio/David -- Se agrega sentencia guessingrows para importar archivo al server
/* 2021-09-01 -- V6 -- Sergio J. 	-- Se elimina el correo de Armando.
/* 2021-06-29 -- V5 -- David V. 	-- Faltaba directorio input en transferencia de archivo a SFTP.
/* 2021-06-07 -- V4 -- David V. 	-- Detalles finales para automatización en servidor SAS.
/* 2021-06-07 -- V3 -- David V. 	-- Cambio para email de notificaciones, incluir tabla resumen.
/* 2021-06-03 -- V2 -- David V. 	-- Ajustes al código para automatizar en server SAS
/* 2021-06-03 -- V1 -- Benjamín S. 	-- Original + detalles para automatización por parte de David

/* INFORMACIÓN:
	Proceso que oma información desde SFTP SAS, que es depositada por Cristian Valenzuela (MIS Riesgo), 
	la deja en SAS, el proceso de Benjamín lo toma y genera 3 salidas, 1.Archivo en SFTP para Cristian, 
	2.Archivo por correo para Pablo Balbontín (Clientes) y 3.Archivo con campañas para proceso en Acoustic

	(IN) Tablas requeridas o conexiones a BD:
	- /sasdata/users94/user_bi/TRASPASO_DOCS/BAJA_CUPO/AJUSTECUPOPROC &fechaMES;

	(OUT) Tablas de Salida o resultado:
 	- Archivo en SFTP para Cristian Valenzuela (MIS) 
		/sasdata/users94/user_bi/TRASPASO_DOCS/BAJA_CUPO/bajacupo_&Max_anomes_SegR..csv
	- Archivos que se envían por mail:
		/sasdata/users94/user_bi/TRASPASO_DOCS/BAJA_CUPO/ENVIOCARTA/CARTA_MORA.xlsx
		/sasdata/users94/user_bi/TRASPASO_DOCS/BAJA_CUPO/ENVIOCARTA/CARTA_DORMIDOS.xlsx
	- Archivo que se deposita para Campañas-Acoustic
		/sasdata/users94/user_bi/unica/INPUT-TR_CAMPANAS-&USUARIO..csv
*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

options validvarname=any;

DATA _null_;
dateMES	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
Call symput("fechaMES", dateMES);
%let libreria=RESULT;

RUN;
%put &libreria;
%put &fechaMES;

proc import datafile="/sasdata/users94/user_bi/TRASPASO_DOCS/BAJA_CUPO/AJUSTECUPOPROC &fechaMES"
out=&libreria..BAJA_CUPO_&fechaMES
dbms=dlm replace;
guessingrows = 7000;
delimiter='	';
getnames=yes;
run;

/*Exportación a AWS*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_ppff_baja_cupo,raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_ppff_baja_cupo,result.baja_cupo_&fechaMES.,raw,sasdata,0)


/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/ 

%let Base_Entregable=%nrstr('RESULT'); /*Base entregable con mayuscula*/

/*Obtener ultima tabla de segmento real disponible*/
PROC SQL NOPRINT;   

select max(anomes) as Max_anomes_ACTR
into :Max_anomes_ACTR
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

PROC SQL NOPRINT;   

select max(anomes) as Max_anomes_SegCOM
into :Max_anomes_SegCOM
from (
select *,
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes
from (
select 
*,
cat(trim(libname),.,trim(memname)) as Nombre_Tabla
from sashelp.vmember
) as a
where upper(Nombre_Tabla) like 'NLAGOSG.SEGMENTO_COMERCIAL_%' 
and length(Nombre_Tabla)=length('NLAGOSG.SEGMENTO_COMERCIAL_AAAAMM')
) as x

;QUIT;

PROC SQL NOPRINT;   

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
where upper(Nombre_Tabla) like 'RESULT.BAJA_CUPO_%' 
and length(Nombre_Tabla)=length('RESULT.BAJA_CUPO_AAAAMM')
) as x

;QUIT;

DATA _NULL_;
Call execute(
cat('
PROC SQL; 
        CREATE TABLE final AS  
        SELECT DISTINCT T1.*,T1.RUT*2-1599 AS ID,
        A.SEGMENTO_FINAL,
        B.ACTIVIDAD_TR,
        C.PRIMER_NOMBRE, 
        C.PATERNO,  
        C.MATERNO,
        D.CALLE,  
        D.NUMERO, 
        D.RESTO,  
        D.COMUNA,  
        D.REGION, 
        CASE WHEN D.RUT IS NOT MISSING THEN 1 ELSE 0 END AS T_DIRECCION, 
        case when F.EMAIL not in (select email from publicin.lnegro_email) and t1.rut not in (select rut from publicin.lnegro_email) then f.email end as Email,  
        CASE WHEN F.RUT IS NOT MISSING THEN 1 ELSE 0 END AS T_EMAIL, 
		case when t1.rut in (select rut from publicin.lnegro_car) then 1 else 0 end as Lnegro 
         FROM ',&Base_Entregable,'.BAJA_CUPO_',&Max_anomes_SegR,' T1
        LEFT JOIN NLAGOSG.SEGMENTO_COMERCIAL_',&Max_anomes_SegCOM,' A ON T1.RUT=A.RUT 
        LEFT JOIN PUBLICIN.ACT_TR_',&Max_anomes_ACTR,' B ON T1.RUT=B.RUT 
        LEFT JOIN PUBLICIN.BASE_NOMBRES C ON T1.RUT=C.RUT 
        LEFT JOIN PUBLICIN.DIRECCIONES D ON T1.RUT=D.RUT 
        LEFT JOIN PUBLICIN.BASE_TRABAJO_EMAIL F ON T1.RUT=F.RUT 
;QUIT;') 
);
run;


proc sql;
create table base_1 as
select *,case when Tipo_Disminucion in('Mora Externa',
'Salida Inmediata') then 'Mora Externa'
when 'Contingente' then 'Dormidos'
end as Base,
case when lower(marca_comunicado) like '%carta%' and calle is not missing then 'Carta'
when lower(marca_comunicado) like '%carta%' and calle is  missing and email is not missing then 'Email'
when lower(marca_comunicado) like '%carta%' and calle is  missing and email is  missing then 'No Comunicar'
when lower(marca_comunicado) like '%email%' and email is not missing then 'Email'
when lower(marca_comunicado) like '%email%' and email is  missing and calle is not missing then 'Carta'
when lower(marca_comunicado) like '%email%' and email is  missing and calle is  missing then 'No Comunicar'
else 'revisar' end as Base2
from final
;Quit;


proc sql;
create table baja_cupo_mora  as
select * from base_1
where base='Mora Externa' and lnegro=0 and (segmento_final is missing or segmento_final='RIPLEY_BAJA')
and actividad_tr in ('DORMIDO DURO','DORMIDO BLANDO') and base2 not in ('No Comunicar')
;quit;


proc sql;
create table baja_cupo_Dormidos as
select * from base_1
where base='Dormidos' and lnegro=0 and (segmento_final is missing or segmento_final='RIPLEY_BAJA')
and actividad_tr in ('DORMIDO DURO','DORMIDO BLANDO') and base2 not in ('No Comunicar')
;quit;


proc sql;
create table baja_cupo as
select *, 'MORA' as VAR_CAMP_TXT_1
from baja_cupo_mora
outer union corr
select *, 'DORMIDO' as VAR_CAMP_TXT_1
from baja_cupo_Dormidos
;QUIT;

proc sql;
create table cuenta as
select 
base,
sum(case when lnegro=1 then 1 else 0 end) as Lnegro,
sum(case when lnegro=0 and (segmento_final is missing or segmento_final='RIPLEY_BAJA')
and actividad_tr in ('DORMIDO DURO','DORMIDO BLANDO') and base2 = 'Carta' then 1 else 0 end) as  Carta,
sum(case when lnegro=0 and (segmento_final is missing or segmento_final='RIPLEY_BAJA')
and actividad_tr in ('DORMIDO DURO','DORMIDO BLANDO') and base2 = 'Email' then 1 else 0 end) as Email,
sum(case when lnegro=0 and (segmento_final is missing or segmento_final='RIPLEY_BAJA')
and actividad_tr in ('DORMIDO DURO','DORMIDO BLANDO') and base2 = 'No Comunicar' then 1 else 0 end) as No_comunicable,
sum(case when lnegro=0 and ((segmento_final is not missing and segmento_final not ='RIPLEY_BAJA')
or actividad_tr not in ('DORMIDO DURO','DORMIDO BLANDO'))  then 1 else 0 end) as no_aplica
from base_1 
group by base
;Quit;

proc sql;
create table base_limpia as
select * from base_1
where lnegro=0 and (segmento_final is missing or segmento_final='RIPLEY_BAJA')
and actividad_tr in ('DORMIDO DURO','DORMIDO BLANDO') and base2 not in ('No Comunicar') 
;quit;

DATA _NULL_;
Call execute(
cat('
proc sql;
create table ',&Base_Entregable,'.baja_cupo_',&Max_anomes_SegR,'_final as 
select * from base_limpia 
;quit;') 
);
run;

/* EXPORTAR SALIDA A SFTP DE SAS */
PROC EXPORT DATA = base_limpia
OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/BAJA_CUPO/bajacupo_&fechaMES..csv"
DBMS=dlm REPLACE;
delimiter=';';
PUTNAMES=YES;
RUN;

proc sql;
create table baja_cupo_mora_carta as 
select rut,id,catx(' ',primer_nombre,paterno,materno) as DESTINATARIO,
catx(' ',calle,numero,resto) as DIRECCION,COMUNA,REGIoN
from baja_cupo_mora
where base2='Carta'  
;quit;

proc sql;
create table baja_cupo_dormidos_carta as 
select rut,id,catx(' ',primer_nombre,paterno,materno) as DESTINATARIO,
catx(' ',calle,numero,resto) as DIRECCION,COMUNA,REGIoN
from baja_cupo_Dormidos
where base2='Carta'  
;quit;

/* EXPORTAR SALIDA A SFTP DE SAS */
    PROC EXPORT DATA=work.baja_cupo_mora_carta
DBMS=xlsx
OUTFILE='/sasdata/users94/user_bi/TRASPASO_DOCS/BAJA_CUPO/ENVIOCARTA/CARTA_MORA.xlsx'
  replace
;RUN;

/* EXPORTAR SALIDA A SFTP DE SAS */
    PROC EXPORT DATA=work.baja_cupo_dormidos_carta
DBMS=xlsx
OUTFILE='/sasdata/users94/user_bi/TRASPASO_DOCS/BAJA_CUPO/ENVIOCARTA/CARTA_DORMIDOS.xlsx'
  replace
;RUN;

/* VARIABLES PARA ENVÍO DE MAILS */
proc sql noprint;
SELECT EMAIL into :EDP_BI 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
SELECT EMAIL into :DEST_1 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ_CAMP';
SELECT EMAIL into :DEST_2 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA_CAMP';
SELECT EMAIL into :DEST_3 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFATURA_CAMP';
SELECT EMAIL into :DEST_4 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CAMP_1';
SELECT EMAIL into :DEST_5 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'BENJAMIN_SOTO';
SELECT EMAIL into :DEST_6 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CAMP_2';
SELECT EMAIL into :DEST_7 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CAMP_3';
SELECT EMAIL into :DEST_8 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_SEGMENTOS_1';
SELECT EMAIL into :DEST_9 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_SEGMENTOS_2';
SELECT EMAIL into :DEST_10 	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_SEGMENTOS';
quit;

%put &=EDP_BI; %put &=DEST_1; %put &=DEST_2; %put &=DEST_3; %put &=DEST_4; %put &=DEST_5;
%put &=DEST_6; %put &=DEST_7; %put &=DEST_8; %put &=DEST_9; %put &=DEST_10;

Filename myEmail EMAIL    
Subject = "MAIL_AUTOM: BASE BAJA CUPO CARTA "
From    = ("&EDP_BI") 
TO      = ("DEST_8","&DEST_9","&DEST_5")
CC      = ("DEST_1","&DEST_2","&DEST_3","&DEST_10")
attach 	= ('/sasdata/users94/user_bi/TRASPASO_DOCS/BAJA_CUPO/ENVIOCARTA/CARTA_DORMIDOS.xlsx' content_type="excel")
attach 	= ('/sasdata/users94/user_bi/TRASPASO_DOCS/BAJA_CUPO/ENVIOCARTA/CARTA_MORA.xlsx' content_type="excel")
Type    = 'Text/Plain';

Data _null_; File myEmail; 
PUT "Estimados,";
PUT "Adjunto BASES PARA BAJA DE CUPO CARTA";
PUT "Saludos.";
PUT " ";
PUT " ";
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
;RUN;

options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/

proc sql outobs=1 NOPRINT;
select 
 floor(input(SB_AHORA('AAAAMMDD'),best.)/100) /*Si Periodo=0, usar periodo del dia anterior*/
 as Periodo 
into :Periodo 
from sashelp.vmember
;quit;

DATA _null_;
hoy		= compress(tranwrd(put(INTNX('DAY',today() , 0),mmddyy10.),"-",""));
fgenera	= compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fecha", hoy);
Call symput("fexe",fgenera);
RUN;
%put &fecha;
%put &fexe;


/*	================================================================== */
/*	=======================	INICIO CODIGO NUEVO	 - EMAIL ============= */
%let USUARIO2 	= BSOTO2;
%let MI_CORREO2 = bsotov@bancoripley.com;
%let CAMPANA2 	= BAJA_CUPO_DORMIDOS_MORA;
%let CAMP_AREA2 = SEGMENTOS;
/*%let CAMP_PROD2 = BJC;*/
%let BASE_LIB2	= WORK.;
%let BASE_TAB2	= baja_cupo;

/* CAMPCODE_B */
DATA _null_;
vCAMPCODE_B = COMPRESS(CAT("&fexe"));
Call symput("CAMPCODE_B", vCAMPCODE_B);
RUN;

%put &USUARIO2;		%put &CAMPCODE_B;	%put &MI_CORREO2;		%put &CAMPANA2;
%put &CAMP_AREA2;	%put &CAMP_PROD2;	%put &BASE_LIB2;		%put &BASE_TAB2;

OPTIONS VALIDVARNAME=ANY;

DATA _null_;
hoy2= compress(tranwrd(put(INTNX('DAY',today() , 0),mmddyy10.),"-",""));
Call symput("fecha2", hoy2);
RUN;

%put &fecha2;

proc sql;
Create table UNICA_CARGA_CAMP_EMAIL (
	'CAMPANA-CAMPCODE'n 	CHAR(200), 		/* OBLIGATORIO SMS / PUSH / EMAIL */
	'CAMPANA-AREA'n 		CHAR(200), 		/* SMS / PUSH / EMAIL */
	'CAMPANA-PRODUCTO'n 	CHAR(200), 		/* SMS / PUSH / EMAIL */
	'CAMPANA-CAMPANA'n 		CHAR(200), 		/* OBLIGATORIO SMS / PUSH / EMAIL */
	'CAMPANA-FECHA'n 		CHAR(38), 		/* SMS / PUSH / EMAIL */
	'CAMPANA-CUSTOMERID'n 	NUMERIC(38),	/* SMS / PUSH / EMAIL */
	'CLIENTE-EMAIL'n 		CHAR(50), 		/* SMS / PUSH / EMAIL */
	'CLIENTE-NOMBRE'n  		CHAR(50),
	'CAMPANA-ID_USUARIO'n 	NUMERIC(38),	/* OBLIGATORIO SMS / PUSH / EMAIL */
	'CLIENTE-ID_USUARIO'n 	NUMERIC(38),	/* OBLIGATORIO SMS / PUSH / EMAIL */
	'CAMPANA-IND_RUT_DUP_CAMP'n NUMERIC(38),
	'CAMPANA-VAR_CAMP_TXT_1'n   CHAR(20)
)
;quit;

/* BASE DE ORIGEN */
DATA _null_;
BASE2 = CAT("&BASE_LIB2","&BASE_TAB2");
Call symput("var_BASE2", BASE2);
RUN;

%put &var_BASE2;

/* INSERT CAMPAÑA --> EMAIL */
proc sql NOPRINT;
INSERT INTO UNICA_CARGA_CAMP_EMAIL
('CAMPANA-CAMPCODE'n, 'CAMPANA-AREA'n, 'CAMPANA-PRODUCTO'n, 'CAMPANA-CAMPANA'n, 'CAMPANA-FECHA'n, 'CAMPANA-CUSTOMERID'n, 'CLIENTE-EMAIL'n, 'CLIENTE-NOMBRE'n,
'CAMPANA-ID_USUARIO'n, 'CLIENTE-ID_USUARIO'n, 'CAMPANA-IND_RUT_DUP_CAMP'n, 'CAMPANA-VAR_CAMP_TXT_1'n )
SELECT DISTINCT "&CAMPCODE_B.", "&CAMP_AREA2.", "&CAMP_PROD2.", "&CAMPANA2.",  "&FECHA2.", RUT, EMAIL,PRIMER_NOMBRE, RUT, RUT, 0 , VAR_CAMP_TXT_1
from &var_BASE2 WHERE BASE2='Email';
;quit;

/*	EXPORT --> Generación archivo CSV */
PROC EXPORT DATA = UNICA_CARGA_CAMP_EMAIL
OUTFILE="/sasdata/users94/user_bi/unica/input/INPUT-TR_CAMPANAS-&USUARIO..csv"

DBMS=dlm REPLACE;
delimiter=',';
PUTNAMES=YES;
RUN;

PROC SQL;
CREATE TABLE COUNT_DE_TABLA_TMP2 AS
SELECT COUNT('CAMPANA-ID_USUARIO') AS CANTIDAD_DE_REGISTROS_CARGADOS
from UNICA_CARGA_CAMP_EMAIL
;QUIT;

%put &CAMPCODE2;
%put &CAMPANA2;

/* IDENTIFICADOR PARA EL EQUIPO CAMPAÑAS */
DATA _null_;
ID2 = CAT(COMPRESS("&CAMPCODE_B."),' - ',"&CAMPANA2.");
Call symput("var_ID_CAMP2", ID2);
RUN;

%put &var_ID_CAMP2;

	FILENAME output EMAIL
	SUBJECT	= "MAIL_AUTOM: Campaña depositada: &var_ID_CAMP2."
	FROM 	= ("&EDP_BI")
	TO 		= ("&DEST_4","&DEST_6","&DEST_7")
	CC 		= ("&DEST_1","&DEST_2","&DEST_3","&DEST_5","&DEST_8","&DEST_9","&DEST_10")
	CT= "text/html" /* Required for HTML output */ ;
	
	FILENAME mail EMAIL TO="&DEST_1"
 	SUBJECT="HTML OUTPUT" CONTENT_TYPE="text/html";
	ODS LISTING CLOSE;
	ODS HTML  path="/sasbin/SASConfig/Lev1/SASApp/" file = "BAJA_CUPO_AUTOM.lst" (URL=none) BODY=output STYLE=sasweb;
	TITLE JUSTIFY=left
	"
	Archivo de campaña depositado, IDENTIFICADOR: &var_ID_CAMP2
	";
	PROC PRINT DATA=COUNT_DE_TABLA_TMP2  NOOBS;
	RUN;
	ODS HTML CLOSE;
	ODS LISTING;
/* ==================================| FIN CODIGO NUEVO |==================================*/

Filename myEmail EMAIL    
Subject = "MAIL_AUTOM: Archivo BAJA_CUPO disponible"
From    = ("&EDP_BI") 
TO      = ("cvalenzuelav@bancoripley.com","&DEST_8","&DEST_9")
CC		= ("&DEST_1","&DEST_2","&DEST_5","&DEST_3","&DEST_10")
Type    = 'Text/Plain';

Data _null_; File myEmail; 
	PUT "Estimado,";
	PUT "Archivo disponible en SFTP";
	PUT " ";
	PUT "Ruta: /sasdata/users94/user_bi/TRASPASO_DOCS/BAJA_CUPO/bajacupo_&fechaMES..csv";
	PUT;
	PUT;
	PUT 'Proceso Vers. 10';
	PUT;
	PUT;
	PUT 'Atte.';
	PUT 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
;RUN;

/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 
