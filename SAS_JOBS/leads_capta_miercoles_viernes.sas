/*%let ini_fisa= 01/04/2021;
%let fin_fisa= 26/04/2021;
%let ini= 01apr2021;
%let fin= 26apr2021;
*/

/* CONTROL DE VERSIONES
/* 2022-07-12 -- V05	-- David V. 	-- Ajustes mínimos, versionado, correo, etc.
/* 2022-05-17 -- V04 	-- Benjamín M. 	-- Últimos cambios
/* 2022-04-13 -- V03 	-- David V.		-- Se agrega correo solicitado por Michael Vargas (jlazcanof@bancoripley.com)
/* 2022-04-05 -- V02 	-- Esteban P. 	-- Se actualizan los correos: Se elimina a EDMUNDO_PIEL y cceleryc@bancoripley.com.
/* 2022-03-24 -- V01 	-- Constanza C. --  
-- Se actualiza el limite, antes eran 540, ahora son 1500 y se agrega a Rene Fonseca para el correo de confirmacion 
-- Se cambian las bases de biometria de cceleryc a kmartine (Rene)
-> Se recodifica todo:
	- Tabla "Work.unicos" eliminacion de est_oferta, ya que trae duplicados y el campo no proporciona nada para la salida final
	- Eliminacion de Bases de Biometria, ya no es necesario
	- Eliminacion de cruce con tabla jgonzale.RUTERO_NACIONALIDADES, no aplica para este caso
	- Modificacion Formato Fecha de la salida (dd-mm-yyyy)
	- Exclusion de captados dentro del periodo en curso con producto TAM
	- Se deja solo ofertados TAM, se elimina para siempre la oferta de TR
	- Eliminacion de logueados en la PWA, no proporciona nada en el objetivo de los Leads
	- Se agregan comentarios varios
	- Autor: Benjamin Martinez, Fecha Modificacion 08-07-2022
*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/
%let libreria=RFONSECA;/*libreria de oferta captacion*/
%put &libreria;

/***FECHAS MACROS PARA PROCESO AUTOMATICO ***/
DATA _NULL;
FIN_FISA = put(intnx('day',today(),-1,'begin'),ddmmyy10.);
INI_FISA = put(intnx('day',today(),-1,'begin'),ddmmyy10.);
FIN = input(put(intnx('day',today(),-1,'same'),date9. ),$10.);
periodo = input(put(intnx('month',today(),0,'same'),yymmn6. ),$10.);
periodo_ant = input(put(intnx('month',today(),-1,'same'),yymmn6. ),$10.);
call symput("FIN_FISA",FIN_FISA); 
call symput("INI_FISA",INI_FISA); 
call symput("FIN",FIN); 
call symput("periodo",periodo);
call symput("periodo_ant",periodo_ant);
run;


%put &FIN_FISA;
%put &INI_FISA;
%put &FIN;
%put &periodo;
%put &periodo_ant;

/***MOVIMIENTO DE CAMPAÑA PARA VER PERSONAS QUE COMENZARON A REALIZAR EL FLUJO DE CAPTACION ***/
PROC SQL ;
CONNECT TO ORACLE AS CAMPANAS (PATH="BRTEFGESTIONP.WORLD" USER='CAMP_COMERCIAL' PASSWORD='ccomer2409');
CREATE TABLE MOV_TRX_OFE AS 
SELECT * FROM CONNECTION TO CAMPANAS(
SELECT 
A.CAMP_MOV_ID_K AS IDENTIFICADOR,
A.CAMP_MOV_RUT_CLI as RUT,
A.CAMP_MOV_EST_ACT as EST_OFERTA,
A.CAMP_MOV_COD_CANAL AS CANAL,
A.CAMP_MOV_COD_SUC AS SUCURSAL,
A.CAMP_MOV_FCH_HOR AS FECHA,
b.PRODUCTO,
b.CON_PRODUCTO,
b.MENSAJE,
b.cod_camp
from CBCAMP_MOV_TRX_OFE  a
left join (
select 
CAMP_MOV_ID_FK,
CAMD_COD_CAMP cod_camp,
CAMD_TIP_PROD as PRODUCTO,
CAMD_COD_CND_PROD AS CON_PRODUCTO,
CASE  when  CAMD_MSJ_POPUPA IS NOT NULL THEN 1 else 0 END AS MENSAJE 
from cbcamp_mov_det_trx_ofe
where
CAMD_TIP_PROD in ('8','9'))  b
on(a.CAMP_MOV_ID_K=b.CAMP_MOV_ID_FK)
where 
TRUNC(a.CAMP_MOV_FCH_HOR) >= to_date(%str(%')&INI_FISA.%str(%'),'dd/mm/yyyy')
and TRUNC(a.CAMP_MOV_FCH_HOR) <= to_date(%str(%')&fin_fisa.%str(%'),'dd/mm/yyyy')

and a.CAMP_MOV_COD_CANAL IN (2)
and A.CAMP_MOV_COD_SUC=39 /*DIGITAL*/
order by a.CAMP_MOV_ID_K
)A
;QUIT;

