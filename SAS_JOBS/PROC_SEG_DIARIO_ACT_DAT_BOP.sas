/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROC_SEG_DIARIO_ACT_DAT_BOP ================================*/
/* CONTROL DE VERSIONES
/* 2022-11-22 -- v09 -- Andrea S. 	-- Se agraga clasificación para canal CAPTACIONHB
/* 2022-11-03 -- v08 -- David V.	-- Se actualizar export a AWS, según nuevas definiciones a RAW.
/* 2022-08-26 -- V07 -- Sergio J. 	-- Se añade sentencia include para borrar y exportar a RAW
/* 2022-07-26 -- v06 -- Andrea S. 	-- Había faltado cambiar un HB_ por PWA_
/* 2022-07-25 -- v05 -- Andrea S. 	-- Se agraga clasificación para canal PWA
/* 2022-07-11 -- v04 -- David V. 	-- Ajustes mínimos para nuevo flujo "Oracloud AWS Athena".
/* 2022-03-31 -- v03 -- Esteban P. 	-- Actualizamos el correo de Pía por PM_CONTACTABILIDAD
/* 2020-08-09 -- v02 -- Pía O.		-- Actualización
/* 2020-05-27 -- v01 -- Original 
*/
/*==================================================================================================*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/


%let libreria=result;

%put==================================================================================================;
%put [00.01] Macro de Fechas ;
%put==================================================================================================;

DATA _null_;
mes_actual	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
mes_anterior	= input(put(intnx('month',today(),-1,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/

Call symput("mes_actual", mes_actual);
Call symput("mes_anterior", mes_anterior);

DATA _null_;
dateMES0	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
dateMES1	= input(put(intnx('month',today(),-1,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
dateMES2	= input(put(intnx('month',today(),-2,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
dateMES3	= input(put(intnx('month',today(),-3,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
dateMES4	= input(put(intnx('month',today(),-4,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
dateMES5	= input(put(intnx('month',today(),-5,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
date0 = put(intnx('month',today(),0,'begin'),date9.) ;

Call symput("VdateMES0", dateMES0);
Call symput("VdateMES1", dateMES1);
Call symput("VdateMES2", dateMES2);
Call symput("VdateMES3", dateMES3);
Call symput("VdateMES4", dateMES4);
Call symput("VdateMES5", dateMES5);
Call symput("fecha0", date0);

RUN;
%put &VdateMES0;
%put &VdateMES1;
%put &VdateMES2;
%put &VdateMES3;
%put &VdateMES4;
%put &VdateMES5;
%put &fecha0;

RUN;
%put &mes_actual;
%put &mes_anterior;

%put==================================================================================================;
%put [00.02] Seguimiento Actualizacion de datos EMAIL desde bopers ;
%put==================================================================================================;

LIBNAME R_bopers ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=BOPERS_ADM  USER='SAS_USR_BI' PASSWORD='SAS_23072020';
PROC SQL;
   CREATE TABLE &libreria..S_ACT_DAT_EMAIL_BOP_&VdateMES0 AS 
   SELECT PEMID_NRO_INN_IDE_K AS IDE,
		  input(PEMID_GLS_NRO_DCT_IDE_K,best.) as RUT,
          PEMMA_GLS_DML_MAI 	 AS EMAIL, 
          PEMMA_COD_EST_LCL	 AS EST,  
          PEMMA_FCH_FIN_ACL	 AS F_ACT,
		  input(put(datepart(PEMMA_FCH_FIN_ACL),yymmddn8.),best.) as fec_num, 
		 /* case when PEMMA_GLS_USR_FIN_ACL = 'HB-APP' THEN 'HB' */
		  case when PEMMA_GLS_USR_FIN_ACL = 'HB' THEN 'HB'
		  when PEMMA_GLS_USR_FIN_ACL = 'PWA' THEN 'PWA'
		  WHEN PEMMA_GLS_USR_FIN_ACL = 'CAPTACIONHB' THEN 'CAPTACIONHB'
			   ELSE 'PLATAFORMA' END AS CANAL
		FROM		r_BOPERS.BOPERS_MAE_MAI A
		LEFT JOIN r_BOPERS.bopers_mae_ide B
		ON (A.PEMID_NRO_INN_IDE_K = B.PEMID_NRO_INN_IDE)
/*		   WHERE 	PEMMA_FCH_FIN_ACL >= '01MAY2020'd and PEMMA_FCH_FIN_ACL < '04MAY2020'd*/
		   WHERE 	PEMMA_FCH_FIN_ACL >= "&fecha0:00:00:00"dt

