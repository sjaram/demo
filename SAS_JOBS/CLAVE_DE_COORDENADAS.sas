/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	CLAVE_DE_COORDENADAS			 ===============================*/
/* CONTROL DE VERSIONES
/* 2023-05-29 -- v04 -- David V.	-- Se actualiza conexión a la bd por cambio en producción banco.
/* 2022-01-24 -- v03 -- David V. 	-- Se cambia librería DVASQUEZ por WORK para automatizar en server SAS
/* 2022-01-03 -- v02 -- David V. 	-- Se agrega límite a la columna estado, para controlar peso del archivo salida
/* 2021-11-05 -- v01 -- David V. 	-- Versión Original

/* INFORMACIÓN:
	Información de clave de coordenadas de cara a los clientes

------------------------------
 DURACIÓN TOTAL:   0:09:38.71
------------------------------
*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria1=WORK;
%let libreria2=PUBLICIN;

DATA _null_;
	/* DECLARACIÓN VARIABLES FECHAS*/
	dateDIA	= compress(substr(put(today(),ddmmyy10.),7,4)||substr(put(today(),ddmmyy10.),4,2)||substr(put(today(),ddmmyy10.),1,2));
	Call symput("VdateDIA", dateDIA);
	dateMES	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
	Call symput("VdateMES", dateMES);
RUN;

%put &VdateDIA;
%put &VdateMES;
LIBNAME REPITFH ORACLE SCHEMA='CLAVEUNICA_ADM'  USER='USR_BI_G' PASSWORD='usrpass2021'
	PATH="  (DESCRIPTION =
	(ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.84.20)(PORT = 1521))
	(CONNECT_DATA =
	(SERVER = DEDICATED)
	(SERVICE_NAME = itfhis)
		)
		)";

PROC SQL;
	CREATE TABLE cards AS
		SELECT * 
			FROM REPITFH.CARDS t1
		where card_state ='PENDING' or card_state = 'CURRENT' or card_state = 'HOLD_PENDING'
;QUIT;

PROC SQL;
	CREATE TABLE WORK.COORDENADAS_1 AS 
		SELECT T1.USER_ID, 
			T1.SERIAL_NUMBER, 
			T1.CARD_STATE as CARD_STATE length=7, 
			T1.GENERATE_DATE,
			INPUT(SUBSTR(t1.USER_ID,1,(LENGTH(t1.USER_ID)-1)),BEST.) AS RUT,
			input(put(datepart(t1.GENERATE_DATE),yymmddn8.),best.) as FECHA_NUM
		FROM WORK.cards t1
			WHERE t1.USER_ID NOT = '';
QUIT;

PROC SQL;
	CREATE TABLE WORK.COORDENADAS_2 AS 
		SELECT T1.RUT, 
			T1.SERIAL_NUMBER, 
			T1.CARD_STATE AS ESTADO, 
			T1.GENERATE_DATE,
			t1.FECHA_NUM,
			MDY(INPUT(SUBSTR(PUT(t1.FECHA_NUM,BEST8.),5,2),BEST4.),
			INPUT(SUBSTR(PUT(t1.FECHA_NUM,BEST8.),7,2),BEST4.),
			INPUT(SUBSTR(PUT(t1.FECHA_NUM,BEST8.),1,4),BEST4.)) FORMAT=YYMMDD10. AS FECHA_GUION,
			put(datepart(t1.GENERATE_DATE),yymmddn8.) as FECHA_STR,
			MDY(
			input(substr(compress(put(FECHA_NUM,best.)),5,2),best.),
			input(substr(compress(put(FECHA_NUM,best.)),7,2),best.),
			input(substr(compress(put(FECHA_NUM,best.)),1,4),best.)
			) format=date9. as FECHA
		FROM WORK.COORDENADAS_1 t1
			WHERE t1.USER_ID NOT = '';
QUIT;

PROC SQL;
	CREATE TABLE WORK.UNO_ AS 
		SELECT t1.*,
			MONTH(FECHA) AS MES,
			YEAR(FECHA) AS ANIO
		FROM WORK.COORDENADAS_2 T1
	;
QUIT;

PROC SQL;
	CREATE TABLE MAX_FECHA AS 
		SELECT t1.RUT, 
			(MAX(t1.FECHA)) FORMAT=DATE9. AS MAX_of_FECHA 
		FROM WORK.UNO_ t1 GROUP BY t1.RUT;
QUIT;

PROC SQL;
	CREATE TABLE RUT_UNICO_COORDENADAS AS
		SELECT A.*
			FROM WORK.UNO_ A
				INNER JOIN MAX_FECHA B ON A.RUT=B.RUT AND A.FECHA=B.MAX_of_FECHA
	;
QUIT;

PROC SQL;
	CREATE TABLE &libreria1..CLAVE_COORDENADAS_&VdateDIA AS				
		SELECT *
			FROM RUT_UNICO_COORDENADAS T1
				WHERE T1.RUT IS NOT MISSING
	;
QUIT;

PROC SQL;
	CREATE TABLE &libreria2..CLAVE_COORDENADAS_&VdateMES AS			
		SELECT RUT, ESTADO, FECHA
			FROM &libreria1..CLAVE_COORDENADAS_&VdateDIA;
QUIT;

/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;