/*EXTRAER CAMPOS DE LOS MOVIMIENTOS DE FLUJO CAPTACION ONLINE*/
PROC SQL;
   CREATE TABLE WORK.ASIGNACION_PRODUCTOS AS 
   SELECT 
          t1.RUT,  
          t1.FECHA, 
		  EST_OFERTA
    FROM WORK.MOV_TRX_OFE t1
;QUIT;

/*TRAER EL ULTIMO MOVIMIENTO DEL CLIENTE EN EL FLUJO DE CAPTACION*/
PROC SQL;
	CREATE TABLE WORK.MAX_FECHA AS 
	SELECT t1.RUT, 
	  /* MAX_of_FECHA */
	    (MAX(t1.FECHA)) FORMAT=DATETIME20. AS MAX_of_FECHA
	FROM WORK.ASIGNACION_PRODUCTOS t1
	GROUP BY t1.RUT;
QUIT;

/*RUT UNICOS CON LA ULTIMA FECHA DE MOVIMIENTO PARA TENER LA MAS ACTUAL*/
PROC SQL;
	CREATE TABLE WORK.unicos AS 
	SELECT DISTINCT t1.RUT, 
	t1.FECHA/*,
	t1.EST_OFERTA*/
	FROM WORK.ASIGNACION_PRODUCTOS t1 INNER JOIN WORK.MAX_FECHA T2 
	ON (T1.RUT=T2.RUT AND t1.FECHA=t2.MAX_of_FECHA);
QUIT;


/*DATOS DE CONTACTABILIDAD SACADA DIRECTAMENTE DE ADMISION (DATOS QUE ESTAN EN "QUIERO SER CLIENTE")*/
PROC SQL ;
CONNECT TO ORACLE AS REPORTITF (PATH="REPORITF.WORLD" USER='PMUNOZC' PASSWORD='pmun2102');
CREATE TABLE telefonos_flujo AS 
SELECT * FROM CONNECTION TO REPORTITF(
SELECT 
*
FROM SFADMI_BCO_DAT_CON_CO
)A
;QUIT;

/*LIMPIEZA NUMERO TELEFONO */
proc sql; 
create table fonos_flujo as 
select distinct 
RUT_CLIENTE	as rut, 
input(NUM_TELEFONO,best.) as telefono1
from telefonos_flujo 
where input(NUM_TELEFONO,best.) not in (99999999,88888888,77777777,66666666,55555555,44444444,33333333,22222222,11111111,00000000,
98989898,89898989,88889999,99998888, 87654321)
;quit;

/***OFERTA DEL MES ACTUAL ONLINE ***/ 
%if (%sysfunc(exist(&libreria..capta_cdp_&periodo.))) %then %do;
proc sql;
create table oferta as 
select  
a.CAMP_COD_CAMP_FK,
a.prod_comerc,
a.rut,
a.dv,
a.cupo
from &libreria..capta_cdp_&periodo. as a
WHERE a.CAMP_COD_CAMP_FK  not like '%CP%'
and tipo_cliente='201'
;RUN; 
%end;
%else %do;
proc sql;
create table oferta as 
select  
a.CAMP_COD_CAMP_FK,
a.prod_comerc,
a.rut,
a.dv,
a.cupo
from &libreria..capta_cdp_&periodo_ant. as a
WHERE a.CAMP_COD_CAMP_FK  not like '%CP%'
and tipo_cliente='201'
;RUN; 
%end;

/*CLIENTES OFERTADOS QUE NO COMPLETARON EL FLUJO DE CAPTACION ONLINE, SE LE AGREGA FECHA DE SOLICITUD*/
PROC SQL ;
CREATE TABLE POTENCIALES AS 
SELECT DISTINCT 
a.RUT,
b.DV,
b.PROD_COMERC,
a.FECHA
FROM UNICOS AS A
INNER JOIN OFERTA AS B
	ON A.RUT=B.RUT
;QUIT;

