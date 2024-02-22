/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	VARIABLES_MOTOR_PRECIO		================================*/
/* CONTROL DE VERSIONES
/* 2023-12-27 -- V14 -- David Vásquez	-- Actualización a base de rsepulv, ahora queda en jaburtom.
/* 2023-06-30 -- V13 -- Sergio Jara		-- Se quita la función input para que el proceso corra correctamente
/* 2022-11-02 -- V12 -- David Vásquez	-- Se quita un inobs
/* 2022-10-27 -- V11 -- Sergio Jara		-- Cambio en variable elasticidad se cambia . por ,
/* 2022-08-30 -- V10 -- David Vásquez	-- Se agrega validvarname, por problema en versión server SAS.
/* 2022-08-29 -- V09 -- José Aburto		-- DV en mayúsc. + nuevos campos elasticity, rentability, propensityAdvance y propensityConsumption
/* 2021-12-15 -- V08 -- David Vásquez	-- Se adjunta archivo comprimido por mail requerido por área PPFF
/* 2021-11-30 -- V07 -- David Vásquez	-- Nuevo cambio en planificación, para que se ejecute en mes en curso.
/* 2021-11-03 -- V06 -- David Vásquez	-- Se cambia extensión de archivo a solo un .txt
/* 2021-11-03 -- V05 -- David Vásquez	-- Cambiar variable fecha para que apunte al mes actual y no al siguiente
/* 2021-08-31 -- V04 -- David Vásquez	-- Versión automatizable en server SAS
/* 2021-08-31 -- V03 -- David Vásquez	-- Actualización con correciones a observaciones de Francisco Toledo
/* 2021-08-27 -- V02 -- David Vásquez	-- Versión actualizada para automatización en server SAS
/* 2021-08-25 -- V01 -- José Aburto		-- Versión Original actualizada

------------------------------
 DURACIÓN TOTAL:   0:14:11.83
------------------------------
*/

/*	VARIABLE TIEMPO	- INICIO VARIABLES	*/

%let tiempo_inicio= %sysfunc(datetime());
options validvarname=any;

DATA _null_;
	datemy = input(put(intnx('month',today(),-2,'end'),yymmn6. ),$10.);	/* cambiar a -2 si no se ejecuta en mes actual*/
	Call symput("fechamy", datemy);
RUN;

%put &fechamy;

/*============================= 1.0 parte Base Matriz desde Riesgo   =================================*/
/* Base + 1 campaña */
DATA _null_;
	datemi = input(put(intnx('month',today(),0,'end'),yymmn6. ),$10.); /*modificar a 0 si no se ejecuta en el mes actual*/
	Call symput("fechami", datemi);
RUN;

%put &fechami;

/*====== de aqui solo se ocupa el rut ========*/
/*====== OJO : Solicitado a jonh benomeisonn dejar el periodo al final, para llamarla por Macros ========*/
PROC SQL;
	CREATE TABLE base_repricing_riesgo_&fechami AS 
		SELECT t1.RUT
			FROM PUBLICRI.REPRICING_SAV_PRE_&fechami. t1
	;
QUIT;

/*====== Funcionarios de prueba solicitados incorporar a jonathan por Fransisco Toledo ==========*/
/*====== cambiar origen de pruebas si es necesario ==========*/
PROC SQL;
	CREATE TABLE rut_Pruebas_motor AS 
		SELECT t1.RUT
			FROM jaburtom.rut_Pruebas_motor t1;
QUIT;

/*====================  1.1 Base final para pegada de variables  =====================================*/
/*====== Ejercicio esta sobre  Agosto 2021 / Cantidad base + funcionarios  1.234.858 + 4 =========*/
PROC SQL;
	CREATE TABLE repricing_riesgo_Final_&fechami as
		Select * from base_repricing_riesgo_&fechami
			outer union corr
				select * from rut_Pruebas_motor
	;
quit;

/*##################################################################################*/
/*Actualizacion Variables del motor de precios*/
/*##################################################################################*/
%put=============================================================================;
%put [01] activityReference : Actividad de Tarjeta (Actividad_TR);
%put=============================================================================;