order by PEMMA_FCH_FIN_ACL
;quit;

PROC SQL;
   CREATE TABLE &libreria..S_ACT_DAT_EMAIL_BOP_HB_&VdateMES0 AS 
   SELECT count(t1.IDE) as CONTAR, t1.fec_num, T1.CANAL
      FROM &libreria..S_ACT_DAT_EMAIL_BOP_&VdateMES0 t1 WHERE T1.CANAL = 'HB'
	group by t1.fec_num, T1.CANAL 
;
QUIT;

PROC SQL;
   CREATE TABLE &libreria..S_ACT_DAT_EMAIL_BOP_PWA_&VdateMES0 AS 
   SELECT count(t1.IDE) as CONTAR, t1.fec_num, T1.CANAL
      FROM &libreria..S_ACT_DAT_EMAIL_BOP_&VdateMES0 t1 WHERE T1.CANAL = 'PWA'
	group by t1.fec_num, T1.CANAL 
;
QUIT;

PROC SQL;
   CREATE TABLE &libreria..S_ACT_DAT_EMAIL_BOP_CAPTACIONHB_&VdateMES0 AS 
   SELECT count(t1.IDE) as CONTAR, t1.fec_num, T1.CANAL
      FROM &libreria..S_ACT_DAT_EMAIL_BOP_&VdateMES0 t1 WHERE T1.CANAL = 'CAPTACIONHB'
	group by t1.fec_num, T1.CANAL 
;
QUIT;

/*PROC SQL;
   CREATE TABLE result.S_ACT_DAT_EMAIL_BOP_APP_&VdateMES0 AS 
   SELECT count(t1.IDE) as CONTAR, t1.fec_num, T1.CANAL
      FROM result.S_ACT_DAT_EMAIL_BOP_&VdateMES0 t1 WHERE T1.CANAL = 'APP'
	group by t1.fec_num, T1.CANAL 
;
QUIT;*/

PROC SQL;
   CREATE TABLE &libreria..S_ACT_DAT_EMAIL_BOP_PLF_&VdateMES0 AS 
   SELECT count(t1.IDE) as CONTAR, t1.fec_num, T1.CANAL
      FROM &libreria..S_ACT_DAT_EMAIL_BOP_&VdateMES0 t1 WHERE T1.CANAL = 'PLATAFORMA'
	group by t1.fec_num, T1.CANAL 
;
QUIT;

PROC SQL;
   CREATE TABLE &libreria..S_ACT_DAT_EMAIL_BOP_TODOS_&VdateMES0 AS 
   SELECT count(t1.IDE) as CONTAR, T1.CANAL
      FROM &libreria..S_ACT_DAT_EMAIL_BOP_&VdateMES0 t1
	group by T1.CANAL 
;
QUIT;

%put==================================================================================================;
%put [00.03] Seguimiento Actualizacion de datos FONO desde bopers ;
%put==================================================================================================;

LIBNAME R_bopers ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=BOPERS_ADM  USER='SAS_USR_BI' PASSWORD='SAS_23072020';
PROC SQL;
   CREATE TABLE &libreria..S_ACT_DAT_FONO_BOP_&VdateMES0 AS 
   SELECT 	PEMID_NRO_INN_IDE_K AS IDE, 
            input(PEMID_GLS_NRO_DCT_IDE_K,best.) as RUT,
			PEMFO_NRO_FON 		AS FONO, 
			PEMFO_COD_EST_LCL 	AS EST,   
			PEMFO_GLS_USR_FIN_ACL AS ejec_canal, 
			PEMFO_FCH_FIN_ACL 	AS F_ACT,
			input(put(datepart(PEMFO_FCH_FIN_ACL),yymmddn8.),best.) as fec_num, 
		/*	case when PEMFO_GLS_USR_FIN_ACL = 'HB-APP' THEN 'HB' */
		    case when PEMFO_GLS_USR_FIN_ACL = 'HB' THEN 'HB' 
			when PEMFO_GLS_USR_FIN_ACL = 'PWA' THEN 'PWA'
			WHEN PEMFO_GLS_USR_FIN_ACL = 'CAPTACIONHB' 	THEN 'CAPTACIONHB'
			   ELSE 'PLATAFORMA' END AS CANAL
		FROM		r_BOPERS.bopers_mae_fon a
			LEFT JOIN r_BOPERS.bopers_mae_ide B
		ON (A.PEMID_NRO_INN_IDE_K = B.PEMID_NRO_INN_IDE)
/*		   WHERE 	PEMFO_FCH_FIN_ACL >= '01MAY2020'd and PEMFO_FCH_FIN_ACL < '04MAY2020'd*/
		WHERE 	PEMFO_FCH_FIN_ACL >= "&fecha0:00:00:00"dt
