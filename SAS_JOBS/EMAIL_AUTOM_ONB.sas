/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	EMAIL_AUTOM_ONBOARDING 		================================*/

/* CONTROL DE VERSIONES
/* 2022-02-02 ---- V02 -- David V. -- Se quita filtro de Auris en la base de salida y optimiza query
/* 2022-04-27 ---- V01 -- David V. -- Inicialmente igual al EMAIL_AUTOM pero sin filtros sernac y suprimidos
 */

/*==================================================================================================*/

*  ====================================================================
*  Nombre del proceso almacenado: EMAIL_AUTOM_ONBOARDING - PARTE 1
*  ====================================================================
*;

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*	VARIABLE LIBRERÍA			*/
%let libreria_1  = PUBLICIN; /*PUBLICIN*/
%let libreria_2  = PUBLICIN; /*RESULT*/
options validvarname=any;

DATA _null_;
	/* DECLARACIÓN VARIABLES FECHAS*/
	dateDIA	= compress(substr(put(today(),ddmmyy10.),7,4)||substr(put(today(),ddmmyy10.),4,2)||substr(put(today(),ddmmyy10.),1,2));
	Call symput("VdateDIA", dateDIA);
	dateMES	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
	Call symput("VdateMES", dateMES);
RUN;

%put &VdateDIA;
%put &VdateMES;

/*=========================================================================================*/
/* CALCULAR CONTACTABILIDAD - NOTA  - Se conservan registros aunque estén suprimidos 	   */
/*=========================================================================================*/
PROC SQL ;
	CREATE TABLE CALCULO_NOTA_VU_&VdateMES AS 
		SELECT t1.rut, 
			t1.EMAIL, 
			(t1.MRC_BOPERS_ACL_VER+ 
			t1.MRC_SUPPRESSED+ 
			t1.MRC_HardBounce+
			t1.MRC_BOPERS+ 
			t1.MRC_EMAIL_APER_3M+ 
			t1.MRC_EMAIL_SENT_3M+
			t1.APERTURAS_3M) AS NOTA,
			t1.APERTURAS_3M AS APERTURAS,
			t1.MRC_BOPERS,
			t1.ORI_CANAL
		FROM RESULT.NOTA_RANK_NEW_2020 t1 WHERE t1.MRC_HardBounce = 0 
			/*and t1.MRC_SUPPRESSED <> -20*/
	;
QUIT;

PROC SQL;
	CREATE TABLE MAXIMO_NOTA_VU_&VdateMES AS 
		SELECT t1.rut, (MAX(t1.NOTA)) AS NOTA
			FROM CALCULO_NOTA_VU_&VdateMES t1
				GROUP BY t1.rut;
QUIT;

PROC SQL;
	CREATE TABLE ELIGE_MAXIMO_NOTA_&VdateMES AS 
		SELECT t1.rut, 
			t1.NOTA, 
			T2.EMAIL,
			T2.APERTURAS,
			t2.MRC_BOPERS,
			t2.ORI_CANAL
		FROM MAXIMO_NOTA_VU_&VdateMES t1 INNER JOIN CALCULO_NOTA_VU_&VdateMES T2 ON (T1.RUT=T2.RUT);
QUIT;

/* MEJORES MAILS SEGÚN NOTA */
PROC SQL;
	CREATE TABLE MEJORES_EMAIL_NOTA_AP AS 
		SELECT 	DISTINCT t1.rut, 
			T2.EMAIL, 
			CASE WHEN t1.APERTURAS < 1 	then 0 
		  	ELSE t1.APERTURAS END as APERTURAS,
			t2.nota, 
			t2.MRC_BOPERS, 
			t2.ORI_CANAL
		FROM ELIGE_MAXIMO_NOTA_&VdateMES t1 
			INNER JOIN CALCULO_NOTA_VU_&VdateMES T2 
				ON (T1.RUT = T2.RUT AND t1.nota = T2.NOTA)  
			where t1.rut < 99999999 and t1.rut > 10000
	;
QUIT;

/*ELIMINA RUTS DUPLICADOS*/
proc sort data=MEJORES_EMAIL_NOTA_AP out=&libreria_2..MEJORES_EMAIL_NOTA_ONB_&VdateMES 
	nodupkeys dupout=duplicados;
	by RUT;
run;

/* BASE EMAIL SIN EXCLUSIONES O SIN FILTROS APLICADOS */
PROC SQL;
	CREATE TABLE &libreria_1..BASE_TRABAJO_EMAIL_ONB AS 
		SELECT 	*
			FROM &libreria_2..MEJORES_EMAIL_NOTA_ONB_&VdateMES
	;
QUIT;

