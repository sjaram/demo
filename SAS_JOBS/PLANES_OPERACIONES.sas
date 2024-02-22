/*==================================================================================================*/
/*==================================	EQUIPO ARQ.DATOS Y AUTOM.		============================*/
/*==================================	PLANES_OPERACIONES					============================*/
/* CONTROL DE VERSIONES
/* 2023-05-24 -- v03	-- David V.		-- Corrección a variable fecha para archivo.
/* 2023-05-23 -- v02	-- David V.		-- Corrección a ruta en donde se deja el archivo.
/* 2023-05-19 -- v01	-- David V.		-- Versionamiento, automatización en server SAS.
/* 2023-05-17 -- v00 	-- Benja M. 	-- Original
 */

/*Información: Informe de Planes Contratados (Vigentes - Cerrados) para el equipo de Operaciones.*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*==================================================================================================*/
PROC SQL;
	create table Seguimiento_Planes as
		select 
			input(substr(identificador_cliente,1,length(identificador_cliente)-1),best.) as rut,
			year(datepart(creado_el))*10000+month(datepart(creado_el))*100+day(datepart(creado_el)) as fecha_apertura,
			cats(hour(creado_el),':',minute(creado_el),':',second(creado_el)) as Hora_Apertura,
		case 
			when estado='ENABLED' then 'vigente' 
			WHEN ESTADO='DISABLED' THEN 'cerrada' 
		END 
	AS ESTADO,
		CASE 
			WHEN calculated ESTADO='cerrada' then year(datepart(actualizado_el))*10000+month(datepart(actualizado_el))*100+day(datepart(actualizado_el)) 
		end 
	as fecha_cierre,
		id,
		plan_id
	from publicin.planes_tbl_plan_cliente
	;
QUIT;

proc sql;
	create table Seguimiento_Planes2 as
		select 
			a.*,
			compress(b.primer_nombre)||" "||compress(b.paterno)||" "||compress(b.materno) as Nombre_ApPaterno_ApMaterno
		from Seguimiento_Planes a
			left join publicin.base_nombres b
				on a.rut=b.rut

	;
quit;

/*SACAR DV*/
PROC SQL;
	CREATE TABLE DATA1 AS
		SELECT a.rut,
			CASE 
				WHEN INPUT(SUBSTR(put(a.rut,best8.),1,1),BEST32.)=. THEN 0 
				ELSE INPUT(SUBSTR(put(a.rut,best8.),1,1),BEST32.) 
			END 
		AS DIG1,
			CASE 
				WHEN INPUT(SUBSTR(put(a.rut,best8.),2,1),BEST32.)=. THEN 0 
				ELSE INPUT(SUBSTR(put(a.rut,best8.),2,1),BEST32.) 
			END 
		AS DIG2,
			CASE 
				WHEN INPUT(SUBSTR(put(a.rut,best8.),3,1),BEST32.)=. THEN 0 
				ELSE INPUT(SUBSTR(put(a.rut,best8.),3,1),BEST32.) 
			END 
		AS DIG3,
			CASE 
				WHEN INPUT(SUBSTR(put(a.rut,best8.),4,1),BEST32.)=. THEN 0 
				ELSE INPUT(SUBSTR(put(a.rut,best8.),4,1),BEST32.) 
			END 
		AS DIG4,
			CASE 
				WHEN INPUT(SUBSTR(put(a.rut,best8.),5,1),BEST32.)=. THEN 0 
				ELSE INPUT(SUBSTR(put(a.rut,best8.),5,1),BEST32.) 
			END 
		AS DIG5,
			CASE 
				WHEN INPUT(SUBSTR(put(a.rut,best8.),6,1),BEST32.)=. THEN 0 
				ELSE INPUT(SUBSTR(put(a.rut,best8.),6,1),BEST32.) 
			END 
		AS DIG6,
			CASE 
				WHEN INPUT(SUBSTR(put(a.rut,best8.),7,1),BEST32.)=. THEN 0 
				ELSE INPUT(SUBSTR(put(a.rut,best8.),7,1),BEST32.) 
			END 
		AS DIG7,
			CASE 
				WHEN INPUT(SUBSTR(put(a.rut,best8.),8,1),BEST32.)=. THEN 0 
				ELSE INPUT(SUBSTR(put(a.rut,best8.),8,1),BEST32.) 
			END 
		AS DIG8
			FROM Seguimiento_Planes as a
	;