order by PEMFO_FCH_FIN_ACL
;quit;

PROC SQL;
   CREATE TABLE &libreria..S_ACT_DAT_FONO_BOP_HB_&VdateMES0 AS 
   SELECT count(t1.IDE) as CONTAR, t1.fec_num, T1.CANAL
      FROM &libreria..S_ACT_DAT_FONO_BOP_&VdateMES0 t1 WHERE T1.CANAL = 'HB'
	group by t1.fec_num, T1.CANAL 
;
QUIT;

PROC SQL;
   CREATE TABLE &libreria..S_ACT_DAT_FONO_BOP_PWA_&VdateMES0 AS 
   SELECT count(t1.IDE) as CONTAR, t1.fec_num, T1.CANAL
      FROM &libreria..S_ACT_DAT_FONO_BOP_&VdateMES0 t1 WHERE T1.CANAL = 'PWA'
	group by t1.fec_num, T1.CANAL 
;
QUIT;

PROC SQL;
   CREATE TABLE result.S_ACT_DAT_FONO_BOP_CAPTACIONHB_&VdateMES0 AS 
   SELECT count(t1.IDE) as CONTAR, t1.fec_num, T1.CANAL
      FROM result.S_ACT_DAT_FONO_BOP_&VdateMES0 t1 WHERE T1.CANAL = 'CAPTACIONHB'
	group by t1.fec_num, T1.CANAL 
;
QUIT; 

PROC SQL;
   CREATE TABLE &libreria..S_ACT_DAT_FONO_BOP_PLF_&VdateMES0 AS 
   SELECT count(t1.IDE) as CONTAR, t1.fec_num, T1.CANAL
      FROM &libreria..S_ACT_DAT_FONO_BOP_&VdateMES0 t1 WHERE T1.CANAL = 'PLATAFORMA'
	group by t1.fec_num, T1.CANAL 
;
QUIT;

PROC SQL;
   CREATE TABLE &libreria..S_ACT_DAT_FONO_BOP_TODOS_&VdateMES0 AS 
   SELECT count(t1.IDE) as CONTAR, T1.CANAL
      FROM &libreria..S_ACT_DAT_FONO_BOP_&VdateMES0 t1
	group by T1.CANAL 
;
QUIT;

%put==================================================================================================;
%put [00.04] Agrupar datos de actualizacion Email y Fono ;
%put==================================================================================================;

proc sql;
create table &libreria..S__FIN_act_dat_email_hb as
select * from result.S_ACT_DAT_EMAIL_BOP_HB_&VdateMES0
union
select * from result.S_ACT_DAT_EMAIL_BOP_HB_&VdateMES1
union
select * from result.S_ACT_DAT_EMAIL_BOP_HB_&VdateMES2
union
select * from result.S_ACT_DAT_EMAIL_BOP_HB_&VdateMES3
union
select * from result.S_ACT_DAT_EMAIL_BOP_HB_&VdateMES4
union
select * from result.S_ACT_DAT_EMAIL_BOP_HB_&VdateMES5
order by 2
;quit;

proc sql;
create table &libreria..S__FIN_act_dat_email_pwa as
select * from result.S_ACT_DAT_EMAIL_BOP_PWA_&VdateMES0
union
select * from result.S_ACT_DAT_EMAIL_BOP_PWA_&VdateMES1
union
select * from result.S_ACT_DAT_EMAIL_BOP_PWA_&VdateMES2
union
select * from result.S_ACT_DAT_EMAIL_BOP_PWA_&VdateMES3
union
select * from result.S_ACT_DAT_EMAIL_BOP_PWA_&VdateMES4
union
select * from result.S_ACT_DAT_EMAIL_BOP_PWA_&VdateMES5
order by 2
;quit;

proc sql;
create table &libreria..S__FIN_act_dat_email_CAPTACIONHB as
select * from result.S_ACT_DAT_EMAIL_BOP_CAPTACIONHB_&VdateMES0
union
select * from result.S_ACT_DAT_EMAIL_BOP_CAPTACIONHB_&VdateMES1
union
select * from result.S_ACT_DAT_EMAIL_BOP_CAPTACIONHB_&VdateMES2
union
select * from result.S_ACT_DAT_EMAIL_BOP_CAPTACIONHB_&VdateMES3
union
select * from result.S_ACT_DAT_EMAIL_BOP_CAPTACIONHB_&VdateMES4
union
select * from result.S_ACT_DAT_EMAIL_BOP_CAPTACIONHB_&VdateMES5
order by 2
;quit;