proc sql;
	create table work.activityReference as 
		select 
			rut,
		case 
			when ACTIVIDAD_TR='ACTIVO' then 4 
			when ACTIVIDAD_TR='SEMIACTIVO' then 3 
			when ACTIVIDAD_TR='NUEVO SIN USO' then 0  
			when ACTIVIDAD_TR='OTROS CON SALDO' then 5 
			when ACTIVIDAD_TR='DORMIDO BLANDO' then 2 
			when ACTIVIDAD_TR='DORMIDO DURO' then 1 
		end 
	as activityReference 
		from publicin.ACT_TR_&fechamy /*Cambiar Periodo*/
	;
quit;

%put=============================================================================;
%put [02] productTypeReference : Propension del producto (SAV);
%put=============================================================================;

/*Valor de propension de SAV de 0 a 99 (lo debe entregar Advance A.)*/


PROC SQL;
	CREATE TABLE productTypeReference AS 
		SELECT t1.RUT as rut,
			input(substr(t1.RANGO_PROB,1,3),best.)*100 as productTypeReference 
		FROM JABURTOM.SCORE_SAV_ADVA_&fechami. t1
	;
QUIT;


%put=============================================================================;
%put [03] productPropensitychannel : Canal Preferente;
%put=============================================================================;

/*No se envia, al parecer queda el espacio disponible, pero nunca se envio*/
%put=============================================================================;
%put [04] inactivityPeriod : Meses de Inactividad (Recencia_TR);
%put=============================================================================;

proc sql;
	create table work.inactivityPeriod as 
		select 
			rut,
			RECENCIA_TR as inactivityPeriod  
		from publicin.ACT_TR_&fechamy /*Cambiar Periodo*/
	where RECENCIA_TR is not null 

	;
quit;

%put=============================================================================;
%put [05] customerRelationhipRating : Grupo SocioEconomico (GSE);
%put=============================================================================;

proc sql;
	create table work.customerRelationhipRating as 
		select 
			rut,
		case 
			when GSE in ('AB','C1') then 'ABC1'
			else GSE 
		end 
	as customerRelationhipRating  
		from publicin.DEMO_BASKET_&fechamy /*Cambiar Periodo*/
	where GSE is not null 

	;
quit;

%put=============================================================================;
%put [06] customerBehaviorModelType : Cliente digital (Perfil Digital);
%put=============================================================================;

DATA _null_;
	datemy = input(put(intnx('month',today(),-2,'end'),yymmn6. ),$10.); /* cambiar a -2 si no se ejecuta en mes actual*/
	Call symput("fechamy", datemy);
RUN;

%put &fechamy;

proc sql;
	create table work.customerBehaviorModelType as 
		select 
			rut,
		case 
			when DIGITALIZACION_IN='FULL_DGL' then 3 
			when DIGITALIZACION_IN='MEDIO_DGL' then 2 
			when DIGITALIZACION_IN='BAJO_DGL' then 1 
			when DIGITALIZACION_IN='NO_DGL' then 0 
		end 
	as customerBehaviorModelType  
		from publicin.PERFIL_DIGITAL_&fechamy /*&fechamy /*Cambiar Periodo estaba apuntando a epiel del periodo 202102*/
	;
quit;

%put=============================================================================;
%put [07] customerRelationshipStatus : Recencia de producto;
%put=============================================================================;

/*Variable igual a una anterior, por lo que no se manda (o se manda en blanco)
Por tanto, es un espacio valioso disponible para a futuro enviar otra variable*/
%put=============================================================================;
%put [08] customerBehaviorModelOther : Indicador de tenencia de otros Bancos;
%put=============================================================================;

proc sql;
	create table work.customerBehaviorModelOther as 
		select 
			rut,
		case 
			when Banco_Secundario='Falabella' then 1 
			when Banco_Secundario='Estado' then 2 
			when Banco_Secundario='Security' then 3 
			when Banco_Secundario='BBVA' then 4 
			when Banco_Secundario='BICE' then 5 
			when Banco_Secundario='Santander' then 6 
			when Banco_Secundario='BCH' then 7  
			when Banco_Secundario='BCI' then 8   
			when Banco_Secundario='ScotiaBank' then 9   
			when Banco_Secundario='CorpBanca' then 10 
			else 11  
		end 
	as customerBehaviorModelOther  
		from PUBLICIN.SGDO_BCO_&fechamy /*Cambiar Periodo*/
	;