QUIT;

PROC SQL;
	CREATE TABLE DATA2 AS
		SELECT *,
			11-(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)-
			(INT(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)/11)*11)) AS DIG,
		CASE 
			WHEN 11-(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)-
			(INT(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)/11)*11))=11 THEN '0'
			WHEN 11-(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)-
			(INT(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)/11)*11))=10 THEN 'K'
			ELSE PUT(11-(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)-
			(INT(SUM(DIG1*3,DIG2*2,DIG3*7,DIG4*6,DIG5*5,DIG6*4,DIG7*3,DIG8*2)/11)*11)),BEST1.) 
		END 
	AS DV_2
		FROM DATA1
	;
QUIT;

proc sql;
	create table Informacion_Planes as
		select 
			cats(a.rut,b.dv_2) as rut_dv,
			a.Nombre_ApPaterno_ApMaterno,
			a.fecha_apertura,
			a.Hora_Apertura,
			a.ESTADO,
			a.fecha_cierre,
			a.ID,
			a.PLAN_ID

		from Seguimiento_Planes2 as a
			left join data2 as b
				on a.rut=b.rut

			order by a.fecha_apertura desc
	;
quit;

data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;

data _null_;
	execDVN = compress(input(put(today(),ddmmyy10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN);
RUN;

%put &fechaeDVN;

DATA _null_;
datemy0 = input(put(intnx('month',today(),0,'BEGIN'),yymmn6. ),$10.);
Call symput("fechamy0", datemy0);	
RUN;

/* Variable ruta */
data _null_;
VAR = COMPRESS('/sasdata/users94/user_bi/TRASPASO_DOCS/Informacion_Planes_'||&fechamy0.||'.csv'," ",);
call symput("ruta",VAR);
run;

/*  EXPORTAR SALIDA A FTP DE SAS	*/
PROC EXPORT DATA= Informacion_Planes
   OUTFILE="&ruta."
   DBMS=dlm REPLACE;
   delimiter=';';
   PUTNAMES=YES;
RUN;


/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'GERENTE_ANALYTICS';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SUBG_BI';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
	SELECT EMAIL into :DEST_7 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_PPFF';
	SELECT EMAIL into :DEST_8 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_2';
quit;

%put &=EDP_BI; %put &=DEST_1; %put &=DEST_2; %put &=DEST_3; %put &=DEST_4; %put &=DEST_5;
%put &=DEST_6; %put &=DEST_7; %put &=DEST_8;

data _null_;
	FILENAME OUTBOX EMAIL
		FROM= ("&EDP_BI")
/*		TO = ("&DEST_1","&DEST_8")*/
		TO = ("portabilidad_operaciones@bancoripley.com","br_custodiacentral@bancoripley.com","aborquezj@bancoripley.com","pzuniga@bancoripley.com")
		CC = ("&DEST_1","&DEST_2","&DEST_3","&DEST_4","&DEST_5","&DEST_6","&DEST_7","&DEST_8",
		"estaroswiecki@bancoripley.com","jaravena@bancoripley.com","jmurillog@bancoripley.com",
		"jolmos@bancoripley.com","mjimenezc@bancoripley.com","oleiva@bancoripley.com")
		attach =("&ruta." content_type="excel")
		SUBJECT= "MAIL_AUTOM: Informacion Planes Operaciones &fechaeDVN.";
	FILE OUTBOX;
	PUT "Estimados:";
	PUT "     Se Adjunta Archivo Informacion de Planes Actualizado";
	PUT;
	PUT;
	PUT;
	PUT 'Proceso Vers. 03';
	PUT;
	PUT;
	PUT 'Atte.';
	PUT 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;

FILENAME OUTBOX CLEAR;