proc sql;
create table &libreria..S__FIN_act_dat_email_PLF as
select * from result.S_ACT_DAT_EMAIL_BOP_PLF_&VdateMES0
union
select * from result.S_ACT_DAT_EMAIL_BOP_PLF_&VdateMES1
union
select * from result.S_ACT_DAT_EMAIL_BOP_PLF_&VdateMES2
union
select * from result.S_ACT_DAT_EMAIL_BOP_PLF_&VdateMES3
union
select * from result.S_ACT_DAT_EMAIL_BOP_PLF_&VdateMES4
union
select * from result.S_ACT_DAT_EMAIL_BOP_PLF_&VdateMES5

order by 2
;quit;

/* proc sql;
create table result.S__FIN_act_dat_email_APP as
select * from result.S_ACT_DAT_EMAIL_BOP_APP_&VdateMES0
union
select * from result.S_ACT_DAT_EMAIL_BOP_APP_&VdateMES1
union
select * from result.S_ACT_DAT_EMAIL_BOP_APP_&VdateMES2
union
select * from result.S_ACT_DAT_EMAIL_BOP_APP_&VdateMES3
union
select * from result.S_ACT_DAT_EMAIL_BOP_APP_&VdateMES4
union
select * from result.S_ACT_DAT_EMAIL_BOP_APP_&VdateMES5

order by 2
;quit; */

proc sql;
create table &libreria..S__FIN_act_dat_FONO_hb as
select * from result.S_ACT_DAT_FONO_BOP_HB_&VdateMES0
union
select * from result.S_ACT_DAT_FONO_BOP_HB_&VdateMES1
union
select * from result.S_ACT_DAT_FONO_BOP_HB_&VdateMES2
union
select * from result.S_ACT_DAT_FONO_BOP_HB_&VdateMES3
union
select * from result.S_ACT_DAT_FONO_BOP_HB_&VdateMES4
union
select * from result.S_ACT_DAT_FONO_BOP_HB_&VdateMES5

order by 2
;quit;


proc sql;
create table &libreria..S__FIN_act_dat_FONO_PWA as
select * from result.S_ACT_DAT_FONO_BOP_PWA_&VdateMES0
union
select * from result.S_ACT_DAT_FONO_BOP_PWA_&VdateMES1
union
select * from result.S_ACT_DAT_FONO_BOP_PWA_&VdateMES2
union
select * from result.S_ACT_DAT_FONO_BOP_PWA_&VdateMES3
union
select * from result.S_ACT_DAT_FONO_BOP_PWA_&VdateMES4
union
select * from result.S_ACT_DAT_FONO_BOP_PWA_&VdateMES5

order by 2
;quit;

proc sql;
create table &libreria..S__FIN_act_dat_FONO_PLF as
select * from result.S_ACT_DAT_FONO_BOP_PLF_&VdateMES0
union
select * from result.S_ACT_DAT_FONO_BOP_PLF_&VdateMES1
union
select * from result.S_ACT_DAT_FONO_BOP_PLF_&VdateMES2
union
select * from result.S_ACT_DAT_FONO_BOP_PLF_&VdateMES3
union
select * from result.S_ACT_DAT_FONO_BOP_PLF_&VdateMES4
union
select * from result.S_ACT_DAT_FONO_BOP_PLF_&VdateMES5

order by 2
;quit;

proc sql;
create table result.S__FIN_act_dat_FONO_CAPTACIONHB as
select * from result.S_ACT_DAT_FONO_BOP_CAPTACIONHB_&VdateMES0
union
select * from result.S_ACT_DAT_FONO_BOP_CAPTACIONHB_&VdateMES1
union
select * from result.S_ACT_DAT_FONO_BOP_CAPTACIONHB_&VdateMES2
union
select * from result.S_ACT_DAT_FONO_BOP_CAPTACIONHB_&VdateMES3
union
select * from result.S_ACT_DAT_FONO_BOP_CAPTACIONHB_&VdateMES4
union
select * from result.S_ACT_DAT_FONO_BOP_CAPTACIONHB_&VdateMES5

order by 2
;quit;


%put==================================================================================================;
%put [00.04] Existencia de tabla ;
%put==================================================================================================;

%if (%sysfunc(exist(&libreria..Agrup_act_contac))) %then %do;
 
%end;
%else %do;



PROC  SQL;
CREATE TABLE &libreria..Agrup_act_contac(
 periodo num,
TIPO char(99),
EST num,  
 F_ACT date,
fec_num num, 
CANAL char(99),
casilla char(99),
TOTAL_CLIENTES num,
CLIENTES_UNICOS num)
;RUN;
%end;

