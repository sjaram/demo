/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	VENCIMIENTOS_TC					 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-12-02 -- v04 -- David V.	-- Cambio en nombre de campo, por cambio en el Universo_Panes.
/* 2022-04-05 -- v03 -- Esteban P.	-- Se actualizan los correos: Se elimina a SEBASTIAN_BARRERA.
/* 2021-03-23 -- v02 -- Nicole L. 	-- Cambios en el n 
/* 2020-12-01 -- v01 -- Nicole L. 	-- Versión Original

/* INFORMACIÓN:
	Proceso que mira los Vencimiento de Tarjeta de Crédito y genera una base/tabla 
	para hacer acciones comerciales e invitar a los clientes a renovar su plástico.

	(IN) Tablas requeridas o conexiones a BD:
		- RESULT.UNIVERSO_PANES
		- PUBLICIN.SEGMENTO_COMERCIAL
        - PUBLICIN.ACT_TR
		- result.EDP_BI_DESTINATARIOS

	(OUT) Tablas de Salida o resultado:
		- RESULT.VENCIMIENTOS_&PERIODO

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria=RESULT;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/

/*
MES ES CURSO: 202011

GRUPO 1:
-------
MES -12: 201911
MES -11: 2021912
MES -10: 202001
MES -9: 202002
MES -8: 202003
MES -7: 202004
MES -6: 202005
MES -5: 202006
MES -4: 202007
MES -3: 202008
MES -2: 202009
MES -1: 202010


GRUPO 2:
-------
MES 0: 202011
MES 1: 202012
MES 2: 202101
MES 3: 202102

GRUPO 3: 
-------
MES 4: 202103
MES 5: 202104
MES 6: 202105

GRUPO 4:
-------
MES 7: 202106
MES 8: 202107
MES 9: 202108

*/


DATA _null_;
/* Variables Fechas de Ejecución */
datePeriodoActual = input(put(intnx('month',today(),0,'end' ),yymmn6. ),$10.);
Call symput("VdateHOY", datePeriodoActual);

RUN;
%put &VdateHOY;


DATA _null_;
/* Variables Fechas de Ejecución */
datePeriodoAnt = input(put(intnx('month',today(),-2,'end' ),yymmn6. ),$10.);
Call symput("VdateANT", datePeriodoAnt);

RUN;
%put &VdateANT;


options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/



/********************** TC ***********************/


/*3640957*/
PROC SQL;
   CREATE TABLE UNIVERSO_PANES_TC AS 
   SELECT *,
   &VdateHOY AS PERIODO, 
   SB_Mover_anomes(&VdateHOY,-12) as anomes_menos12,
   SB_Mover_anomes(&VdateHOY,3) as anomes_mas3,
   SB_Mover_anomes(&VdateHOY,6) as anomes_mas6,
   SB_Mover_anomes(&VdateHOY,9) as anomes_mas9
      FROM RESULT.UNIVERSO_PANES
      WHERE /*T_TR_VIG = 1 AND */
	        INDSITTAR=5 AND /*EN PODER DEL CLIENTE*/
			FECBAJA_CTTO='0001-01-01' AND   /*CONTRATO VIGENTE*/
		    CODBLQ IN (0,1,2,4,16,40,43,47,80,82,99) AND  /*SOLO BLOQUEOS DE TARJETA BLANDOS*/
            CALPART = 'TI' AND    /*SOLO TITULARES*/
            TIPO_TARJETA<> 'CUENTA VISTA' 
ORDER BY RUT ASC, TIPO_TARJETA DESC, NUMPLASTICO DESC,FECALTA_CTTO DESC, CUENTA DESC
;
QUIT;


PROC SQL NOPRINT;    
select max(anomes) as MAX_OFERTA 
into :MAX_OFERTA 
from ( 
select *, 
input(substr(Nombre_Tabla,length(Nombre_Tabla)-5,6),best.) as anomes 
from ( 
select  
*, 
cat(trim(libname),.,trim(memname)) as Nombre_Tabla 
from sashelp.vmember 
) as a 
where upper(Nombre_Tabla) like '%RFONSECA.CAPTA_CDP_%' 
and length(Nombre_Tabla)=length('RFONSECA.CAPTA_CDP_202112') 
) as x 
;QUIT; 


%LET MAX_OFERTA=&MAX_OFERTA;


PROC SQL;
CREATE TABLE UNIVERSO_PANES_TC AS
SELECT A.*, B.SEGMENTO AS SEGMENTO_COMERCIAL, C.VU_C_PRIMA
FROM UNIVERSO_PANES_TC AS A
LEFT JOIN PUBLICIN.SEGMENTO_COMERCIAL AS B ON A.RUT=B.RUT
LEFT JOIN PUBLICIN.ACT_TR_&VdateANT AS C ON A.RUT=C.RUT
left join RFONSECA.CAPTA_CDP_&MAX_OFERTA as d on (a.rut=d.rut)
where d.rut is not null 
;qUIT;

/*DUPLICADOS*/
DATA UNIVERSO_PANES_TC;
SET  UNIVERSO_PANES_TC;
IF RUT=LAG(RUT) THEN FILTRO =0; 
ELSE FILTRO=1; 
RUN;


/*3371613*/
PROC SQL;
DELETE * 
FROM UNIVERSO_PANES_TC 
WHERE FILTRO=0;
QUIT;



/*GRUPO 1 TC:
YA VENCIDOS 1 AÑO*/

/*121193*/
PROC SQL;
CREATE TABLE GRUPO_1_TC AS
SELECT *
FROM UNIVERSO_PANES_TC
WHERE FECCADTAR>=anomes_menos12 AND FECCADTAR<PERIODO
;QUIT;