/**************************************************************************************************
BASE FINAL DE COMUNICACION DONDE SE LE AGREGAN CAMPOS DE CONTACTABILIDAD A LOS CLIENTES POTENCIALES,
ES DECIR, CLIENTES QUE TIENEN OFERTA Y NO COMPLETARON EL FLUJO DE CAPTACION DIGITAL
***************************************************************************************************/
PROC SQL;
CREATE TABLE BASE_FINAL AS
SELECT DISTINCT
A.RUT,
A.DV,
B.PATERNO AS APELLIDO,
B.PRIMER_NOMBRE AS NOMBRE,
C.TELEFONO1 AS FONO_OPCION_1,
CASE WHEN C.TELEFONO1 IS NULL OR C.TELEFONO1<>D.TELEFONO THEN D.TELEFONO END AS FONO_OPCION_2,
A.PROD_COMERC,
DATEPART(A.FECHA) FORMAT=DDMMYYD10. AS FECHA

FROM POTENCIALES AS A
INNER JOIN PUBLICIN.BASE_NOMBRES AS B
	ON A.RUT=B.RUT
INNER JOIN FONOS_FLUJO AS C
	ON A.RUT=C.RUT
LEFT JOIN PUBLICIN.FONOS_MOVIL_FINAL AS D
	ON A.RUT=D.CLIRUT
LEFT JOIN PUBLICIN.BASE_TRABAJO_EMAIL AS E
	ON A.RUT=E.RUT
LEFT JOIN PUBLICIN.LNEGRO_CAR AS F
	ON A.RUT=F.RUT
LEFT JOIN PUBLICIN.MORA_SINACOFI AS G
	ON A.RUT=G.RUT

WHERE F.RUT IS NULL
AND G.RUT IS NULL
AND A.RUT NOT IN (SELECT RUT_CLIENTE FROM RESULT.CAPTA_SALIDA WHERE YEAR(FECHA)*100+MONTH(FECHA)=&PERIODO. AND PRODUCTO IN ('TAM','TAM_CERRADA','TAM_CUOTAS'))
AND A.PROD_COMERC IN ('TAM')

;QUIT;

/*SALIDA DE DATOS*/
PROC SQL;
CREATE TABLE COMUNICAR AS
SELECT *
FROM BASE_FINAL 
;QUIT;


/*	LEADS_SAV_CALL_INTERNO*/
/*  EXPORTAR SALIDA A FTP DE SAS	*/
PROC EXPORT DATA=work.COMUNICAR OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/LEADS_SAV_CALL/COMUNICAR.csv"
   DBMS=dlm REPLACE;
   delimiter=';';
   PUTNAMES=YES;
RUN;

/*	EXPORTAR DE SAS A UN SFTP	*/ 
       filename server sftp 'COMUNICAR.csv' CD='/Call_Interno/' 
		HOST='192.168.80.15' user='usr_bi_g';
data _null_;
       infile "/sasdata/users94/user_bi/TRASPASO_DOCS/LEADS_SAV_CALL/COMUNICAR.csv";
       file server;
       input;
       put _infile_;
run;

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI  FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1  FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2  FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3  FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4  FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_PPFF';
	SELECT EMAIL into :DEST_5  FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_1';
	SELECT EMAIL into :DEST_6  FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_2';
	SELECT EMAIL into :DEST_7  FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'CONSUELO_ARTEAGA';
	SELECT EMAIL into :DEST_8  FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'MICHAEL_VARGAS';
	SELECT EMAIL into :DEST_9  FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'CLAUDIA_PAREDES';
	SELECT EMAIL into :DEST_10 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'CRISTIAN_ECHEVERRIA';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;
%put &=DEST_6;	%put &=DEST_7;	%put &=DEST_8;	%put &=DEST_9;	%put &=DEST_10;

/*	MAIL PARA CALL INTERNO	*/
data _null_;
FILENAME OUTBOX EMAIL
FROM 	= ("&EDP_BI")
TO 		= ("&DEST_7","&DEST_8","&DEST_10","jlazcanof@bancoripley.com")
CC 		= ("&DEST_1","&DEST_2","&DEST_3","&DEST_4","&DEST_5","&DEST_6","kvasconeg@bancoripley.com","&DEST_9")
ATTACH	= "/sasdata/users94/user_bi/TRASPASO_DOCS/LEADS_SAV_CALL/COMUNICAR.csv"
SUBJECT = ("MAIL_AUTOM: Proceso LEADS_CAPTA_MIERCOLES_VIERNES - Interno");
FILE OUTBOX;
 PUT "Estimados:";
 put "        Proceso LEADS_CAPTA_MIERCOLES_VIERNES, ejecutado con fecha: &fechaeDVN";   
 PUT ;
 PUT '     Se adjunta archivo: COMUNICAR.csv';
 PUT ;
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 05'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