%put==================================================================================================;
%put [01.00] Generacion de información asociado a los periodos  &mes_actual. y &mes_anterior.;
%put==================================================================================================;

proc sql;
create table tabla_paso as 
select distinct 
year(datepart(F_ACT))*100+month(datepart(F_ACT)) as periodo,
'EMAIL' as TIPO,
EST,  
datepart(F_ACT) format=date9. as F_ACT,
fec_num, 
CANAL,
substr(upcase(email), index(upcase(email), '@'), length(email) ) as casilla,
count(IDE) as TOTAL_CLIENTES,
count(distinct IDE) as CLIENTES_UNICOS
from &libreria..S_ACT_DAT_EMAIL_BOP_&mes_actual.
group by 
EST,  
calculated F_ACT,
fec_num, 
CANAL,
calculated casilla
outer union corr 

select distinct 
year(datepart(F_ACT))*100+month(datepart(F_ACT)) as periodo,
'FONO' as TIPO,
EST,  
datepart(F_ACT) format=date9. as F_ACT,
fec_num, 
CANAL,
'' as casilla,
count(IDE) as TOTAL_CLIENTES,
count(distinct IDE) as CLIENTES_UNICOS
from &libreria..S_ACT_DAT_FONO_BOP_&mes_actual.
group by 
EST,  
calculated F_ACT,
fec_num, 
CANAL

outer union corr
select distinct 
year(datepart(F_ACT))*100+month(datepart(F_ACT)) as periodo,
'EMAIL' as TIPO,
EST,  
datepart(F_ACT) format=date9. as F_ACT,
fec_num, 
CANAL,
substr(upcase(email), index(upcase(email), '@'), length(email) ) as casilla,
count(IDE) as TOTAL_CLIENTES,
count(distinct IDE) as CLIENTES_UNICOS
from &libreria..S_ACT_DAT_EMAIL_BOP_&mes_anterior.
group by 
EST,  
calculated F_ACT,
fec_num, 
CANAL,
calculated casilla
outer union corr 

select distinct 
year(datepart(F_ACT))*100+month(datepart(F_ACT)) as periodo,
'FONO' as TIPO,
EST,  
datepart(F_ACT) format=date9. as F_ACT,
fec_num, 
CANAL,
'' as casilla,
count(IDE) as TOTAL_CLIENTES,
count(distinct IDE) as CLIENTES_UNICOS
from &libreria..S_ACT_DAT_FONO_BOP_&mes_anterior.
group by 
EST,  
calculated F_ACT,
fec_num, 
CANAL
;QUIT;

%put==================================================================================================;
%put [02.00] Borrado he insercion a los periodos  &mes_actual. y &mes_anterior.;
%put==================================================================================================;

proc sql;
delete *
from &libreria..Agrup_act_contac 
where periodo in (&mes_actual. , &mes_anterior.)
;QUIT;

proc sql;
insert into &libreria..Agrup_act_contac 
select 
*
from tabla_paso
;QUIT;

proc sql;
drop table tabla_paso
;QUIT;


%put==================================================================================================;
%put SUBIR A AWS ;
%put==================================================================================================;
/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================        EXPORT_TO_AWS - INI          ===============================*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(ctbl_agrup_act_contac,raw,oracloud,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(ctbl_agrup_act_contac,&libreria..agrup_act_contac,raw,oracloud,0);

/*==============================        EXPORT_TO_AWS - END          ===============================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
%put==================================================================================================;
%put [04.00] Envio automatico de email;
%put==================================================================================================;


/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */


/*	Fecha ejecución del proceso	*/
data _null_;
execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechaeDVN", execDVN) ;
RUN;
%put &fechaeDVN;/*fecha ejecucion proceso */

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */

proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CONTACTABILIDAD';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4","&DEST_5")
CC = ("&DEST_1","&DEST_2","&DEST_3")
SUBJECT="MAIL_AUTOM: Seguimiento de Actualización datos de contacto %sysfunc(date(),yymmdd10.)" ;
FILE OUTBOX;
	PUT 'Estimados:'; 
 	PUT "Proceso Seguimiento Actualización datos de contacto, ejecutado con fecha: &fechaeDVN";  
 	PUT ;
 	PUT ;
 	PUT 'Proceso Vers. 09'; 
 	PUT;
 	PUT;
 	PUT 'Atte.';
 	PUT 'Equipo Arquitectura de Datos y Automatización BI';
 	PUT;
RUN;
FILENAME OUTBOX CLEAR;