quit;

%put=============================================================================;
%put [09] productReference : Indicador de Vinculacion (Principalidad_TCTD);
%put=============================================================================;

proc sql;
	create table work.productReference as 
		select 
			rut,
		case 
			when round(100*RFM_Total)>=100 then 99 
			else round(100*RFM_Total) 
		end 
	as productReference  /* Corresponde a RFM */
	from publicin.PRINCIPALIDAD_TCTD_&fechamy /*Cambiar Periodo*/
	;
quit;

%put=============================================================================;
%put [10] : Modelo de Propension AV;
%put=============================================================================;

/*NUEVA VARIABLE NO ENTREGADA EN PRIMERA ITERACION (FUE SOLICITADA QUE SE AGREGARA)
Valor de propension de AV de 0 a 99 (lo debe entregar Advance A.)*/

/* IDEM SAV de Base de ANALITISC ***/
/*  1 Siempte ****/

PROC SQL;
	CREATE TABLE propensityAdvance AS 
		SELECT t1.RUT as rut,
			input(substr(t1.RANGO_PROB,1,3),best.)*100 as propensityAdvance 
		FROM JABURTOM.SCORE_SAV_ADVA_&fechami. t1
	;
QUIT;


%put=============================================================================;
%put [11] : Modelo de Propension Consumo;
%put=============================================================================;

/*NUEVA VARIABLE NO ENTREGADA EN PRIMERA ITERACION (FUE SOLICITADA QUE SE AGREGARA)
Valor de propension de Cons de 0 a 99 (lo debe entregar Advance A.)*/

PROC SQL;
   CREATE TABLE WORK.propensityConsumption AS 
   SELECT t1.RUT,  /*se quita la función input para que el proceso corra correctamente*/
          t1.PROP_DESAFIANTE, 
          t1.RANGO_BCO,
		  (t1.RANGO_BCO * 10)AS propensityConsumption
      FROM PUBLICRI.SCORE_DESAFIANTE_&fechami. t1;
QUIT;


%put=============================================================================;
%put [12] : Modelo de Elasticidad;
%put=============================================================================;

/*NUEVA VARIABLE NO ENTREGADA EN PRIMERA ITERACION (FUE SOLICITADA QUE SE AGREGARA)
Valor de elasticidad que debe contener 3 valores: alto, medio, bajo 
(lo debe entregar Advance A.)*/


%put=============================================================================;
%put [13] : Rentabilidad total de cliente;
%put=============================================================================;

/*NUEVA VARIABLE NO ENTREGADA EN PRIMERA ITERACION (FUE SOLICITADA QUE SE AGREGARA)
Valor de rentabilidad entregado como decil/veintil  
(lo debe entregar Advance A.)*/

/*===============================================================================*/
/*===================  	CRUCE DE VARIABLES MOTOR		=========================*/
/* 1234858 + 4 ,esto OK*/

PROC SQL;
	CREATE TABLE cruce_variables_motor_1 AS 
		SELECT t1.RUT,
			t2.activityReference,              /* todos los vacios con -9 segun data excel*/
	t3.customerBehaviorModelOther,     /* todos los vacios con -9 segun data excel*/
	t4.customerBehaviorModelType,      /* todos los vacios con -9 segun data excel*/
	t5.customerRelationhipRating,      /* todos los vacios con X segun data excel*/
	t6.inactivityPeriod,               /* todos los vacios con -9 segun data excel*/
	t7.productReference,               /* todos los vacios con -9 segun data excel*/
	t8.productTypeReference,            /* todos los vacios con -9 segun data excel*/
	t9.propensityAdvance,            /* todos los vacios con -9 segun data excel (AVANCE) 29-08-2022*/
	t10.propensityConsumption            /* todos los vacios con -9 segun data excel (CONSUMO)29-08-2022*/
	FROM WORK.REPRICING_RIESGO_FINAL_&fechami t1
		LEFT JOIN WORK.ACTIVITYREFERENCE t2 ON (t1.RUT = t2.RUT)
		LEFT JOIN WORK.CUSTOMERBEHAVIORMODELOTHER t3 ON (t1.RUT = t3.RUT)
		LEFT JOIN WORK.CUSTOMERBEHAVIORMODELTYPE t4 ON (t1.RUT = t4.RUT)
		LEFT JOIN WORK.CUSTOMERRELATIONHIPRATING t5 ON (t1.RUT = t5.RUT)
		LEFT JOIN WORK.INACTIVITYPERIOD t6 ON (t1.RUT = t6.RUT)
		LEFT JOIN WORK.PRODUCTREFERENCE t7 ON (t1.RUT = t7.rut)
		LEFT JOIN WORK.productTypeReference t8 ON (t1.RUT = t8.rut)
		LEFT JOIN WORK.propensityAdvance t9 ON (t1.RUT = t9.rut)
		LEFT JOIN WORK.propensityConsumption t10 ON (t1.RUT = t10.rut)
	;