/*GRUPO 2 TC:
POR VENCER 3 MESES SIGUIENTES*/

/*65751*/
PROC SQL;
CREATE TABLE GRUPO_2_TC AS
SELECT *
FROM UNIVERSO_PANES_TC
WHERE FECCADTAR<=anomes_mas3 AND FECCADTAR>=PERIODO
;QUIT;


/*GRUPO 3 TC:
POR VENCER 6 MESES SIGUIENTES*/

/*89067*/
PROC SQL;
CREATE TABLE GRUPO_3_TC AS
SELECT *
FROM UNIVERSO_PANES_TC
WHERE FECCADTAR<=anomes_mas6 AND FECCADTAR>=PERIODO and FECCADTAR>anomes_mas3
;QUIT;


/*GRUPO 4 TC:
POR VENCER 9 MESES SIGUIENTES*/

/*303611*/
PROC SQL;
CREATE TABLE GRUPO_4_TC AS
SELECT *
FROM UNIVERSO_PANES_TC
WHERE FECCADTAR<=anomes_mas9 AND FECCADTAR>=PERIODO and FECCADTAR>anomes_mas6
;QUIT;




PROC SQL;
CREATE TABLE &libreria..VENCIMIENTOS_&VdateHOY AS
SELECT * FROM (
SELECT *, 1 AS GRUPO FROM GRUPO_1_TC
OUTER UNION CORR
SELECT *, 2 AS GRUPO FROM GRUPO_2_TC
OUTER UNION CORR
SELECT *, 3 AS GRUPO FROM GRUPO_3_TC
OUTER UNION CORR
SELECT *, 4 AS GRUPO FROM GRUPO_4_TC)
WHERE VU_C_PRIMA NOT IN(

'a FALLECIDO',
'b CASTIGADO',
'c REPACTADO',
'f MOROSO',
'g LCA<M20',
'h CERRADA',
'i CESANTE',
'j BLOQUEO_CONTRATO')
;QUIT;


/*RESUMENES*/


PROC SQL;
   CREATE TABLE RESUMEN_TOTAL AS 
   SELECT /* COUNT_of_RUT */
            (COUNT(t1.RUT)) AS COUNT_of_RUT, 
          /* COUNT_DISTINCT_of_RUT */
            (COUNT(DISTINCT(t1.RUT))) AS COUNT_DISTINCT_of_RUT, 
          t1.TIPO_TARJETA, 
		  t1.VU_C_PRIMA,
          t1.FECCADTAR, 
          t1.SEGMENTO_COMERCIAL, 
          GRUPO
      FROM &libreria..VENCIMIENTOS_&VdateHOY t1
      GROUP BY t1.TIPO_TARJETA,
               t1.FECCADTAR,
			   t1.VU_C_PRIMA,
               t1.SEGMENTO_COMERCIAL,
grupo;
QUIT;



/*BASES ENTREGABLES EN .CSV*/

PROC SQL;
   CREATE TABLE CANALES_DIGITALES_&VdateHOY AS 
   SELECT cats(t1.rut,SB_DV(t1.Rut)) as RUT_DV,
          t1.GRUPO
      FROM RESULT.VENCIMIENTOS_&VdateHOY t1
      WHERE t1.GRUPO <= 2;
QUIT;

PROC SQL;
   CREATE TABLE CONTACT_Y_TOTAL_PACK_&VdateHOY AS 
   SELECT t1.RUT, 
          t1.GRUPO
      FROM RESULT.VENCIMIENTOS_&VdateHOY t1
  ;
QUIT;
 
proc sql noprint;
select count(RUT_DV) as canales 
into:canales 
from CANALES_DIGITALES_&VdateHOY
;QUIT;

%let CANALES =  &canales;

proc sql noprint;
select count(RUT) as  CONTACT 
into :contact 
from CONTACT_Y_TOTAL_PACK_&VdateHOY 
;QUIT;

%let CONTACT =&contact;
   
PROC EXPORT DATA =work.CANALES_DIGITALES_&VdateHOY
DBMS=csv
OUTFILE= "/sasdata/users94/user_bi/ENTREGABLE_CANALES_DIGITALES.csv"
replace
;RUN;
  
PROC EXPORT DATA =work.CONTACT_Y_TOTAL_PACK_&VdateHOY
DBMS=csv
OUTFILE= "/sasdata/users94/user_bi/ENTREGABLE_CONTACT_Y_TOTAL_PACK.csv"
replace
;RUN;

/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*	VARIABLE TIEMPO	- FIN	*/
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
	SELECT EMAIL into :DEST_4  FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_CLIENTES';
	SELECT EMAIL into :DEST_5  FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CLIENTES_1';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3; %put &=DEST_4;	%put &=DEST_5;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_4","&DEST_5")
CC = ("&DEST_1", "&DEST_2", "&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso VENCIMIENTOS_TC");
FILE OUTBOX;
 	PUT "Estimados:";
 	PUT "  Proceso VENCIMIENTOS_TC, ejecutado con fecha: &fechaeDVN";  
 	PUT ;
 	PUT "  Se adjuntan CSV Entregables";
 	PUT ;
 	PUT "  CANALES_DIGITALES = &CANALES. " ;
 	PUT "  CONTACT_Y_TOTAL_PACK = &CONTACT. " ;
 	PUT ;
 	PUT ;
 	PUT 'Proceso Vers. 04'; 
	PUT;
	PUT;
	PUT 'Atte.';
	PUT 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;
FILENAME OUTBOX CLEAR;
filename myfile "/sasdata/users94/user_bi/ENTREGABLE_CANALES_DIGITALES.csv" ;
filename myfile "/sasdata/users94/user_bi/ENTREGABLE_CONTACT_Y_TOTAL_PACK.csv"
;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/