/*se crea base_trabajo_email_se_info donde solo se excluyen clientes puntuales para comunicacion informativa */
/*PROC SQl;*/
/*	CREATE TABLE LNEGRO_EMAIL AS */
/*		SELECT DISTINCT  RUT*/
/*			FROM publicin.lnegro_email */
/*				WHERE motivo not in ('EMAIL_NO_CORRESPONDE','AURIS') */
/*	;*/
/*quit;*/
proc sql;
	create table &libreria_1..BASE_TRABAJO_EMAIL_ONB as 
		select 
			distinct t1.*
		from PUBLICIN.BASE_TRABAJO_EMAIL_ONB t1
			left join publicin.lnegro_car t2
				on (t1.rut=t2.rut)
			left join publicin.LNEGRO_EMAIL t3
				on (t1.rut=t3.rut)
			where 
				t2.tipo_inhibicion not in ('FALLECIDO','FALLECIDOS','COMPLIANCE','INTER',
				'LISTA_NEGRA_CAR','LRI','NO MAS PROMOCIONES','PEP',
				/*'SERNAC','SERNAC_BCO',*/
				'SIR','TRIBUNAL')
				AND T3.motivo not in ('ANTIGUO','EMAIL_NO_CORRESPONDE','NO_COMUNICACION'
				)
				/*,'RIESGO','ECCSA','BANCO','CAR','AURIS','SERNAC','SERNAC_BCO','SERNAC_CAR','SERNAC_ECCSA','SERNAC_ECSSA',
				'SERNAC_SEG','SERNAC_SEGUROS'*/
	;
quit;

/*EXCLUSIONES PUNTUALES SOLICITADAS*/
PROC SQL;
	CREATE TABLE BASE_TRABAJO_EMAIL_EPUNT AS 
		SELECT t1.RUT, 
			t1.EMAIL, 
			t1.MRC_BOPERS,
			t1.APERTURAS,
			t1.NOTA,
			t1.ORI_CANAL
		FROM &libreria_1..BASE_TRABAJO_EMAIL_ONB T1 LEFT JOIN POLAVARR.EXCLUSIONES_PUNTUALES T2
			ON (T1.RUT = T2.RUT AND T1.EMAIL = T2.EMAIL) where T2.RUT IS MISSING
	;
QUIT;

PROC SQL;
	CREATE TABLE BASE_TRABAJO_EMAIL_WEBBULA AS 
		SELECT T1.RUT,
			T1.EMAIL,
			T1.MRC_BOPERS,
			T1.APERTURAS,
			T1.NOTA,
			T1.ORI_CANAL
		FROM BASE_TRABAJO_EMAIL_EPUNT T1 
			LEFT JOIN POLAVARR.WEBBULA_EXCLUSION T2
				ON (T1.RUT=T2.RUT AND T1.EMAIL=T2.EMAIL)
			WHERE T2.RUT IS NULL AND T2.EMAIL IS NULL
	;
quit;


PROC SQL;
	CREATE TABLE &libreria_1..BASE_TRABAJO_EMAIL_ONB AS 
		SELECT t1.RUT, 
			t1.EMAIL, 
			t1.MRC_BOPERS,
			t1.APERTURAS,
			t1.NOTA,
			t1.ORI_CANAL
		FROM BASE_TRABAJO_EMAIL_WEBBULA 	T1 
	;
QUIT;

PROC SQL;
	CREATE INDEX rut ON &libreria_1..BASE_TRABAJO_EMAIL_ONB (rut);
QUIT;

/*=========================================================================================*/
/* FIN - CALCULAR CONTACTABILIDAD - NOTA */
/*=========================================================================================*/

/*  ==========================================================================*/
/*  Nombre del proceso almacenado: EMAIL_AUTOM_ONBOARDING - TERMINADA 		  */
/*  ==========================================================================*/

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */

/*	Fecha ejecución del proceso	*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN);
RUN;

%put &fechaeDVN;/*fecha ejecucion proceso */

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CONTACTABILIDAD';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;

data _null_;
	FILENAME OUTBOX EMAIL
		FROM = ("&EDP_BI")
		TO = ("&DEST_1","&DEST_2")
		CC = ("&DEST_3")
		SUBJECT = ("MAIL_AUTOM: PROCESO EMAIL_AUTOM_ONBOARDING");
	FILE OUTBOX;
	PUT "Estimados:";
	put "		Proceso de contactabilidad EMAIL_AUTOM_ONBOARDING, ejecutado con fecha: &fechaeDVN";
	PUT;
	PUT;
	put 'Proceso Vers. 02';
	PUT;
	PUT;
	PUT 'Atte.';
	Put 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;

FILENAME OUTBOX CLEAR;