QUIT;

/*==================================================================================================*/
/*=======================	Actualiza data Missing explicadas en data excel		============================*/

PROC SQL noprint;
	Update cruce_variables_motor_1
		set activityReference = -9
			where activityReference is missing
	;
	Update cruce_variables_motor_1
		set customerBehaviorModelOther = -9
			where customerBehaviorModelOther is missing
	;
	Update cruce_variables_motor_1
		set customerBehaviorModelType = -9
			where customerBehaviorModelType is missing
	;
	Update cruce_variables_motor_1
		set customerRelationhipRating = 'X'
			where customerRelationhipRating is missing
	;
	Update cruce_variables_motor_1
		set inactivityPeriod = -9
			where inactivityPeriod is missing
	;
	Update cruce_variables_motor_1
		set productReference = -9
			where productReference is missing
	;
	Update cruce_variables_motor_1
		set productTypeReference = -9
			where productTypeReference is missing
	;
	Update cruce_variables_motor_1
		set propensityAdvance = -9
			where propensityAdvance is missing
	;
	Update cruce_variables_motor_1
		set propensityConsumption = -9
			where propensityConsumption is missing
	;
quit;

/*==================================================================================================*/
/*================== Parte de formato (RUT DV),revision y Orden de variables    =====================*/


options cmplib=sbarrera.funcs;

PROC SQL ;
	CREATE TABLE Revision_variables AS  
		SELECT /*t1.customerIdentification,*/
	cats(t1.RUT,UPCASE(SB_DV(t1.RUT))) as customerIdentification,
	/*  t1.DV as dv, */
	t1.activityReference,
	t1.productTypeReference,
	0 as productPropensitychannel, /* va por defecto en formato del archivo , Indicaciones de Joaquin */
	t1.inactivityPeriod,
	t1.customerRelationhipRating,
	t1.customerBehaviorModelType,
	0 as customerRelationshipStatus, /* va por defecto en formato del archivo , Indicaciones de Joaquin */
	t1.customerBehaviorModelOther, 
	t1.productReference,
	'-9,99' as elasticity,
	-9 as rentability,
	t1.propensityAdvance,
	t1.propensityConsumption
	FROM WORK.cruce_variables_motor_1 t1
	;
QUIT;

/*==================================================================================================*/
/*================= Formatear el Rut con 00 a la izquierda y un largo de 10    =====================*/
/*data de salida final***/
/* con el Orden de variables incicadas por david */

PROC SQL;
	CREATE TABLE Salida_final AS  
		SELECT 
			distinct cats(repeat('0', 10-length(t1.customerIdentification)-1), customerIdentification)as customerIdentification,
			t1.activityReference,
			t1.productTypeReference,
			t1.productPropensitychannel,
			t1.inactivityPeriod,
			t1.customerRelationhipRating,
			t1.customerBehaviorModelType,
			t1.customerRelationshipStatus, 
			t1.customerBehaviorModelOther, 
			t1.productReference,
		    t1.elasticity, /*agregado 29-08-2022*/
	        t1.rentability, /*agregado 29-08-2022*/
	        t1.propensityAdvance, /*agregado 29-08-2022*/
	        t1.propensityConsumption, /*agregado 29-08-2022*/
			'' as punto_y_coma
		FROM WORK.Revision_variables t1
		order by 1 
	;
QUIT;

PROC SQL;
	CREATE TABLE RESULT.variables_motor_precio AS  
		SELECT * FROM WORK.Salida_final t1
	;
QUIT;

PROC SURVEYSELECT noprint DATA= Salida_final 
	OUT=revisa_largo_rut
	METHOD=SRS
	N= 2
	/*SEED=1*/
	;
QUIT;

/************************************ VALIDA LARGO RUT ********************************/
proc sql;
	create table LARGO as
		select length(customerIdentification) as largo_customerIdentification
			from revisa_largo_rut
	;
quit;

/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*****************  DAVID DEBE GENERAR LA BASE DE SALIDA Y FORMATO A RUTA FPT  ******************/

/******* disponibilidad al equipo de fransisco toledo de  David para procesos Automatico ************
desde ruta indicada en archivo indicado por joaquin ***/

/* SALIDA SEGUN ORDEN DE JOAQUIN  - SIMEPRE DEBE IR IGUAL SIN ENCABEZADO ****/

/*
CREATE TABLE Vista_Motor_Pricing_2(
customerIdentification      VARCHAR(10),
activityReference           NUMERIC,
productTypeReference        NUMERIC,
productPropensitychannel    NUMERIC,
inactivityPeriod            NUMERIC,
customerRelationhipRating   VARCHAR(10),
customerBehaviorModelType   NUMERIC,
customerRelationshipStatus  NUMERIC,
customerBehaviorModelOther  NUMERIC,
productReference            FLOAT
propensityAdvance,          NUMERIC,
propensityConsumption,      VARCHAR
);
COMMIT;*/


PROC EXPORT DATA = Salida_final
	OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/Variables_Motor_Precio/VISTA_MOTOR_PRICING_DATA_TABLE.txt"
	DBMS=dlm REPLACE;
	delimiter=';';
	PUTNAMES=NO;
RUN;

/* EXPORTAR DE SAS A UN FTP O SFTP  - VALIDADO OK */
filename server ftp "VISTA_MOTOR_PRICING_DATA_TABLE.txt" CD='/bas_04/sat/ripley/ripprod/dat' 
	HOST='192.168.84.65' user='ftppric' pass='wHZLo9tItHTyD7wU' PORT=21;

data _null_;
	infile "/sasdata/users94/user_bi/TRASPASO_DOCS/Variables_Motor_Precio/VISTA_MOTOR_PRICING_DATA_TABLE.txt";
	file server;
	input;
	put _infile_;
run;

x " gzip /sasdata/users94/user_bi/TRASPASO_DOCS/Variables_Motor_Precio/VISTA_MOTOR_PRICING_DATA_TABLE.txt";

/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN);
RUN;

%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JOSE_ABURTO';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'CRISTIAN_PEREZ';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;

FILENAME	output EMAIL
	FROM 	= ("&EDP_BI")
	TO		= ("&DEST_1","&DEST_4","nlizamac@bancoripley.com")
	CC		= ("&DEST_2","&DEST_3")
	ATTACH	= "/sasdata/users94/user_bi/TRASPASO_DOCS/Variables_Motor_Precio/VISTA_MOTOR_PRICING_DATA_TABLE.txt.gz"
	SUBJECT	= "MAIL_AUTOM: Variables motor de precio" CONTENT_TYPE="text/html"	
	CT		= "text/html";
ODS LISTING CLOSE;
ODS HTML path	= "/sasdata/users94/user_bi" file = "Variables_Motor_Precios_final.lst" (URL=none) BODY=output STYLE=sasweb;
TITLE height=10pt J=left color=black;
TITLE color = black 
	"Estimados:";
TITLE2 height=10pt color=black	
	"	Proceso ejecutado con fecha de hoy &fechaeDVN";
TITLE3 height=10pt color=black 
	" 	Archivos depositados en server 192.168.84.65 - /bas_04/sat/ripley/ripprod/dat";
TITLE4 height=10pt color=blue	
	" ";
TITLE5 height=10pt color=black	
	" Proc. Vers. 14 - Miró fechamy: &fechamy. y fechami: &fechami.";
footnote "Gracias, Saludos, Equipo BI.";

PROC PRINT DATA=LARGO NOOBS;
RUN;

FILENAME OUTBOX CLEAR;
ODS HTML CLOSE;
ODS LISTING;

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;
