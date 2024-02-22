/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	EMAIL_AUTOM			 		================================*/
/* CONTROL DE VERSIONES
/* 2022-07-05 ---- V22 -- David V.	 -- Se comenta parte del código, filtro email not LIKE	('% %') 
/* 2022-04-27 ---- V21 -- David V.	 -- Actualizar código para que la nota 0 quede en la tabla final, y no se vea vacío al igual que aperturas.
/* 2022-04-04 ---- V20 -- Esteban P. --Se actualizan correos: Se reemplaza a Pía Olavarría por "PM_CONTACTABILIDAD".
/* 2022-03-10 ---- v19 - se inhiben de escritura los origenes del quiero se cliente por tema de legal en cuanto al uso de los datos del cliente, se volveran a agregar una vez que el area legal asi lo permita */
/* 2021-07-26 ---- v18 - Se agrega paso intermedio para poner en mayuscula los correos del lnegro_email 
/* 2021-06-15 ---- v17 - Solución a x que faltaba en un cruce y a filtro adicional erróneo 
/* 2021-06-10 ---- v16 - Se quitan tablas asociadas a librería DVASQUEZ 
/* 2021-05-13 ---- v15 - Se excluyen nuevos casillas erroneas 
/* 2021-05-11 ---- v14 - SE EXCLUYEN EMAIL MALOS (ANALISIS DE WEBBULA) AL FINAL DEL PROCESO.
/* 2021-04-23 ---- v13 - SE CAMBIA LIBRERIA E EXCLUSIONES PUNTUALES 
/* 2021-04-13 ---- V12 - SE CAMBIA LIBRERIA DE BASES CHEK Y QSC (AHORA SE BUSCA EN PUBLICIN), ademas se agregan casillas mal escritas desde analisis de webbula
/* 2021-01-11 ---- v11 - Se agrega base, donde se excluyen fallecidos para comunicacion informativa. (base_trabajo_email_se_info)
/* 2020-11-12 ---- v10 - Se elimina el ingreso de datos de LPF (soliictado por Paola )
(* 2020-10-30 ---- V9 - Se agrega base de LPF como nuevo ingreso de datos (sequencia 13)
/* 2020-10-05 ---- V8 - Corrección a Correos Fake librería Pía y quitar OTMAIL.COM de exclusiones
/* 2020-08-27 ---- Simulaciones desde librería Pía y otros correos Fake
/* 2020-08-20 ---- Correos falsos agregados
/* 2020-07-23 ---- Correción al agregado de base Corrimiento
/* 2020-07-22 ---- Se incluye medición de tiempo de ejecución y envío de correo al final, además
				 - Actualizaciones realizadas por Pía :
				 - Agrega información de Corrimiento Cuota
				 - Cambia origen de datos de ripley_com a librería de Pía
/* 2020-06-23 ---- 	Quitar respaldo diario de RESULT.NOTA_RANK_NEW
					Crear respaldo Sin filtros LNegros Aplicados (PUBLICIN.BASE_TRABAJO_EMAIL_SE)
/* 2020-05-07 ---- Corrección al calculo de Nota, agrega aperturas */ 
*/
/*==================================================================================================*/

*  ====================================================================
*  Nombre del proceso almacenado: EMAIL_AUTOMATICO_3.0 - PARTE 1
*  ====================================================================
*;

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

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
/*======	Respaldo tabla Anterior de Emails		=======================================*/
/*=========================================================================================*/

proc sql;
	create table RESULT.BASE_TRABAJO_EMAIL_&VdateMES AS
		SELECT * FROM PUBLICIN.BASE_TRABAJO_EMAIL
;quit;

/*proc sql;
	create table RESULT.BASE_TRABAJO_EMAIL_&VdateDIA AS
		SELECT * FROM PUBLICIN.BASE_TRABAJO_EMAIL as T1
;quit;*/

/*PROC SQL;
CREATE INDEX RUT ON RESULT.BASE_TRABAJO_EMAIL_&VdateDIA  (RUT);
QUIT;*/

/*proc sql;
	create table RESULT.NOTA_RANK_NEW_&VdateDIA AS
		SELECT * FROM result.NOTA_RANK_NEW_2020
;quit;*/

proc sql;
	create table RESULT.NOTA_RANK_NEW_&VdateMES AS
		SELECT * FROM result.NOTA_RANK_NEW_2020
;quit;

/*=========================================================================================*/
/*======	1.- Obtener Emails desde: las TEFs		=======================================*/
/*=========================================================================================*/
%let mz_connect_BANCO=CONNECT TO ORACLE as BANCO(USER='RIPLEYC' PASSWORD='ri99pley'
PATH="(DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP) (Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SERVICE_NAME = ripleyc)(SERVER = DEDICATED)))"); 

proc sql; 
	&mz_connect_BANCO; 
		create table RESULT.R_TEFs as 
			select	 MTIFO_RUN_CLI_ORE as rut, 
			         COMPRESS(UPCASE(MTIFO_NOM_MAI_ORE)) as email length=50,
					 input(put(datepart(MTIFO_FCH_ING_TRS),yymmddn8.),best.) as FECHA_ACT
			from	connection to BANCO(
										select *
										from BOTEF_ADM.BOTEF_MOV_TRN_IFO 
										where MTIFO_FLG_EST_TRS = 2 /*TRXs correcta*/
									  ) as C2_Emisor
			WHERE 	MTIFO_NOM_MAI_ORE IS NOT NULL
;QUIT;

PROC SQL;
   CREATE TABLE RESULT.R_CORREOS_TEF_MAX AS 
   SELECT distinct t1.RUT, 
          t1.email 	AS EMAIL, 
          MAX(t1.FECHA_ACT) AS FECHA_ACT
      FROM RESULT.R_TEFs t1
      GROUP BY t1.rut;
QUIT;

/*Tomar el registro de fecha máxima de TEFs*/
proc sql;
create table RESULT.BASE_EMAIL_TEFs AS
	SELECT	DISTINCT T1.RUT, 
	        T1.EMAIL, 	      
			t2.FECHA_ACT
	    FROM RESULT.R_CORREOS_TEF_MAX t1 INNER JOIN RESULT.R_TEFs T2
			ON (T1.RUT = T2.RUT AND T1.FECHA_ACT = T2.FECHA_ACT AND T1.EMAIL = T2.EMAIL)
		WHERE T2.FECHA_ACT IS NOT MISSING AND T2.RUT < 99999999 AND T2.RUT > 10000
	AND t1.email not LIKE	('.-%')				AND t1.email not LIKE	('%.')
	AND t1.email not LIKE	('-%')				AND t1.email not LIKE	('%.@%')
	/*AND t1.email not LIKE	('% %')*/
    AND t1.email not CONTAINS 	('XXXXX')
	AND t1.email not CONTAINS 	('DEFAULT')		AND t1.email not CONTAINS 	('TEST@')
	AND t1.email not CONTAINS 	('..')			AND t1.email not CONTAINS 	('PRUEBA')
	AND t1.email not CONTAINS	('(')			AND t1.email not CONTAINS 	(')')
	AND t1.email not CONTAINS	('/')			AND t1.email not CONTAINS	('?')
	AND t1.email not CONTAINS 	('¿')			AND t1.email not CONTAINS 	('SINMAIL')
	AND t1.email not CONTAINS 	('NOTIENE')		AND t1.email not CONTAINS 	('NOTENGO')
	AND t1.email not CONTAINS 	('SINCORRE')	AND t1.email not CONTAINS 	('TEST@')
	AND t1.email <>'@'							AND t1.email not CONTAINS	('GFFDF')
	AND t1.email not CONTAINS 	('0000000')		AND t1.email not CONTAINS 	('GMAIL.CL')
	AND t1.email not CONTAINS 	('GMAIL.ES')	AND t1.email <>'0'
	AND t1.email CONTAINS 	('@')				AND t1.email not CONTAINS 	('SINEMAIL')
	AND t1.email not CONTAINS 	('NOREGISTRA')  AND t1.email not CONTAINS 	('SINMALLIL')
	AND t1.email not CONTAINS 	('@MAILINATOR.COM')	AND t1.email not CONTAINS	('@MICORREO.COM')	
	AND t1.email not CONTAINS 	('@HOTRMAIL.COM')	AND t1.email not CONTAINS	('@SDFDF.CL' )
	/*agregado pia*/
	 AND t1.email not CONTAINS ('HORTMAIL.COM')       AND t1.email not CONTAINS ('REPLEY.COM')
	 AND t1.email not CONTAINS ('BANCPORIPLEY.COM')       AND t1.email not CONTAINS ('GMAL.COM')
	 AND t1.email not CONTAINS ('RILPLEY.COM')       AND t1.email not CONTAINS ('HOTMAI.COM')
	 AND t1.email not CONTAINS ('GAMIL.COM')       AND t1.email not CONTAINS ('RIPEY.CL')
	 AND t1.email not CONTAINS ('RIPLEY.VOM')       AND t1.email not CONTAINS ('HTOMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.CON')       AND t1.email not CONTAINS ('GMIL.COM')
	 AND t1.email not CONTAINS ('HOTAMIL.COM')       AND t1.email not CONTAINS ('123MAIL.CL')
	 AND t1.email not CONTAINS ('ICLOOUD.COM')       AND t1.email not CONTAINS ('YMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMIAL.COM')       AND t1.email not CONTAINS ('GMAI.COM')
	 AND t1.email not CONTAINS ('HOTMAIL.OM')       AND t1.email not CONTAINS ('GMAIIL.COM')
	 AND t1.email not CONTAINS ('RIOLPLEY.COM')       AND t1.email not CONTAINS ('aol.com')
	 AND t1.email not CONTAINS ('GMSAIL.COM')       AND t1.email not CONTAINS ('ICLOU.COM')
	 AND t1.email not CONTAINS ('GMAIL.CM')       AND t1.email not CONTAINS ('GMIAL.COM')
	 AND t1.email not CONTAINS ('UAHOO.COM')       AND t1.email not CONTAINS ('HOTMAIL.OCM')
	 AND t1.email not CONTAINS ('GMAILC.OM')       AND t1.email not CONTAINS ('UTLOOOK.COM')
	 AND t1.email not CONTAINS ('RIPLE.COM')       AND t1.email not CONTAINS ('GMAILL.COM')
	 AND t1.email not CONTAINS ('GMAOL.COM')       AND t1.email not CONTAINS ('HORMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMAL.COM')       /*AND t1.email not CONTAINS ('OTMAIL.COM')*/
	 AND t1.email not CONTAINS ('2HOTMAIL.ES')       AND t1.email not CONTAINS ('XXX.COM')
	 AND t1.email not CONTAINS ('AUTLOOK.COM')       AND t1.email not CONTAINS ('8GMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMN')       AND t1.email not CONTAINS ('OITLOOK.COM')
	 AND t1.email not CONTAINS ('OUTLOCK.COM')       AND t1.email not CONTAINS ('GMAIL.OM')
	 AND t1.email not CONTAINS ('GMAIL.LCOM')       AND t1.email not CONTAINS ('OUTLLOK.CL')
	 AND t1.email not CONTAINS ('OULOOCK.ES')       AND t1.email not CONTAINS ('OULOOKS.ES')
	 AND t1.email not CONTAINS ('GAMIAL.COM')       AND t1.email not CONTAINS ('HOTMAILL.COM')
	 AND t1.email not CONTAINS ('GMAIL.CPM')       AND t1.email not CONTAINS ('64GMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIOL.COM')
	 /*agregado email Lore Gerrero*/
     	 AND t1.email not CONTAINS ('yahho.com')       AND t1.email not CONTAINS ('EMAIL.CON')
	 AND t1.email not CONTAINS ('OUTLOKK.ES')       AND t1.email not CONTAINS ('HORMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.VOM')       AND t1.email not CONTAINS ('YAHOO.CL')
	 AND t1.email not CONTAINS ('GMEIL.CL')       AND t1.email not CONTAINS ('GMAKL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COL')       AND t1.email not CONTAINS ('GMAIL.COMO')
	 AND t1.email not CONTAINS ('GHOTMAIL.COM')       AND t1.email not CONTAINS ('GMAIL.COMF')
	 AND t1.email not CONTAINS ('LIVE.CK')       AND t1.email not CONTAINS ('GMEIL.CMMAIL.COM')
	 AND t1.email not CONTAINS ('GMMAIL.COM')       AND t1.email not CONTAINS ('HOTMKAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMHOTMAIL.COM')       AND t1.email not CONTAINS ('HOTRMAIL.COM')
	 AND t1.email not CONTAINS ('HOIMAIL.COM')       AND t1.email not CONTAINS ('XN--GMAI-JQA.COM')
	 AND t1.email not CONTAINS ('HMAIL.COM')       AND t1.email not CONTAINS ('OUTLOOK.CM')
	 AND t1.email not CONTAINS ('HATMAIL.CON')       AND t1.email not CONTAINS ('GMAIL.COMON')
	 AND t1.email not CONTAINS ('GMIL.CO')       AND t1.email not CONTAINS ('GMALL.COM')
	 AND t1.email not CONTAINS ('HOTMAIAL.COM')       AND t1.email not CONTAINS ('GMAIK.COM')
	 AND t1.email not CONTAINS ('OUTLOOCK.COM')       AND t1.email not CONTAINS ('GMAQIL.COM')
	 AND t1.email not CONTAINS ('GMAILC.OM')       AND t1.email not CONTAINS ('GMAIA.COM')
	 AND t1.email not CONTAINS ('HOTMAIL.COL')       AND t1.email not CONTAINS ('GMNAIL.COM')
	 AND t1.email not CONTAINS ('OUTLLOOK.ES')       AND t1.email not CONTAINS ('GMEIL.CON')
	 /*agregados de la base de simulacion hb new*/
   /*  AND t1.email not CONTAINS ('GMAIL.CO') */	          AND t1.email not CONTAINS ('GMAIL.COMU')
	 AND t1.email not CONTAINS ('GMAIL.CON')           AND t1.email not CONTAINS ('123MAIL.CL')
	 AND t1.email not CONTAINS ('GMAIL.COMOESTAS')    AND t1.email not CONTAINS ('GMAIL.COMO')
	 AND t1.email not CONTAINS ('GIMAIL.COM')        AND t1.email not CONTAINS ('GMAL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMM')        AND t1.email not CONTAINS ('GMAIL.XOM')
	 AND t1.email not CONTAINS ('GMAIL.CM')         AND t1.email not CONTAINS ('GIMEIL.COM')
	 AND t1.email not CONTAINS ('HOTMIAL.COM')       AND t1.email not CONTAINS ('HOOTMAIL.ES')
	 AND t1.email not CONTAINS ('HOTMAIL.CON')       AND t1.email not CONTAINS ('GIMAIL.CON')
	 AND t1.email not CONTAINS ('HOTMEIL.COM')       AND t1.email not CONTAINS ('GMAIL.VOM')
	 AND t1.email not CONTAINS ('HOTMEIL.ES')        AND t1.email not CONTAINS ('GMAIL.CL.COM')
	 AND t1.email not CONTAINS ('GIMAL.COM')         AND t1.email not CONTAINS ('GMAIL.COMIL.COM')
	 AND t1.email not CONTAINS ('HOTMAIK.COM')       AND t1.email not CONTAINS ('GMAIL.COMQ')
	 AND t1.email not CONTAINS ('HOTMAIIL.COM')      AND t1.email not CONTAINS ('HOTMAIL.CPM')
	AND t1.email not CONTAINS ('GMAIL.COML')        AND t1.email not CONTAINS ('G.MAIL.COM')
	 AND t1.email not CONTAINS ('HOTMAOL.COM')       AND t1.email not CONTAINS ('GMAILL.COM')
	 AND t1.email not CONTAINS ('GIMAIL.CL')         AND t1.email not CONTAINS ('GMAIL.COMD')
	 AND t1.email not CONTAINS ('HOTTMAIL.COM')      AND t1.email not CONTAINS ('HOTMAILC.OM')
	 AND t1.email not CONTAINS ('1967GMAIL.COM')     AND t1.email not CONTAINS ('HOTMAY.COM')
	/* AND t1.email not CONTAINS ('HOTMAIL.CO') */       AND t1.email not CONTAINS ('GMIAL.COM')
	 AND t1.email not CONTAINS ('2382HOTMAIL.COM')   AND t1.email not CONTAINS ('GMALL.COM')
	 AND t1.email not CONTAINS ('GIMALL.COM')        AND t1.email not CONTAINS ('HOTMAIL.COMBUE')
	 AND t1.email not CONTAINS ('GMAIL.CPM')         AND t1.email not CONTAINS ('123GMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMP')        AND t1.email not CONTAINS ('GMIL.CPM')
	 AND t1.email not CONTAINS ('GMALI.COM')         AND t1.email not CONTAINS ('JAJAJA.CL')
	 AND t1.email not CONTAINS ('AUTLOOK.COM')       AND t1.email not CONTAINS ('GMAIL.CLOM')
	 AND t1.email not CONTAINS ('GMAIL.COMCOM')      AND t1.email not CONTAINS ('GMAIL.CIM')
	 AND t1.email not CONTAINS ('ICLOUD.CON')        AND t1.email not CONTAINS ('OUTLOOK.COMM')
	 AND t1.email not CONTAINS ('HOTMEIL.CL')        AND t1.email not CONTAINS ('HOTMAIO.COM')
	 AND t1.email not CONTAINS ('GMAIL.COPM')        AND t1.email not CONTAINS ('GAIML.COM')
	AND t1.email not CONTAINS ('HOTMAIL.COMO')      AND t1.email not CONTAINS ('JAJAGMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMEMAIL')    AND t1.email not CONTAINS ('HOTMAIL.COMR')
	 AND t1.email not CONTAINS ('OULTOOK.CL')        AND t1.email not CONTAINS ('BANCORYPLEY.CL')
	 AND t1.email not CONTAINS ('GMAIM.COM')         AND t1.email not CONTAINS ('B8477491ANCORIPLEY.COM')
	AND t1.email not CONTAINS ('GMAIL.COMN')        AND t1.email not CONTAINS ('GMMAIL.COM')
	 AND t1.email not CONTAINS ('2857GMAIL.COM')     AND t1.email not CONTAINS ('HOTMAIEL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COL')         AND t1.email not CONTAINS ('GHOTMAIL.COM')
	/* AND t1.email not CONTAINS ('OUTLOOK.CO')*/        AND t1.email not CONTAINS ('GMAIIL.COM')
	 AND t1.email not CONTAINS ('OUTLOOK.CON')       AND t1.email not CONTAINS ('LIVE.CM')
	 AND t1.email not CONTAINS ('HOGMAIL.ES')        AND t1.email not CONTAINS ('GMAIL.COMQQSWS')
	 AND t1.email not CONTAINS ('HOTMAKL.COM')       AND t1.email not CONTAINS ('GMAIL.CO.COM')
	AND t1.email not CONTAINS ('HOTMAUL.COM')        AND t1.email not CONTAINS ('OUTLOOCK.COM')
	 AND t1.email not CONTAINS ('GMANIL.COM')        AND t1.email not CONTAINS ('OUTLOO.COM')
	 AND t1.email not CONTAINS ('ICLUD.COM')         AND t1.email not CONTAINS ('GMAIL.COM.CL')
	 AND t1.email not CONTAINS ('OUTLLOK.COM')       AND t1.email not CONTAINS ('GMAIL.COK')
	 AND t1.email not CONTAINS ('GMAIL.COM.COM')     AND t1.email not CONTAINS ('OULOOK.COM')
	 AND t1.email not CONTAINS ('OUTOOK.COM')        AND t1.email not CONTAINS ('59GMEIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.CCOM')        AND t1.email not CONTAINS ('GMAIL.COOM')
	 AND t1.email not CONTAINS ('434GOTMAIL.CL')     AND t1.email not CONTAINS ('GM8AIL.COM')
	 AND t1.email not CONTAINS ('HOGMAIL.COM')       AND t1.email not CONTAINS ('GMAIL.COMA')
	 AND t1.email not CONTAINS ('GMAIIL.CO')         AND t1.email not CONTAINS ('HOTMEY.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMS')        AND t1.email not CONTAINS ('YAHUU.COM')
	 AND t1.email not CONTAINS ('A01GMAIL.COM')      AND t1.email not CONTAINS ('HOTMAIL.COL')
	 AND t1.email not CONTAINS ('GMAIO.COM')         AND t1.email not CONTAINS ('GMAIL.GMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMOM')       AND t1.email not CONTAINS ('HOTMAIM.COM')
	AND t1.email not CONTAINS ('HOTMAIL.COMK')
	/* AGREGADOS POR ANALISIS DE WEBBULA */
	 AND t1.email not CONTAINS ('GMSIL.COM')       AND t1.email not CONTAINS ('MC.COM')
	 AND t1.email not CONTAINS ('LIVER.COM')        AND t1.email not CONTAINS ('HOMAIL.COM')
	 AND t1.email not CONTAINS ('GMAUL.COM')       AND t1.email not CONTAINS ('HTMAIL.COM')
  	 AND t1.email not CONTAINS ('GNAIL.COM')        AND t1.email not CONTAINS ('HOYMAIL.COM')
     AND t1.email not CONTAINS ('LIV.COM')        AND t1.email not CONTAINS ('HPTMAIL.COM')
	 AND t1.email not CONTAINS ('GMAOIL.COM')         AND t1.email not CONTAINS ('HOTMWIL.COM')
	 AND t1.email not CONTAINS ('GMAAIL.COM')       AND t1.email not CONTAINS ('GMASIL.COM')
	 AND t1.email not CONTAINS ('GFMAIL.COM')     AND t1.email not CONTAINS ('MGAIL.COM')
	 AND t1.email not CONTAINS ('H0TMAIL.COM')        AND t1.email not CONTAINS ('GMJAIL.COM')
	 AND t1.email not CONTAINS ('FGMAIL.COM')        AND t1.email not CONTAINS ('HOTMAAIL.CO')
	 AND t1.email not CONTAINS ('HITMAIL.COM')     AND t1.email not CONTAINS ('HOTMAIL.COMQUE')
	 AND t1.email not CONTAINS ('HOTMASIL.COM')       AND t1.email not CONTAINS ('HOTAIL.COM')
	 AND t1.email not CONTAINS ('GOTMAIL.COM')         AND t1.email not CONTAINS ('GTMAIL.COM')
	 AND t1.email not CONTAINS ('NSN.COM')        AND t1.email not CONTAINS ('HOTMSIL.COM')
	 AND t1.email not CONTAINS ('FMAIL.COM')      AND t1.email not CONTAINS ('HOTMAOIL.COM')
	 AND t1.email not CONTAINS ('HOMTAIL.COM')         AND t1.email not CONTAINS ('LIUVE.COM')
	 AND t1.email not CONTAINS ('GMAILO.COM')       AND t1.email not CONTAINS ('GGMAIL.COM')
	 AND t1.email not CONTAINS ('JOTMAIL.COM')       AND t1.email not CONTAINS ('GMQIL.COM')
	 AND t1.email not CONTAINS ('GMAIKL.COM')        AND t1.email not CONTAINS ('HOTMSAIL.COM')
	 AND t1.email not CONTAINS ('GAIL.COM')       AND t1.email not CONTAINS ('GMAIL.COMCIMI')
	 AND t1.email not CONTAINS ('LICE.COM')        AND t1.email not CONTAINS ('GMAIL.CKM')
     AND t1.email not CONTAINS ('HHOTMAIL.COM')        AND t1.email not CONTAINS ('HLTMAIL.COM')
	 AND t1.email not CONTAINS ('ICLOUB.COM')         AND t1.email not CONTAINS ('HOTMAIL.COOM')
	 AND t1.email not CONTAINS ('HOTMAIKL.COM')       AND t1.email not CONTAINS ('HJOTMAIL.COM')
	 AND t1.email not CONTAINS ('HOPTMAIL.COM')     AND t1.email not CONTAINS ('HOTMAIUL.COM')
	 AND t1.email not CONTAINS ('HOTMMAIL.COM')        AND t1.email not CONTAINS ('HOTMALL.COM')
	 AND t1.email not CONTAINS ('HOTGMAIL.COM')        AND t1.email not CONTAINS ('LIVE.COL')
	 AND t1.email not CONTAINS ('HOTNAIL.COM')     AND t1.email not CONTAINS ('LIBE.COM')
	 AND t1.email not CONTAINS ('GMAUIL.COM')       AND t1.email not CONTAINS ('H0OTMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMAQIL.COM')         AND t1.email not CONTAINS ('GMAI9L.COM')
	 AND t1.email not CONTAINS ('GNMAIL.COM')        AND t1.email not CONTAINS ('HOTMAILK.COM')
	 AND t1.email not CONTAINS ('HOYTMAIL.COM')      AND t1.email not CONTAINS ('HOTMAIL.CM')
	 AND t1.email not CONTAINS ('HOTMAAIL.COM')         AND t1.email not CONTAINS ('HOTFMAIL.COM')
	 AND t1.email not CONTAINS ('HOMAIL.CO')       AND t1.email not CONTAINS ('HIOTMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMAKIL.COM')         AND t1.email not CONTAINS ('GMAILK.COM')
	 AND t1.email not CONTAINS ('HOHTMAIL.COM')       AND t1.email not CONTAINS ('HOTYMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMAUIL.COM')     AND t1.email not CONTAINS ('ME.CM')
	 AND t1.email not CONTAINS ('HOTMAIL.COIM')        AND t1.email not CONTAINS ('L8VE.COM')
	 AND t1.email not CONTAINS ('HOTMNAIL.COM')        AND t1.email not CONTAINS ('OHTMAIL.COM')
	 AND t1.email not CONTAINS ('HOT6MAIL.COM')     AND t1.email not CONTAINS ('GMQIL.VOM')
	 AND t1.email not CONTAINS ('GMZAIL.COM')       AND t1.email not CONTAINS ('LIVE.CCOM')
	 AND t1.email not CONTAINS ('LIVEW.COM')         AND t1.email not CONTAINS ('YGMAIL.COM')
	 AND t1.email not CONTAINS ('BOTMAIL.COM')        AND t1.email not CONTAINS ('GMAIL.CO9M')
	 AND t1.email not CONTAINS ('GMAIL.COMG')      AND t1.email not CONTAINS ('HOTMAIL.CIOM')
	 AND t1.email not CONTAINS ('HPOTMAIL.COM')         AND t1.email not CONTAINS ('MAIL.CM')
	 AND t1.email not CONTAINS ('HOHMAIL.COM')       AND t1.email not CONTAINS ('HOTMAIL.COPM')
	 AND t1.email not CONTAINS ('HOT5MAIL.COM')        AND t1.email not CONTAINS ('GMZIL.COM')
	 AND t1.email not CONTAINS ('HOLTMAIL.COM')      AND t1.email not CONTAINS ('LIVE.CON')
	 AND t1.email not CONTAINS ('HUOTMAIL.COM')         AND t1.email not CONTAINS ('MSNM.COM')
	 AND t1.email not CONTAINS ('HO0TMAIL.COM')       AND t1.email not CONTAINS ('HOTMAI.COK')
	 AND t1.email not CONTAINS ('GMAZIL.COM')         AND t1.email not CONTAINS ('LVIE.COM')
	 AND t1.email not CONTAINS ('HOTMAIL.CCOM')       AND t1.email not CONTAINS ('HOTMAIL.CLOM')
	 AND t1.email not CONTAINS ('HOOTMAIL.COM')     AND t1.email not CONTAINS ('HOTHMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMIL.CON')        AND t1.email not CONTAINS ('MZN.COM')
	 AND t1.email not CONTAINS ('HOMAIL.CM')        AND t1.email not CONTAINS ('ICLOUD.OM')
	 AND t1.email not CONTAINS ('HGOTMAIL.COM')     AND t1.email not CONTAINS ('GMIL.CON')
	 AND t1.email not CONTAINS ('LIVE.VOM')       AND t1.email not CONTAINS ('GAIL.CO')
	 AND t1.email not CONTAINS ('GMA9IL.COM')         AND t1.email not CONTAINS ('HTMAIL.CPM')
	 AND t1.email not CONTAINS ('GMAI.LCOM')        AND t1.email not CONTAINS ('GMIL.CM')
	 AND t1.email not CONTAINS ('MSN.CM')      AND t1.email not CONTAINS ('BHOTMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIUL.COM')         AND t1.email not CONTAINS ('HO9TMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMJAIL.COM')       AND t1.email not CONTAINS ('GMA8L.COM')
     AND t1.email not CONTAINS ('GAMIL.CON')      AND t1.email not CONTAINS ('GKMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.BOM')         AND t1.email not CONTAINS ('LIE.COM')
	 AND t1.email not CONTAINS ('HOTMIL.CO')       AND t1.email not CONTAINS ('GMAIL.CIOM')
	 AND t1.email not CONTAINS ('LUVE.COM')         AND t1.email not CONTAINS ('NOTMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMQAIL.COM')       AND t1.email not CONTAINS ('HOTMIL.CM')
	 AND t1.email not CONTAINS ('GMAIL.VCOM')     AND t1.email not CONTAINS ('HOTMAIL.CAM')
	 AND t1.email not CONTAINS ('HOTNAIL.CO')        AND t1.email not CONTAINS ('HOTJMAIL.COM')
	 AND t1.email not CONTAINS ('GMIIL.COM')        AND t1.email not CONTAINS ('H9OTMAIL.COM')
	 AND t1.email not CONTAINS ('GYMAIL.COM')     AND t1.email not CONTAINS ('HNOTMAIL.COM')
	 AND t1.email not CONTAINS ('HOTNMAIL.COM')       AND t1.email not CONTAINS ('GMA8IL.COM')
	 AND t1.email not CONTAINS ('GHMAIL.COM')         AND t1.email not CONTAINS ('GJMAIL.COM')
	 AND t1.email not CONTAINS ('GMAWIL.COM')        AND t1.email not CONTAINS ('HOTMMAIL.CO')
	 AND t1.email not CONTAINS ('GMWIL.COM')      AND t1.email not CONTAINS ('LIVD.COM')
	 AND t1.email not CONTAINS ('HYOTMAIL.COM')         AND t1.email not CONTAINS ('HOMAIL.OM')
	 AND t1.email not CONTAINS ('LIVE.CM')       AND t1.email not CONTAINS ('HOMAIL.CON')
	 AND t1.email not CONTAINS ('HLOTMAIL.COM')         AND t1.email not CONTAINS ('HGMAIL.CO')
	 AND t1.email not CONTAINS ('HOTAIL.CO')       AND t1.email not CONTAINS ('GMAKIL.COM')
	 AND t1.email not CONTAINS ('LILVE.COM')         AND t1.email not CONTAINS ('HOOTMAIL.CO')
	 AND t1.email not CONTAINS ('HBOTMAIL.COM')       AND t1.email not CONTAINS ('GMQAIL.COM')
	 AND t1.email not CONTAINS ('LIVE.CIM')     AND t1.email not CONTAINS ('HORMAIL.CON')
	 AND t1.email not CONTAINS ('HOTMAI9L.COM')        AND t1.email not CONTAINS ('GMKAIL.COM')
	 AND t1.email not CONTAINS ('MSMN.COM')        AND t1.email not CONTAINS ('GKAIL.COM')
	 AND t1.email not CONTAINS ('YHAOO.COM')     AND t1.email not CONTAINS ('YAHHO.COM')
	 AND t1.email not CONTAINS ('YAHO.COM')       AND t1.email not CONTAINS ('YAHOIO.COM')
	 AND t1.email not CONTAINS ('YAOO.COM')         AND t1.email not CONTAINS ('YAHOOO.COM')
	 AND t1.email not CONTAINS ('YAHOO.CO')        AND t1.email not CONTAINS ('HOTMAIL.DOM')
	 AND t1.email not CONTAINS ('GMAILL.CM')      AND t1.email not CONTAINS ('HOTMAIL.COM.YAHOO.ES')
	 AND t1.email not CONTAINS ('YQHOO.COM')         AND t1.email not CONTAINS ('HOTMAI.CM')
	 AND t1.email not CONTAINS ('TAHOO.COM')       AND t1.email not CONTAINS ('HOTMA8L.COM')
	 AND t1.email not CONTAINS ('JMAIL.COM')        AND t1.email not CONTAINS ('GIMAIL.CM')
	 AND t1.email not CONTAINS ('GEMAIL.CO')      AND t1.email not CONTAINS ('GIMAIL.CO')
	 AND t1.email not CONTAINS ('YOPMAIL.CO')         AND t1.email not CONTAINS ('HOTMAIL.17.COM')
	 AND t1.email not CONTAINS ('CORREO.OM')       AND t1.email not CONTAINS ('HORMAIL.CO')
	 AND t1.email not CONTAINS ('UTLOOK.COM')         AND t1.email not CONTAINS ('YHOO.COM')
	 AND t1.email not CONTAINS ('YAJOO.COM')       AND t1.email not CONTAINS ('HOTMIAL.CO')
	 AND t1.email not CONTAINS ('YAYOO.COM')         AND t1.email not CONTAINS ('HOTMALIL.COM')
	 AND t1.email not CONTAINS ('YMSIL.COM')       AND t1.email not CONTAINS ('HOTMIAL.CM')
	 AND t1.email not CONTAINS ('YASHOO.COM')     AND t1.email not CONTAINS ('HOTMAILL.CO')
	 AND t1.email not CONTAINS ('YAHOOL.COM')        AND t1.email not CONTAINS ('HOTMAIOL.COM')
	 AND t1.email not CONTAINS ('HOTMMAIL.OM')        AND t1.email not CONTAINS ('YAQHOO.COM')
	 AND t1.email not CONTAINS ('YSHOO.COM')     AND t1.email not CONTAINS ('GMIAL.CON')
	 AND t1.email not CONTAINS ('LIVR.COM')       AND t1.email not CONTAINS ('HOTMAWIL.COM')
	 AND t1.email not CONTAINS ('GMMAIL.CO')         AND t1.email not CONTAINS ('HTMAIL.CM')
	 AND t1.email not CONTAINS ('NAIL.COM')        AND t1.email not CONTAINS ('MAIOL.COM')
	 AND t1.email not CONTAINS ('GM.CON')      AND t1.email not CONTAINS ('GM.CO')
	 AND t1.email not CONTAINS ('HO5TMAIL.COM')         AND t1.email not CONTAINS ('GMAIL.FOM')
	 AND t1.email not CONTAINS ('MAI.CM')       AND t1.email not CONTAINS ('EMAIL.CO')
	 AND t1.email not CONTAINS ('GOTMAIL.CO')        AND t1.email not CONTAINS ('LIVS.COM')
	 AND t1.email not CONTAINS ('LICVE.COM')      AND t1.email not CONTAINS ('MAIL.CON')
	 AND t1.email not CONTAINS ('JMAIL.CO')         AND t1.email not CONTAINS ('MAIIL.COM')
	 AND t1.email not CONTAINS ('GIMEI.CO')       AND t1.email not CONTAINS ('HOTMAILC.OM')
	 AND t1.email not CONTAINS ('GMAILC.OM')         AND t1.email not CONTAINS ('GIMIL.CON')
	 AND t1.email not CONTAINS ('HOTAMAIL.CO')       AND t1.email not CONTAINS ('YMAIL.CM')
	 AND t1.email not CONTAINS ('YMAIL.CO')         AND t1.email not CONTAINS ('OUTLOOOK.COM')
	 AND t1.email not CONTAINS ('GAMIAL.CO')       AND t1.email not CONTAINS ('OITLOOK.COM')
	 AND t1.email not CONTAINS ('ICLUD.CON')     AND t1.email not CONTAINS ('OUTLOOK.CON')
	 AND t1.email not CONTAINS ('AUTLOOK.CO')        AND t1.email not CONTAINS ('GIMEI.CON')
	 AND t1.email not CONTAINS ('OUTLOKK.COM')        AND t1.email not CONTAINS ('GMLI.CON')
	 AND t1.email not CONTAINS ('GMEIL.CO')     AND t1.email not CONTAINS ('GOMAIL.CO')
	 AND t1.email not CONTAINS ('MGMAIL.CO')       AND t1.email not CONTAINS ('GMEIL.CPM')
	 AND t1.email not CONTAINS ('HOTMEIL.COM')         AND t1.email not CONTAINS ('GITMAIL.COM')
	 AND t1.email not CONTAINS ('UMAIL.COM')        AND t1.email not CONTAINS ('HJFJH.CM')
	 AND t1.email not CONTAINS ('GEMEIL.CO')      AND t1.email not CONTAINS ('HIMAIL.CO')
	 AND t1.email not CONTAINS ('GAMAIL.CO')         AND t1.email not CONTAINS ('GIMEIL.CO')
	 AND t1.email not CONTAINS ('GIMIL.COMO')       AND t1.email not CONTAINS ('GIMAL.CON')
	 AND t1.email not CONTAINS ('HOTM.COMAIL')         AND t1.email not CONTAINS ('YNAIL.COM')
	 AND t1.email not CONTAINS ('GIMEIL.CIM')       AND t1.email not CONTAINS ('HOLMAIL.CM')
	 AND t1.email not CONTAINS ('YMIAL.COM')        AND t1.email not CONTAINS ('GMEIL.COMO')
	 AND t1.email not CONTAINS ('HOIMAIL.COM')      AND t1.email not CONTAINS ('HOITMAIL.CL')
	 AND t1.email not CONTAINS ('WWW.HOTMAIL.COM')         AND t1.email not CONTAINS ('THOMAIL.CL')
	 AND t1.email not CONTAINS ('YQAHOO.COM')       AND t1.email not CONTAINS ('HAHOO.COM')
	 AND t1.email not CONTAINS ('YAHOL.COM')         AND t1.email not CONTAINS ('YAGOO.COM')
	 AND t1.email not CONTAINS ('UAHOO.COM')       AND t1.email not CONTAINS ('YAHOO.CM')
	 AND t1.email not CONTAINS ('YAHHOO.COM')         AND t1.email not CONTAINS ('YAAHOO.COM')
	 AND t1.email not CONTAINS ('YSAHOO.COM')       AND t1.email not CONTAINS ('YAHOO.CON.CO')
	 AND t1.email not CONTAINS ('YAHO0.COM')     AND t1.email not CONTAINS ('YAHOOP.COM')
	 AND t1.email not CONTAINS ('YYAHOO.COM')        AND t1.email not CONTAINS ('YABHOO.COM')
	 AND t1.email not CONTAINS ('YAHPOO.COM')        AND t1.email not CONTAINS ('YAHJOO.COM')
	 AND t1.email not CONTAINS ('HYAHOO.COM')     AND t1.email not CONTAINS ('YTAHOO.COM')
	 AND t1.email not CONTAINS ('YAHIO.COM')       AND t1.email not CONTAINS ('UYAHOO.COM')
	 AND t1.email not CONTAINS ('YAHOO0.COM')         AND t1.email not CONTAINS ('YAHOO.COM')
	 AND t1.email not CONTAINS ('YAHOO.CMO')        AND t1.email not CONTAINS ('YAH0O.COM')
	 AND t1.email not CONTAINS ('YABOO.COM')      AND t1.email not CONTAINS ('YAHGOO.COM')
	 AND t1.email not CONTAINS ('TYAHOO.COM')         AND t1.email not CONTAINS ('YAHUOO.COM')
	 AND t1.email not CONTAINS ('YAHO0O.COM')       AND t1.email not CONTAINS ('YUAHOO.COM')
	 AND t1.email not CONTAINS ('GYAHOO.COM')         AND t1.email not CONTAINS ('YHAHOO.COM')
	AND t1.email not in (select email from POLAVARR.CORREOS_FAKE_V2)

;quit;

PROC SQL;
CREATE INDEX rut ON RESULT.BASE_EMAIL_TEFs (RUT);
QUIT;

/*Eliminar tablas de Paso de TEFs*/
PROC SQL;
/*	DROP TABLE RESULT.R_TEFs;*/
	DROP TABLE RESULT.R_CORREOS_TEF_MAX;
;QUIT;

/*=========================================================================================*/
/*======	2.- Obtener Emails desde: FISA y CAÑON	=======================================*/
/*=========================================================================================*/
PROC SQL;
	CONNECT TO ORACLE AS GESTION (PATH="QANEW.WORLD" USER='ripleyc' PASSWORD='ri99pley');
	CREATE TABLE BASE_EMAIL_FISA_CANON AS 
		SELECT input(rut,best.) as RUT, UPCASE(EMAIL) AS EMAIL length=50, FECHA_ACTUALIZACION, SEQUENCIA, ORIGEN 
			FROM CONNECTION TO GESTION(
			select distinct 
					(substr(c.cli_identifica, 1, length(c.cli_identifica) - 1)) rut,
			       	a.dir_direccion || a.dir_direccion2 || a.dir_direccion3 email,
			       	a.dir_fecver fecha_ACTUALIZACION,
					to_number(7) SEQUENCIA,
			        'FISA' origen
			  	from tcli_direccion a,
			       tcli_persona c
				where a.dir_codcli = c.cli_codigo
				   and dir_tipodir in(6,4)
				   and a.dir_direccion is not null
				   and to_number(substr(c.cli_identifica, 1, length(c.cli_identifica) - 1))>1000000
			union
			select TO_CHAR(rut) RUT,
			        direccion email, 
			        fecha_carga fecha_ACTUALIZACION,
			        to_number(8) SEQUENCIA,
			        'CANON BCO' ORIGEN
			  from br_dm_direccion_cliente
			where tipodir in (4,6)
			   and direccion is not null
			)A
	WHERE email not LIKE	('.-%')			AND email not LIKE	('%.')
	AND email not LIKE	('-%')				AND email not LIKE	('%.@%')
	/*AND email not LIKE	('% %')*/
    AND email not CONTAINS 	('XXXXX')
	AND email not CONTAINS 	('DEFAULT')		AND email not CONTAINS 	('TEST@')
	AND email not CONTAINS 	('..')			AND email not CONTAINS 	('PRUEBA')
	AND email not CONTAINS	('(')			AND email not CONTAINS 	(')')
	AND email not CONTAINS	('/')			AND email not CONTAINS	('?')
	AND email not CONTAINS 	('¿')			AND email not CONTAINS 	('SINMAIL')
	AND email not CONTAINS 	('NOTIENE')		AND email not CONTAINS 	('NOTENGO')
	AND email not CONTAINS 	('SINCORRE')	AND email not CONTAINS 	('TEST@')
	AND email <>'@'							AND email not CONTAINS	('GFFDF')
	AND email not CONTAINS 	('0000000')		AND email not CONTAINS 	('GMAIL.CL')
	AND email not CONTAINS 	('GMAIL.ES')	AND email <>'0'
	AND email CONTAINS 	('@')				AND email not CONTAINS 	('SINEMAIL')
	AND email not CONTAINS 	('NOREGISTRA')  AND email not CONTAINS 	('SINMALLIL')
	AND email not CONTAINS 	('@MAILINATOR.COM')	AND email not CONTAINS ('@MICORREO.COM')	
	AND email not CONTAINS 	('@HOTRMAIL.COM')	AND email not CONTAINS	('@SDFDF.CL' )
	/*agregado pia*/
	 AND email not CONTAINS ('HORTMAIL.COM')       AND email not CONTAINS ('REPLEY.COM')
	 AND email not CONTAINS ('BANCPORIPLEY.COM')       AND email not CONTAINS ('GMAL.COM')
	 AND email not CONTAINS ('RILPLEY.COM')       AND email not CONTAINS ('HOTMAI.COM')
	 AND email not CONTAINS ('GAMIL.COM')       AND email not CONTAINS ('RIPEY.CL')
	 AND email not CONTAINS ('RIPLEY.VOM')       AND email not CONTAINS ('HTOMAIL.COM')
	 AND email not CONTAINS ('GMAIL.CON')       AND email not CONTAINS ('GMIL.COM')
	 AND email not CONTAINS ('HOTAMIL.COM')       AND email not CONTAINS ('123MAIL.CL')
	 AND email not CONTAINS ('ICLOOUD.COM')       AND email not CONTAINS ('YMAIL.COM')
	 AND email not CONTAINS ('HOTMIAL.COM')       AND email not CONTAINS ('GMAI.COM')
	 AND email not CONTAINS ('HOTMAIL.OM')       AND email not CONTAINS ('GMAIIL.COM')
	 AND email not CONTAINS ('RIOLPLEY.COM')       AND email not CONTAINS ('aol.com')
	 AND email not CONTAINS ('GMSAIL.COM')       AND email not CONTAINS ('ICLOU.COM')
	 AND email not CONTAINS ('GMAIL.CM')       AND email not CONTAINS ('GMIAL.COM')
	 AND email not CONTAINS ('UAHOO.COM')       AND email not CONTAINS ('HOTMAIL.OCM')
	 AND email not CONTAINS ('GMAILC.OM')       AND email not CONTAINS ('UTLOOOK.COM')
	 AND email not CONTAINS ('RIPLE.COM')       AND email not CONTAINS ('GMAILL.COM')
	 AND email not CONTAINS ('GMAOL.COM')       AND email not CONTAINS ('HORMAIL.COM')
	 AND email not CONTAINS ('HOTMAL.COM')       /*AND t1.email not CONTAINS ('OTMAIL.COM')*/
	 AND email not CONTAINS ('2HOTMAIL.ES')       AND email not CONTAINS ('XXX.COM')
	 AND email not CONTAINS ('AUTLOOK.COM')       AND email not CONTAINS ('8GMAIL.COM')
	 AND email not CONTAINS ('GMAIL.COMN')       AND email not CONTAINS ('OITLOOK.COM')
	 AND email not CONTAINS ('OUTLOCK.COM')       AND email not CONTAINS ('GMAIL.OM')
	 AND email not CONTAINS ('GMAIL.LCOM')       AND email not CONTAINS ('OUTLLOK.CL')
	 AND email not CONTAINS ('OULOOCK.ES')       AND email not CONTAINS ('OULOOKS.ES')
	 AND email not CONTAINS ('GAMIAL.COM')       AND email not CONTAINS ('HOTMAILL.COM')
	 AND email not CONTAINS ('GMAIL.CPM')       AND email not CONTAINS ('64GMAIL.COM')
	 AND email not CONTAINS ('GMAIOL.COM')
	 /*agregado email Lore Gerrero*/
     	 AND email not CONTAINS ('yahho.com')       AND email not CONTAINS ('EMAIL.CON')
	 AND email not CONTAINS ('OUTLOKK.ES')       AND email not CONTAINS ('HORMAIL.COM')
	 AND email not CONTAINS ('GMAIL.VOM')       AND email not CONTAINS ('YAHOO.CL')
	 AND email not CONTAINS ('GMEIL.CL')       AND email not CONTAINS ('GMAKL.COM')
	 AND email not CONTAINS ('GMAIL.COL')       AND email not CONTAINS ('GMAIL.COMO')
	 AND email not CONTAINS ('GHOTMAIL.COM')       AND email not CONTAINS ('GMAIL.COMF')
	 AND email not CONTAINS ('LIVE.CK')       AND email not CONTAINS ('GMEIL.CMMAIL.COM')
	 AND email not CONTAINS ('GMMAIL.COM')       AND email not CONTAINS ('HOTMKAIL.COM')
	 AND email not CONTAINS ('GMAIL.COMHOTMAIL.COM')       AND email not CONTAINS ('HOTRMAIL.COM')
	 AND email not CONTAINS ('HOIMAIL.COM')       AND email not CONTAINS ('XN--GMAI-JQA.COM')
	 AND email not CONTAINS ('HMAIL.COM')       AND email not CONTAINS ('OUTLOOK.CM')
	 AND email not CONTAINS ('HATMAIL.CON')       AND email not CONTAINS ('GMAIL.COMON')
	 AND email not CONTAINS ('GMIL.CO')       AND email not CONTAINS ('GMALL.COM')
	 AND email not CONTAINS ('HOTMAIAL.COM')       AND email not CONTAINS ('GMAIK.COM')
	 AND email not CONTAINS ('OUTLOOCK.COM')       AND email not CONTAINS ('GMAQIL.COM')
	 AND email not CONTAINS ('GMAILC.OM')       AND email not CONTAINS ('GMAIA.COM')
	 AND email not CONTAINS ('HOTMAIL.COL')       AND email not CONTAINS ('GMNAIL.COM')
	 AND email not CONTAINS ('OUTLLOOK.ES')       AND email not CONTAINS ('GMEIL.CON')
	 	 /*agregados de la base de simulacion hb new*/
    /*  AND email not CONTAINS ('GMAIL.CO') */	          AND email not CONTAINS ('GMAIL.COMU')
	AND email not CONTAINS ('GMAIL.CON')           AND email not CONTAINS ('123MAIL.CL')
	 AND email not CONTAINS ('GMAIL.COMOESTAS')    AND email not CONTAINS ('GMAIL.COMO')
	 AND email not CONTAINS ('GIMAIL.COM')        AND email not CONTAINS ('GMAL.COM')
	 AND email not CONTAINS ('GMAIL.COMM')        AND email not CONTAINS ('GMAIL.XOM')
	 AND email not CONTAINS ('GMAIL.CM')         AND email not CONTAINS ('GIMEIL.COM')
	 AND email not CONTAINS ('HOTMIAL.COM')       AND email not CONTAINS ('HOOTMAIL.ES')
	 AND email not CONTAINS ('HOTMAIL.CON')       AND email not CONTAINS ('GIMAIL.CON')
	 AND email not CONTAINS ('HOTMEIL.COM')       AND email not CONTAINS ('GMAIL.VOM')
	 AND email not CONTAINS ('HOTMEIL.ES')        AND email not CONTAINS ('GMAIL.CL.COM')
	 AND email not CONTAINS ('GIMAL.COM')         AND email not CONTAINS ('GMAIL.COMIL.COM')
	 AND email not CONTAINS ('HOTMAIK.COM')       AND email not CONTAINS ('GMAIL.COMQ')
	 AND email not CONTAINS ('HOTMAIIL.COM')      AND email not CONTAINS ('HOTMAIL.CPM')
	AND email not CONTAINS ('GMAIL.COML')        AND email not CONTAINS ('G.MAIL.COM')
	 AND email not CONTAINS ('HOTMAOL.COM')       AND email not CONTAINS ('GMAILL.COM')
	 AND email not CONTAINS ('GIMAIL.CL')         AND email not CONTAINS ('GMAIL.COMD')
	 AND email not CONTAINS ('HOTTMAIL.COM')      AND email not CONTAINS ('HOTMAILC.OM')
	 AND email not CONTAINS ('1967GMAIL.COM')     AND email not CONTAINS ('HOTMAY.COM')
	/* AND email not CONTAINS ('HOTMAIL.CO') */       AND email not CONTAINS ('GMIAL.COM')
	 AND email not CONTAINS ('2382HOTMAIL.COM')   AND email not CONTAINS ('GMALL.COM')
	 AND email not CONTAINS ('GIMALL.COM')        AND email not CONTAINS ('HOTMAIL.COMBUE')
	 AND email not CONTAINS ('GMAIL.CPM')         AND email not CONTAINS ('123GMAIL.COM')
	 AND email not CONTAINS ('GMAIL.COMP')        AND email not CONTAINS ('GMIL.CPM')
	 AND email not CONTAINS ('GMALI.COM')         AND email not CONTAINS ('JAJAJA.CL')
	 AND email not CONTAINS ('AUTLOOK.COM')       AND email not CONTAINS ('GMAIL.CLOM')
	 AND email not CONTAINS ('GMAIL.COMCOM')      AND email not CONTAINS ('GMAIL.CIM')
	 AND email not CONTAINS ('ICLOUD.CON')        AND email not CONTAINS ('OUTLOOK.COMM')
	 AND email not CONTAINS ('HOTMEIL.CL')        AND email not CONTAINS ('HOTMAIO.COM')
	 AND email not CONTAINS ('GMAIL.COPM')        AND email not CONTAINS ('GAIML.COM')
	AND email not CONTAINS ('HOTMAIL.COMO')      AND email not CONTAINS ('JAJAGMAIL.COM')
	 AND email not CONTAINS ('GMAIL.COMEMAIL')    AND email not CONTAINS ('HOTMAIL.COMR')
	 AND email not CONTAINS ('OULTOOK.CL')        AND email not CONTAINS ('BANCORYPLEY.CL')
	 AND email not CONTAINS ('GMAIM.COM')         AND email not CONTAINS ('B8477491ANCORIPLEY.COM')
	AND email not CONTAINS ('GMAIL.COMN')        AND email not CONTAINS ('GMMAIL.COM')
	 AND email not CONTAINS ('2857GMAIL.COM')     AND email not CONTAINS ('HOTMAIEL.COM')
	 AND email not CONTAINS ('GMAIL.COL')         AND email not CONTAINS ('GHOTMAIL.COM')
	/* AND email not CONTAINS ('OUTLOOK.CO')*/        AND email not CONTAINS ('GMAIIL.COM')
	 AND email not CONTAINS ('OUTLOOK.CON')       AND email not CONTAINS ('LIVE.CM')
	 AND email not CONTAINS ('HOGMAIL.ES')        AND email not CONTAINS ('GMAIL.COMQQSWS')
	 AND email not CONTAINS ('HOTMAKL.COM')       AND email not CONTAINS ('GMAIL.CO.COM')
	AND email not CONTAINS ('HOTMAUL.COM')        AND email not CONTAINS ('OUTLOOCK.COM')
	 AND email not CONTAINS ('GMANIL.COM')        AND email not CONTAINS ('OUTLOO.COM')
	 AND email not CONTAINS ('ICLUD.COM')         AND email not CONTAINS ('GMAIL.COM.CL')
	 AND email not CONTAINS ('OUTLLOK.COM')       AND email not CONTAINS ('GMAIL.COK')
	 AND email not CONTAINS ('GMAIL.COM.COM')     AND email not CONTAINS ('OULOOK.COM')
	 AND email not CONTAINS ('OUTOOK.COM')        AND email not CONTAINS ('59GMEIL.COM')
	 AND email not CONTAINS ('GMAIL.CCOM')        AND email not CONTAINS ('GMAIL.COOM')
	 AND email not CONTAINS ('434GOTMAIL.CL')     AND email not CONTAINS ('GM8AIL.COM')
	 AND email not CONTAINS ('HOGMAIL.COM')       AND email not CONTAINS ('GMAIL.COMA')
	 AND email not CONTAINS ('GMAIIL.CO')         AND email not CONTAINS ('HOTMEY.COM')
	 AND email not CONTAINS ('GMAIL.COMS')        AND email not CONTAINS ('YAHUU.COM')
	 AND email not CONTAINS ('A01GMAIL.COM')      AND email not CONTAINS ('HOTMAIL.COL')
	 AND email not CONTAINS ('GMAIO.COM')         AND email not CONTAINS ('GMAIL.GMAIL.COM')
	 AND email not CONTAINS ('GMAIL.COMOM')       AND email not CONTAINS ('HOTMAIM.COM')
	AND email not CONTAINS ('HOTMAIL.COMK')
		/* AGREGADOS POR ANALISIS DE WEBBULA */
	 AND email not CONTAINS ('GMSIL.COM')       AND email not CONTAINS ('MC.COM')
	 AND email not CONTAINS ('LIVER.COM')        AND email not CONTAINS ('HOMAIL.COM')
	 AND email not CONTAINS ('GMAUL.COM')       AND email not CONTAINS ('HTMAIL.COM')
  	 AND email not CONTAINS ('GNAIL.COM')        AND email not CONTAINS ('HOYMAIL.COM')
     AND email not CONTAINS ('LIV.COM')        AND email not CONTAINS ('HPTMAIL.COM')
	 AND email not CONTAINS ('GMAOIL.COM')         AND email not CONTAINS ('HOTMWIL.COM')
	 AND email not CONTAINS ('GMAAIL.COM')       AND email not CONTAINS ('GMASIL.COM')
	 AND email not CONTAINS ('GFMAIL.COM')     AND email not CONTAINS ('MGAIL.COM')
	 AND email not CONTAINS ('H0TMAIL.COM')        AND email not CONTAINS ('GMJAIL.COM')
	 AND email not CONTAINS ('FGMAIL.COM')        AND email not CONTAINS ('HOTMAAIL.CO')
	 AND email not CONTAINS ('HITMAIL.COM')     AND email not CONTAINS ('HOTMAIL.COMQUE')
	 AND email not CONTAINS ('HOTMASIL.COM')       AND email not CONTAINS ('HOTAIL.COM')
	 AND email not CONTAINS ('GOTMAIL.COM')         AND email not CONTAINS ('GTMAIL.COM')
	 AND email not CONTAINS ('NSN.COM')        AND email not CONTAINS ('HOTMSIL.COM')
	 AND email not CONTAINS ('FMAIL.COM')      AND email not CONTAINS ('HOTMAOIL.COM')
	 AND email not CONTAINS ('HOMTAIL.COM')         AND email not CONTAINS ('LIUVE.COM')
	 AND email not CONTAINS ('GMAILO.COM')       AND email not CONTAINS ('GGMAIL.COM')
	 AND email not CONTAINS ('JOTMAIL.COM')       AND email not CONTAINS ('GMQIL.COM')
	 AND email not CONTAINS ('GMAIKL.COM')        AND email not CONTAINS ('HOTMSAIL.COM')
	 AND email not CONTAINS ('GAIL.COM')       AND email not CONTAINS ('GMAIL.COMCIMI')
	 AND email not CONTAINS ('LICE.COM')        AND email not CONTAINS ('GMAIL.CKM')
     AND email not CONTAINS ('HHOTMAIL.COM')        AND email not CONTAINS ('HLTMAIL.COM')
	 AND email not CONTAINS ('ICLOUB.COM')         AND email not CONTAINS ('HOTMAIL.COOM')
	 AND email not CONTAINS ('HOTMAIKL.COM')       AND email not CONTAINS ('HJOTMAIL.COM')
	 AND email not CONTAINS ('HOPTMAIL.COM')     AND email not CONTAINS ('HOTMAIUL.COM')
	 AND email not CONTAINS ('HOTMMAIL.COM')        AND email not CONTAINS ('HOTMALL.COM')
	 AND email not CONTAINS ('HOTGMAIL.COM')        AND email not CONTAINS ('LIVE.COL')
	 AND email not CONTAINS ('HOTNAIL.COM')     AND email not CONTAINS ('LIBE.COM')
	 AND email not CONTAINS ('GMAUIL.COM')       AND email not CONTAINS ('H0OTMAIL.COM')
	 AND email not CONTAINS ('HOTMAQIL.COM')         AND email not CONTAINS ('GMAI9L.COM')
	 AND email not CONTAINS ('GNMAIL.COM')        AND email not CONTAINS ('HOTMAILK.COM')
	 AND email not CONTAINS ('HOYTMAIL.COM')      AND email not CONTAINS ('HOTMAIL.CM')
	 AND email not CONTAINS ('HOTMAAIL.COM')         AND email not CONTAINS ('HOTFMAIL.COM')
	 AND email not CONTAINS ('HOMAIL.CO')       AND email not CONTAINS ('HIOTMAIL.COM')
	 AND email not CONTAINS ('HOTMAKIL.COM')         AND email not CONTAINS ('GMAILK.COM')
	 AND email not CONTAINS ('HOHTMAIL.COM')       AND email not CONTAINS ('HOTYMAIL.COM')
	 AND email not CONTAINS ('HOTMAUIL.COM')     AND email not CONTAINS ('ME.CM')
	 AND email not CONTAINS ('HOTMAIL.COIM')        AND email not CONTAINS ('L8VE.COM')
	 AND email not CONTAINS ('HOTMNAIL.COM')        AND email not CONTAINS ('OHTMAIL.COM')
	 AND email not CONTAINS ('HOT6MAIL.COM')     AND email not CONTAINS ('GMQIL.VOM')
	 AND email not CONTAINS ('GMZAIL.COM')       AND email not CONTAINS ('LIVE.CCOM')
	 AND email not CONTAINS ('LIVEW.COM')         AND email not CONTAINS ('YGMAIL.COM')
	 AND email not CONTAINS ('BOTMAIL.COM')        AND email not CONTAINS ('GMAIL.CO9M')
	 AND email not CONTAINS ('GMAIL.COMG')      AND email not CONTAINS ('HOTMAIL.CIOM')
	 AND email not CONTAINS ('HPOTMAIL.COM')         AND email not CONTAINS ('MAIL.CM')
	 AND email not CONTAINS ('HOHMAIL.COM')       AND email not CONTAINS ('HOTMAIL.COPM')
	 AND email not CONTAINS ('HOT5MAIL.COM')        AND email not CONTAINS ('GMZIL.COM')
	 AND email not CONTAINS ('HOLTMAIL.COM')      AND email not CONTAINS ('LIVE.CON')
	 AND email not CONTAINS ('HUOTMAIL.COM')         AND email not CONTAINS ('MSNM.COM')
	 AND email not CONTAINS ('HO0TMAIL.COM')       AND email not CONTAINS ('HOTMAI.COK')
	 AND email not CONTAINS ('GMAZIL.COM')         AND email not CONTAINS ('LVIE.COM')
	 AND email not CONTAINS ('HOTMAIL.CCOM')       AND email not CONTAINS ('HOTMAIL.CLOM')
	 AND email not CONTAINS ('HOOTMAIL.COM')     AND email not CONTAINS ('HOTHMAIL.COM')
	 AND email not CONTAINS ('HOTMIL.CON')        AND email not CONTAINS ('MZN.COM')
	 AND email not CONTAINS ('HOMAIL.CM')        AND email not CONTAINS ('ICLOUD.OM')
	 AND email not CONTAINS ('HGOTMAIL.COM')     AND email not CONTAINS ('GMIL.CON')
	 AND email not CONTAINS ('LIVE.VOM')       AND email not CONTAINS ('GAIL.CO')
	 AND email not CONTAINS ('GMA9IL.COM')         AND email not CONTAINS ('HTMAIL.CPM')
	 AND email not CONTAINS ('GMAI.LCOM')        AND email not CONTAINS ('GMIL.CM')
	 AND email not CONTAINS ('MSN.CM')      AND email not CONTAINS ('BHOTMAIL.COM')
	 AND email not CONTAINS ('GMAIUL.COM')         AND email not CONTAINS ('HO9TMAIL.COM')
	 AND email not CONTAINS ('HOTMJAIL.COM')       AND email not CONTAINS ('GMA8L.COM')
     AND email not CONTAINS ('GAMIL.CON')      AND email not CONTAINS ('GKMAIL.COM')
	 AND email not CONTAINS ('GMAIL.BOM')         AND email not CONTAINS ('LIE.COM')
	 AND email not CONTAINS ('HOTMIL.CO')       AND email not CONTAINS ('GMAIL.CIOM')
	 AND email not CONTAINS ('LUVE.COM')         AND email not CONTAINS ('NOTMAIL.COM')
	 AND email not CONTAINS ('HOTMQAIL.COM')       AND email not CONTAINS ('HOTMIL.CM')
	 AND email not CONTAINS ('GMAIL.VCOM')     AND email not CONTAINS ('HOTMAIL.CAM')
	 AND email not CONTAINS ('HOTNAIL.CO')        AND email not CONTAINS ('HOTJMAIL.COM')
	 AND email not CONTAINS ('GMIIL.COM')        AND email not CONTAINS ('H9OTMAIL.COM')
	 AND email not CONTAINS ('GYMAIL.COM')     AND email not CONTAINS ('HNOTMAIL.COM')
	 AND email not CONTAINS ('HOTNMAIL.COM')       AND email not CONTAINS ('GMA8IL.COM')
	 AND email not CONTAINS ('GHMAIL.COM')         AND email not CONTAINS ('GJMAIL.COM')
	 AND email not CONTAINS ('GMAWIL.COM')        AND email not CONTAINS ('HOTMMAIL.CO')
	 AND email not CONTAINS ('GMWIL.COM')      AND email not CONTAINS ('LIVD.COM')
	 AND email not CONTAINS ('HYOTMAIL.COM')         AND email not CONTAINS ('HOMAIL.OM')
	 AND email not CONTAINS ('LIVE.CM')       AND email not CONTAINS ('HOMAIL.CON')
	 AND email not CONTAINS ('HLOTMAIL.COM')         AND email not CONTAINS ('HGMAIL.CO')
	 AND email not CONTAINS ('HOTAIL.CO')       AND email not CONTAINS ('GMAKIL.COM')
	 AND email not CONTAINS ('LILVE.COM')         AND email not CONTAINS ('HOOTMAIL.CO')
	 AND email not CONTAINS ('HBOTMAIL.COM')       AND email not CONTAINS ('GMQAIL.COM')
	 AND email not CONTAINS ('LIVE.CIM')     AND email not CONTAINS ('HORMAIL.CON')
	 AND email not CONTAINS ('HOTMAI9L.COM')        AND email not CONTAINS ('GMKAIL.COM')
	 AND email not CONTAINS ('MSMN.COM')        AND email not CONTAINS ('GKAIL.COM')
	 AND email not CONTAINS ('YHAOO.COM')     AND email not CONTAINS ('YAHHO.COM')
	 AND email not CONTAINS ('YAHO.COM')       AND email not CONTAINS ('YAHOIO.COM')
	 AND email not CONTAINS ('YAOO.COM')         AND email not CONTAINS ('YAHOOO.COM')
	 AND email not CONTAINS ('YAHOO.CO')        AND email not CONTAINS ('HOTMAIL.DOM')
	 AND email not CONTAINS ('GMAILL.CM')      AND email not CONTAINS ('HOTMAIL.COM.YAHOO.ES')
	 AND email not CONTAINS ('YQHOO.COM')         AND email not CONTAINS ('HOTMAI.CM')
	 AND email not CONTAINS ('TAHOO.COM')       AND email not CONTAINS ('HOTMA8L.COM')
	 AND email not CONTAINS ('JMAIL.COM')        AND email not CONTAINS ('GIMAIL.CM')
	 AND email not CONTAINS ('GEMAIL.CO')      AND email not CONTAINS ('GIMAIL.CO')
	 AND email not CONTAINS ('YOPMAIL.CO')         AND email not CONTAINS ('HOTMAIL.17.COM')
	 AND email not CONTAINS ('CORREO.OM')       AND email not CONTAINS ('HORMAIL.CO')
	 AND email not CONTAINS ('UTLOOK.COM')         AND email not CONTAINS ('YHOO.COM')
	 AND email not CONTAINS ('YAJOO.COM')       AND email not CONTAINS ('HOTMIAL.CO')
	 AND email not CONTAINS ('YAYOO.COM')         AND email not CONTAINS ('HOTMALIL.COM')
	 AND email not CONTAINS ('YMSIL.COM')       AND email not CONTAINS ('HOTMIAL.CM')
	 AND email not CONTAINS ('YASHOO.COM')     AND email not CONTAINS ('HOTMAILL.CO')
	 AND email not CONTAINS ('YAHOOL.COM')        AND email not CONTAINS ('HOTMAIOL.COM')
	 AND email not CONTAINS ('HOTMMAIL.OM')        AND email not CONTAINS ('YAQHOO.COM')
	 AND email not CONTAINS ('YSHOO.COM')     AND email not CONTAINS ('GMIAL.CON')
	 AND email not CONTAINS ('LIVR.COM')       AND email not CONTAINS ('HOTMAWIL.COM')
	 AND email not CONTAINS ('GMMAIL.CO')         AND email not CONTAINS ('HTMAIL.CM')
	 AND email not CONTAINS ('NAIL.COM')        AND email not CONTAINS ('MAIOL.COM')
	 AND email not CONTAINS ('GM.CON')      AND email not CONTAINS ('GM.CO')
	 AND email not CONTAINS ('HO5TMAIL.COM')         AND email not CONTAINS ('GMAIL.FOM')
	 AND email not CONTAINS ('MAI.CM')       AND email not CONTAINS ('EMAIL.CO')
	 AND email not CONTAINS ('GOTMAIL.CO')        AND email not CONTAINS ('LIVS.COM')
	 AND email not CONTAINS ('LICVE.COM')      AND email not CONTAINS ('MAIL.CON')
	 AND email not CONTAINS ('JMAIL.CO')         AND email not CONTAINS ('MAIIL.COM')
	 AND email not CONTAINS ('GIMEI.CO')       AND email not CONTAINS ('HOTMAILC.OM')
	 AND email not CONTAINS ('GMAILC.OM')         AND email not CONTAINS ('GIMIL.CON')
	 AND email not CONTAINS ('HOTAMAIL.CO')       AND email not CONTAINS ('YMAIL.CM')
	 AND email not CONTAINS ('YMAIL.CO')         AND email not CONTAINS ('OUTLOOOK.COM')
	 AND email not CONTAINS ('GAMIAL.CO')       AND email not CONTAINS ('OITLOOK.COM')
	 AND email not CONTAINS ('ICLUD.CON')     AND email not CONTAINS ('OUTLOOK.CON')
	 AND email not CONTAINS ('AUTLOOK.CO')        AND email not CONTAINS ('GIMEI.CON')
	 AND email not CONTAINS ('OUTLOKK.COM')        AND email not CONTAINS ('GMLI.CON')
	 AND email not CONTAINS ('GMEIL.CO')     AND email not CONTAINS ('GOMAIL.CO')
	 AND email not CONTAINS ('MGMAIL.CO')       AND email not CONTAINS ('GMEIL.CPM')
	 AND email not CONTAINS ('HOTMEIL.COM')         AND email not CONTAINS ('GITMAIL.COM')
	 AND email not CONTAINS ('UMAIL.COM')        AND email not CONTAINS ('HJFJH.CM')
	 AND email not CONTAINS ('GEMEIL.CO')      AND email not CONTAINS ('HIMAIL.CO')
	 AND email not CONTAINS ('GAMAIL.CO')         AND email not CONTAINS ('GIMEIL.CO')
	 AND email not CONTAINS ('GIMIL.COMO')       AND email not CONTAINS ('GIMAL.CON')
	 AND email not CONTAINS ('HOTM.COMAIL')         AND email not CONTAINS ('YNAIL.COM')
	 AND email not CONTAINS ('GIMEIL.CIM')       AND email not CONTAINS ('HOLMAIL.CM')
	 AND email not CONTAINS ('YMIAL.COM')        AND email not CONTAINS ('GMEIL.COMO')
	 AND email not CONTAINS ('HOIMAIL.COM')      AND email not CONTAINS ('HOITMAIL.CL')
	 AND email not CONTAINS ('WWW.HOTMAIL.COM')         AND email not CONTAINS ('THOMAIL.CL')
	 AND email not CONTAINS ('YQAHOO.COM')       AND email not CONTAINS ('HAHOO.COM')
	 AND email not CONTAINS ('YAHOL.COM')         AND email not CONTAINS ('YAGOO.COM')
	 AND email not CONTAINS ('UAHOO.COM')       AND email not CONTAINS ('YAHOO.CM')
	 AND email not CONTAINS ('YAHHOO.COM')         AND email not CONTAINS ('YAAHOO.COM')
	 AND email not CONTAINS ('YSAHOO.COM')       AND email not CONTAINS ('YAHOO.CON.CO')
	 AND email not CONTAINS ('YAHO0.COM')     AND email not CONTAINS ('YAHOOP.COM')
	 AND email not CONTAINS ('YYAHOO.COM')        AND email not CONTAINS ('YABHOO.COM')
	 AND email not CONTAINS ('YAHPOO.COM')        AND email not CONTAINS ('YAHJOO.COM')
	 AND email not CONTAINS ('HYAHOO.COM')     AND email not CONTAINS ('YTAHOO.COM')
	 AND email not CONTAINS ('YAHIO.COM')       AND email not CONTAINS ('UYAHOO.COM')
	 AND email not CONTAINS ('YAHOO0.COM')         AND email not CONTAINS ('YAHOO.COM')
	 AND email not CONTAINS ('YAHOO.CMO')        AND email not CONTAINS ('YAH0O.COM')
	 AND email not CONTAINS ('YABOO.COM')      AND email not CONTAINS ('YAHGOO.COM')
	 AND email not CONTAINS ('TYAHOO.COM')         AND email not CONTAINS ('YAHUOO.COM')
	 AND email not CONTAINS ('YAHO0O.COM')       AND email not CONTAINS ('YUAHOO.COM')
	 AND email not CONTAINS ('GYAHOO.COM')         AND email not CONTAINS ('YHAHOO.COM')
	AND email not in (select email from POLAVARR.CORREOS_FAKE_V2)
;QUIT;

/*Eliminar tablas de Paso de TEFs*/
PROC SQL;
CREATE TABLE BASE_EMAIL_FISA AS
   	SELECT 	t7.rut, 
          	t7.EMAIL length=50, 
			input(put(datepart(t7.FECHA_ACTUALIZACION),yymmddn8.),best.) as FECHA_ACT,
            t7.sequencia,
            t7.ORIGEN
 	FROM BASE_EMAIL_FISA_CANON t7
	WHERE t7.sequencia = 7
;QUIT;

PROC SQL;
   CREATE TABLE R_CORREOS_FISA_MAX AS 
   SELECT distinct t1.RUT, 
          t1.email 	AS EMAIL, 
          MAX(t1.FECHA_ACT) AS FECHA_ACT
      FROM BASE_EMAIL_FISA t1
      GROUP BY t1.rut;
QUIT;

proc sql;
create table RESULT.BASE_EMAIL_FISA AS
	SELECT	DISTINCT T1.RUT, 
	        T1.EMAIL, 	      
			t2.FECHA_ACT,
			t2.sequencia,
            t2.ORIGEN
	    FROM R_CORREOS_FISA_MAX t1 INNER JOIN BASE_EMAIL_FISA T2
			ON (T1.RUT = T2.RUT AND T1.FECHA_ACT = T2.FECHA_ACT AND T1.EMAIL = T2.EMAIL)
		WHERE T2.FECHA_ACT IS NOT MISSING AND T2.RUT < 99999999 AND T2.RUT > 10000
;QUIT;

PROC SQL;
CREATE TABLE BASE_EMAIL_CANON AS
   	SELECT 	t8.rut, 
          	t8.EMAIL length=50, 
			input(put(datepart(t8.FECHA_ACTUALIZACION),yymmddn8.),best.) as FECHA_ACT,
            t8.sequencia,
            t8.ORIGEN
 	FROM BASE_EMAIL_FISA_CANON t8
	WHERE t8.sequencia = 8
;QUIT;

PROC SQL;
   CREATE TABLE R_CORREOS_CANON_MAX AS 
   SELECT distinct t1.RUT, 
          t1.email 	AS EMAIL, 
          MAX(t1.FECHA_ACT) AS FECHA_ACT
      FROM BASE_EMAIL_CANON t1
      GROUP BY t1.rut;
QUIT;

proc sql;
create table RESULT.BASE_EMAIL_CANON AS
	SELECT	DISTINCT T1.RUT, 
	        T1.EMAIL, 	      
			t2.FECHA_ACT,
			t2.sequencia,
            t2.ORIGEN
	    FROM R_CORREOS_CANON_MAX t1 INNER JOIN BASE_EMAIL_CANON T2
			ON (T1.RUT = T2.RUT AND T1.FECHA_ACT = T2.FECHA_ACT AND T1.EMAIL = T2.EMAIL)
		WHERE T2.FECHA_ACT IS NOT MISSING AND T2.RUT < 99999999 AND T2.RUT > 10000
;QUIT;

PROC SQL;
	DROP TABLE BASE_EMAIL_FISA_CANON;
	DROP TABLE BASE_EMAIL_FISA;
	DROP TABLE R_CORREOS_FISA_MAX;
	DROP TABLE BASE_EMAIL_CANON;
	DROP TABLE R_CORREOS_CANON_MAX;
;QUIT;

PROC SQL;
CREATE INDEX rut ON RESULT.BASE_EMAIL_FISA (RUT);
QUIT;

PROC SQL;
CREATE INDEX rut ON RESULT.BASE_EMAIL_CANON (RUT);
QUIT;

/*=========================================================================================*/
/*======	3.- Obtener Emails desde: BOPERS todos los que no estén dados de baja	=======*/
/*=========================================================================================*/
LIBNAME R_bopers ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=BOPERS_ADM  USER='SAS_USR_BI' PASSWORD='SAS_23072020';
PROC SQL;
   CREATE TABLE result.R_BOPERS_TOTALES2 AS 
   SELECT	DISTINCT input(ide.PEMID_GLS_NRO_DCT_IDE_K,best.)	AS RUT,
   			ide.pemid_nro_inn_ide			AS IDINTERNO,
			dml.PEMDM_NRO_SEQ_DML_K 		AS SEQ_ID,
           	compress(upcase(t2.PEMMA_GLS_DML_MAI)) 		AS EMAIL length=50,
			input(put(datepart(t2.PEMMA_FCH_FIN_ACL),yymmddn8.),best.) AS FECHA_ACT,
			t2.PEMMA_COD_EST_LCL 			AS ESTADO_ACT_VER,
            (t2.PEMMA_NRO_SEQ_MAI_K) 		AS SEQUENCIA,
			CASE 	WHEN t2.PEMMA_GLS_USR_FIN_ACL = 'HB-APP'	then 'BOPERS_HB'
					WHEN t2.PEMMA_GLS_USR_FIN_ACL = 'APP' 		then 'BOPERS_APP' 
					ELSE 'BOPERS_CCSS' END as ORIGEN
		FROM	r_BOPERS.BOPERS_MAE_IDE ide, 		r_BOPERS.bopers_mae_dml dml, 
				r_BOPERS.bopers_rel_ing_lcl lcl, 	r_BOPERS.BOPERS_MAE_MAI t2
		   WHERE 	t2.PEMMA_COD_EST_LCL NOT = 6 
		   and		lcl.peril_cod_tip_lcl_dos_k = 4 and
					lcl.peril_cod_tip_lcl_uno_k = 1 and
					lcl.peril_nro_seq_lcl_uno_k = dml.PEMDM_NRO_SEQ_DML_K and
					lcl.pemid_nro_inn_ide_k=ide.pemid_nro_inn_ide and
					dml.pemid_nro_inn_ide_k=ide.pemid_nro_inn_ide and
					dml.PEMDM_COD_DML_PPA=1 and
					dml.pemdm_cod_tip_dml = 1 and
					dml.pemdm_cod_neg_dml = 1 and
					t2.PEMID_NRO_INN_IDE_K = ide.pemid_nro_inn_ide and
					t2.PEMMA_NRO_SEQ_MAI_K = lcl.PERIL_NRO_SEQ_LCL_DOS_K
			ORDER BY 1
;QUIT;

PROC SQL;
   CREATE TABLE RESULT.R_BOPERS_TOTALES_EMAIL AS 
   SELECT	t1.*
		FROM	result.R_BOPERS_TOTALES2 t1 left join POLAVARR.CORREOS_FAKE_V2 t2
				ON (T1.EMAIL = T2.EMAIL) WHERE T2.EMAIL IS MISSING
				AND t1.email not LIKE ('.-%') 					AND t1.email not LIKE ('%.')
				AND t1.email not LIKE		('-%')				AND t1.email not LIKE	('%.@%')
                AND t1.email not CONTAINS 	('XXXXX')
				AND t1.email not CONTAINS 	('DEFAULT')			AND t1.email not CONTAINS 	('TEST@')
				AND t1.email not CONTAINS 	('..')				AND t1.email not CONTAINS 	('PRUEBA')
				AND t1.email not CONTAINS	('(')				AND t1.email not CONTAINS 	(')')
				AND t1.email not CONTAINS	('/')				AND t1.email not CONTAINS	('?')
				AND t1.email not CONTAINS 	('¿')				AND t1.email not CONTAINS 	('SINMAIL')
				AND t1.email not CONTAINS 	('NOTIENE')			AND t1.email not CONTAINS 	('NOTENGO')
				AND t1.email not CONTAINS 	('SINCORRE')		AND t1.email not CONTAINS 	('TEST@')
				AND t1.email <>'@'								AND t1.email not CONTAINS	('GFFDF')
				AND t1.email not CONTAINS 	('0000000')			AND t1.email not CONTAINS 	('GMAIL.CL')
				AND t1.email not CONTAINS 	('GMAIL.ES')		AND t1.email <>'0'
				AND t1.email CONTAINS 		('@')				AND t1.email not CONTAINS 	('SINEMAIL')
				AND t1.email not CONTAINS 	('NOREGISTRA')  	AND t1.email not CONTAINS 	('SINMALLIL') 
				AND t1.email not CONTAINS 	('@MAILINATOR.COM')	AND t1.email not CONTAINS ('@MICORREO.COM')	
				AND t1.email not CONTAINS 	('@HOTRMAIL.COM')	AND t1.email not CONTAINS	('@SDFDF.CL' )
				/*agregado pia*/
	 AND t1.email not CONTAINS ('HORTMAIL.COM')       AND t1.email not CONTAINS ('REPLEY.COM')
	 AND t1.email not CONTAINS ('BANCPORIPLEY.COM')       AND t1.email not CONTAINS ('GMAL.COM')
	 AND t1.email not CONTAINS ('RILPLEY.COM')       AND t1.email not CONTAINS ('HOTMAI.COM')
	 AND t1.email not CONTAINS ('GAMIL.COM')       AND t1.email not CONTAINS ('RIPEY.CL')
	 AND t1.email not CONTAINS ('RIPLEY.VOM')       AND t1.email not CONTAINS ('HTOMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.CON')       AND t1.email not CONTAINS ('GMIL.COM')
	 AND t1.email not CONTAINS ('HOTAMIL.COM')       AND t1.email not CONTAINS ('123MAIL.CL')
	 AND t1.email not CONTAINS ('ICLOOUD.COM')       AND t1.email not CONTAINS ('YMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMIAL.COM')       AND t1.email not CONTAINS ('GMAI.COM')
	 AND t1.email not CONTAINS ('HOTMAIL.OM')       AND t1.email not CONTAINS ('GMAIIL.COM')
	 AND t1.email not CONTAINS ('RIOLPLEY.COM')       AND t1.email not CONTAINS ('aol.com')
	 AND t1.email not CONTAINS ('GMSAIL.COM')       AND t1.email not CONTAINS ('ICLOU.COM')
	 AND t1.email not CONTAINS ('GMAIL.CM')       AND t1.email not CONTAINS ('GMIAL.COM')
	 AND t1.email not CONTAINS ('UAHOO.COM')       AND t1.email not CONTAINS ('HOTMAIL.OCM')
	 AND t1.email not CONTAINS ('GMAILC.OM')       AND t1.email not CONTAINS ('UTLOOOK.COM')
	 AND t1.email not CONTAINS ('RIPLE.COM')       AND t1.email not CONTAINS ('GMAILL.COM')
	 AND t1.email not CONTAINS ('GMAOL.COM')       AND t1.email not CONTAINS ('HORMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMAL.COM')      /*AND t1.email not CONTAINS ('OTMAIL.COM')*/
	 AND t1.email not CONTAINS ('2HOTMAIL.ES')       AND t1.email not CONTAINS ('XXX.COM')
	 AND t1.email not CONTAINS ('AUTLOOK.COM')       AND t1.email not CONTAINS ('8GMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMN')       AND t1.email not CONTAINS ('OITLOOK.COM')
	 AND t1.email not CONTAINS ('OUTLOCK.COM')       AND t1.email not CONTAINS ('GMAIL.OM')
	 AND t1.email not CONTAINS ('GMAIL.LCOM')       AND t1.email not CONTAINS ('OUTLLOK.CL')
	 AND t1.email not CONTAINS ('OULOOCK.ES')       AND t1.email not CONTAINS ('OULOOKS.ES')
	 AND t1.email not CONTAINS ('GAMIAL.COM')       AND t1.email not CONTAINS ('HOTMAILL.COM')
	 AND t1.email not CONTAINS ('GMAIL.CPM')       AND t1.email not CONTAINS ('64GMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIOL.COM')
	 /*agregado email Lore Gerrero*/
     	 AND t1.email not CONTAINS ('yahho.com')       AND t1.email not CONTAINS ('EMAIL.CON')
	 AND t1.email not CONTAINS ('OUTLOKK.ES')       AND t1.email not CONTAINS ('HORMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.VOM')       AND t1.email not CONTAINS ('YAHOO.CL')
	 AND t1.email not CONTAINS ('GMEIL.CL')       AND t1.email not CONTAINS ('GMAKL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COL')       AND t1.email not CONTAINS ('GMAIL.COMO')
	 AND t1.email not CONTAINS ('GHOTMAIL.COM')       AND t1.email not CONTAINS ('GMAIL.COMF')
	 AND t1.email not CONTAINS ('LIVE.CK')       AND t1.email not CONTAINS ('GMEIL.CMMAIL.COM')
	 AND t1.email not CONTAINS ('GMMAIL.COM')       AND t1.email not CONTAINS ('HOTMKAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMHOTMAIL.COM')       AND t1.email not CONTAINS ('HOTRMAIL.COM')
	 AND t1.email not CONTAINS ('HOIMAIL.COM')       AND t1.email not CONTAINS ('XN--GMAI-JQA.COM')
	 AND t1.email not CONTAINS ('HMAIL.COM')       AND t1.email not CONTAINS ('OUTLOOK.CM')
	 AND t1.email not CONTAINS ('HATMAIL.CON')       AND t1.email not CONTAINS ('GMAIL.COMON')
	 AND t1.email not CONTAINS ('GMIL.CO')       AND t1.email not CONTAINS ('GMALL.COM')
	 AND t1.email not CONTAINS ('HOTMAIAL.COM')       AND t1.email not CONTAINS ('GMAIK.COM')
	 AND t1.email not CONTAINS ('OUTLOOCK.COM')       AND t1.email not CONTAINS ('GMAQIL.COM')
	 AND t1.email not CONTAINS ('GMAILC.OM')       AND t1.email not CONTAINS ('GMAIA.COM')
	 AND t1.email not CONTAINS ('HOTMAIL.COL')       AND t1.email not CONTAINS ('GMNAIL.COM')
	 AND t1.email not CONTAINS ('OUTLLOOK.ES')       AND t1.email not CONTAINS ('GMEIL.CON')
	 	 /*agregados de la base de simulacion hb new*/
     /*  AND t1.email not CONTAINS ('GMAIL.CO') */	          AND t1.email not CONTAINS ('GMAIL.COMU')
	AND t1.email not CONTAINS ('GMAIL.CON')           AND t1.email not CONTAINS ('123MAIL.CL')
	 AND t1.email not CONTAINS ('GMAIL.COMOESTAS')    AND t1.email not CONTAINS ('GMAIL.COMO')
	 AND t1.email not CONTAINS ('GIMAIL.COM')        AND t1.email not CONTAINS ('GMAL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMM')        AND t1.email not CONTAINS ('GMAIL.XOM')
	 AND t1.email not CONTAINS ('GMAIL.CM')         AND t1.email not CONTAINS ('GIMEIL.COM')
	 AND t1.email not CONTAINS ('HOTMIAL.COM')       AND t1.email not CONTAINS ('HOOTMAIL.ES')
	 AND t1.email not CONTAINS ('HOTMAIL.CON')       AND t1.email not CONTAINS ('GIMAIL.CON')
	 AND t1.email not CONTAINS ('HOTMEIL.COM')       AND t1.email not CONTAINS ('GMAIL.VOM')
	 AND t1.email not CONTAINS ('HOTMEIL.ES')        AND t1.email not CONTAINS ('GMAIL.CL.COM')
	 AND t1.email not CONTAINS ('GIMAL.COM')         AND t1.email not CONTAINS ('GMAIL.COMIL.COM')
	 AND t1.email not CONTAINS ('HOTMAIK.COM')       AND t1.email not CONTAINS ('GMAIL.COMQ')
	 AND t1.email not CONTAINS ('HOTMAIIL.COM')      AND t1.email not CONTAINS ('HOTMAIL.CPM')
	AND t1.email not CONTAINS ('GMAIL.COML')        AND t1.email not CONTAINS ('G.MAIL.COM')
	 AND t1.email not CONTAINS ('HOTMAOL.COM')       AND t1.email not CONTAINS ('GMAILL.COM')
	 AND t1.email not CONTAINS ('GIMAIL.CL')         AND t1.email not CONTAINS ('GMAIL.COMD')
	 AND t1.email not CONTAINS ('HOTTMAIL.COM')      AND t1.email not CONTAINS ('HOTMAILC.OM')
	 AND t1.email not CONTAINS ('1967GMAIL.COM')     AND t1.email not CONTAINS ('HOTMAY.COM')
	/* AND t1.email not CONTAINS ('HOTMAIL.CO') */       AND t1.email not CONTAINS ('GMIAL.COM')
	 AND t1.email not CONTAINS ('2382HOTMAIL.COM')   AND t1.email not CONTAINS ('GMALL.COM')
	 AND t1.email not CONTAINS ('GIMALL.COM')        AND t1.email not CONTAINS ('HOTMAIL.COMBUE')
	 AND t1.email not CONTAINS ('GMAIL.CPM')         AND t1.email not CONTAINS ('123GMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMP')        AND t1.email not CONTAINS ('GMIL.CPM')
	 AND t1.email not CONTAINS ('GMALI.COM')         AND t1.email not CONTAINS ('JAJAJA.CL')
	 AND t1.email not CONTAINS ('AUTLOOK.COM')       AND t1.email not CONTAINS ('GMAIL.CLOM')
	 AND t1.email not CONTAINS ('GMAIL.COMCOM')      AND t1.email not CONTAINS ('GMAIL.CIM')
	 AND t1.email not CONTAINS ('ICLOUD.CON')        AND t1.email not CONTAINS ('OUTLOOK.COMM')
	 AND t1.email not CONTAINS ('HOTMEIL.CL')        AND t1.email not CONTAINS ('HOTMAIO.COM')
	 AND t1.email not CONTAINS ('GMAIL.COPM')        AND t1.email not CONTAINS ('GAIML.COM')
	AND t1.email not CONTAINS ('HOTMAIL.COMO')      AND t1.email not CONTAINS ('JAJAGMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMEMAIL')    AND t1.email not CONTAINS ('HOTMAIL.COMR')
	 AND t1.email not CONTAINS ('OULTOOK.CL')        AND t1.email not CONTAINS ('BANCORYPLEY.CL')
	 AND t1.email not CONTAINS ('GMAIM.COM')         AND t1.email not CONTAINS ('B8477491ANCORIPLEY.COM')
	AND t1.email not CONTAINS ('GMAIL.COMN')        AND t1.email not CONTAINS ('GMMAIL.COM')
	 AND t1.email not CONTAINS ('2857GMAIL.COM')     AND t1.email not CONTAINS ('HOTMAIEL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COL')         AND t1.email not CONTAINS ('GHOTMAIL.COM')
	/* AND t1.email not CONTAINS ('OUTLOOK.CO')*/        AND t1.email not CONTAINS ('GMAIIL.COM')
	 AND t1.email not CONTAINS ('OUTLOOK.CON')       AND t1.email not CONTAINS ('LIVE.CM')
	 AND t1.email not CONTAINS ('HOGMAIL.ES')        AND t1.email not CONTAINS ('GMAIL.COMQQSWS')
	 AND t1.email not CONTAINS ('HOTMAKL.COM')       AND t1.email not CONTAINS ('GMAIL.CO.COM')
	AND t1.email not CONTAINS ('HOTMAUL.COM')        AND t1.email not CONTAINS ('OUTLOOCK.COM')
	 AND t1.email not CONTAINS ('GMANIL.COM')        AND t1.email not CONTAINS ('OUTLOO.COM')
	 AND t1.email not CONTAINS ('ICLUD.COM')         AND t1.email not CONTAINS ('GMAIL.COM.CL')
	 AND t1.email not CONTAINS ('OUTLLOK.COM')       AND t1.email not CONTAINS ('GMAIL.COK')
	 AND t1.email not CONTAINS ('GMAIL.COM.COM')     AND t1.email not CONTAINS ('OULOOK.COM')
	 AND t1.email not CONTAINS ('OUTOOK.COM')        AND t1.email not CONTAINS ('59GMEIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.CCOM')        AND t1.email not CONTAINS ('GMAIL.COOM')
	 AND t1.email not CONTAINS ('434GOTMAIL.CL')     AND t1.email not CONTAINS ('GM8AIL.COM')
	 AND t1.email not CONTAINS ('HOGMAIL.COM')       AND t1.email not CONTAINS ('GMAIL.COMA')
	 AND t1.email not CONTAINS ('GMAIIL.CO')         AND t1.email not CONTAINS ('HOTMEY.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMS')        AND t1.email not CONTAINS ('YAHUU.COM')
	 AND t1.email not CONTAINS ('A01GMAIL.COM')      AND t1.email not CONTAINS ('HOTMAIL.COL')
	 AND t1.email not CONTAINS ('GMAIO.COM')         AND t1.email not CONTAINS ('GMAIL.GMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMOM')       AND t1.email not CONTAINS ('HOTMAIM.COM')
	AND t1.email not CONTAINS ('HOTMAIL.COMK')
		/* AGREGADOS POR ANALISIS DE WEBBULA */
	 AND t1.email not CONTAINS ('GMSIL.COM')       AND t1.email not CONTAINS ('MC.COM')
	 AND t1.email not CONTAINS ('LIVER.COM')        AND t1.email not CONTAINS ('HOMAIL.COM')
	 AND t1.email not CONTAINS ('GMAUL.COM')       AND t1.email not CONTAINS ('HTMAIL.COM')
  	 AND t1.email not CONTAINS ('GNAIL.COM')        AND t1.email not CONTAINS ('HOYMAIL.COM')
     AND t1.email not CONTAINS ('LIV.COM')        AND t1.email not CONTAINS ('HPTMAIL.COM')
	 AND t1.email not CONTAINS ('GMAOIL.COM')         AND t1.email not CONTAINS ('HOTMWIL.COM')
	 AND t1.email not CONTAINS ('GMAAIL.COM')       AND t1.email not CONTAINS ('GMASIL.COM')
	 AND t1.email not CONTAINS ('GFMAIL.COM')     AND t1.email not CONTAINS ('MGAIL.COM')
	 AND t1.email not CONTAINS ('H0TMAIL.COM')        AND t1.email not CONTAINS ('GMJAIL.COM')
	 AND t1.email not CONTAINS ('FGMAIL.COM')        AND t1.email not CONTAINS ('HOTMAAIL.CO')
	 AND t1.email not CONTAINS ('HITMAIL.COM')     AND t1.email not CONTAINS ('HOTMAIL.COMQUE')
	 AND t1.email not CONTAINS ('HOTMASIL.COM')       AND t1.email not CONTAINS ('HOTAIL.COM')
	 AND t1.email not CONTAINS ('GOTMAIL.COM')         AND t1.email not CONTAINS ('GTMAIL.COM')
	 AND t1.email not CONTAINS ('NSN.COM')        AND t1.email not CONTAINS ('HOTMSIL.COM')
	 AND t1.email not CONTAINS ('FMAIL.COM')      AND t1.email not CONTAINS ('HOTMAOIL.COM')
	 AND t1.email not CONTAINS ('HOMTAIL.COM')         AND t1.email not CONTAINS ('LIUVE.COM')
	 AND t1.email not CONTAINS ('GMAILO.COM')       AND t1.email not CONTAINS ('GGMAIL.COM')
	 AND t1.email not CONTAINS ('JOTMAIL.COM')       AND t1.email not CONTAINS ('GMQIL.COM')
	 AND t1.email not CONTAINS ('GMAIKL.COM')        AND t1.email not CONTAINS ('HOTMSAIL.COM')
	 AND t1.email not CONTAINS ('GAIL.COM')       AND t1.email not CONTAINS ('GMAIL.COMCIMI')
	 AND t1.email not CONTAINS ('LICE.COM')        AND t1.email not CONTAINS ('GMAIL.CKM')
     AND t1.email not CONTAINS ('HHOTMAIL.COM')        AND t1.email not CONTAINS ('HLTMAIL.COM')
	 AND t1.email not CONTAINS ('ICLOUB.COM')         AND t1.email not CONTAINS ('HOTMAIL.COOM')
	 AND t1.email not CONTAINS ('HOTMAIKL.COM')       AND t1.email not CONTAINS ('HJOTMAIL.COM')
	 AND t1.email not CONTAINS ('HOPTMAIL.COM')     AND t1.email not CONTAINS ('HOTMAIUL.COM')
	 AND t1.email not CONTAINS ('HOTMMAIL.COM')        AND t1.email not CONTAINS ('HOTMALL.COM')
	 AND t1.email not CONTAINS ('HOTGMAIL.COM')        AND t1.email not CONTAINS ('LIVE.COL')
	 AND t1.email not CONTAINS ('HOTNAIL.COM')     AND t1.email not CONTAINS ('LIBE.COM')
	 AND t1.email not CONTAINS ('GMAUIL.COM')       AND t1.email not CONTAINS ('H0OTMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMAQIL.COM')         AND t1.email not CONTAINS ('GMAI9L.COM')
	 AND t1.email not CONTAINS ('GNMAIL.COM')        AND t1.email not CONTAINS ('HOTMAILK.COM')
	 AND t1.email not CONTAINS ('HOYTMAIL.COM')      AND t1.email not CONTAINS ('HOTMAIL.CM')
	 AND t1.email not CONTAINS ('HOTMAAIL.COM')         AND t1.email not CONTAINS ('HOTFMAIL.COM')
	 AND t1.email not CONTAINS ('HOMAIL.CO')       AND t1.email not CONTAINS ('HIOTMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMAKIL.COM')         AND t1.email not CONTAINS ('GMAILK.COM')
	 AND t1.email not CONTAINS ('HOHTMAIL.COM')       AND t1.email not CONTAINS ('HOTYMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMAUIL.COM')     AND t1.email not CONTAINS ('ME.CM')
	 AND t1.email not CONTAINS ('HOTMAIL.COIM')        AND t1.email not CONTAINS ('L8VE.COM')
	 AND t1.email not CONTAINS ('HOTMNAIL.COM')        AND t1.email not CONTAINS ('OHTMAIL.COM')
	 AND t1.email not CONTAINS ('HOT6MAIL.COM')     AND t1.email not CONTAINS ('GMQIL.VOM')
	 AND t1.email not CONTAINS ('GMZAIL.COM')       AND t1.email not CONTAINS ('LIVE.CCOM')
	 AND t1.email not CONTAINS ('LIVEW.COM')         AND t1.email not CONTAINS ('YGMAIL.COM')
	 AND t1.email not CONTAINS ('BOTMAIL.COM')        AND t1.email not CONTAINS ('GMAIL.CO9M')
	 AND t1.email not CONTAINS ('GMAIL.COMG')      AND t1.email not CONTAINS ('HOTMAIL.CIOM')
	 AND t1.email not CONTAINS ('HPOTMAIL.COM')         AND t1.email not CONTAINS ('MAIL.CM')
	 AND t1.email not CONTAINS ('HOHMAIL.COM')       AND t1.email not CONTAINS ('HOTMAIL.COPM')
	 AND t1.email not CONTAINS ('HOT5MAIL.COM')        AND t1.email not CONTAINS ('GMZIL.COM')
	 AND t1.email not CONTAINS ('HOLTMAIL.COM')      AND t1.email not CONTAINS ('LIVE.CON')
	 AND t1.email not CONTAINS ('HUOTMAIL.COM')         AND t1.email not CONTAINS ('MSNM.COM')
	 AND t1.email not CONTAINS ('HO0TMAIL.COM')       AND t1.email not CONTAINS ('HOTMAI.COK')
	 AND t1.email not CONTAINS ('GMAZIL.COM')         AND t1.email not CONTAINS ('LVIE.COM')
	 AND t1.email not CONTAINS ('HOTMAIL.CCOM')       AND t1.email not CONTAINS ('HOTMAIL.CLOM')
	 AND t1.email not CONTAINS ('HOOTMAIL.COM')     AND t1.email not CONTAINS ('HOTHMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMIL.CON')        AND t1.email not CONTAINS ('MZN.COM')
	 AND t1.email not CONTAINS ('HOMAIL.CM')        AND t1.email not CONTAINS ('ICLOUD.OM')
	 AND t1.email not CONTAINS ('HGOTMAIL.COM')     AND t1.email not CONTAINS ('GMIL.CON')
	 AND t1.email not CONTAINS ('LIVE.VOM')       AND t1.email not CONTAINS ('GAIL.CO')
	 AND t1.email not CONTAINS ('GMA9IL.COM')         AND t1.email not CONTAINS ('HTMAIL.CPM')
	 AND t1.email not CONTAINS ('GMAI.LCOM')        AND t1.email not CONTAINS ('GMIL.CM')
	 AND t1.email not CONTAINS ('MSN.CM')      AND t1.email not CONTAINS ('BHOTMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIUL.COM')         AND t1.email not CONTAINS ('HO9TMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMJAIL.COM')       AND t1.email not CONTAINS ('GMA8L.COM')
     AND t1.email not CONTAINS ('GAMIL.CON')      AND t1.email not CONTAINS ('GKMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.BOM')         AND t1.email not CONTAINS ('LIE.COM')
	 AND t1.email not CONTAINS ('HOTMIL.CO')       AND t1.email not CONTAINS ('GMAIL.CIOM')
	 AND t1.email not CONTAINS ('LUVE.COM')         AND t1.email not CONTAINS ('NOTMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMQAIL.COM')       AND t1.email not CONTAINS ('HOTMIL.CM')
	 AND t1.email not CONTAINS ('GMAIL.VCOM')     AND t1.email not CONTAINS ('HOTMAIL.CAM')
	 AND t1.email not CONTAINS ('HOTNAIL.CO')        AND t1.email not CONTAINS ('HOTJMAIL.COM')
	 AND t1.email not CONTAINS ('GMIIL.COM')        AND t1.email not CONTAINS ('H9OTMAIL.COM')
	 AND t1.email not CONTAINS ('GYMAIL.COM')     AND t1.email not CONTAINS ('HNOTMAIL.COM')
	 AND t1.email not CONTAINS ('HOTNMAIL.COM')       AND t1.email not CONTAINS ('GMA8IL.COM')
	 AND t1.email not CONTAINS ('GHMAIL.COM')         AND t1.email not CONTAINS ('GJMAIL.COM')
	 AND t1.email not CONTAINS ('GMAWIL.COM')        AND t1.email not CONTAINS ('HOTMMAIL.CO')
	 AND t1.email not CONTAINS ('GMWIL.COM')      AND t1.email not CONTAINS ('LIVD.COM')
	 AND t1.email not CONTAINS ('HYOTMAIL.COM')         AND t1.email not CONTAINS ('HOMAIL.OM')
	 AND t1.email not CONTAINS ('LIVE.CM')       AND t1.email not CONTAINS ('HOMAIL.CON')
	 AND t1.email not CONTAINS ('HLOTMAIL.COM')         AND t1.email not CONTAINS ('HGMAIL.CO')
	 AND t1.email not CONTAINS ('HOTAIL.CO')       AND t1.email not CONTAINS ('GMAKIL.COM')
	 AND t1.email not CONTAINS ('LILVE.COM')         AND t1.email not CONTAINS ('HOOTMAIL.CO')
	 AND t1.email not CONTAINS ('HBOTMAIL.COM')       AND t1.email not CONTAINS ('GMQAIL.COM')
	 AND t1.email not CONTAINS ('LIVE.CIM')     AND t1.email not CONTAINS ('HORMAIL.CON')
	 AND t1.email not CONTAINS ('HOTMAI9L.COM')        AND t1.email not CONTAINS ('GMKAIL.COM')
	 AND t1.email not CONTAINS ('MSMN.COM')        AND t1.email not CONTAINS ('GKAIL.COM')
	 AND t1.email not CONTAINS ('YHAOO.COM')     AND t1.email not CONTAINS ('YAHHO.COM')
	 AND t1.email not CONTAINS ('YAHO.COM')       AND t1.email not CONTAINS ('YAHOIO.COM')
	 AND t1.email not CONTAINS ('YAOO.COM')         AND t1.email not CONTAINS ('YAHOOO.COM')
	 AND t1.email not CONTAINS ('YAHOO.CO')        AND t1.email not CONTAINS ('HOTMAIL.DOM')
	 AND t1.email not CONTAINS ('GMAILL.CM')      AND t1.email not CONTAINS ('HOTMAIL.COM.YAHOO.ES')
	 AND t1.email not CONTAINS ('YQHOO.COM')         AND t1.email not CONTAINS ('HOTMAI.CM')
	 AND t1.email not CONTAINS ('TAHOO.COM')       AND t1.email not CONTAINS ('HOTMA8L.COM')
	 AND t1.email not CONTAINS ('JMAIL.COM')        AND t1.email not CONTAINS ('GIMAIL.CM')
	 AND t1.email not CONTAINS ('GEMAIL.CO')      AND t1.email not CONTAINS ('GIMAIL.CO')
	 AND t1.email not CONTAINS ('YOPMAIL.CO')         AND t1.email not CONTAINS ('HOTMAIL.17.COM')
	 AND t1.email not CONTAINS ('CORREO.OM')       AND t1.email not CONTAINS ('HORMAIL.CO')
	 AND t1.email not CONTAINS ('UTLOOK.COM')         AND t1.email not CONTAINS ('YHOO.COM')
	 AND t1.email not CONTAINS ('YAJOO.COM')       AND t1.email not CONTAINS ('HOTMIAL.CO')
	 AND t1.email not CONTAINS ('YAYOO.COM')         AND t1.email not CONTAINS ('HOTMALIL.COM')
	 AND t1.email not CONTAINS ('YMSIL.COM')       AND t1.email not CONTAINS ('HOTMIAL.CM')
	 AND t1.email not CONTAINS ('YASHOO.COM')     AND t1.email not CONTAINS ('HOTMAILL.CO')
	 AND t1.email not CONTAINS ('YAHOOL.COM')        AND t1.email not CONTAINS ('HOTMAIOL.COM')
	 AND t1.email not CONTAINS ('HOTMMAIL.OM')        AND t1.email not CONTAINS ('YAQHOO.COM')
	 AND t1.email not CONTAINS ('YSHOO.COM')     AND t1.email not CONTAINS ('GMIAL.CON')
	 AND t1.email not CONTAINS ('LIVR.COM')       AND t1.email not CONTAINS ('HOTMAWIL.COM')
	 AND t1.email not CONTAINS ('GMMAIL.CO')         AND t1.email not CONTAINS ('HTMAIL.CM')
	 AND t1.email not CONTAINS ('NAIL.COM')        AND t1.email not CONTAINS ('MAIOL.COM')
	 AND t1.email not CONTAINS ('GM.CON')      AND t1.email not CONTAINS ('GM.CO')
	 AND t1.email not CONTAINS ('HO5TMAIL.COM')         AND t1.email not CONTAINS ('GMAIL.FOM')
	 AND t1.email not CONTAINS ('MAI.CM')       AND t1.email not CONTAINS ('EMAIL.CO')
	 AND t1.email not CONTAINS ('GOTMAIL.CO')        AND t1.email not CONTAINS ('LIVS.COM')
	 AND t1.email not CONTAINS ('LICVE.COM')      AND t1.email not CONTAINS ('MAIL.CON')
	 AND t1.email not CONTAINS ('JMAIL.CO')         AND t1.email not CONTAINS ('MAIIL.COM')
	 AND t1.email not CONTAINS ('GIMEI.CO')       AND t1.email not CONTAINS ('HOTMAILC.OM')
	 AND t1.email not CONTAINS ('GMAILC.OM')         AND t1.email not CONTAINS ('GIMIL.CON')
	 AND t1.email not CONTAINS ('HOTAMAIL.CO')       AND t1.email not CONTAINS ('YMAIL.CM')
	 AND t1.email not CONTAINS ('YMAIL.CO')         AND t1.email not CONTAINS ('OUTLOOOK.COM')
	 AND t1.email not CONTAINS ('GAMIAL.CO')       AND t1.email not CONTAINS ('OITLOOK.COM')
	 AND t1.email not CONTAINS ('ICLUD.CON')     AND t1.email not CONTAINS ('OUTLOOK.CON')
	 AND t1.email not CONTAINS ('AUTLOOK.CO')        AND t1.email not CONTAINS ('GIMEI.CON')
	 AND t1.email not CONTAINS ('OUTLOKK.COM')        AND t1.email not CONTAINS ('GMLI.CON')
	 AND t1.email not CONTAINS ('GMEIL.CO')     AND t1.email not CONTAINS ('GOMAIL.CO')
	 AND t1.email not CONTAINS ('MGMAIL.CO')       AND t1.email not CONTAINS ('GMEIL.CPM')
	 AND t1.email not CONTAINS ('HOTMEIL.COM')         AND t1.email not CONTAINS ('GITMAIL.COM')
	 AND t1.email not CONTAINS ('UMAIL.COM')        AND t1.email not CONTAINS ('HJFJH.CM')
	 AND t1.email not CONTAINS ('GEMEIL.CO')      AND t1.email not CONTAINS ('HIMAIL.CO')
	 AND t1.email not CONTAINS ('GAMAIL.CO')         AND t1.email not CONTAINS ('GIMEIL.CO')
	 AND t1.email not CONTAINS ('GIMIL.COMO')       AND t1.email not CONTAINS ('GIMAL.CON')
	 AND t1.email not CONTAINS ('HOTM.COMAIL')         AND t1.email not CONTAINS ('YNAIL.COM')
	 AND t1.email not CONTAINS ('GIMEIL.CIM')       AND t1.email not CONTAINS ('HOLMAIL.CM')
	 AND t1.email not CONTAINS ('YMIAL.COM')        AND t1.email not CONTAINS ('GMEIL.COMO')
	 AND t1.email not CONTAINS ('HOIMAIL.COM')      AND t1.email not CONTAINS ('HOITMAIL.CL')
	 AND t1.email not CONTAINS ('WWW.HOTMAIL.COM')         AND t1.email not CONTAINS ('THOMAIL.CL')
	 AND t1.email not CONTAINS ('YQAHOO.COM')       AND t1.email not CONTAINS ('HAHOO.COM')
	 AND t1.email not CONTAINS ('YAHOL.COM')         AND t1.email not CONTAINS ('YAGOO.COM')
	 AND t1.email not CONTAINS ('UAHOO.COM')       AND t1.email not CONTAINS ('YAHOO.CM')
	 AND t1.email not CONTAINS ('YAHHOO.COM')         AND t1.email not CONTAINS ('YAAHOO.COM')
	 AND t1.email not CONTAINS ('YSAHOO.COM')       AND t1.email not CONTAINS ('YAHOO.CON.CO')
	 AND t1.email not CONTAINS ('YAHO0.COM')     AND t1.email not CONTAINS ('YAHOOP.COM')
	 AND t1.email not CONTAINS ('YYAHOO.COM')        AND t1.email not CONTAINS ('YABHOO.COM')
	 AND t1.email not CONTAINS ('YAHPOO.COM')        AND t1.email not CONTAINS ('YAHJOO.COM')
	 AND t1.email not CONTAINS ('HYAHOO.COM')     AND t1.email not CONTAINS ('YTAHOO.COM')
	 AND t1.email not CONTAINS ('YAHIO.COM')       AND t1.email not CONTAINS ('UYAHOO.COM')
	 AND t1.email not CONTAINS ('YAHOO0.COM')         AND t1.email not CONTAINS ('YAHOO.COM')
	 AND t1.email not CONTAINS ('YAHOO.CMO')        AND t1.email not CONTAINS ('YAH0O.COM')
	 AND t1.email not CONTAINS ('YABOO.COM')      AND t1.email not CONTAINS ('YAHGOO.COM')
	 AND t1.email not CONTAINS ('TYAHOO.COM')         AND t1.email not CONTAINS ('YAHUOO.COM')
	 AND t1.email not CONTAINS ('YAHO0O.COM')       AND t1.email not CONTAINS ('YUAHOO.COM')
	 AND t1.email not CONTAINS ('GYAHOO.COM')         AND t1.email not CONTAINS ('YHAHOO.COM')
	AND t1.email not in (select email from POLAVARR.CORREOS_FAKE_V2) 
;QUIT;


PROC SQL;
CREATE INDEX rut ON RESULT.R_BOPERS_TOTALES_EMAIL (RUT);
QUIT;

/*=========================================================================================*/
/*======	4.- Obtener Emails desde: CNAVAR.RESPALDO_MAIL_DGC en buen formato	 ==========*/
/*=========================================================================================*/
proc sql;
create table R_DEPASO_CNAVARRO as
	select	x1.RUT,
     	upcase(x1.EMAIL) as EMAIL length=50,
	  	x1.FECHA as FECHA_ACTUALIZACION,
		input(put(x1.FECHA,yymmddn8.),best.) as FECHAN,
		6 AS sequencia,
	  	'DGC' as ORIGEN,
		x1.INHIBIDO
	FROM CNAVAR.RESPALDO_MAIL_20181012 X1
;quit;

proc sql;
create table RESULT.R_EMAILS_CNAVARRO_DGC as
select	DISTINCT x1.RUT,
        x1.EMAIL,
		x1.FECHAN AS FECHA_ACT,
		sequencia,
	  	ORIGEN
	FROM R_DEPASO_CNAVARRO X1
	WHERE x1.RUT < 99999999 AND x1.RUT > 10000
	AND	x1.email not LIKE	('.-%')				AND x1.email not LIKE	('%.')
	AND x1.email not LIKE	('-%')				AND x1.email not LIKE	('%.@%')
	/*AND x1.email not LIKE	('% %')*/
    AND x1.email not CONTAINS 	('XXXXX')
	AND x1.email not CONTAINS 	('DEFAULT')		AND x1.email not CONTAINS 	('TEST@')
	AND x1.email not CONTAINS 	('..')			AND x1.email not CONTAINS 	('PRUEBA')
	AND x1.email not CONTAINS	('(')			AND x1.email not CONTAINS 	(')')
	AND x1.email not CONTAINS	('/')			AND x1.email not CONTAINS	('?')
	AND x1.email not CONTAINS 	('¿')			AND x1.email not CONTAINS 	('SINMAIL')
	AND x1.email not CONTAINS 	('NOTIENE')		AND x1.email not CONTAINS 	('NOTENGO')
	AND x1.email not CONTAINS 	('SINCORRE')	AND x1.email not CONTAINS 	('TEST@')
	AND x1.email <>'@'							AND x1.email not CONTAINS	('GFFDF')
	AND x1.email not CONTAINS 	('0000000')		AND x1.email not CONTAINS 	('GMAIL.CL')
	AND x1.email not CONTAINS 	('GMAIL.ES')	AND x1.email <>'0'
	AND x1.email CONTAINS 	('@')				AND x1.email not CONTAINS 	('SINEMAIL')
	AND x1.email not CONTAINS 	('NOREGISTRA')  AND x1.email not CONTAINS 	('SINMALLIL')
	AND x1.email not CONTAINS 	('@MAILINATOR.COM')	AND x1.email not CONTAINS 	('@MICORREO.COM')	
	AND x1.email not CONTAINS 	('@HOTRMAIL.COM')	AND x1.email not CONTAINS	('@SDFDF.CL' )
	/*agregado pia*/
	 AND x1.email not CONTAINS ('HORTMAIL.COM')       AND x1.email not CONTAINS ('REPLEY.COM')
	 AND x1.email not CONTAINS ('BANCPORIPLEY.COM')       AND x1.email not CONTAINS ('GMAL.COM')
	 AND x1.email not CONTAINS ('RILPLEY.COM')       AND x1.email not CONTAINS ('HOTMAI.COM')
	 AND x1.email not CONTAINS ('GAMIL.COM')       AND x1.email not CONTAINS ('RIPEY.CL')
	 AND x1.email not CONTAINS ('RIPLEY.VOM')       AND x1.email not CONTAINS ('HTOMAIL.COM')
	 AND x1.email not CONTAINS ('GMAIL.CON')       AND x1.email not CONTAINS ('GMIL.COM')
	 AND x1.email not CONTAINS ('HOTAMIL.COM')       AND x1.email not CONTAINS ('123MAIL.CL')
	 AND x1.email not CONTAINS ('ICLOOUD.COM')       AND x1.email not CONTAINS ('YMAIL.COM')
	 AND x1.email not CONTAINS ('HOTMIAL.COM')       AND x1.email not CONTAINS ('GMAI.COM')
	 AND x1.email not CONTAINS ('HOTMAIL.OM')       AND x1.email not CONTAINS ('GMAIIL.COM')
	 AND x1.email not CONTAINS ('RIOLPLEY.COM')       AND x1.email not CONTAINS ('aol.com')
	 AND x1.email not CONTAINS ('GMSAIL.COM')       AND x1.email not CONTAINS ('ICLOU.COM')
	 AND x1.email not CONTAINS ('GMAIL.CM')       AND x1.email not CONTAINS ('GMIAL.COM')
	 AND x1.email not CONTAINS ('UAHOO.COM')       AND x1.email not CONTAINS ('HOTMAIL.OCM')
	 AND x1.email not CONTAINS ('GMAILC.OM')       AND x1.email not CONTAINS ('UTLOOOK.COM')
	 AND x1.email not CONTAINS ('RIPLE.COM')       AND x1.email not CONTAINS ('GMAILL.COM')
	 AND x1.email not CONTAINS ('GMAOL.COM')       AND x1.email not CONTAINS ('HORMAIL.COM')
	 AND x1.email not CONTAINS ('HOTMAL.COM')       AND x1.email not CONTAINS ('OTMAIL.COM')
	 AND x1.email not CONTAINS ('2HOTMAIL.ES')       AND x1.email not CONTAINS ('XXX.COM')
	 AND x1.email not CONTAINS ('AUTLOOK.COM')       AND x1.email not CONTAINS ('8GMAIL.COM')
	 AND x1.email not CONTAINS ('GMAIL.COMN')       AND x1.email not CONTAINS ('OITLOOK.COM')
	 AND x1.email not CONTAINS ('OUTLOCK.COM')       AND x1.email not CONTAINS ('GMAIL.OM')
	 AND x1.email not CONTAINS ('GMAIL.LCOM')       AND x1.email not CONTAINS ('OUTLLOK.CL')
	 AND x1.email not CONTAINS ('OULOOCK.ES')       AND x1.email not CONTAINS ('OULOOKS.ES')
	 AND x1.email not CONTAINS ('GAMIAL.COM')       AND x1.email not CONTAINS ('HOTMAILL.COM')
	 AND x1.email not CONTAINS ('GMAIL.CPM')       AND x1.email not CONTAINS ('64GMAIL.COM')
	 AND x1.email not CONTAINS ('GMAIOL.COM')
	 /*agregado email Lore Gerrero*/
   AND x1.email not CONTAINS ('yahho.com')       AND x1.email not CONTAINS ('EMAIL.CON')
	 AND x1.email not CONTAINS ('OUTLOKK.ES')       AND x1.email not CONTAINS ('HORMAIL.COM')
	 AND x1.email not CONTAINS ('GMAIL.VOM')       AND x1.email not CONTAINS ('YAHOO.CL')
	 AND x1.email not CONTAINS ('GMEIL.CL')       AND x1.email not CONTAINS ('GMAKL.COM')
	 AND x1.email not CONTAINS ('GMAIL.COL')       AND x1.email not CONTAINS ('GMAIL.COMO')
	 AND x1.email not CONTAINS ('GHOTMAIL.COM')       AND x1.email not CONTAINS ('GMAIL.COMF')
	 AND x1.email not CONTAINS ('LIVE.CK')       AND x1.email not CONTAINS ('GMEIL.CMMAIL.COM')
	 AND x1.email not CONTAINS ('GMMAIL.COM')       AND x1.email not CONTAINS ('HOTMKAIL.COM')
	 AND x1.email not CONTAINS ('GMAIL.COMHOTMAIL.COM')       AND x1.email not CONTAINS ('HOTRMAIL.COM')
	 AND x1.email not CONTAINS ('HOIMAIL.COM')       AND x1.email not CONTAINS ('XN--GMAI-JQA.COM')
	 AND x1.email not CONTAINS ('HMAIL.COM')       AND x1.email not CONTAINS ('OUTLOOK.CM')
	 AND x1.email not CONTAINS ('HATMAIL.CON')       AND x1.email not CONTAINS ('GMAIL.COMON')
	 AND x1.email not CONTAINS ('GMIL.CO')       AND x1.email not CONTAINS ('GMALL.COM')
	 AND x1.email not CONTAINS ('HOTMAIAL.COM')       AND x1.email not CONTAINS ('GMAIK.COM')
	 AND x1.email not CONTAINS ('OUTLOOCK.COM')       AND x1.email not CONTAINS ('GMAQIL.COM')
	 AND x1.email not CONTAINS ('GMAILC.OM')       AND x1.email not CONTAINS ('GMAIA.COM')
	 AND x1.email not CONTAINS ('HOTMAIL.COL')       AND x1.email not CONTAINS ('GMNAIL.COM')
	 AND x1.email not CONTAINS ('OUTLLOOK.ES')       AND x1.email not CONTAINS ('GMEIL.CON')
	 	 /*agregados de la base de simulacion hb new*/
    /*  AND x1.email not CONTAINS ('GMAIL.CO') */	          AND x1.email not CONTAINS ('GMAIL.COMU')
	AND x1.email not CONTAINS ('GMAIL.CON')           AND x1.email not CONTAINS ('123MAIL.CL')
	 AND x1.email not CONTAINS ('GMAIL.COMOESTAS')    AND x1.email not CONTAINS ('GMAIL.COMO')
	 AND x1.email not CONTAINS ('GIMAIL.COM')        AND x1.email not CONTAINS ('GMAL.COM')
	 AND x1.email not CONTAINS ('GMAIL.COMM')        AND x1.email not CONTAINS ('GMAIL.XOM')
	 AND x1.email not CONTAINS ('GMAIL.CM')         AND x1.email not CONTAINS ('GIMEIL.COM')
	 AND x1.email not CONTAINS ('HOTMIAL.COM')       AND x1.email not CONTAINS ('HOOTMAIL.ES')
	 AND x1.email not CONTAINS ('HOTMAIL.CON')       AND x1.email not CONTAINS ('GIMAIL.CON')
	 AND x1.email not CONTAINS ('HOTMEIL.COM')       AND x1.email not CONTAINS ('GMAIL.VOM')
	 AND x1.email not CONTAINS ('HOTMEIL.ES')        AND x1.email not CONTAINS ('GMAIL.CL.COM')
	 AND x1.email not CONTAINS ('GIMAL.COM')         AND x1.email not CONTAINS ('GMAIL.COMIL.COM')
	 AND x1.email not CONTAINS ('HOTMAIK.COM')       AND x1.email not CONTAINS ('GMAIL.COMQ')
	 AND x1.email not CONTAINS ('HOTMAIIL.COM')      AND x1.email not CONTAINS ('HOTMAIL.CPM')
	AND x1.email not CONTAINS ('GMAIL.COML')        AND x1.email not CONTAINS ('G.MAIL.COM')
	 AND x1.email not CONTAINS ('HOTMAOL.COM')       AND x1.email not CONTAINS ('GMAILL.COM')
	 AND x1.email not CONTAINS ('GIMAIL.CL')         AND x1.email not CONTAINS ('GMAIL.COMD')
	 AND x1.email not CONTAINS ('HOTTMAIL.COM')      AND x1.email not CONTAINS ('HOTMAILC.OM')
	 AND x1.email not CONTAINS ('1967GMAIL.COM')     AND x1.email not CONTAINS ('HOTMAY.COM')
	/* AND x1.email not CONTAINS ('HOTMAIL.CO') */       AND x1.email not CONTAINS ('GMIAL.COM')
	 AND x1.email not CONTAINS ('2382HOTMAIL.COM')   AND x1.email not CONTAINS ('GMALL.COM')
	 AND x1.email not CONTAINS ('GIMALL.COM')        AND x1.email not CONTAINS ('HOTMAIL.COMBUE')
	 AND x1.email not CONTAINS ('GMAIL.CPM')         AND x1.email not CONTAINS ('123GMAIL.COM')
	 AND x1.email not CONTAINS ('GMAIL.COMP')        AND x1.email not CONTAINS ('GMIL.CPM')
	 AND x1.email not CONTAINS ('GMALI.COM')         AND x1.email not CONTAINS ('JAJAJA.CL')
	 AND x1.email not CONTAINS ('AUTLOOK.COM')       AND x1.email not CONTAINS ('GMAIL.CLOM')
	 AND x1.email not CONTAINS ('GMAIL.COMCOM')      AND x1.email not CONTAINS ('GMAIL.CIM')
	 AND x1.email not CONTAINS ('ICLOUD.CON')        AND x1.email not CONTAINS ('OUTLOOK.COMM')
	 AND x1.email not CONTAINS ('HOTMEIL.CL')        AND x1.email not CONTAINS ('HOTMAIO.COM')
	 AND x1.email not CONTAINS ('GMAIL.COPM')        AND x1.email not CONTAINS ('GAIML.COM')
	AND x1.email not CONTAINS ('HOTMAIL.COMO')      AND x1.email not CONTAINS ('JAJAGMAIL.COM')
	 AND x1.email not CONTAINS ('GMAIL.COMEMAIL')    AND x1.email not CONTAINS ('HOTMAIL.COMR')
	 AND x1.email not CONTAINS ('OULTOOK.CL')        AND x1.email not CONTAINS ('BANCORYPLEY.CL')
	 AND x1.email not CONTAINS ('GMAIM.COM')         AND x1.email not CONTAINS ('B8477491ANCORIPLEY.COM')
	AND x1.email not CONTAINS ('GMAIL.COMN')        AND x1.email not CONTAINS ('GMMAIL.COM')
	 AND x1.email not CONTAINS ('2857GMAIL.COM')     AND x1.email not CONTAINS ('HOTMAIEL.COM')
	 AND x1.email not CONTAINS ('GMAIL.COL')         AND x1.email not CONTAINS ('GHOTMAIL.COM')
	/* AND x1.email not CONTAINS ('OUTLOOK.CO')*/        AND x1.email not CONTAINS ('GMAIIL.COM')
	 AND x1.email not CONTAINS ('OUTLOOK.CON')       AND x1.email not CONTAINS ('LIVE.CM')
	 AND x1.email not CONTAINS ('HOGMAIL.ES')        AND x1.email not CONTAINS ('GMAIL.COMQQSWS')
	 AND x1.email not CONTAINS ('HOTMAKL.COM')       AND x1.email not CONTAINS ('GMAIL.CO.COM')
	AND x1.email not CONTAINS ('HOTMAUL.COM')        AND x1.email not CONTAINS ('OUTLOOCK.COM')
	 AND x1.email not CONTAINS ('GMANIL.COM')        AND x1.email not CONTAINS ('OUTLOO.COM')
	 AND x1.email not CONTAINS ('ICLUD.COM')         AND x1.email not CONTAINS ('GMAIL.COM.CL')
	 AND x1.email not CONTAINS ('OUTLLOK.COM')       AND x1.email not CONTAINS ('GMAIL.COK')
	 AND x1.email not CONTAINS ('GMAIL.COM.COM')     AND x1.email not CONTAINS ('OULOOK.COM')
	 AND x1.email not CONTAINS ('OUTOOK.COM')        AND x1.email not CONTAINS ('59GMEIL.COM')
	 AND x1.email not CONTAINS ('GMAIL.CCOM')        AND x1.email not CONTAINS ('GMAIL.COOM')
	 AND x1.email not CONTAINS ('434GOTMAIL.CL')     AND x1.email not CONTAINS ('GM8AIL.COM')
	 AND x1.email not CONTAINS ('HOGMAIL.COM')       AND x1.email not CONTAINS ('GMAIL.COMA')
	 AND x1.email not CONTAINS ('GMAIIL.CO')         AND x1.email not CONTAINS ('HOTMEY.COM')
	 AND x1.email not CONTAINS ('GMAIL.COMS')        AND x1.email not CONTAINS ('YAHUU.COM')
	 AND x1.email not CONTAINS ('A01GMAIL.COM')      AND x1.email not CONTAINS ('HOTMAIL.COL')
	 AND x1.email not CONTAINS ('GMAIO.COM')         AND x1.email not CONTAINS ('GMAIL.GMAIL.COM')
	 AND x1.email not CONTAINS ('GMAIL.COMOM')       AND x1.email not CONTAINS ('HOTMAIM.COM')
	AND x1.email not CONTAINS ('HOTMAIL.COMK')
		/* AGREGADOS POR ANALISIS DE WEBBULA */
	 AND x1.email not CONTAINS ('GMSIL.COM')       AND x1.email not CONTAINS ('MC.COM')
	 AND x1.email not CONTAINS ('LIVER.COM')        AND x1.email not CONTAINS ('HOMAIL.COM')
	 AND x1.email not CONTAINS ('GMAUL.COM')       AND x1.email not CONTAINS ('HTMAIL.COM')
  	 AND x1.email not CONTAINS ('GNAIL.COM')        AND x1.email not CONTAINS ('HOYMAIL.COM')
     AND x1.email not CONTAINS ('LIV.COM')        AND x1.email not CONTAINS ('HPTMAIL.COM')
	 AND x1.email not CONTAINS ('GMAOIL.COM')         AND x1.email not CONTAINS ('HOTMWIL.COM')
	 AND x1.email not CONTAINS ('GMAAIL.COM')       AND x1.email not CONTAINS ('GMASIL.COM')
	 AND x1.email not CONTAINS ('GFMAIL.COM')     AND x1.email not CONTAINS ('MGAIL.COM')
	 AND x1.email not CONTAINS ('H0TMAIL.COM')        AND x1.email not CONTAINS ('GMJAIL.COM')
	 AND x1.email not CONTAINS ('FGMAIL.COM')        AND x1.email not CONTAINS ('HOTMAAIL.CO')
	 AND x1.email not CONTAINS ('HITMAIL.COM')     AND x1.email not CONTAINS ('HOTMAIL.COMQUE')
	 AND x1.email not CONTAINS ('HOTMASIL.COM')       AND x1.email not CONTAINS ('HOTAIL.COM')
	 AND x1.email not CONTAINS ('GOTMAIL.COM')         AND x1.email not CONTAINS ('GTMAIL.COM')
	 AND x1.email not CONTAINS ('NSN.COM')        AND x1.email not CONTAINS ('HOTMSIL.COM')
	 AND x1.email not CONTAINS ('FMAIL.COM')      AND x1.email not CONTAINS ('HOTMAOIL.COM')
	 AND x1.email not CONTAINS ('HOMTAIL.COM')         AND x1.email not CONTAINS ('LIUVE.COM')
	 AND x1.email not CONTAINS ('GMAILO.COM')       AND x1.email not CONTAINS ('GGMAIL.COM')
	 AND x1.email not CONTAINS ('JOTMAIL.COM')       AND x1.email not CONTAINS ('GMQIL.COM')
	 AND x1.email not CONTAINS ('GMAIKL.COM')        AND x1.email not CONTAINS ('HOTMSAIL.COM')
	 AND x1.email not CONTAINS ('GAIL.COM')       AND x1.email not CONTAINS ('GMAIL.COMCIMI')
	 AND x1.email not CONTAINS ('LICE.COM')        AND x1.email not CONTAINS ('GMAIL.CKM')
     AND x1.email not CONTAINS ('HHOTMAIL.COM')        AND x1.email not CONTAINS ('HLTMAIL.COM')
	 AND x1.email not CONTAINS ('ICLOUB.COM')         AND x1.email not CONTAINS ('HOTMAIL.COOM')
	 AND x1.email not CONTAINS ('HOTMAIKL.COM')       AND x1.email not CONTAINS ('HJOTMAIL.COM')
	 AND x1.email not CONTAINS ('HOPTMAIL.COM')     AND x1.email not CONTAINS ('HOTMAIUL.COM')
	 AND x1.email not CONTAINS ('HOTMMAIL.COM')        AND x1.email not CONTAINS ('HOTMALL.COM')
	 AND x1.email not CONTAINS ('HOTGMAIL.COM')        AND x1.email not CONTAINS ('LIVE.COL')
	 AND x1.email not CONTAINS ('HOTNAIL.COM')     AND x1.email not CONTAINS ('LIBE.COM')
	 AND x1.email not CONTAINS ('GMAUIL.COM')       AND x1.email not CONTAINS ('H0OTMAIL.COM')
	 AND x1.email not CONTAINS ('HOTMAQIL.COM')         AND x1.email not CONTAINS ('GMAI9L.COM')
	 AND x1.email not CONTAINS ('GNMAIL.COM')        AND x1.email not CONTAINS ('HOTMAILK.COM')
	 AND x1.email not CONTAINS ('HOYTMAIL.COM')      AND x1.email not CONTAINS ('HOTMAIL.CM')
	 AND x1.email not CONTAINS ('HOTMAAIL.COM')         AND x1.email not CONTAINS ('HOTFMAIL.COM')
	 AND x1.email not CONTAINS ('HOMAIL.CO')       AND x1.email not CONTAINS ('HIOTMAIL.COM')
	 AND x1.email not CONTAINS ('HOTMAKIL.COM')         AND x1.email not CONTAINS ('GMAILK.COM')
	 AND x1.email not CONTAINS ('HOHTMAIL.COM')       AND x1.email not CONTAINS ('HOTYMAIL.COM')
	 AND x1.email not CONTAINS ('HOTMAUIL.COM')     AND x1.email not CONTAINS ('ME.CM')
	 AND x1.email not CONTAINS ('HOTMAIL.COIM')        AND x1.email not CONTAINS ('L8VE.COM')
	 AND x1.email not CONTAINS ('HOTMNAIL.COM')        AND x1.email not CONTAINS ('OHTMAIL.COM')
	 AND x1.email not CONTAINS ('HOT6MAIL.COM')     AND x1.email not CONTAINS ('GMQIL.VOM')
	 AND x1.email not CONTAINS ('GMZAIL.COM')       AND x1.email not CONTAINS ('LIVE.CCOM')
	 AND x1.email not CONTAINS ('LIVEW.COM')         AND x1.email not CONTAINS ('YGMAIL.COM')
	 AND x1.email not CONTAINS ('BOTMAIL.COM')        AND x1.email not CONTAINS ('GMAIL.CO9M')
	 AND x1.email not CONTAINS ('GMAIL.COMG')      AND x1.email not CONTAINS ('HOTMAIL.CIOM')
	 AND x1.email not CONTAINS ('HPOTMAIL.COM')         AND x1.email not CONTAINS ('MAIL.CM')
	 AND x1.email not CONTAINS ('HOHMAIL.COM')       AND x1.email not CONTAINS ('HOTMAIL.COPM')
	 AND x1.email not CONTAINS ('HOT5MAIL.COM')        AND x1.email not CONTAINS ('GMZIL.COM')
	 AND x1.email not CONTAINS ('HOLTMAIL.COM')      AND x1.email not CONTAINS ('LIVE.CON')
	 AND x1.email not CONTAINS ('HUOTMAIL.COM')         AND x1.email not CONTAINS ('MSNM.COM')
	 AND x1.email not CONTAINS ('HO0TMAIL.COM')       AND x1.email not CONTAINS ('HOTMAI.COK')
	 AND x1.email not CONTAINS ('GMAZIL.COM')         AND x1.email not CONTAINS ('LVIE.COM')
	 AND x1.email not CONTAINS ('HOTMAIL.CCOM')       AND x1.email not CONTAINS ('HOTMAIL.CLOM')
	 AND x1.email not CONTAINS ('HOOTMAIL.COM')     AND x1.email not CONTAINS ('HOTHMAIL.COM')
	 AND x1.email not CONTAINS ('HOTMIL.CON')        AND x1.email not CONTAINS ('MZN.COM')
	 AND x1.email not CONTAINS ('HOMAIL.CM')        AND x1.email not CONTAINS ('ICLOUD.OM')
	 AND x1.email not CONTAINS ('HGOTMAIL.COM')     AND x1.email not CONTAINS ('GMIL.CON')
	 AND x1.email not CONTAINS ('LIVE.VOM')       AND x1.email not CONTAINS ('GAIL.CO')
	 AND x1.email not CONTAINS ('GMA9IL.COM')         AND x1.email not CONTAINS ('HTMAIL.CPM')
	 AND x1.email not CONTAINS ('GMAI.LCOM')        AND x1.email not CONTAINS ('GMIL.CM')
	 AND x1.email not CONTAINS ('MSN.CM')      AND x1.email not CONTAINS ('BHOTMAIL.COM')
	 AND x1.email not CONTAINS ('GMAIUL.COM')         AND x1.email not CONTAINS ('HO9TMAIL.COM')
	 AND x1.email not CONTAINS ('HOTMJAIL.COM')       AND x1.email not CONTAINS ('GMA8L.COM')
     AND x1.email not CONTAINS ('GAMIL.CON')      AND x1.email not CONTAINS ('GKMAIL.COM')
	 AND x1.email not CONTAINS ('GMAIL.BOM')         AND x1.email not CONTAINS ('LIE.COM')
	 AND x1.email not CONTAINS ('HOTMIL.CO')       AND x1.email not CONTAINS ('GMAIL.CIOM')
	 AND x1.email not CONTAINS ('LUVE.COM')         AND x1.email not CONTAINS ('NOTMAIL.COM')
	 AND x1.email not CONTAINS ('HOTMQAIL.COM')       AND x1.email not CONTAINS ('HOTMIL.CM')
	 AND x1.email not CONTAINS ('GMAIL.VCOM')     AND x1.email not CONTAINS ('HOTMAIL.CAM')
	 AND x1.email not CONTAINS ('HOTNAIL.CO')        AND x1.email not CONTAINS ('HOTJMAIL.COM')
	 AND x1.email not CONTAINS ('GMIIL.COM')        AND x1.email not CONTAINS ('H9OTMAIL.COM')
	 AND x1.email not CONTAINS ('GYMAIL.COM')     AND x1.email not CONTAINS ('HNOTMAIL.COM')
	 AND x1.email not CONTAINS ('HOTNMAIL.COM')       AND x1.email not CONTAINS ('GMA8IL.COM')
	 AND x1.email not CONTAINS ('GHMAIL.COM')         AND x1.email not CONTAINS ('GJMAIL.COM')
	 AND x1.email not CONTAINS ('GMAWIL.COM')        AND x1.email not CONTAINS ('HOTMMAIL.CO')
	 AND x1.email not CONTAINS ('GMWIL.COM')      AND x1.email not CONTAINS ('LIVD.COM')
	 AND x1.email not CONTAINS ('HYOTMAIL.COM')         AND x1.email not CONTAINS ('HOMAIL.OM')
	 AND x1.email not CONTAINS ('LIVE.CM')       AND x1.email not CONTAINS ('HOMAIL.CON')
	 AND x1.email not CONTAINS ('HLOTMAIL.COM')         AND x1.email not CONTAINS ('HGMAIL.CO')
	 AND x1.email not CONTAINS ('HOTAIL.CO')       AND x1.email not CONTAINS ('GMAKIL.COM')
	 AND x1.email not CONTAINS ('LILVE.COM')         AND x1.email not CONTAINS ('HOOTMAIL.CO')
	 AND x1.email not CONTAINS ('HBOTMAIL.COM')       AND x1.email not CONTAINS ('GMQAIL.COM')
	 AND x1.email not CONTAINS ('LIVE.CIM')     AND x1.email not CONTAINS ('HORMAIL.CON')
	 AND x1.email not CONTAINS ('HOTMAI9L.COM')        AND x1.email not CONTAINS ('GMKAIL.COM')
	 AND x1.email not CONTAINS ('MSMN.COM')        AND x1.email not CONTAINS ('GKAIL.COM')
	 AND x1.email not CONTAINS ('YHAOO.COM')     AND x1.email not CONTAINS ('YAHHO.COM')
	 AND x1.email not CONTAINS ('YAHO.COM')       AND x1.email not CONTAINS ('YAHOIO.COM')
	 AND x1.email not CONTAINS ('YAOO.COM')         AND x1.email not CONTAINS ('YAHOOO.COM')
	 AND x1.email not CONTAINS ('YAHOO.CO')        AND x1.email not CONTAINS ('HOTMAIL.DOM')
	 AND x1.email not CONTAINS ('GMAILL.CM')      AND x1.email not CONTAINS ('HOTMAIL.COM.YAHOO.ES')
	 AND x1.email not CONTAINS ('YQHOO.COM')         AND x1.email not CONTAINS ('HOTMAI.CM')
	 AND x1.email not CONTAINS ('TAHOO.COM')       AND x1.email not CONTAINS ('HOTMA8L.COM')
	 AND x1.email not CONTAINS ('JMAIL.COM')        AND x1.email not CONTAINS ('GIMAIL.CM')
	 AND x1.email not CONTAINS ('GEMAIL.CO')      AND x1.email not CONTAINS ('GIMAIL.CO')
	 AND x1.email not CONTAINS ('YOPMAIL.CO')         AND x1.email not CONTAINS ('HOTMAIL.17.COM')
	 AND x1.email not CONTAINS ('CORREO.OM')       AND x1.email not CONTAINS ('HORMAIL.CO')
	 AND x1.email not CONTAINS ('UTLOOK.COM')         AND x1.email not CONTAINS ('YHOO.COM')
	 AND x1.email not CONTAINS ('YAJOO.COM')       AND x1.email not CONTAINS ('HOTMIAL.CO')
	 AND x1.email not CONTAINS ('YAYOO.COM')         AND x1.email not CONTAINS ('HOTMALIL.COM')
	 AND x1.email not CONTAINS ('YMSIL.COM')       AND x1.email not CONTAINS ('HOTMIAL.CM')
	 AND x1.email not CONTAINS ('YASHOO.COM')     AND x1.email not CONTAINS ('HOTMAILL.CO')
	 AND x1.email not CONTAINS ('YAHOOL.COM')        AND x1.email not CONTAINS ('HOTMAIOL.COM')
	 AND x1.email not CONTAINS ('HOTMMAIL.OM')        AND x1.email not CONTAINS ('YAQHOO.COM')
	 AND x1.email not CONTAINS ('YSHOO.COM')     AND x1.email not CONTAINS ('GMIAL.CON')
	 AND x1.email not CONTAINS ('LIVR.COM')       AND x1.email not CONTAINS ('HOTMAWIL.COM')
	 AND x1.email not CONTAINS ('GMMAIL.CO')         AND x1.email not CONTAINS ('HTMAIL.CM')
	 AND x1.email not CONTAINS ('NAIL.COM')        AND x1.email not CONTAINS ('MAIOL.COM')
	 AND x1.email not CONTAINS ('GM.CON')      AND x1.email not CONTAINS ('GM.CO')
	 AND x1.email not CONTAINS ('HO5TMAIL.COM')         AND x1.email not CONTAINS ('GMAIL.FOM')
	 AND x1.email not CONTAINS ('MAI.CM')       AND x1.email not CONTAINS ('EMAIL.CO')
	 AND x1.email not CONTAINS ('GOTMAIL.CO')        AND x1.email not CONTAINS ('LIVS.COM')
	 AND x1.email not CONTAINS ('LICVE.COM')      AND x1.email not CONTAINS ('MAIL.CON')
	 AND x1.email not CONTAINS ('JMAIL.CO')         AND x1.email not CONTAINS ('MAIIL.COM')
	 AND x1.email not CONTAINS ('GIMEI.CO')       AND x1.email not CONTAINS ('HOTMAILC.OM')
	 AND x1.email not CONTAINS ('GMAILC.OM')         AND x1.email not CONTAINS ('GIMIL.CON')
	 AND x1.email not CONTAINS ('HOTAMAIL.CO')       AND x1.email not CONTAINS ('YMAIL.CM')
	 AND x1.email not CONTAINS ('YMAIL.CO')         AND x1.email not CONTAINS ('OUTLOOOK.COM')
	 AND x1.email not CONTAINS ('GAMIAL.CO')       AND x1.email not CONTAINS ('OITLOOK.COM')
	 AND x1.email not CONTAINS ('ICLUD.CON')     AND x1.email not CONTAINS ('OUTLOOK.CON')
	 AND x1.email not CONTAINS ('AUTLOOK.CO')        AND x1.email not CONTAINS ('GIMEI.CON')
	 AND x1.email not CONTAINS ('OUTLOKK.COM')        AND x1.email not CONTAINS ('GMLI.CON')
	 AND x1.email not CONTAINS ('GMEIL.CO')     AND x1.email not CONTAINS ('GOMAIL.CO')
	 AND x1.email not CONTAINS ('MGMAIL.CO')       AND x1.email not CONTAINS ('GMEIL.CPM')
	 AND x1.email not CONTAINS ('HOTMEIL.COM')         AND x1.email not CONTAINS ('GITMAIL.COM')
	 AND x1.email not CONTAINS ('UMAIL.COM')        AND x1.email not CONTAINS ('HJFJH.CM')
	 AND x1.email not CONTAINS ('GEMEIL.CO')      AND x1.email not CONTAINS ('HIMAIL.CO')
	 AND x1.email not CONTAINS ('GAMAIL.CO')         AND x1.email not CONTAINS ('GIMEIL.CO')
	 AND x1.email not CONTAINS ('GIMIL.COMO')       AND x1.email not CONTAINS ('GIMAL.CON')
	 AND x1.email not CONTAINS ('HOTM.COMAIL')         AND x1.email not CONTAINS ('YNAIL.COM')
	 AND x1.email not CONTAINS ('GIMEIL.CIM')       AND x1.email not CONTAINS ('HOLMAIL.CM')
	 AND x1.email not CONTAINS ('YMIAL.COM')        AND x1.email not CONTAINS ('GMEIL.COMO')
	 AND x1.email not CONTAINS ('HOIMAIL.COM')      AND x1.email not CONTAINS ('HOITMAIL.CL')
	 AND x1.email not CONTAINS ('WWW.HOTMAIL.COM')         AND x1.email not CONTAINS ('THOMAIL.CL')
	 AND x1.email not CONTAINS ('YQAHOO.COM')       AND x1.email not CONTAINS ('HAHOO.COM')
	 AND x1.email not CONTAINS ('YAHOL.COM')         AND x1.email not CONTAINS ('YAGOO.COM')
	 AND x1.email not CONTAINS ('UAHOO.COM')       AND x1.email not CONTAINS ('YAHOO.CM')
	 AND x1.email not CONTAINS ('YAHHOO.COM')         AND x1.email not CONTAINS ('YAAHOO.COM')
	 AND x1.email not CONTAINS ('YSAHOO.COM')       AND x1.email not CONTAINS ('YAHOO.CON.CO')
	 AND x1.email not CONTAINS ('YAHO0.COM')     AND x1.email not CONTAINS ('YAHOOP.COM')
	 AND x1.email not CONTAINS ('YYAHOO.COM')        AND x1.email not CONTAINS ('YABHOO.COM')
	 AND x1.email not CONTAINS ('YAHPOO.COM')        AND x1.email not CONTAINS ('YAHJOO.COM')
	 AND x1.email not CONTAINS ('HYAHOO.COM')     AND x1.email not CONTAINS ('YTAHOO.COM')
	 AND x1.email not CONTAINS ('YAHIO.COM')       AND x1.email not CONTAINS ('UYAHOO.COM')
	 AND x1.email not CONTAINS ('YAHOO0.COM')         AND x1.email not CONTAINS ('YAHOO.COM')
	 AND x1.email not CONTAINS ('YAHOO.CMO')        AND x1.email not CONTAINS ('YAH0O.COM')
	 AND x1.email not CONTAINS ('YABOO.COM')      AND x1.email not CONTAINS ('YAHGOO.COM')
	 AND x1.email not CONTAINS ('TYAHOO.COM')         AND x1.email not CONTAINS ('YAHUOO.COM')
	 AND x1.email not CONTAINS ('YAHO0O.COM')       AND x1.email not CONTAINS ('YUAHOO.COM')
	 AND x1.email not CONTAINS ('GYAHOO.COM')         AND x1.email not CONTAINS ('YHAHOO.COM')
	AND x1.email not in (select email from POLAVARR.CORREOS_FAKE_V2)
;quit;

PROC SQL;
	DROP TABLE R_DEPASO_CNAVARRO;
;QUIT;

PROC SQL;
CREATE INDEX rut ON RESULT.R_EMAILS_CNAVARRO_DGC (RUT);
QUIT;

/*=========================================================================================*/
/*======	5.- OBTENER DATOS DESDE LA APP - PROCESO DEFINITIVO		=======================*/
/*=========================================================================================*/

/*========	RESPALDO DE TABLAS ANTERIORES DE APP	====================*/
/*PROC SQL;
create table RESULT.RESP_BASE_EMAIL_APP_FINAL_&VdateMES AS
	SELECT * FROM RESULT.BASE_EMAIL_APP_FINAL
;quit;
PROC SQL;
create table RESULT.RESP_USER_INFO_&VdateMES AS
	SELECT * FROM RESULT.USER_INFO
;quit;
PROC SQL;
create table RESULT.RESP_DATOS_APP_HIST_&VdateMES AS
	SELECT * FROM RESULT.DATOS_APP_HIST /* DATOS DESDE JULIO 2018 AL 27 DE AGOSTO 2019 */
/*;quit;*/

/*========	OBTENER DATOS DE APP DE BD HIS		================================================*/
PROC SQL;
   CREATE TABLE TMP_DEPASO_DATOS_APP_HIS AS 
   SELECT 	(INPUT(LEFT(SUBSTR(LEFT(COMPRESS(COMPRESS(t1.RUT,'.'),'-')),1,LENGTH(LEFT(COMPRESS(COMPRESS(t1.RUT,'.'),'-')))-1)),BEST.)) AS RUT,
   			COMPRESS(upcase(T1.email)) as EMAIL length=50,
			input(cat((SUBSTR(T1.FECHA_ULTIMO_LOGIN,1,4)),(SUBSTR(T1.FECHA_ULTIMO_LOGIN,6,2)),(SUBSTR(T1.FECHA_ULTIMO_LOGIN,9,2))) ,BEST10.) AS F_ULTIMO_CONTACT
      FROM result.DATOS_APP_HIST t1 WHERE t1.RUT IS NOT NULL
ORDER BY t1.RUT
;
QUIT;

/*Maxima fecha de ultimo login*/
proc sql;
create table TMP_DEPASO_APP_HIS_FMAX_CREACION AS
	SELECT	DISTINCT RUT, 
	        EMAIL, 
	        MAX(T1.F_ULTIMO_CONTACT) AS FECHA,
	        4 AS SEQUENCIA,
			'APP HIS' AS ORIGEN
	    FROM TMP_DEPASO_DATOS_APP_HIS t1
	GROUP BY RUT
;quit;

/*Tomar el registro de fecha máximo*/
proc sql;
create table TMP_DEPASO_APP_HIS_FMAX_UN_REG AS
	SELECT	DISTINCT T1.RUT, 
	        T1.EMAIL, 
	        T2.F_ULTIMO_CONTACT AS FECHA,
	        T1.SEQUENCIA,
			T1.ORIGEN
	    FROM TMP_DEPASO_APP_HIS_FMAX_CREACION t1 LEFT JOIN TMP_DEPASO_DATOS_APP_HIS T2
			ON (T1.RUT = T2.RUT AND T1.FECHA = T2.F_ULTIMO_CONTACT AND T1.EMAIL = T2.EMAIL)
		WHERE T2.F_ULTIMO_CONTACT IS NOT MISSING
;quit;

/*Convertir data anterior con fecha correspondiente*/
PROC SQL;
   CREATE TABLE TMP_DATOS_APP_HIS AS 
   SELECT 	T1.RUT,
   			T1.EMAIL,
			DHMS((MDY(INPUT(SUBSTR(PUT(T1.FECHA,BEST8.),5,2),BEST4.),
                  INPUT(SUBSTR(PUT(T1.FECHA,BEST8.),7,2),BEST4.),
                  INPUT(SUBSTR(PUT(T1.FECHA,BEST8.),1,4),BEST4.))),0,0,0) FORMAT=datetime20. AS FECHA_ACTUALIZACION,
			T1.SEQUENCIA,
			T1.ORIGEN
      FROM TMP_DEPASO_APP_HIS_FMAX_UN_REG t1 WHERE t1.RUT > 0
ORDER BY t1.RUT
;
QUIT;
/*========	FIN - OBTENER DATOS DE APP DE BD HIS		====================================*/

/*========	OBTENER DATOS DE APP DE BD DIARIO			====================================*/
PROC SQL;
   CREATE TABLE TMP_DEPASO_DATOS_APP_DIA_2 AS 
   SELECT 	reverse(substr(compress(reverse(t1.RUT)),2,length(t1.RUT)-1)) as rut_sin_dv,
   			COMPRESS(upcase(T1.email)) as EMAIL length=50,
			input(cat((SUBSTR(T1.UpdatedAt,1,4)),(SUBSTR(T1.UpdatedAt,6,2)),(SUBSTR(T1.UpdatedAt,9,2))) ,BEST10.) AS F_ULTIMO_CONTACT,
			input(cat((SUBSTR(T1.CreatedAt,1,4)),(SUBSTR(T1.CreatedAt,6,2)),(SUBSTR(T1.CreatedAt,9,2))) ,BEST10.) AS F_CREACION
      FROM result.USER_INFO t1 WHERE t1.RUT IS NOT NULL
ORDER BY t1.RUT
;
QUIT;

/*Convertir rut de alfanumerico a numérico*/
PROC SQL;
   CREATE TABLE TMP_DEPASO_DATOS_APP_DIA_3 AS 
   SELECT 	input(cat(t1.rut_sin_dv),best.) as RUT,
   			T1.EMAIL,
			T1.F_ULTIMO_CONTACT,
			T1.F_CREACION
      FROM TMP_DEPASO_DATOS_APP_DIA_2 t1 
ORDER BY RUT
;
QUIT;

/*Tomar fecha maxima de creación DIA*/
proc sql;
create table TMP_DATOS_APP_FMAX_CREACION AS
	SELECT	DISTINCT RUT, 
	        EMAIL, 
	        MAX(T1.F_CREACION) AS FECHA,
	        3 AS SEQUENCIA,
			'APP_USER_INFO' AS ORIGEN
	    FROM TMP_DEPASO_DATOS_APP_DIA_3 t1
	GROUP BY RUT
;quit;

/*Tomar fecha maxima de ultimo contacto DIA*/
proc sql;
create table TMP_DATOS_APP_FMAX_ULT_CONTACTO AS
SELECT	DISTINCT RUT, 
        EMAIL, 
        MAX(T1.F_ULTIMO_CONTACT) AS FECHA,
        3 AS SEQUENCIA,
		'APP' AS ORIGEN
    FROM TMP_DEPASO_DATOS_APP_DIA_3 t1
GROUP BY RUT
;quit;

/*FECHA MÁS RECIENTE YA SEA DE CREACIÓN O DE ULTIMO CONTACTO*/
PROC SQL;
CREATE TABLE TMP_DATOS_APP_FECHA_RECIENTE AS
SELECT DISTINCT T1.RUT,
		T1.EMAIL,
		CASE WHEN (T2.FECHA > T1.FECHA AND T2.FECHA IS NOT NULL) THEN T2.FECHA ELSE T1.FECHA END AS FECHA,
		T1.SEQUENCIA,
		T1.ORIGEN
	FROM TMP_DATOS_APP_FMAX_CREACION T1 LEFT JOIN TMP_DATOS_APP_FMAX_ULT_CONTACTO T2
		ON (T1.RUT = T2.RUT)
;QUIT;

/*CAMBIAR A FORMATO FECHA IGUAL A LOS DEMÁS PROCESOS*/
PROC SQL;
CREATE TABLE TMP_DATOS_APP_UNION_DIA AS
SELECT DISTINCT T1.RUT,
		T1.EMAIL,
		DHMS((MDY(INPUT(SUBSTR(PUT(t1.FECHA,BEST8.),5,2),BEST4.),
                  INPUT(SUBSTR(PUT(t1.FECHA,BEST8.),7,2),BEST4.),
                  INPUT(SUBSTR(PUT(t1.FECHA,BEST8.),1,4),BEST4.))),0,0,0) FORMAT=datetime20. AS FECHA_ACTUALIZACION,
		T1.SEQUENCIA,
		T1.ORIGEN
	FROM TMP_DATOS_APP_FECHA_RECIENTE T1
;QUIT;
/*========	FIN - OBTENER DATOS DE APP DE BD DIARIO		====================================*/

/*========	De la dos bases, el registro más actualizado	================================*/
/*LEFT JOIN*/
PROC SQL;
CREATE TABLE TMP_BASE_EMAIL_APP_UNION3 AS
SELECT 	DISTINCT T1.RUT,
		T1.EMAIL,
		CASE WHEN (T2.FECHA_ACTUALIZACION > T1.FECHA_ACTUALIZACION AND T2.FECHA_ACTUALIZACION IS NOT NULL) THEN T2.FECHA_ACTUALIZACION ELSE T1.FECHA_ACTUALIZACION END AS FECHA_ACTUALIZACION,
		T1.SEQUENCIA,
		T1.ORIGEN
	FROM TMP_DATOS_APP_UNION_DIA T1 left JOIN TMP_DATOS_APP_HIS T2
		ON (T1.RUT = T2.RUT)
;QUIT;

/*RIGHT JOIN*/
PROC SQL;
CREATE TABLE TMP_BASE_EMAIL_APP_UNION4 AS
SELECT 	DISTINCT T2.RUT,
		T2.EMAIL,
		CASE WHEN (T2.FECHA_ACTUALIZACION > T1.FECHA_ACTUALIZACION AND T2.FECHA_ACTUALIZACION IS NOT NULL) THEN T2.FECHA_ACTUALIZACION ELSE T1.FECHA_ACTUALIZACION END AS FECHA_ACTUALIZACION,
		T2.SEQUENCIA,
		T2.ORIGEN
	FROM TMP_DATOS_APP_UNION_DIA T1 RIGHT JOIN TMP_DATOS_APP_HIS T2
		ON (T1.RUT = T2.RUT) WHERE T1.RUT IS NULL
;QUIT;

/*PASAR LA FECHA DEL LEFT JOIN A FORMATO FECHA*/
PROC SQL;
CREATE TABLE TMP_BASE_EMAIL_APP_UNION5 AS
SELECT 	T1.RUT,
		T1.EMAIL,
		t1.FECHA_ACTUALIZACION FORMAT=datetime20. AS FECHA_ACTUALIZACION,
		T1.SEQUENCIA,
		T1.ORIGEN
	FROM TMP_BASE_EMAIL_APP_UNION3 T1
order by FECHA_ACTUALIZACION
;QUIT;

/*PASAR LA FECHA DEL RIGHT JOIN A FORMATO FECHA*/
PROC SQL;
CREATE TABLE TMP_BASE_EMAIL_APP_UNION6 AS
SELECT 	T1.RUT,
		T1.EMAIL,
		t1.FECHA_ACTUALIZACION FORMAT=datetime20. AS FECHA_ACTUALIZACION,
		T1.SEQUENCIA,
		T1.ORIGEN
	FROM TMP_BASE_EMAIL_APP_UNION4 T1
order by FECHA_ACTUALIZACION
;QUIT;

/*UNIR AMBOS RESULTADOS PARA OBTENER TODOS LOS REGISTROS MÁS ACTUALIZADOS DEL DIA Y HISTÓRICOS*/
PROC SQL;
CREATE TABLE BASE_EMAIL_APP_FINAL AS
	SELECT * FROM TMP_BASE_EMAIL_APP_UNION5
UNION ALL
	SELECT * FROM TMP_BASE_EMAIL_APP_UNION6
;QUIT;

PROC SQL;
CREATE TABLE RESULT.BASE_EMAIL_APP_FINAL AS
	SELECT T1.RUT,
		T1.EMAIL,
		input(put(datepart(t1.FECHA_ACTUALIZACION),yymmddn8.),best.) as FECHA_ACT,
		T1.SEQUENCIA,
		T1.ORIGEN FROM BASE_EMAIL_APP_FINAL t1
	WHERE T1.RUT < 99999999 AND T1.RUT > 10000 AND T1.RUT IS NOT MISSING
	AND t1.email not LIKE	('.-%')				AND t1.email not LIKE	('%.')
	AND t1.email not LIKE	('-%')				AND t1.email not LIKE	('%.@%')
	/*AND t1.email not LIKE	('% %')*/
    AND t1.email not CONTAINS 	('XXXXX')
	AND t1.email not CONTAINS 	('DEFAULT')		AND t1.email not CONTAINS 	('TEST@')
	AND t1.email not CONTAINS 	('..')			AND t1.email not CONTAINS 	('PRUEBA')
	AND t1.email not CONTAINS	('(')			AND t1.email not CONTAINS 	(')')
	AND t1.email not CONTAINS	('/')			AND t1.email not CONTAINS	('?')
	AND t1.email not CONTAINS 	('¿')			AND t1.email not CONTAINS 	('SINMAIL')
	AND t1.email not CONTAINS 	('NOTIENE')		AND t1.email not CONTAINS 	('NOTENGO')
	AND t1.email not CONTAINS 	('SINCORRE')	AND t1.email not CONTAINS 	('TEST@')
	AND t1.email <>'@'							AND t1.email not CONTAINS	('GFFDF')
	AND t1.email not CONTAINS 	('0000000')		AND t1.email not CONTAINS 	('GMAIL.CL')
	AND t1.email not CONTAINS 	('GMAIL.ES')	AND t1.email <>'0'
	AND t1.email CONTAINS 	('@')				AND t1.email not CONTAINS 	('SINEMAIL')
	AND t1.email not CONTAINS 	('NOREGISTRA')  AND t1.email not CONTAINS 	('SINMALLIL')
	AND t1.email not CONTAINS 	('@MAILINATOR.COM')	AND t1.email not CONTAINS 	('@MICORREO.COM')	
	AND t1.email not CONTAINS 	('@HOTRMAIL.COM')	AND t1.email not CONTAINS	('@SDFDF.CL' )
	/*agregado pia*/
	 AND t1.email not CONTAINS ('HORTMAIL.COM')       AND t1.email not CONTAINS ('REPLEY.COM')
	 AND t1.email not CONTAINS ('BANCPORIPLEY.COM')       AND t1.email not CONTAINS ('GMAL.COM')
	 AND t1.email not CONTAINS ('RILPLEY.COM')       AND t1.email not CONTAINS ('HOTMAI.COM')
	 AND t1.email not CONTAINS ('GAMIL.COM')       AND t1.email not CONTAINS ('RIPEY.CL')
	 AND t1.email not CONTAINS ('RIPLEY.VOM')       AND t1.email not CONTAINS ('HTOMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.CON')       AND t1.email not CONTAINS ('GMIL.COM')
	 AND t1.email not CONTAINS ('HOTAMIL.COM')       AND t1.email not CONTAINS ('123MAIL.CL')
	 AND t1.email not CONTAINS ('ICLOOUD.COM')       AND t1.email not CONTAINS ('YMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMIAL.COM')       AND t1.email not CONTAINS ('GMAI.COM')
	 AND t1.email not CONTAINS ('HOTMAIL.OM')       AND t1.email not CONTAINS ('GMAIIL.COM')
	 AND t1.email not CONTAINS ('RIOLPLEY.COM')       AND t1.email not CONTAINS ('aol.com')
	 AND t1.email not CONTAINS ('GMSAIL.COM')       AND t1.email not CONTAINS ('ICLOU.COM')
	 AND t1.email not CONTAINS ('GMAIL.CM')       AND t1.email not CONTAINS ('GMIAL.COM')
	 AND t1.email not CONTAINS ('UAHOO.COM')       AND t1.email not CONTAINS ('HOTMAIL.OCM')
	 AND t1.email not CONTAINS ('GMAILC.OM')       AND t1.email not CONTAINS ('UTLOOOK.COM')
	 AND t1.email not CONTAINS ('RIPLE.COM')       AND t1.email not CONTAINS ('GMAILL.COM')
	 AND t1.email not CONTAINS ('GMAOL.COM')       AND t1.email not CONTAINS ('HORMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMAL.COM')       /*AND t1.email not CONTAINS ('OTMAIL.COM')*/
	 AND t1.email not CONTAINS ('2HOTMAIL.ES')       AND t1.email not CONTAINS ('XXX.COM')
	 AND t1.email not CONTAINS ('AUTLOOK.COM')       AND t1.email not CONTAINS ('8GMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMN')       AND t1.email not CONTAINS ('OITLOOK.COM')
	 AND t1.email not CONTAINS ('OUTLOCK.COM')       AND t1.email not CONTAINS ('GMAIL.OM')
	 AND t1.email not CONTAINS ('GMAIL.LCOM')       AND t1.email not CONTAINS ('OUTLLOK.CL')
	 AND t1.email not CONTAINS ('OULOOCK.ES')       AND t1.email not CONTAINS ('OULOOKS.ES')
	 AND t1.email not CONTAINS ('GAMIAL.COM')       AND t1.email not CONTAINS ('HOTMAILL.COM')
	 AND t1.email not CONTAINS ('GMAIL.CPM')       AND t1.email not CONTAINS ('64GMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIOL.COM')
	 /*agregado email Lore Gerrero*/
     	 AND t1.email not CONTAINS ('yahho.com')       AND t1.email not CONTAINS ('EMAIL.CON')
	 AND t1.email not CONTAINS ('OUTLOKK.ES')       AND t1.email not CONTAINS ('HORMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.VOM')       AND t1.email not CONTAINS ('YAHOO.CL')
	 AND t1.email not CONTAINS ('GMEIL.CL')       AND t1.email not CONTAINS ('GMAKL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COL')       AND t1.email not CONTAINS ('GMAIL.COMO')
	 AND t1.email not CONTAINS ('GHOTMAIL.COM')       AND t1.email not CONTAINS ('GMAIL.COMF')
	 AND t1.email not CONTAINS ('LIVE.CK')       AND t1.email not CONTAINS ('GMEIL.CMMAIL.COM')
	 AND t1.email not CONTAINS ('GMMAIL.COM')       AND t1.email not CONTAINS ('HOTMKAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMHOTMAIL.COM')       AND t1.email not CONTAINS ('HOTRMAIL.COM')
	 AND t1.email not CONTAINS ('HOIMAIL.COM')       AND t1.email not CONTAINS ('XN--GMAI-JQA.COM')
	 AND t1.email not CONTAINS ('HMAIL.COM')       AND t1.email not CONTAINS ('OUTLOOK.CM')
	 AND t1.email not CONTAINS ('HATMAIL.CON')       AND t1.email not CONTAINS ('GMAIL.COMON')
	 AND t1.email not CONTAINS ('GMIL.CO')       AND t1.email not CONTAINS ('GMALL.COM')
	 AND t1.email not CONTAINS ('HOTMAIAL.COM')       AND t1.email not CONTAINS ('GMAIK.COM')
	 AND t1.email not CONTAINS ('OUTLOOCK.COM')       AND t1.email not CONTAINS ('GMAQIL.COM')
	 AND t1.email not CONTAINS ('GMAILC.OM')       AND t1.email not CONTAINS ('GMAIA.COM')
	 AND t1.email not CONTAINS ('HOTMAIL.COL')       AND t1.email not CONTAINS ('GMNAIL.COM')
	 AND t1.email not CONTAINS ('OUTLLOOK.ES')       AND t1.email not CONTAINS ('GMEIL.CON')
	 	 /*agregados de la base de simulacion hb new*/
     /*  AND t1.email not CONTAINS ('GMAIL.CO') */	          AND t1.email not CONTAINS ('GMAIL.COMU')
	AND t1.email not CONTAINS ('GMAIL.CON')           AND t1.email not CONTAINS ('123MAIL.CL')
	 AND t1.email not CONTAINS ('GMAIL.COMOESTAS')    AND t1.email not CONTAINS ('GMAIL.COMO')
	 AND t1.email not CONTAINS ('GIMAIL.COM')        AND t1.email not CONTAINS ('GMAL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMM')        AND t1.email not CONTAINS ('GMAIL.XOM')
	 AND t1.email not CONTAINS ('GMAIL.CM')         AND t1.email not CONTAINS ('GIMEIL.COM')
	 AND t1.email not CONTAINS ('HOTMIAL.COM')       AND t1.email not CONTAINS ('HOOTMAIL.ES')
	 AND t1.email not CONTAINS ('HOTMAIL.CON')       AND t1.email not CONTAINS ('GIMAIL.CON')
	 AND t1.email not CONTAINS ('HOTMEIL.COM')       AND t1.email not CONTAINS ('GMAIL.VOM')
	 AND t1.email not CONTAINS ('HOTMEIL.ES')        AND t1.email not CONTAINS ('GMAIL.CL.COM')
	 AND t1.email not CONTAINS ('GIMAL.COM')         AND t1.email not CONTAINS ('GMAIL.COMIL.COM')
	 AND t1.email not CONTAINS ('HOTMAIK.COM')       AND t1.email not CONTAINS ('GMAIL.COMQ')
	 AND t1.email not CONTAINS ('HOTMAIIL.COM')      AND t1.email not CONTAINS ('HOTMAIL.CPM')
	AND t1.email not CONTAINS ('GMAIL.COML')        AND t1.email not CONTAINS ('G.MAIL.COM')
	 AND t1.email not CONTAINS ('HOTMAOL.COM')       AND t1.email not CONTAINS ('GMAILL.COM')
	 AND t1.email not CONTAINS ('GIMAIL.CL')         AND t1.email not CONTAINS ('GMAIL.COMD')
	 AND t1.email not CONTAINS ('HOTTMAIL.COM')      AND t1.email not CONTAINS ('HOTMAILC.OM')
	 AND t1.email not CONTAINS ('1967GMAIL.COM')     AND t1.email not CONTAINS ('HOTMAY.COM')
	/* AND t1.email not CONTAINS ('HOTMAIL.CO') */       AND t1.email not CONTAINS ('GMIAL.COM')
	 AND t1.email not CONTAINS ('2382HOTMAIL.COM')   AND t1.email not CONTAINS ('GMALL.COM')
	 AND t1.email not CONTAINS ('GIMALL.COM')        AND t1.email not CONTAINS ('HOTMAIL.COMBUE')
	 AND t1.email not CONTAINS ('GMAIL.CPM')         AND t1.email not CONTAINS ('123GMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMP')        AND t1.email not CONTAINS ('GMIL.CPM')
	 AND t1.email not CONTAINS ('GMALI.COM')         AND t1.email not CONTAINS ('JAJAJA.CL')
	 AND t1.email not CONTAINS ('AUTLOOK.COM')       AND t1.email not CONTAINS ('GMAIL.CLOM')
	 AND t1.email not CONTAINS ('GMAIL.COMCOM')      AND t1.email not CONTAINS ('GMAIL.CIM')
	 AND t1.email not CONTAINS ('ICLOUD.CON')        AND t1.email not CONTAINS ('OUTLOOK.COMM')
	 AND t1.email not CONTAINS ('HOTMEIL.CL')        AND t1.email not CONTAINS ('HOTMAIO.COM')
	 AND t1.email not CONTAINS ('GMAIL.COPM')        AND t1.email not CONTAINS ('GAIML.COM')
	AND t1.email not CONTAINS ('HOTMAIL.COMO')      AND t1.email not CONTAINS ('JAJAGMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMEMAIL')    AND t1.email not CONTAINS ('HOTMAIL.COMR')
	 AND t1.email not CONTAINS ('OULTOOK.CL')        AND t1.email not CONTAINS ('BANCORYPLEY.CL')
	 AND t1.email not CONTAINS ('GMAIM.COM')         AND t1.email not CONTAINS ('B8477491ANCORIPLEY.COM')
	AND t1.email not CONTAINS ('GMAIL.COMN')        AND t1.email not CONTAINS ('GMMAIL.COM')
	 AND t1.email not CONTAINS ('2857GMAIL.COM')     AND t1.email not CONTAINS ('HOTMAIEL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COL')         AND t1.email not CONTAINS ('GHOTMAIL.COM')
	/* AND t1.email not CONTAINS ('OUTLOOK.CO')*/        AND t1.email not CONTAINS ('GMAIIL.COM')
	 AND t1.email not CONTAINS ('OUTLOOK.CON')       AND t1.email not CONTAINS ('LIVE.CM')
	 AND t1.email not CONTAINS ('HOGMAIL.ES')        AND t1.email not CONTAINS ('GMAIL.COMQQSWS')
	 AND t1.email not CONTAINS ('HOTMAKL.COM')       AND t1.email not CONTAINS ('GMAIL.CO.COM')
	AND t1.email not CONTAINS ('HOTMAUL.COM')        AND t1.email not CONTAINS ('OUTLOOCK.COM')
	 AND t1.email not CONTAINS ('GMANIL.COM')        AND t1.email not CONTAINS ('OUTLOO.COM')
	 AND t1.email not CONTAINS ('ICLUD.COM')         AND t1.email not CONTAINS ('GMAIL.COM.CL')
	 AND t1.email not CONTAINS ('OUTLLOK.COM')       AND t1.email not CONTAINS ('GMAIL.COK')
	 AND t1.email not CONTAINS ('GMAIL.COM.COM')     AND t1.email not CONTAINS ('OULOOK.COM')
	 AND t1.email not CONTAINS ('OUTOOK.COM')        AND t1.email not CONTAINS ('59GMEIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.CCOM')        AND t1.email not CONTAINS ('GMAIL.COOM')
	 AND t1.email not CONTAINS ('434GOTMAIL.CL')     AND t1.email not CONTAINS ('GM8AIL.COM')
	 AND t1.email not CONTAINS ('HOGMAIL.COM')       AND t1.email not CONTAINS ('GMAIL.COMA')
	 AND t1.email not CONTAINS ('GMAIIL.CO')         AND t1.email not CONTAINS ('HOTMEY.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMS')        AND t1.email not CONTAINS ('YAHUU.COM')
	 AND t1.email not CONTAINS ('A01GMAIL.COM')      AND t1.email not CONTAINS ('HOTMAIL.COL')
	 AND t1.email not CONTAINS ('GMAIO.COM')         AND t1.email not CONTAINS ('GMAIL.GMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.COMOM')       AND t1.email not CONTAINS ('HOTMAIM.COM')
	AND t1.email not CONTAINS ('HOTMAIL.COMK')
		/* AGREGADOS POR ANALISIS DE WEBBULA */
	 AND t1.email not CONTAINS ('GMSIL.COM')       AND t1.email not CONTAINS ('MC.COM')
	 AND t1.email not CONTAINS ('LIVER.COM')        AND t1.email not CONTAINS ('HOMAIL.COM')
	 AND t1.email not CONTAINS ('GMAUL.COM')       AND t1.email not CONTAINS ('HTMAIL.COM')
  	 AND t1.email not CONTAINS ('GNAIL.COM')        AND t1.email not CONTAINS ('HOYMAIL.COM')
     AND t1.email not CONTAINS ('LIV.COM')        AND t1.email not CONTAINS ('HPTMAIL.COM')
	 AND t1.email not CONTAINS ('GMAOIL.COM')         AND t1.email not CONTAINS ('HOTMWIL.COM')
	 AND t1.email not CONTAINS ('GMAAIL.COM')       AND t1.email not CONTAINS ('GMASIL.COM')
	 AND t1.email not CONTAINS ('GFMAIL.COM')     AND t1.email not CONTAINS ('MGAIL.COM')
	 AND t1.email not CONTAINS ('H0TMAIL.COM')        AND t1.email not CONTAINS ('GMJAIL.COM')
	 AND t1.email not CONTAINS ('FGMAIL.COM')        AND t1.email not CONTAINS ('HOTMAAIL.CO')
	 AND t1.email not CONTAINS ('HITMAIL.COM')     AND t1.email not CONTAINS ('HOTMAIL.COMQUE')
	 AND t1.email not CONTAINS ('HOTMASIL.COM')       AND t1.email not CONTAINS ('HOTAIL.COM')
	 AND t1.email not CONTAINS ('GOTMAIL.COM')         AND t1.email not CONTAINS ('GTMAIL.COM')
	 AND t1.email not CONTAINS ('NSN.COM')        AND t1.email not CONTAINS ('HOTMSIL.COM')
	 AND t1.email not CONTAINS ('FMAIL.COM')      AND t1.email not CONTAINS ('HOTMAOIL.COM')
	 AND t1.email not CONTAINS ('HOMTAIL.COM')         AND t1.email not CONTAINS ('LIUVE.COM')
	 AND t1.email not CONTAINS ('GMAILO.COM')       AND t1.email not CONTAINS ('GGMAIL.COM')
	 AND t1.email not CONTAINS ('JOTMAIL.COM')       AND t1.email not CONTAINS ('GMQIL.COM')
	 AND t1.email not CONTAINS ('GMAIKL.COM')        AND t1.email not CONTAINS ('HOTMSAIL.COM')
	 AND t1.email not CONTAINS ('GAIL.COM')       AND t1.email not CONTAINS ('GMAIL.COMCIMI')
	 AND t1.email not CONTAINS ('LICE.COM')        AND t1.email not CONTAINS ('GMAIL.CKM')
     AND t1.email not CONTAINS ('HHOTMAIL.COM')        AND t1.email not CONTAINS ('HLTMAIL.COM')
	 AND t1.email not CONTAINS ('ICLOUB.COM')         AND t1.email not CONTAINS ('HOTMAIL.COOM')
	 AND t1.email not CONTAINS ('HOTMAIKL.COM')       AND t1.email not CONTAINS ('HJOTMAIL.COM')
	 AND t1.email not CONTAINS ('HOPTMAIL.COM')     AND t1.email not CONTAINS ('HOTMAIUL.COM')
	 AND t1.email not CONTAINS ('HOTMMAIL.COM')        AND t1.email not CONTAINS ('HOTMALL.COM')
	 AND t1.email not CONTAINS ('HOTGMAIL.COM')        AND t1.email not CONTAINS ('LIVE.COL')
	 AND t1.email not CONTAINS ('HOTNAIL.COM')     AND t1.email not CONTAINS ('LIBE.COM')
	 AND t1.email not CONTAINS ('GMAUIL.COM')       AND t1.email not CONTAINS ('H0OTMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMAQIL.COM')         AND t1.email not CONTAINS ('GMAI9L.COM')
	 AND t1.email not CONTAINS ('GNMAIL.COM')        AND t1.email not CONTAINS ('HOTMAILK.COM')
	 AND t1.email not CONTAINS ('HOYTMAIL.COM')      AND t1.email not CONTAINS ('HOTMAIL.CM')
	 AND t1.email not CONTAINS ('HOTMAAIL.COM')         AND t1.email not CONTAINS ('HOTFMAIL.COM')
	 AND t1.email not CONTAINS ('HOMAIL.CO')       AND t1.email not CONTAINS ('HIOTMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMAKIL.COM')         AND t1.email not CONTAINS ('GMAILK.COM')
	 AND t1.email not CONTAINS ('HOHTMAIL.COM')       AND t1.email not CONTAINS ('HOTYMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMAUIL.COM')     AND t1.email not CONTAINS ('ME.CM')
	 AND t1.email not CONTAINS ('HOTMAIL.COIM')        AND t1.email not CONTAINS ('L8VE.COM')
	 AND t1.email not CONTAINS ('HOTMNAIL.COM')        AND t1.email not CONTAINS ('OHTMAIL.COM')
	 AND t1.email not CONTAINS ('HOT6MAIL.COM')     AND t1.email not CONTAINS ('GMQIL.VOM')
	 AND t1.email not CONTAINS ('GMZAIL.COM')       AND t1.email not CONTAINS ('LIVE.CCOM')
	 AND t1.email not CONTAINS ('LIVEW.COM')         AND t1.email not CONTAINS ('YGMAIL.COM')
	 AND t1.email not CONTAINS ('BOTMAIL.COM')        AND t1.email not CONTAINS ('GMAIL.CO9M')
	 AND t1.email not CONTAINS ('GMAIL.COMG')      AND t1.email not CONTAINS ('HOTMAIL.CIOM')
	 AND t1.email not CONTAINS ('HPOTMAIL.COM')         AND t1.email not CONTAINS ('MAIL.CM')
	 AND t1.email not CONTAINS ('HOHMAIL.COM')       AND t1.email not CONTAINS ('HOTMAIL.COPM')
	 AND t1.email not CONTAINS ('HOT5MAIL.COM')        AND t1.email not CONTAINS ('GMZIL.COM')
	 AND t1.email not CONTAINS ('HOLTMAIL.COM')      AND t1.email not CONTAINS ('LIVE.CON')
	 AND t1.email not CONTAINS ('HUOTMAIL.COM')         AND t1.email not CONTAINS ('MSNM.COM')
	 AND t1.email not CONTAINS ('HO0TMAIL.COM')       AND t1.email not CONTAINS ('HOTMAI.COK')
	 AND t1.email not CONTAINS ('GMAZIL.COM')         AND t1.email not CONTAINS ('LVIE.COM')
	 AND t1.email not CONTAINS ('HOTMAIL.CCOM')       AND t1.email not CONTAINS ('HOTMAIL.CLOM')
	 AND t1.email not CONTAINS ('HOOTMAIL.COM')     AND t1.email not CONTAINS ('HOTHMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMIL.CON')        AND t1.email not CONTAINS ('MZN.COM')
	 AND t1.email not CONTAINS ('HOMAIL.CM')        AND t1.email not CONTAINS ('ICLOUD.OM')
	 AND t1.email not CONTAINS ('HGOTMAIL.COM')     AND t1.email not CONTAINS ('GMIL.CON')
	 AND t1.email not CONTAINS ('LIVE.VOM')       AND t1.email not CONTAINS ('GAIL.CO')
	 AND t1.email not CONTAINS ('GMA9IL.COM')         AND t1.email not CONTAINS ('HTMAIL.CPM')
	 AND t1.email not CONTAINS ('GMAI.LCOM')        AND t1.email not CONTAINS ('GMIL.CM')
	 AND t1.email not CONTAINS ('MSN.CM')      AND t1.email not CONTAINS ('BHOTMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIUL.COM')         AND t1.email not CONTAINS ('HO9TMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMJAIL.COM')       AND t1.email not CONTAINS ('GMA8L.COM')
     AND t1.email not CONTAINS ('GAMIL.CON')      AND t1.email not CONTAINS ('GKMAIL.COM')
	 AND t1.email not CONTAINS ('GMAIL.BOM')         AND t1.email not CONTAINS ('LIE.COM')
	 AND t1.email not CONTAINS ('HOTMIL.CO')       AND t1.email not CONTAINS ('GMAIL.CIOM')
	 AND t1.email not CONTAINS ('LUVE.COM')         AND t1.email not CONTAINS ('NOTMAIL.COM')
	 AND t1.email not CONTAINS ('HOTMQAIL.COM')       AND t1.email not CONTAINS ('HOTMIL.CM')
	 AND t1.email not CONTAINS ('GMAIL.VCOM')     AND t1.email not CONTAINS ('HOTMAIL.CAM')
	 AND t1.email not CONTAINS ('HOTNAIL.CO')        AND t1.email not CONTAINS ('HOTJMAIL.COM')
	 AND t1.email not CONTAINS ('GMIIL.COM')        AND t1.email not CONTAINS ('H9OTMAIL.COM')
	 AND t1.email not CONTAINS ('GYMAIL.COM')     AND t1.email not CONTAINS ('HNOTMAIL.COM')
	 AND t1.email not CONTAINS ('HOTNMAIL.COM')       AND t1.email not CONTAINS ('GMA8IL.COM')
	 AND t1.email not CONTAINS ('GHMAIL.COM')         AND t1.email not CONTAINS ('GJMAIL.COM')
	 AND t1.email not CONTAINS ('GMAWIL.COM')        AND t1.email not CONTAINS ('HOTMMAIL.CO')
	 AND t1.email not CONTAINS ('GMWIL.COM')      AND t1.email not CONTAINS ('LIVD.COM')
	 AND t1.email not CONTAINS ('HYOTMAIL.COM')         AND t1.email not CONTAINS ('HOMAIL.OM')
	 AND t1.email not CONTAINS ('LIVE.CM')       AND t1.email not CONTAINS ('HOMAIL.CON')
	 AND t1.email not CONTAINS ('HLOTMAIL.COM')         AND t1.email not CONTAINS ('HGMAIL.CO')
	 AND t1.email not CONTAINS ('HOTAIL.CO')       AND t1.email not CONTAINS ('GMAKIL.COM')
	 AND t1.email not CONTAINS ('LILVE.COM')         AND t1.email not CONTAINS ('HOOTMAIL.CO')
	 AND t1.email not CONTAINS ('HBOTMAIL.COM')       AND t1.email not CONTAINS ('GMQAIL.COM')
	 AND t1.email not CONTAINS ('LIVE.CIM')     AND t1.email not CONTAINS ('HORMAIL.CON')
	 AND t1.email not CONTAINS ('HOTMAI9L.COM')        AND t1.email not CONTAINS ('GMKAIL.COM')
	 AND t1.email not CONTAINS ('MSMN.COM')        AND t1.email not CONTAINS ('GKAIL.COM')
	 AND t1.email not CONTAINS ('YHAOO.COM')     AND t1.email not CONTAINS ('YAHHO.COM')
	 AND t1.email not CONTAINS ('YAHO.COM')       AND t1.email not CONTAINS ('YAHOIO.COM')
	 AND t1.email not CONTAINS ('YAOO.COM')         AND t1.email not CONTAINS ('YAHOOO.COM')
	 AND t1.email not CONTAINS ('YAHOO.CO')        AND t1.email not CONTAINS ('HOTMAIL.DOM')
	 AND t1.email not CONTAINS ('GMAILL.CM')      AND t1.email not CONTAINS ('HOTMAIL.COM.YAHOO.ES')
	 AND t1.email not CONTAINS ('YQHOO.COM')         AND t1.email not CONTAINS ('HOTMAI.CM')
	 AND t1.email not CONTAINS ('TAHOO.COM')       AND t1.email not CONTAINS ('HOTMA8L.COM')
	 AND t1.email not CONTAINS ('JMAIL.COM')        AND t1.email not CONTAINS ('GIMAIL.CM')
	 AND t1.email not CONTAINS ('GEMAIL.CO')      AND t1.email not CONTAINS ('GIMAIL.CO')
	 AND t1.email not CONTAINS ('YOPMAIL.CO')         AND t1.email not CONTAINS ('HOTMAIL.17.COM')
	 AND t1.email not CONTAINS ('CORREO.OM')       AND t1.email not CONTAINS ('HORMAIL.CO')
	 AND t1.email not CONTAINS ('UTLOOK.COM')         AND t1.email not CONTAINS ('YHOO.COM')
	 AND t1.email not CONTAINS ('YAJOO.COM')       AND t1.email not CONTAINS ('HOTMIAL.CO')
	 AND t1.email not CONTAINS ('YAYOO.COM')         AND t1.email not CONTAINS ('HOTMALIL.COM')
	 AND t1.email not CONTAINS ('YMSIL.COM')       AND t1.email not CONTAINS ('HOTMIAL.CM')
	 AND t1.email not CONTAINS ('YASHOO.COM')     AND t1.email not CONTAINS ('HOTMAILL.CO')
	 AND t1.email not CONTAINS ('YAHOOL.COM')        AND t1.email not CONTAINS ('HOTMAIOL.COM')
	 AND t1.email not CONTAINS ('HOTMMAIL.OM')        AND t1.email not CONTAINS ('YAQHOO.COM')
	 AND t1.email not CONTAINS ('YSHOO.COM')     AND t1.email not CONTAINS ('GMIAL.CON')
	 AND t1.email not CONTAINS ('LIVR.COM')       AND t1.email not CONTAINS ('HOTMAWIL.COM')
	 AND t1.email not CONTAINS ('GMMAIL.CO')         AND t1.email not CONTAINS ('HTMAIL.CM')
	 AND t1.email not CONTAINS ('NAIL.COM')        AND t1.email not CONTAINS ('MAIOL.COM')
	 AND t1.email not CONTAINS ('GM.CON')      AND t1.email not CONTAINS ('GM.CO')
	 AND t1.email not CONTAINS ('HO5TMAIL.COM')         AND t1.email not CONTAINS ('GMAIL.FOM')
	 AND t1.email not CONTAINS ('MAI.CM')       AND t1.email not CONTAINS ('EMAIL.CO')
	 AND t1.email not CONTAINS ('GOTMAIL.CO')        AND t1.email not CONTAINS ('LIVS.COM')
	 AND t1.email not CONTAINS ('LICVE.COM')      AND t1.email not CONTAINS ('MAIL.CON')
	 AND t1.email not CONTAINS ('JMAIL.CO')         AND t1.email not CONTAINS ('MAIIL.COM')
	 AND t1.email not CONTAINS ('GIMEI.CO')       AND t1.email not CONTAINS ('HOTMAILC.OM')
	 AND t1.email not CONTAINS ('GMAILC.OM')         AND t1.email not CONTAINS ('GIMIL.CON')
	 AND t1.email not CONTAINS ('HOTAMAIL.CO')       AND t1.email not CONTAINS ('YMAIL.CM')
	 AND t1.email not CONTAINS ('YMAIL.CO')         AND t1.email not CONTAINS ('OUTLOOOK.COM')
	 AND t1.email not CONTAINS ('GAMIAL.CO')       AND t1.email not CONTAINS ('OITLOOK.COM')
	 AND t1.email not CONTAINS ('ICLUD.CON')     AND t1.email not CONTAINS ('OUTLOOK.CON')
	 AND t1.email not CONTAINS ('AUTLOOK.CO')        AND t1.email not CONTAINS ('GIMEI.CON')
	 AND t1.email not CONTAINS ('OUTLOKK.COM')        AND t1.email not CONTAINS ('GMLI.CON')
	 AND t1.email not CONTAINS ('GMEIL.CO')     AND t1.email not CONTAINS ('GOMAIL.CO')
	 AND t1.email not CONTAINS ('MGMAIL.CO')       AND t1.email not CONTAINS ('GMEIL.CPM')
	 AND t1.email not CONTAINS ('HOTMEIL.COM')         AND t1.email not CONTAINS ('GITMAIL.COM')
	 AND t1.email not CONTAINS ('UMAIL.COM')        AND t1.email not CONTAINS ('HJFJH.CM')
	 AND t1.email not CONTAINS ('GEMEIL.CO')      AND t1.email not CONTAINS ('HIMAIL.CO')
	 AND t1.email not CONTAINS ('GAMAIL.CO')         AND t1.email not CONTAINS ('GIMEIL.CO')
	 AND t1.email not CONTAINS ('GIMIL.COMO')       AND t1.email not CONTAINS ('GIMAL.CON')
	 AND t1.email not CONTAINS ('HOTM.COMAIL')         AND t1.email not CONTAINS ('YNAIL.COM')
	 AND t1.email not CONTAINS ('GIMEIL.CIM')       AND t1.email not CONTAINS ('HOLMAIL.CM')
	 AND t1.email not CONTAINS ('YMIAL.COM')        AND t1.email not CONTAINS ('GMEIL.COMO')
	 AND t1.email not CONTAINS ('HOIMAIL.COM')      AND t1.email not CONTAINS ('HOITMAIL.CL')
	 AND t1.email not CONTAINS ('WWW.HOTMAIL.COM')         AND t1.email not CONTAINS ('THOMAIL.CL')
	 AND t1.email not CONTAINS ('YQAHOO.COM')       AND t1.email not CONTAINS ('HAHOO.COM')
	 AND t1.email not CONTAINS ('YAHOL.COM')         AND t1.email not CONTAINS ('YAGOO.COM')
	 AND t1.email not CONTAINS ('UAHOO.COM')       AND t1.email not CONTAINS ('YAHOO.CM')
	 AND t1.email not CONTAINS ('YAHHOO.COM')         AND t1.email not CONTAINS ('YAAHOO.COM')
	 AND t1.email not CONTAINS ('YSAHOO.COM')       AND t1.email not CONTAINS ('YAHOO.CON.CO')
	 AND t1.email not CONTAINS ('YAHO0.COM')     AND t1.email not CONTAINS ('YAHOOP.COM')
	 AND t1.email not CONTAINS ('YYAHOO.COM')        AND t1.email not CONTAINS ('YABHOO.COM')
	 AND t1.email not CONTAINS ('YAHPOO.COM')        AND t1.email not CONTAINS ('YAHJOO.COM')
	 AND t1.email not CONTAINS ('HYAHOO.COM')     AND t1.email not CONTAINS ('YTAHOO.COM')
	 AND t1.email not CONTAINS ('YAHIO.COM')       AND t1.email not CONTAINS ('UYAHOO.COM')
	 AND t1.email not CONTAINS ('YAHOO0.COM')         AND t1.email not CONTAINS ('YAHOO.COM')
	 AND t1.email not CONTAINS ('YAHOO.CMO')        AND t1.email not CONTAINS ('YAH0O.COM')
	 AND t1.email not CONTAINS ('YABOO.COM')      AND t1.email not CONTAINS ('YAHGOO.COM')
	 AND t1.email not CONTAINS ('TYAHOO.COM')         AND t1.email not CONTAINS ('YAHUOO.COM')
	 AND t1.email not CONTAINS ('YAHO0O.COM')       AND t1.email not CONTAINS ('YUAHOO.COM')
	 AND t1.email not CONTAINS ('GYAHOO.COM')         AND t1.email not CONTAINS ('YHAHOO.COM')
	AND t1.email not in (select email from POLAVARR.CORREOS_FAKE_V2)
;QUIT;

PROC SQL;
CREATE INDEX rut ON RESULT.BASE_EMAIL_APP_FINAL (RUT);
QUIT;

/*Eliminar tablas temporales*/
PROC SQL;
	DROP TABLE WORK.TMP_BASE_EMAIL_APP_UNION3;
	DROP TABLE WORK.TMP_BASE_EMAIL_APP_UNION4;
	DROP TABLE WORK.TMP_BASE_EMAIL_APP_UNION5;
	DROP TABLE WORK.TMP_BASE_EMAIL_APP_UNION6;
	DROP TABLE WORK.TMP_DATOS_APP_FECHA_RECIENTE;
	DROP TABLE WORK.TMP_DATOS_APP_FMAX_CREACION;
	DROP TABLE WORK.TMP_DATOS_APP_FMAX_ULT_CONTACTO;
	DROP TABLE WORK.TMP_DATOS_APP_HIS;
	DROP TABLE WORK.TMP_DATOS_APP_UNION_DIA;
	DROP TABLE WORK.TMP_DEPASO_APP_HIS_FMAX_CREACION;
	DROP TABLE WORK.TMP_DEPASO_APP_HIS_FMAX_UN_REG;
	DROP TABLE WORK.TMP_DEPASO_DATOS_APP_DIA_2;
	DROP TABLE WORK.TMP_DEPASO_DATOS_APP_DIA_3;
	DROP TABLE WORK.TMP_DEPASO_DATOS_APP_HIS;
;QUIT;
/*======	FIN 5.- OBTENER DATOS DESDE LA APP - PROCESO DEFINITIVO		===================*/
/*=========================================================================================*/

/*=========================================================================================*/
/*======	6.- Une Email de todos los Orígenes	actuales		===========================*/
/*======		QUE NO ESTÉN EN BOPERS O QUE TENGAN UNA FECHA MEJOR LOS AGREGA		=======*/
/*=========================================================================================*/
PROC SQL;
CREATE TABLE RESULT.R_EMAIL_UNIDOS AS					/* maxima secuencia 8 */
/*	SIMULACIONES_HB - SEQ 2 */
	SELECT
          t2.RUT, 
          t2.EMAIL length=50, 
		  t2.FECHA_ACT,
          t2.SEQUENCIA,
          t2.ORIGEN
    FROM RESULT.SIMULACIONES_HB_EMAIL t2				/* Datos hasta 22 Nov 2019 */
		LEFT JOIN RESULT.R_BOPERS_TOTALES_EMAIL tx on (t2.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t2.FECHA_ACT > tx.FECHA_ACT	/* Ya aplicados los filtros al email*/ 
union
/*	BOPERS	- SEQ ALEATORIA */
	SELECT	tx.rut, 
          	tx.EMAIL length=50, 
          	tx.FECHA_ACT,
           	tx.SEQUENCIA,
            Tx.ORIGEN
    FROM RESULT.R_BOPERS_TOTALES_EMAIL tx
union
/*	FISA - SEQ 7 */
   	SELECT 	distinct t7.rut, 
          	t7.EMAIL length=50, 
          	t7.FECHA_ACT,
            t7.sequencia,
            t7.ORIGEN
 	FROM RESULT.BASE_EMAIL_FISA t7 
		LEFT JOIN RESULT.R_BOPERS_TOTALES_EMAIL tx on (t7.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t7.FECHA_ACT > tx.FECHA_ACT
union
/*	CAÑON - SEQ 8 */
   	SELECT 	distinct t8.rut, 
          	t8.EMAIL length=50, 
          	t8.FECHA_ACT,
            t8.sequencia,
            t8.ORIGEN
 	FROM RESULT.BASE_EMAIL_CANON t8
		LEFT JOIN RESULT.R_BOPERS_TOTALES_EMAIL tx on (t8.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t8.FECHA_ACT > tx.FECHA_ACT
union
/*	TEF 	- SEQ 5 */
	SELECT	DISTINCT t5.RUT,
          	t5.EMAIL length=50, 
          	t5.FECHA_ACT,
          	5 AS sequencia,
          	'TEF' AS ORIGEN
    FROM RESULT.BASE_EMAIL_TEFs t5 
		LEFT JOIN RESULT.R_BOPERS_TOTALES_EMAIL tx on (t5.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t5.FECHA_ACT > tx.FECHA_ACT
union
/*	CNAVARRO 	- SEQ 6 */
  	select	distinct t6.RUT,
          	t6.EMAIL length=50,
		  	t6.FECHA_ACT,
		  	t6.sequencia,
		  	t6.ORIGEN
	FROM RESULT.R_EMAILS_CNAVARRO_DGC t6 
		LEFT JOIN RESULT.R_BOPERS_TOTALES_EMAIL tx on (t6.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t6.FECHA_ACT > tx.FECHA_ACT
union
/*	RETAIL_COM 	- SEQ 1*/
   	SELECT	distinct t1.RUT, 
          	t1.EMAIL length=50, 
          	t1.FECHA_ACT,
		  	t1.sequencia,
		  	t1.ORIGEN
  	FROM PUBLICIN.BASE_EMAIL_COM_&VdateMES t1 
		LEFT JOIN RESULT.R_BOPERS_TOTALES_EMAIL tx on (t1.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t1.FECHA_ACT > tx.FECHA_ACT
union 
/* CORRIMIENTO DE CUOTAS SEQ 12*/
SELECT distinct t12.RUT,
				t12.EMAIL length=50,
				t12.FECHA_ACT,
				t12.sequencia,
				t12.ORIGEN
	FROM POLAVARR.BASE_CORRIMIENTO_FINAL t12
		LEFT JOIN RESULT.R_BOPERS_TOTALES_EMAIL tx on (t12.RUT=tx.rut)
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t12.FECHA_ACT > tx.FECHA_ACT

union
/*	APP 	- SEQ 3 NEW Y HIS SEQ 4 */
   	SELECT	distinct t3.RUT, 
          	t3.EMAIL length=50, 
          	t3.FECHA_ACT,
		  	t3.sequencia,
		  	t3.ORIGEN
  	FROM RESULT.BASE_EMAIL_APP_FINAL t3 
		LEFT JOIN RESULT.R_BOPERS_TOTALES_EMAIL tx on (t3.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t3.FECHA_ACT > tx.FECHA_ACT
union 
/*	SIMULACIONES NEW HB 	- SEQ 9 */
   	SELECT	distinct t9.RUT, 
          	t9.EMAIL length=50, 
          	t9.FECHA_ACT,
		  	t9.sequencia,
		  	t9.ORIGEN
  	FROM POLAVARR.SIMULACIONES_HB_NEW_E t9 				/* Ya aplicados los filtros al email */
		LEFT JOIN RESULT.R_BOPERS_TOTALES2 tx on (t9.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t9.FECHA_ACT > tx.FECHA_ACT
/*union 
	QUIERO SER CLIENTE HB 	- SEQ 10 
   	SELECT	distinct t10.RUT, 
          	t10.EMAIL length=50, 
          	t10.FECHA_ACT,
		  	t10.sequencia,
		  	t10.ORIGEN
  	FROM PUBLICIN.QUIERO_SER_CLIENTE_HB_E t10 
		LEFT JOIN RESULT.R_BOPERS_TOTALES_EMAIL tx on (t10.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t10.FECHA_ACT > tx.FECHA_ACT */
union 
/*	CHEK 	- SEQ 11 */
   	SELECT	distinct t11.RUT, 
          	t11.EMAIL length=50, 
          	t11.FECHA_ACT,
		  	t11.sequencia,
		  	t11.ORIGEN
  	FROM PUBLICIN.CHEK_E t11 
		LEFT JOIN RESULT.R_BOPERS_TOTALES_EMAIL tx on (t11.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t11.FECHA_ACT > tx.FECHA_ACT

/*union 
	QSC HB NEW	- SEQ 13 
   	SELECT	distinct t11.RUT, 
          	t13.EMAIL length=50, 
          	t13.FECHA_ACT,
		  	t13.sequencia,
		  	t13.ORIGEN
  	FROM PUBLICIN.QSC_GHB_E_NEW t13 
		LEFT JOIN RESULT.R_BOPERS_TOTALES_EMAIL tx on (t13.RUT=tx.rut) 
			where tx.RUT is null OR tx.ESTADO_ACT_VER = 1 AND t13.FECHA_ACT > tx.FECHA_ACT */

;
QUIT;
/*======	FIN 6.- Une Email de todos los Orígenes	actuales	=======================*/
/*=====================================================================================*/

PROC SQL;
CREATE INDEX RUT ON RESULT.R_EMAIL_UNIDOS  (RUT);
QUIT;

/*=========================================================================================*/
/*======	7.- Cruce con Emails incorrectos y dominios incorrectos		===================*/
/*=========================================================================================*/
PROC SQL;
CREATE TABLE RESULT.R_BASE_TRABAJO_EMAIL AS
	SELECT	t1.rut,
			t1.email,
			t1.FECHA_ACT,
			t1.SEQUENCIA,
			t1.ORIGEN
		FROM RESULT.R_EMAIL_UNIDOS T1 
			LEFT JOIN result.EMAIL_INCORRECTOS_ACUMULADOS T2 ON (T1.EMAIL = T2.EMAIL)
		WHERE PRXMATCH( '/^[A-Z0-9_\.\+-]+(\.[A-Z0-9_\+-]+)*@[A-Z0-9-]{2,}(\.[A-Z0-9-]+)*\.([A-Z]{2,8})/',COMPRESS(UPCASE(t1.email)))
				AND (SUBSTR(t1.EMAIL,(INDEX(t1.EMAIL,'@'))+1)) 
					NOT IN (SELECT DOMINIOS FROM RESULT.DOMINIOS_INCORRECTOS)
				AND T2.email IS missing
;quit;

PROC SQL;
CREATE INDEX rut ON RESULT.R_BASE_TRABAJO_EMAIL (RUT);
QUIT;

PROC SQL;
   CREATE TABLE RESULT.R_BASE_TRABAJO_ORIGEN AS 
	   SELECT 	DISTINCT t1.rut, 
          		t1.EMAIL, 
          		t1.FECHA_ACT,
				t1.SEQUENCIA,
/*				ESTO ES LO DESCRITO EN R_UNIDOS - AL SUMAR APP VERIFICANDO EMAIL. REVISAR */
				CASE 	WHEN t1.ORIGEN = 'BOPERS_HB'	then 2
						WHEN t1.ORIGEN = 'APP' 			then 2 
						WHEN t1.ORIGEN = 'BOPERS_CCSS' 	then 1
					ELSE 0 END as ORIGEN,
				t1.ORIGEN as ORI_CANAL
		FROM RESULT.R_BASE_TRABAJO_EMAIL t1
;
QUIT;

PROC SQL;
CREATE INDEX rut ON RESULT.R_BASE_TRABAJO_ORIGEN (RUT);
QUIT;

*  ==========================================================================
*  Nombre del proceso almacenado: EMAIL_AUTOMATICO_3.0 - PARTE 1 - TERMINADA
*  ==========================================================================




/*NUEVO PROGRAMA EMAIL ENERO 2020*/

*  ====================================================================
*  Nombre del proceso almacenado: EMAIL_AUTOMATICO_3.0 - PARTE 2
*  ====================================================================
*;

/*=========================================================================================*/
/*======		BÚSQUEDA A ÚNICA DIARIAMENTE --- 45 MINUTOS APROX		===================*/
/*=========================================================================================*/

/*=========================================================================================*/
/*======	00.- CONECCIÓN Y VARIABLES FECHA		=======================================*/
/*=========================================================================================*/

DATA _null_;
datex0 = put(intnx('month',today(),0,'same'),yymmn6. );
datex1 = put(intnx('month',today(),-1,'same'),yymmn6. );
datex2 = put(intnx('month',today(),-2,'same'),yymmn6. );
Call symput("fechax0", datex0);
Call symput("fechax1", datex1);
Call symput("fechax2", datex2);

date0 = put(intnx('month',today(),0,'begin'),date9.) ;
Call symput("fecha0", date0);

RUN;

/*===========		01.- Correo Abiertos DEL ULTIMO PERIODO		=========================*/
proc sql ;
CREATE TABLE RESULT.SP_OPEN_&fechax0 as 
	SELECT	t1.customer_id AS RUT, 
			COMPRESS(UPCASE(t1.email)) AS EMAIL length=50
	FROM LIBCOMUN.output_email_&fechax0 t1 
	where EVENT_TIMESTAMP >= "&fecha0:00:00:00"dt and event_type='Open'

;quit;

/*===========		02.- Correo Abiertos - Cantidad por RUT	DEL ULTIMO PERIODO	=========*/
PROC SQL;
CREATE TABLE RESULT.SP_OPEN_APER_&fechax0 AS 
   SELECT t1.RUT, 
          t1.EMAIL length=50, 
          (COUNT(t1.EMAIL)) AS aperturas
FROM RESULT.SP_OPEN_&fechax0 t1 
   
	  WHERE t1.RUT IS NOT MISSING AND t1.RUT > 10000 AND t1.RUT < 99999999
      GROUP BY t1.RUT,
               t1.EMAIL;
QUIT;

PROC SQL;
CREATE INDEX EMAIL ON RESULT.SP_OPEN_APER_&fechax0   (EMAIL);
QUIT;

/*===========		03.- Correo Enviados DEL ULTIMO PERIODO			=====================*/
proc sql ;
 CREATE TABLE RESULT.SP_SENT_&fechax0 as 
	SELECT	t1.customer_id AS RUT,  
			COMPRESS(UPCASE(t1.email)) AS EMAIL length=50
	FROM LIBCOMUN.output_email_&fechax0 t1 
	where  /*EVENT_TIMESTAMP >= "&fecha0:00:00:00"dt AND */ event_type= 'Sent'
;quit;


/*===========		04.- Correo Enviados - Cantidad	DEL ULTIMO PERIODO	=================*/
PROC SQL;
CREATE TABLE RESULT.SP_SENT_ENVIADO_&fechax0 AS 
   SELECT t1.RUT, 
          t1.EMAIL length=50, 
          (COUNT(t1.EMAIL)) AS envios
	FROM RESULT.SP_SENT_&fechax0 t1 
	  WHERE t1.RUT IS NOT MISSING AND t1.RUT > 10000 AND t1.RUT < 99999999
      GROUP BY t1.RUT,
               t1.EMAIL;
QUIT;

PROC SQL;
 CREATE INDEX EMAIL ON RESULT.SP_SENT_ENVIADO_&fechax0  (EMAIL); 
QUIT;

/*===========		05.- Correo SUPRIMIDOS - DEL ULTIMO PERIODO		===========================*/
proc sql;
	CREATE TABLE SP_SUPPRESSED_A as		
		SELECT	CUSTOMER_ID AS RUT,
				compress(upcase(email)) as EMAIL length=50, 
				input(PUT(DATEPART(EVENT_TIMESTAMP),date9.),$9.) as FECHA,
				1 AS SUPPRESSED
		FROM LIBCOMUN.output_email_&fechax0
			WHERE suppression_reason in ('Global Suppression List', 'Invalid Organization Email Domain',
			'Invalid System Email Domain', 'Organization Suppression List', 'Mailing Level Suppression')
			/*	and EVENT_TIMESTAMP >= "&fecha0:00:00:00"dt > '08JAN2020:16:00:00.000000'dt*/
;quit;

/*===========		05.- Correo SUPRIMIDOS - FORMATO FECHA Y LIMPIEZA		==================*/
proc sql;
	CREATE TABLE SP_SUPPRESSED_B as			/* cambiado a formato fecha */
		SELECT	t1.RUT, 
				t1.email length=50, 
				input(t1.fecha,date9.) format=date9. as FECHA, 
				T1.SUPPRESSED
		FROM SP_SUPPRESSED_A t1
		where 
            email not CONTAINS 	('XXXXX')
			AND email not CONTAINS 	('DEFAULT')		AND email not CONTAINS 	('TEST@')
			AND email not CONTAINS 	('..')			AND email not CONTAINS 	('PRUEBA')
			AND email not CONTAINS	('(')			AND email not CONTAINS 	(')')
			AND email not CONTAINS	('/')			AND email not CONTAINS	('?')
			AND email not CONTAINS 	('¿')			AND email not CONTAINS 	('SINMAIL')
			AND email not CONTAINS 	('NOTIENE')		AND email not CONTAINS 	('NOTENGO')
			AND email not CONTAINS 	('SINCORRE')	AND email not CONTAINS 	('TEST@')
			AND email <>'@'							AND email not CONTAINS	('GFFDF')
			AND email not CONTAINS 	('0000000')		AND email not CONTAINS 	('GMAIL.CL')
			AND email not CONTAINS 	('GMAIL.ES')	AND email <>'0'
			AND email CONTAINS 	('@')				AND email not CONTAINS 	('SINEMAIL')
			AND email not CONTAINS 	('NOREGISTRA')  AND email not CONTAINS 	('SINMALLIL')
			AND email not CONTAINS 	('@MAILINATOR.COM')	AND email not CONTAINS 	('@MICORREO.COM')	
			AND email not CONTAINS 	('@HOTRMAIL.COM')	AND email not CONTAINS	('@SDFDF.CL' )
			/*agregado pia*/
	 AND email not CONTAINS ('HORTMAIL.COM')       AND email not CONTAINS ('REPLEY.COM')
	 AND email not CONTAINS ('BANCPORIPLEY.COM')       AND email not CONTAINS ('GMAL.COM')
	 AND email not CONTAINS ('RILPLEY.COM')       AND email not CONTAINS ('HOTMAI.COM')
	 AND email not CONTAINS ('GAMIL.COM')       AND email not CONTAINS ('RIPEY.CL')
	 AND email not CONTAINS ('RIPLEY.VOM')       AND email not CONTAINS ('HTOMAIL.COM')
	 AND email not CONTAINS ('GMAIL.CON')       AND email not CONTAINS ('GMIL.COM')
	 AND email not CONTAINS ('HOTAMIL.COM')       AND email not CONTAINS ('123MAIL.CL')
	 AND email not CONTAINS ('ICLOOUD.COM')       AND email not CONTAINS ('YMAIL.COM')
	 AND email not CONTAINS ('HOTMIAL.COM')       AND email not CONTAINS ('GMAI.COM')
	 AND email not CONTAINS ('HOTMAIL.OM')       AND email not CONTAINS ('GMAIIL.COM')
	 AND email not CONTAINS ('RIOLPLEY.COM')       AND email not CONTAINS ('aol.com')
	 AND email not CONTAINS ('GMSAIL.COM')       AND email not CONTAINS ('ICLOU.COM')
	 AND email not CONTAINS ('GMAIL.CM')       AND email not CONTAINS ('GMIAL.COM')
	 AND email not CONTAINS ('UAHOO.COM')       AND email not CONTAINS ('HOTMAIL.OCM')
	 AND email not CONTAINS ('GMAILC.OM')       AND email not CONTAINS ('UTLOOOK.COM')
	 AND email not CONTAINS ('RIPLE.COM')       AND email not CONTAINS ('GMAILL.COM')
	 AND email not CONTAINS ('GMAOL.COM')       AND email not CONTAINS ('HORMAIL.COM')
	 AND email not CONTAINS ('HOTMAL.COM')       AND email not CONTAINS ('OTMAIL.COM')
	 AND email not CONTAINS ('2HOTMAIL.ES')       AND email not CONTAINS ('XXX.COM')
	 AND email not CONTAINS ('AUTLOOK.COM')       AND email not CONTAINS ('8GMAIL.COM')
	 AND email not CONTAINS ('GMAIL.COMN')       AND email not CONTAINS ('OITLOOK.COM')
	 AND email not CONTAINS ('OUTLOCK.COM')       AND email not CONTAINS ('GMAIL.OM')
	 AND email not CONTAINS ('GMAIL.LCOM')       AND email not CONTAINS ('OUTLLOK.CL')
	 AND email not CONTAINS ('OULOOCK.ES')       AND email not CONTAINS ('OULOOKS.ES')
	 AND email not CONTAINS ('GAMIAL.COM')       AND email not CONTAINS ('HOTMAILL.COM')
	 AND email not CONTAINS ('GMAIL.CPM')       AND email not CONTAINS ('64GMAIL.COM')
	 AND email not CONTAINS ('GMAIOL.COM')
	 /*agregado email Lore Gerrero*/
     	 AND email not CONTAINS ('yahho.com')       AND email not CONTAINS ('EMAIL.CON')
	 AND email not CONTAINS ('OUTLOKK.ES')       AND email not CONTAINS ('HORMAIL.COM')
	 AND email not CONTAINS ('GMAIL.VOM')       AND email not CONTAINS ('YAHOO.CL')
	 AND email not CONTAINS ('GMEIL.CL')       AND email not CONTAINS ('GMAKL.COM')
	 AND email not CONTAINS ('GMAIL.COL')       AND email not CONTAINS ('GMAIL.COMO')
	 AND email not CONTAINS ('GHOTMAIL.COM')       AND email not CONTAINS ('GMAIL.COMF')
	 AND email not CONTAINS ('LIVE.CK')       AND email not CONTAINS ('GMEIL.CMMAIL.COM')
	 AND email not CONTAINS ('GMMAIL.COM')       AND email not CONTAINS ('HOTMKAIL.COM')
	 AND email not CONTAINS ('GMAIL.COMHOTMAIL.COM')       AND email not CONTAINS ('HOTRMAIL.COM')
	 AND email not CONTAINS ('HOIMAIL.COM')       AND email not CONTAINS ('XN--GMAI-JQA.COM')
	 AND email not CONTAINS ('HMAIL.COM')       AND email not CONTAINS ('OUTLOOK.CM')
	 AND email not CONTAINS ('HATMAIL.CON')       AND email not CONTAINS ('GMAIL.COMON')
	 AND email not CONTAINS ('GMIL.CO')       AND email not CONTAINS ('GMALL.COM')
	 AND email not CONTAINS ('HOTMAIAL.COM')       AND email not CONTAINS ('GMAIK.COM')
	 AND email not CONTAINS ('OUTLOOCK.COM')       AND email not CONTAINS ('GMAQIL.COM')
	 AND email not CONTAINS ('GMAILC.OM')       AND email not CONTAINS ('GMAIA.COM')
	 AND email not CONTAINS ('HOTMAIL.COL')       AND email not CONTAINS ('GMNAIL.COM')
	 AND email not CONTAINS ('OUTLLOOK.ES')       AND email not CONTAINS ('GMEIL.CON')
	 	 /*agregados de la base de simulacion hb new*/
     /*  AND t1.email not CONTAINS ('GMAIL.CO') */	          AND email not CONTAINS ('GMAIL.COMU')
	 AND email not CONTAINS ('GMAIL.CON')           AND email not CONTAINS ('123MAIL.CL')
	 AND email not CONTAINS ('GMAIL.COMOESTAS')    AND email not CONTAINS ('GMAIL.COMO')
	 AND email not CONTAINS ('GIMAIL.COM')        AND email not CONTAINS ('GMAL.COM')
	 AND email not CONTAINS ('GMAIL.COMM')        AND email not CONTAINS ('GMAIL.XOM')
	 AND email not CONTAINS ('GMAIL.CM')         AND email not CONTAINS ('GIMEIL.COM')
	 AND email not CONTAINS ('HOTMIAL.COM')       AND email not CONTAINS ('HOOTMAIL.ES')
	 AND email not CONTAINS ('HOTMAIL.CON')       AND email not CONTAINS ('GIMAIL.CON')
	 AND email not CONTAINS ('HOTMEIL.COM')       AND email not CONTAINS ('GMAIL.VOM')
	 AND email not CONTAINS ('HOTMEIL.ES')        AND email not CONTAINS ('GMAIL.CL.COM')
	 AND email not CONTAINS ('GIMAL.COM')         AND email not CONTAINS ('GMAIL.COMIL.COM')
	 AND email not CONTAINS ('HOTMAIK.COM')       AND email not CONTAINS ('GMAIL.COMQ')
	 AND email not CONTAINS ('HOTMAIIL.COM')      AND email not CONTAINS ('HOTMAIL.CPM')
	AND email not CONTAINS ('GMAIL.COML')        AND email not CONTAINS ('G.MAIL.COM')
	 AND email not CONTAINS ('HOTMAOL.COM')       AND email not CONTAINS ('GMAILL.COM')
	 AND email not CONTAINS ('GIMAIL.CL')         AND email not CONTAINS ('GMAIL.COMD')
	 AND email not CONTAINS ('HOTTMAIL.COM')      AND email not CONTAINS ('HOTMAILC.OM')
	 AND email not CONTAINS ('1967GMAIL.COM')     AND email not CONTAINS ('HOTMAY.COM')
	/* AND t1.email not CONTAINS ('HOTMAIL.CO') */       AND email not CONTAINS ('GMIAL.COM')
	 AND email not CONTAINS ('2382HOTMAIL.COM')   AND email not CONTAINS ('GMALL.COM')
	 AND email not CONTAINS ('GIMALL.COM')        AND email not CONTAINS ('HOTMAIL.COMBUE')
	 AND email not CONTAINS ('GMAIL.CPM')         AND email not CONTAINS ('123GMAIL.COM')
	 AND email not CONTAINS ('GMAIL.COMP')        AND email not CONTAINS ('GMIL.CPM')
	 AND email not CONTAINS ('GMALI.COM')         AND email not CONTAINS ('JAJAJA.CL')
	 AND email not CONTAINS ('AUTLOOK.COM')       AND email not CONTAINS ('GMAIL.CLOM')
	 AND email not CONTAINS ('GMAIL.COMCOM')      AND email not CONTAINS ('GMAIL.CIM')
	 AND email not CONTAINS ('ICLOUD.CON')        AND email not CONTAINS ('OUTLOOK.COMM')
	 AND email not CONTAINS ('HOTMEIL.CL')        AND email not CONTAINS ('HOTMAIO.COM')
	 AND email not CONTAINS ('GMAIL.COPM')        AND email not CONTAINS ('GAIML.COM')
	AND email not CONTAINS ('HOTMAIL.COMO')      AND email not CONTAINS ('JAJAGMAIL.COM')
	 AND email not CONTAINS ('GMAIL.COMEMAIL')    AND email not CONTAINS ('HOTMAIL.COMR')
	 AND email not CONTAINS ('OULTOOK.CL')        AND email not CONTAINS ('BANCORYPLEY.CL')
	 AND email not CONTAINS ('GMAIM.COM')         AND email not CONTAINS ('B8477491ANCORIPLEY.COM')
	AND email not CONTAINS ('GMAIL.COMN')        AND email not CONTAINS ('GMMAIL.COM')
	 AND email not CONTAINS ('2857GMAIL.COM')     AND email not CONTAINS ('HOTMAIEL.COM')
	 AND email not CONTAINS ('GMAIL.COL')         AND email not CONTAINS ('GHOTMAIL.COM')
	/* AND email not CONTAINS ('OUTLOOK.CO')*/        AND email not CONTAINS ('GMAIIL.COM')
	 AND email not CONTAINS ('OUTLOOK.CON')       AND email not CONTAINS ('LIVE.CM')
	 AND email not CONTAINS ('HOGMAIL.ES')        AND email not CONTAINS ('GMAIL.COMQQSWS')
	 AND email not CONTAINS ('HOTMAKL.COM')       AND email not CONTAINS ('GMAIL.CO.COM')
	AND email not CONTAINS ('HOTMAUL.COM')        AND email not CONTAINS ('OUTLOOCK.COM')
	 AND email not CONTAINS ('GMANIL.COM')        AND email not CONTAINS ('OUTLOO.COM')
	 AND email not CONTAINS ('ICLUD.COM')         AND email not CONTAINS ('GMAIL.COM.CL')
	 AND email not CONTAINS ('OUTLLOK.COM')       AND email not CONTAINS ('GMAIL.COK')
	 AND email not CONTAINS ('GMAIL.COM.COM')     AND email not CONTAINS ('OULOOK.COM')
	 AND email not CONTAINS ('OUTOOK.COM')        AND email not CONTAINS ('59GMEIL.COM')
	 AND email not CONTAINS ('GMAIL.CCOM')        AND email not CONTAINS ('GMAIL.COOM')
	 AND email not CONTAINS ('434GOTMAIL.CL')     AND email not CONTAINS ('GM8AIL.COM')
	 AND email not CONTAINS ('HOGMAIL.COM')       AND email not CONTAINS ('GMAIL.COMA')
	 AND email not CONTAINS ('GMAIIL.CO')         AND email not CONTAINS ('HOTMEY.COM')
	 AND email not CONTAINS ('GMAIL.COMS')        AND email not CONTAINS ('YAHUU.COM')
	 AND email not CONTAINS ('A01GMAIL.COM')      AND email not CONTAINS ('HOTMAIL.COL')
	 AND email not CONTAINS ('GMAIO.COM')         AND email not CONTAINS ('GMAIL.GMAIL.COM')
	 AND email not CONTAINS ('GMAIL.COMOM')       AND email not CONTAINS ('HOTMAIM.COM')
	AND email not CONTAINS ('HOTMAIL.COMK')
		/* AGREGADOS POR ANALISIS DE WEBBULA */
	 AND email not CONTAINS ('GMSIL.COM')       AND email not CONTAINS ('MC.COM')
	 AND email not CONTAINS ('LIVER.COM')        AND email not CONTAINS ('HOMAIL.COM')
	 AND email not CONTAINS ('GMAUL.COM')       AND email not CONTAINS ('HTMAIL.COM')
  	 AND email not CONTAINS ('GNAIL.COM')        AND email not CONTAINS ('HOYMAIL.COM')
     AND email not CONTAINS ('LIV.COM')        AND email not CONTAINS ('HPTMAIL.COM')
	 AND email not CONTAINS ('GMAOIL.COM')         AND email not CONTAINS ('HOTMWIL.COM')
	 AND email not CONTAINS ('GMAAIL.COM')       AND email not CONTAINS ('GMASIL.COM')
	 AND email not CONTAINS ('GFMAIL.COM')     AND email not CONTAINS ('MGAIL.COM')
	 AND email not CONTAINS ('H0TMAIL.COM')        AND email not CONTAINS ('GMJAIL.COM')
	 AND email not CONTAINS ('FGMAIL.COM')        AND email not CONTAINS ('HOTMAAIL.CO')
	 AND email not CONTAINS ('HITMAIL.COM')     AND email not CONTAINS ('HOTMAIL.COMQUE')
	 AND email not CONTAINS ('HOTMASIL.COM')       AND email not CONTAINS ('HOTAIL.COM')
	 AND email not CONTAINS ('GOTMAIL.COM')         AND email not CONTAINS ('GTMAIL.COM')
	 AND email not CONTAINS ('NSN.COM')        AND email not CONTAINS ('HOTMSIL.COM')
	 AND email not CONTAINS ('FMAIL.COM')      AND email not CONTAINS ('HOTMAOIL.COM')
	 AND email not CONTAINS ('HOMTAIL.COM')         AND email not CONTAINS ('LIUVE.COM')
	 AND email not CONTAINS ('GMAILO.COM')       AND email not CONTAINS ('GGMAIL.COM')
	 AND email not CONTAINS ('JOTMAIL.COM')       AND email not CONTAINS ('GMQIL.COM')
	 AND email not CONTAINS ('GMAIKL.COM')        AND email not CONTAINS ('HOTMSAIL.COM')
	 AND email not CONTAINS ('GAIL.COM')       AND email not CONTAINS ('GMAIL.COMCIMI')
	 AND email not CONTAINS ('LICE.COM')        AND email not CONTAINS ('GMAIL.CKM')
     AND email not CONTAINS ('HHOTMAIL.COM')        AND email not CONTAINS ('HLTMAIL.COM')
	 AND email not CONTAINS ('ICLOUB.COM')         AND email not CONTAINS ('HOTMAIL.COOM')
	 AND email not CONTAINS ('HOTMAIKL.COM')       AND email not CONTAINS ('HJOTMAIL.COM')
	 AND email not CONTAINS ('HOPTMAIL.COM')     AND email not CONTAINS ('HOTMAIUL.COM')
	 AND email not CONTAINS ('HOTMMAIL.COM')        AND email not CONTAINS ('HOTMALL.COM')
	 AND email not CONTAINS ('HOTGMAIL.COM')        AND email not CONTAINS ('LIVE.COL')
	 AND email not CONTAINS ('HOTNAIL.COM')     AND email not CONTAINS ('LIBE.COM')
	 AND email not CONTAINS ('GMAUIL.COM')       AND email not CONTAINS ('H0OTMAIL.COM')
	 AND email not CONTAINS ('HOTMAQIL.COM')         AND email not CONTAINS ('GMAI9L.COM')
	 AND email not CONTAINS ('GNMAIL.COM')        AND email not CONTAINS ('HOTMAILK.COM')
	 AND email not CONTAINS ('HOYTMAIL.COM')      AND email not CONTAINS ('HOTMAIL.CM')
	 AND email not CONTAINS ('HOTMAAIL.COM')         AND email not CONTAINS ('HOTFMAIL.COM')
	 AND email not CONTAINS ('HOMAIL.CO')       AND email not CONTAINS ('HIOTMAIL.COM')
	 AND email not CONTAINS ('HOTMAKIL.COM')         AND email not CONTAINS ('GMAILK.COM')
	 AND email not CONTAINS ('HOHTMAIL.COM')       AND email not CONTAINS ('HOTYMAIL.COM')
	 AND email not CONTAINS ('HOTMAUIL.COM')     AND email not CONTAINS ('ME.CM')
	 AND email not CONTAINS ('HOTMAIL.COIM')        AND email not CONTAINS ('L8VE.COM')
	 AND email not CONTAINS ('HOTMNAIL.COM')        AND email not CONTAINS ('OHTMAIL.COM')
	 AND email not CONTAINS ('HOT6MAIL.COM')     AND email not CONTAINS ('GMQIL.VOM')
	 AND email not CONTAINS ('GMZAIL.COM')       AND email not CONTAINS ('LIVE.CCOM')
	 AND email not CONTAINS ('LIVEW.COM')         AND email not CONTAINS ('YGMAIL.COM')
	 AND email not CONTAINS ('BOTMAIL.COM')        AND email not CONTAINS ('GMAIL.CO9M')
	 AND email not CONTAINS ('GMAIL.COMG')      AND email not CONTAINS ('HOTMAIL.CIOM')
	 AND email not CONTAINS ('HPOTMAIL.COM')         AND email not CONTAINS ('MAIL.CM')
	 AND email not CONTAINS ('HOHMAIL.COM')       AND email not CONTAINS ('HOTMAIL.COPM')
	 AND email not CONTAINS ('HOT5MAIL.COM')        AND email not CONTAINS ('GMZIL.COM')
	 AND email not CONTAINS ('HOLTMAIL.COM')      AND email not CONTAINS ('LIVE.CON')
	 AND email not CONTAINS ('HUOTMAIL.COM')         AND email not CONTAINS ('MSNM.COM')
	 AND email not CONTAINS ('HO0TMAIL.COM')       AND email not CONTAINS ('HOTMAI.COK')
	 AND email not CONTAINS ('GMAZIL.COM')         AND email not CONTAINS ('LVIE.COM')
	 AND email not CONTAINS ('HOTMAIL.CCOM')       AND email not CONTAINS ('HOTMAIL.CLOM')
	 AND email not CONTAINS ('HOOTMAIL.COM')     AND email not CONTAINS ('HOTHMAIL.COM')
	 AND email not CONTAINS ('HOTMIL.CON')        AND email not CONTAINS ('MZN.COM')
	 AND email not CONTAINS ('HOMAIL.CM')        AND email not CONTAINS ('ICLOUD.OM')
	 AND email not CONTAINS ('HGOTMAIL.COM')     AND email not CONTAINS ('GMIL.CON')
	 AND email not CONTAINS ('LIVE.VOM')       AND email not CONTAINS ('GAIL.CO')
	 AND email not CONTAINS ('GMA9IL.COM')         AND email not CONTAINS ('HTMAIL.CPM')
	 AND email not CONTAINS ('GMAI.LCOM')        AND email not CONTAINS ('GMIL.CM')
	 AND email not CONTAINS ('MSN.CM')      AND email not CONTAINS ('BHOTMAIL.COM')
	 AND email not CONTAINS ('GMAIUL.COM')         AND email not CONTAINS ('HO9TMAIL.COM')
	 AND email not CONTAINS ('HOTMJAIL.COM')       AND email not CONTAINS ('GMA8L.COM')
     AND email not CONTAINS ('GAMIL.CON')      AND email not CONTAINS ('GKMAIL.COM')
	 AND email not CONTAINS ('GMAIL.BOM')         AND email not CONTAINS ('LIE.COM')
	 AND email not CONTAINS ('HOTMIL.CO')       AND email not CONTAINS ('GMAIL.CIOM')
	 AND email not CONTAINS ('LUVE.COM')         AND email not CONTAINS ('NOTMAIL.COM')
	 AND email not CONTAINS ('HOTMQAIL.COM')       AND email not CONTAINS ('HOTMIL.CM')
	 AND email not CONTAINS ('GMAIL.VCOM')     AND email not CONTAINS ('HOTMAIL.CAM')
	 AND email not CONTAINS ('HOTNAIL.CO')        AND email not CONTAINS ('HOTJMAIL.COM')
	 AND email not CONTAINS ('GMIIL.COM')        AND email not CONTAINS ('H9OTMAIL.COM')
	 AND email not CONTAINS ('GYMAIL.COM')     AND email not CONTAINS ('HNOTMAIL.COM')
	 AND email not CONTAINS ('HOTNMAIL.COM')       AND email not CONTAINS ('GMA8IL.COM')
	 AND email not CONTAINS ('GHMAIL.COM')         AND email not CONTAINS ('GJMAIL.COM')
	 AND email not CONTAINS ('GMAWIL.COM')        AND email not CONTAINS ('HOTMMAIL.CO')
	 AND email not CONTAINS ('GMWIL.COM')      AND email not CONTAINS ('LIVD.COM')
	 AND email not CONTAINS ('HYOTMAIL.COM')         AND email not CONTAINS ('HOMAIL.OM')
	 AND email not CONTAINS ('LIVE.CM')       AND email not CONTAINS ('HOMAIL.CON')
	 AND email not CONTAINS ('HLOTMAIL.COM')         AND email not CONTAINS ('HGMAIL.CO')
	 AND email not CONTAINS ('HOTAIL.CO')       AND email not CONTAINS ('GMAKIL.COM')
	 AND email not CONTAINS ('LILVE.COM')         AND email not CONTAINS ('HOOTMAIL.CO')
	 AND email not CONTAINS ('HBOTMAIL.COM')       AND email not CONTAINS ('GMQAIL.COM')
	 AND email not CONTAINS ('LIVE.CIM')     AND email not CONTAINS ('HORMAIL.CON')
	 AND email not CONTAINS ('HOTMAI9L.COM')        AND email not CONTAINS ('GMKAIL.COM')
	 AND email not CONTAINS ('MSMN.COM')        AND email not CONTAINS ('GKAIL.COM')
	 AND email not CONTAINS ('YHAOO.COM')     AND email not CONTAINS ('YAHHO.COM')
	 AND email not CONTAINS ('YAHO.COM')       AND email not CONTAINS ('YAHOIO.COM')
	 AND email not CONTAINS ('YAOO.COM')         AND email not CONTAINS ('YAHOOO.COM')
	 AND email not CONTAINS ('YAHOO.CO')        AND email not CONTAINS ('HOTMAIL.DOM')
	 AND email not CONTAINS ('GMAILL.CM')      AND email not CONTAINS ('HOTMAIL.COM.YAHOO.ES')
	 AND email not CONTAINS ('YQHOO.COM')         AND email not CONTAINS ('HOTMAI.CM')
	 AND email not CONTAINS ('TAHOO.COM')       AND email not CONTAINS ('HOTMA8L.COM')
	 AND email not CONTAINS ('JMAIL.COM')        AND email not CONTAINS ('GIMAIL.CM')
	 AND email not CONTAINS ('GEMAIL.CO')      AND email not CONTAINS ('GIMAIL.CO')
	 AND email not CONTAINS ('YOPMAIL.CO')         AND email not CONTAINS ('HOTMAIL.17.COM')
	 AND email not CONTAINS ('CORREO.OM')       AND email not CONTAINS ('HORMAIL.CO')
	 AND email not CONTAINS ('UTLOOK.COM')         AND email not CONTAINS ('YHOO.COM')
	 AND email not CONTAINS ('YAJOO.COM')       AND email not CONTAINS ('HOTMIAL.CO')
	 AND email not CONTAINS ('YAYOO.COM')         AND email not CONTAINS ('HOTMALIL.COM')
	 AND email not CONTAINS ('YMSIL.COM')       AND email not CONTAINS ('HOTMIAL.CM')
	 AND email not CONTAINS ('YASHOO.COM')     AND email not CONTAINS ('HOTMAILL.CO')
	 AND email not CONTAINS ('YAHOOL.COM')        AND email not CONTAINS ('HOTMAIOL.COM')
	 AND email not CONTAINS ('HOTMMAIL.OM')        AND email not CONTAINS ('YAQHOO.COM')
	 AND email not CONTAINS ('YSHOO.COM')     AND email not CONTAINS ('GMIAL.CON')
	 AND email not CONTAINS ('LIVR.COM')       AND email not CONTAINS ('HOTMAWIL.COM')
	 AND email not CONTAINS ('GMMAIL.CO')         AND email not CONTAINS ('HTMAIL.CM')
	 AND email not CONTAINS ('NAIL.COM')        AND email not CONTAINS ('MAIOL.COM')
	 AND email not CONTAINS ('GM.CON')      AND email not CONTAINS ('GM.CO')
	 AND email not CONTAINS ('HO5TMAIL.COM')         AND email not CONTAINS ('GMAIL.FOM')
	 AND email not CONTAINS ('MAI.CM')       AND email not CONTAINS ('EMAIL.CO')
	 AND email not CONTAINS ('GOTMAIL.CO')        AND email not CONTAINS ('LIVS.COM')
	 AND email not CONTAINS ('LICVE.COM')      AND email not CONTAINS ('MAIL.CON')
	 AND email not CONTAINS ('JMAIL.CO')         AND email not CONTAINS ('MAIIL.COM')
	 AND email not CONTAINS ('GIMEI.CO')       AND email not CONTAINS ('HOTMAILC.OM')
	 AND email not CONTAINS ('GMAILC.OM')         AND email not CONTAINS ('GIMIL.CON')
	 AND email not CONTAINS ('HOTAMAIL.CO')       AND email not CONTAINS ('YMAIL.CM')
	 AND email not CONTAINS ('YMAIL.CO')         AND email not CONTAINS ('OUTLOOOK.COM')
	 AND email not CONTAINS ('GAMIAL.CO')       AND email not CONTAINS ('OITLOOK.COM')
	 AND email not CONTAINS ('ICLUD.CON')     AND email not CONTAINS ('OUTLOOK.CON')
	 AND email not CONTAINS ('AUTLOOK.CO')        AND email not CONTAINS ('GIMEI.CON')
	 AND email not CONTAINS ('OUTLOKK.COM')        AND email not CONTAINS ('GMLI.CON')
	 AND email not CONTAINS ('GMEIL.CO')     AND email not CONTAINS ('GOMAIL.CO')
	 AND email not CONTAINS ('MGMAIL.CO')       AND email not CONTAINS ('GMEIL.CPM')
	 AND email not CONTAINS ('HOTMEIL.COM')         AND email not CONTAINS ('GITMAIL.COM')
	 AND email not CONTAINS ('UMAIL.COM')        AND email not CONTAINS ('HJFJH.CM')
	 AND email not CONTAINS ('GEMEIL.CO')      AND email not CONTAINS ('HIMAIL.CO')
	 AND email not CONTAINS ('GAMAIL.CO')         AND email not CONTAINS ('GIMEIL.CO')
	 AND email not CONTAINS ('GIMIL.COMO')       AND email not CONTAINS ('GIMAL.CON')
	 AND email not CONTAINS ('HOTM.COMAIL')         AND email not CONTAINS ('YNAIL.COM')
	 AND email not CONTAINS ('GIMEIL.CIM')       AND email not CONTAINS ('HOLMAIL.CM')
	 AND email not CONTAINS ('YMIAL.COM')        AND email not CONTAINS ('GMEIL.COMO')
	 AND email not CONTAINS ('HOIMAIL.COM')      AND email not CONTAINS ('HOITMAIL.CL')
	 AND email not CONTAINS ('WWW.HOTMAIL.COM')         AND email not CONTAINS ('THOMAIL.CL')
	 AND email not CONTAINS ('YQAHOO.COM')       AND email not CONTAINS ('HAHOO.COM')
	 AND email not CONTAINS ('YAHOL.COM')         AND email not CONTAINS ('YAGOO.COM')
	 AND email not CONTAINS ('UAHOO.COM')       AND email not CONTAINS ('YAHOO.CM')
	 AND email not CONTAINS ('YAHHOO.COM')         AND email not CONTAINS ('YAAHOO.COM')
	 AND email not CONTAINS ('YSAHOO.COM')       AND email not CONTAINS ('YAHOO.CON.CO')
	 AND email not CONTAINS ('YAHO0.COM')     AND email not CONTAINS ('YAHOOP.COM')
	 AND email not CONTAINS ('YYAHOO.COM')        AND email not CONTAINS ('YABHOO.COM')
	 AND email not CONTAINS ('YAHPOO.COM')        AND email not CONTAINS ('YAHJOO.COM')
	 AND email not CONTAINS ('HYAHOO.COM')     AND email not CONTAINS ('YTAHOO.COM')
	 AND email not CONTAINS ('YAHIO.COM')       AND email not CONTAINS ('UYAHOO.COM')
	 AND email not CONTAINS ('YAHOO0.COM')         AND email not CONTAINS ('YAHOO.COM')
	 AND email not CONTAINS ('YAHOO.CMO')        AND email not CONTAINS ('YAH0O.COM')
	 AND email not CONTAINS ('YABOO.COM')      AND email not CONTAINS ('YAHGOO.COM')
	 AND email not CONTAINS ('TYAHOO.COM')         AND email not CONTAINS ('YAHUOO.COM')
	 AND email not CONTAINS ('YAHO0O.COM')       AND email not CONTAINS ('YUAHOO.COM')
	 AND email not CONTAINS ('GYAHOO.COM')         AND email not CONTAINS ('YHAHOO.COM')
			AND email not in (select email from POLAVARR.CORREOS_FAKE_V2)
;quit;

/*===========		05.- Correo SUPRIMIDOS - FORMATO NUMÉRICO Y RUT UNICO		============*/
/*===========		TODOS LOS SUPRIMIDOS SOLICITADOS POR EL RUT					============*/
proc sql;
	CREATE TABLE RESULT.SP_SUPPRESSED_&fechax0 as 			/* cambiado fecha a numérica */
		SELECT	T1.RUT, 
				T1.email length=50, 
				input(put(FECHA,yymmddn8.),best.) as FECHA_NUM, 
				T1.SUPPRESSED
		FROM SP_SUPPRESSED_B t1
;quit;

/*===========		05.- Correo SUPRIMIDOS - MAXIMO FECHA RUT E EMAIL			============*/
/*===========		YA QUE UN RUT PODRÍA SUPRIMIR MÁS DE UN EMAIL				============*/
PROC SQL;
   CREATE TABLE SP_SUPPRESSED_MAX AS 
	   SELECT	T1.RUT,
				T1.email length=50,
				MAX(T1.FECHA_NUM) AS FECHA, 
				T1.SUPPRESSED
		FROM RESULT.SP_SUPPRESSED_&fechax0 t1 
	  group by  t1.rut, t1.email
;
QUIT;

/*===========		06.- Correo SUPRIMIDOS - FINAL DEL PERIODO				============*/
/*===========	VALIDADO. EXISTEN POCOS REGISTROS DE UN RUT CON MAS DE UN EMAIL SUPRIMIDO	===*/
PROC SQL;
  CREATE TABLE RESULT.SP_SUPPRESSED_UNICO_&fechax0 AS  
	   SELECT 	T1.RUT, 
				T1.email length=50, 
				T1.FECHA_NUM, 
				T1.SUPPRESSED
	  FROM RESULT.SP_SUPPRESSED_&fechax0 t1 
	  	INNER JOIN SP_SUPPRESSED_MAX T2 
			ON (T1.RUT = T2.RUT AND T1.FECHA_NUM = T2.FECHA and t1.email = t2.email)
;QUIT;


/*UNION DE LA TODA LA HISTORIA DE SUPRIMIDOS MÁS EL ÚLTIMO PERIODO*/
PROC SQL;
CREATE TABLE SP_SUPPRESSED_UNION_HIS_NEW AS
	SELECT 	T1.RUT,
			T1.email length=50, 
			T1.FECHA_NUM, 
			T1.SUPPRESSED
		FROM RESULT.SP_SUPRIMIDOS_FINAL_HIS T1
UNION ALL
	SELECT 	T2.RUT,
			T2.email length=50, 
			T2.FECHA_NUM, 
			T2.SUPPRESSED
			FROM RESULT.SP_SUPPRESSED_UNICO_&fechax0 T2 
;QUIT;

PROC SQL;
CREATE INDEX RUT ON SP_SUPPRESSED_UNION_HIS_NEW  (RUT);
QUIT;

/*MAXIMO DE LA UNION DE HIS Y NUEVO DEL PERIODO*/
PROC SQL;
   CREATE TABLE SP_SUPPRESSED_UNION_MAX AS 
	   SELECT	T1.RUT,
	   			T1.email length=50,
				MAX(T1.FECHA_NUM) AS FECHA, 
				T1.SUPPRESSED
      FROM SP_SUPPRESSED_UNION_HIS_NEW t1
	  group by t1.RUT, t1.email
;
QUIT;

PROC SQL;
CREATE INDEX RUT ON SP_SUPPRESSED_UNION_MAX  (RUT);
QUIT;

/* SUPRIMIDOS FINAL Y TOTAL A TOMAR EN CUENTA - HASTA ESTE PERIODO */
PROC SQL;
  CREATE TABLE RESULT.SP_SUPPRESSED_&fechax0 AS 
	   SELECT 	T1.RUT,
	   			T1.EMAIL length=50,
				T1.FECHA_NUM, 
				T1.SUPPRESSED
      FROM SP_SUPPRESSED_UNION_HIS_NEW t1
	  	INNER JOIN SP_SUPPRESSED_UNION_MAX T2 
			ON (T1.RUT = T2.RUT AND T1.FECHA_NUM = T2.FECHA and t1.email = t2.email)
;QUIT;

PROC SQL;
CREATE INDEX EMAIL ON RESULT.SP_SUPPRESSED_&fechax0  (EMAIL); 
QUIT;


/*===========		08.- Correo REBOTADOS - DURO - FORMATO FECHA	============*/
PROC SQL;
   CREATE TABLE SP_REBOTE_DURO AS 					
   SELECT CUSTOMER_ID AS RUT,
          compress(upcase(email)) as EMAIL length=50, 
		  case when t1.EVENT_TYPE = 'Hard Bounce' then 1 else 0 end as rebote_duro
      FROM LIBCOMUN.output_email_&fechax0 t1
	  GROUP BY t1.EMAIL
	order by 1
    ;
QUIT;

/* proc sort data=SP_REBOTE_DURO out=RESULT.SP_REBOTE_DURO nodupkeys dupout=WORK.duplicados_RUT_rebote;
by EMAIL;
run; */ 


proc sort data=SP_REBOTE_DURO out=RESULT.SP_REBOTE_DURO nodupkeys dupout=WORK.duplicados_RUT_rebote;
by EMAIL;
run;

PROC SQL;
CREATE INDEX EMAIL ON RESULT.SP_REBOTE_DURO  (EMAIL);
QUIT; 

PROC SQL;
CREATE INDEX EMAIL ON SP_REBOTE_DURO  (EMAIL);
QUIT;

/*	VALIDADO OK	*/
/*===========		09.- Correo con aperturas últimos 3 meses	============*/
DATA _null_;
datex0 = put(intnx('month',today(),0,'same'),yymmn6. );
datex1 = put(intnx('month',today(),-1,'same'),yymmn6. );
datex2 = put(intnx('month',today(),-2,'same'),yymmn6. );
Call symput("fechax0", datex0);
Call symput("fechax1", datex1);
Call symput("fechax2", datex2);
RUN;

proc sql;
create table SP_OPEN_APER_X3 as
	select  * from RESULT.SP_OPEN_APER_&fechax0
		outer union corr
	select  * from RESULT.SP_OPEN_APER_&fechax1
		outer union corr
	select  * from RESULT.SP_OPEN_APER_&fechax2		
;quit; 


PROC SQL;
CREATE INDEX RUT ON SP_OPEN_APER_X3  (RUT);
QUIT;

/*APERTURAS DE LOS ÚLTIMOS 3 PERIODOS*/
PROC SQL;
  CREATE TABLE RESULT.SP_OPEN_APER_X3 AS 
   SELECT 	distinct compress(upcase(t1.EMAIL)) as EMAIL length=50,
			t1.RUT,
          	(COUNT(t1.EMAIL)) AS APERTURAS_3M
      FROM SP_OPEN_APER_X3 t1
	  WHERE t1.RUT IS NOT MISSING AND t1.RUT > 10000 AND t1.RUT < 99999999
      GROUP BY t1.EMAIL, T1.RUT
;QUIT;

 PROC SQL;
CREATE INDEX EMAIL ON RESULT.SP_OPEN_APER_X3  (EMAIL);
QUIT; 


proc sql;
create table SP_SENT_ENVIADO_X3 as
	select  * from RESULT.SP_SENT_ENVIADO_&fechax0
		outer union corr
	select  * from RESULT.SP_SENT_ENVIADO_&fechax1
		outer union corr
	select  * from RESULT.SP_SENT_ENVIADO_&fechax2
;quit; 

PROC SQL;
CREATE INDEX RUT ON SP_SENT_ENVIADO_X3  (RUT);
QUIT;

/*ENVIADOS LOS ÚLTIMOS 3 PERIODOS*/
PROC SQL;
 CREATE TABLE RESULT.SP_SENT_ENVIADO_X3 AS 
   SELECT 	compress(upcase(t1.EMAIL)) as EMAIL length=50,
			t1.RUT, 
          	(COUNT(t1.EMAIL)) AS ENVIOS_3M
      FROM SP_SENT_ENVIADO_X3 t1
	  WHERE t1.RUT IS NOT MISSING AND t1.RUT > 10000 AND t1.RUT < 99999999
      GROUP BY t1.EMAIL, T1.RUT
;QUIT;

PROC SQL;
CREATE INDEX EMAIL ON RESULT.SP_SENT_ENVIADO_X3  (EMAIL);
QUIT; 

*  ==========================================================================
*  Nombre del proceso almacenado: EMAIL_AUTOMATICO_3.0 - PARTE 2 - TERMINADA
*  ==========================================================================

/*NUEVO PROGRAMA EMAIL ENERO 2020*/

*  ====================================================================
*  Nombre del proceso almacenado: EMAIL_AUTOMATICO_3.0 - PARTE 3
*  ====================================================================
*;
/*=========================================================================================*/
/*======	00.- VARIABLES FECHA					=======================================*/
/*=========================================================================================*/
DATA _null_;
datex0 = put(intnx('month',today(),0,'same'),yymmn6. );
Call symput("fechax0", datex0);
RUN;

/*=========================================================================================*/
/*======	01.- CALCULO NOTA: NIVEL REBOTE - SUPPRISSED					===============*/
/*======					5 horas											===============*/
/*=========================================================================================*/
proc sql;
CREATE TABLE NOTA_RANK_INI_1 AS 
	select
		DISTINCT t1.RUT,
        t1.EMAIL length=50,
		t1.FECHA_ACT,
        case when t2.rebote_duro = 1 		then -15	else 0 end AS  	MRC_HardBounce,
        case when t2.rebote_duro = 0 		then 0		else 0 end AS  	MRC_SoftBounce,
		CASE 	WHEN T1.ORIGEN = 2 			then 2  	/*	si esta en bopers y es HB o APP	*/
				WHEN T1.ORIGEN = 1 			then 1 		/*	si esta en bopers y es CCSS	*/
				ELSE 0 END as 	MRC_BOPERS,
		CASE 	WHEN T6.ESTADO_ACT_VER = 2 	then 2  	/* cuando llegue otro verificado debe quedar en este estado */
				WHEN T6.ESTADO_ACT_VER = 1 	then 1 		
				ELSE 0 END as 	MRC_BOPERS_ACL_VER,
		CASE 	WHEN T6.ESTADO_ACT_VER = 2 	then 2 
				WHEN T6.ESTADO_ACT_VER = 1 	then 1 		
				WHEN T6.ESTADO_ACT_VER = 4 	then 4 		/* Para que quede el 0 en la tabla */		
				ELSE 0 END as 	ESTADO_ACT_VER,
		T1.ORIGEN,
		t1.ORI_CANAL
			FROM RESULT.R_BASE_TRABAJO_ORIGEN	t1
			LEFT JOIN RESULT.SP_REBOTE_DURO 	t2 
					ON (t1.EMAIL = t2.EMAIL)
				LEFT JOIN RESULT.R_BOPERS_TOTALES_EMAIL		t6
					ON (T1.RUT = T6.RUT AND T1.EMAIL = T6.EMAIL)
;QUIT;

PROC SQL;
CREATE INDEX RUT ON NOTA_RANK_INI_1  (RUT);
QUIT;


proc sql;
CREATE TABLE NOTA_RANK_INI_2 AS 
	select
		t1.*,
        case when t3.email is not missing 	then -20  	else 0 end AS	MRC_SUPPRESSED
			FROM NOTA_RANK_INI_1	t1
				LEFT JOIN RESULT.SP_SUPPRESSED_&fechax0 	t3 
					ON (t1.EMAIL = t3.EMAIL AND T1.RUT = T3.RUT)
;QUIT;

PROC SQL;
CREATE INDEX RUT ON NOTA_RANK_INI_2  (RUT);
QUIT;

proc sql;
CREATE TABLE NOTA_RANK_INI_3 AS 
	select
		t1.*,
		case when t4.email is not missing 	then 1  	else 0 end AS	MRC_EMAIL_APER_3M,
		case when t5.email is not missing 	then 1  	else 0 end AS	MRC_EMAIL_SENT_3M,
		T4.APERTURAS_3M,
		T5.ENVIOS_3M
			FROM NOTA_RANK_INI_2	t1
					LEFT JOIN RESULT.SP_OPEN_APER_X3 			t4 
					ON (T1.EMAIL = T4.EMAIL AND T1.RUT = T4.RUT)
					LEFT JOIN RESULT.SP_SENT_ENVIADO_X3 		t5 
					ON (T1.EMAIL = T5.EMAIL)
;QUIT;

proc sql;
CREATE TABLE RESULT.NOTA_RANK_NEW_2020 AS 
	select distinct *
			FROM NOTA_RANK_INI_3
;QUIT; 

PROC SQL;
CREATE INDEX RUT ON RESULT.NOTA_RANK_NEW_2020  (RUT);
QUIT; 


DATA _null_;
dateMES	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
Call symput("VdateMES", dateMES);

RUN;
%put &VdateMES; 

/*=========================================================================================*/
/* CALCULAR CONTACTABILIDAD - NOTA  - dice nota VU pero no es VU.. */
/*=========================================================================================*/
PROC SQL;
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
	FROM RESULT.NOTA_RANK_NEW_2020 t1 WHERE t1.MRC_HardBounce = 0 and t1.MRC_SUPPRESSED <> -20
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
proc sort data=MEJORES_EMAIL_NOTA_AP out=RESULT.MEJORES_EMAIL_NOTA_AP_&VdateMES 
nodupkeys dupout=duplicados;
by RUT;
run;

/* BASE EMAIL SIN EXCLUSIONES O SIN FILTROS APLICADOS */
PROC SQL;
   CREATE TABLE PUBLICIN.BASE_TRABAJO_EMAIL_SE AS 
   SELECT 	*
      FROM	RESULT.MEJORES_EMAIL_NOTA_AP_&VdateMES
;QUIT;


/*se crea base_trabajo_email_se_info donde solo se excluyen clientes puntuales para comunicacion informativa */ 
PROC SQl;
CREATE TABLE LNEGRO_EMAIL AS 
SELECT DISTINCT  RUT
FROM publicin.lnegro_email 
WHERE motivo  in ('EMAIL_NO_CORRESPONDE') 
;quit;

proc sql;
create table PUBLICIN.base_trabajo_email_se_INFO as 
select 
t1.*
from publicin.base_trabajo_email_se t1
left join publicin.lnegro_car t2
on (t1.rut=t2.rut)
left join LNEGRO_EMAIL t3
on (t1.rut=t3.rut)
where /*(tipo_inhibicion=lista_negra_car and canal_reclamo=auris) and */
t2.tipo_inhibicion not in ('FALLECIDO','FALLECIDOS')  AND 
T3.RUT IS NULL
;quit ; 


/*EXCLUSIONES PUNTUALES SOLICITADAS*/
PROC SQL;
   CREATE TABLE BASE_TRABAJO_EMAIL_EPUNT AS 
   SELECT t1.RUT, 
          t1.EMAIL, 
          t1.MRC_BOPERS,
		  t1.APERTURAS,
          t1.NOTA,
		  t1.ORI_CANAL
      FROM RESULT.MEJORES_EMAIL_NOTA_AP_&VdateMES T1 LEFT JOIN POLAVARR.EXCLUSIONES_PUNTUALES T2
	  	ON (T1.RUT = T2.RUT AND T1.EMAIL = T2.EMAIL) where T2.RUT IS MISSING
;QUIT;

PROC SQL;
   CREATE TABLE BASE_TRABAJO_EMAIL_LNCAR AS 
   SELECT t1.RUT, 
          t1.EMAIL, 
          t1.MRC_BOPERS,
		  t1.APERTURAS,
          t1.NOTA,
		  t1.ORI_CANAL
		FROM BASE_TRABAJO_EMAIL_EPUNT 	T1 
			LEFT JOIN PUBLICIN.LNEGRO_CAR T2
				ON (T1.RUT = T2.RUT) where T2.RUT IS MISSING
;QUIT;

PROC SQL;
   CREATE TABLE BASE_TRABAJO_EMAIL_LNEMAIL_R AS 
   SELECT t1.RUT, 
          t1.EMAIL, 
          t1.MRC_BOPERS,
		  t1.APERTURAS,
          t1.NOTA,
		  t1.ORI_CANAL
		FROM BASE_TRABAJO_EMAIL_LNCAR 	T1 
			LEFT JOIN PUBLICIN.LNEGRO_EMAIL T3	
				ON (T1.RUT = T3.RUT) where T3.RUT IS MISSING
;QUIT;
 
PROC SQL;
	CREATE TABLE BASE_TRABAJO_EMAIL_WEBBULA AS 
	SELECT T1.RUT,
		   T1.EMAIL,
           T1.MRC_BOPERS,
           T1.APERTURAS,
           T1.NOTA,
           T1.ORI_CANAL
        FROM BASE_TRABAJO_EMAIL_LNEMAIL_R T1 
			LEFT JOIN POLAVARR.WEBBULA_EXCLUSION T2
				ON (T1.RUT=T2.RUT AND T1.EMAIL=T2.EMAIL)
					WHERE T2.RUT IS NULL AND T2.EMAIL IS NULL
;quit;


/* TRANSFORMACION A MAYUSCULA DE TODOS LOS EMAILS DEL LNEGRO_EMAIL*/
proc sql;
create table lnegro_email_mayusc as
select upcase(email) as email
from PUBLICIN.LNEGRO_EMAIL;
quit;

/*APLICADOS FILTROS DE LNEGROS CAR/EMAIL (PARA EL EMAIL Y RUT)*/
PROC SQL;
   CREATE TABLE RESULT.BASE_TRABAJO_EMAIL AS 
   SELECT t1.RUT, 
          t1.EMAIL, 
          t1.MRC_BOPERS,
		  t1.APERTURAS,
          t1.NOTA,
		  t1.ORI_CANAL
		FROM BASE_TRABAJO_EMAIL_WEBBULA 	T1 
			LEFT JOIN work.lnegro_email_mayusc T4
				ON (T1.EMAIL = T4.EMAIL) where T4.EMAIL IS MISSING
ORDER BY T1.RUT
;QUIT;

PROC SQL;
CREATE INDEX rut ON RESULT.BASE_TRABAJO_EMAIL (rut);
QUIT;

/*=========================================================================================*/
/* FIN - CALCULAR CONTACTABILIDAD - NOTA */
/*=========================================================================================*/

/*=========================================================================================*/
/*=========================================================================================*/
/* PASAR DESDE LIBRERÍA PERSONAL A PUBLICIN */
PROC SQL;
   CREATE TABLE PUBLICIN.BASE_TRABAJO_EMAIL AS 
   SELECT *
      FROM RESULT.BASE_TRABAJO_EMAIL
;
QUIT;

PROC SQL;
CREATE INDEX rut ON PUBLICIN.BASE_TRABAJO_EMAIL (rut);
QUIT;

/*  ==========================================================================*/
/*  Nombre del proceso almacenado: EMAIL_AUTOMATICO_3.0 - PARTE 3 - TERMINADA */
/*  ==========================================================================*/

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
TO = ("&DEST_1")
CC = ("&DEST_2","&DEST_3")
SUBJECT = ("MAIL_AUTOM: PROCESO DE CONTACTABILIDAD - EMAIL");
FILE OUTBOX;
	PUT "Estimados:";
 	put "		Proceso de contactabilidad EMAIL, ejecutado con fecha: &fechaeDVN";  
	PUT;
	PUT;
	put 'Proceso Vers. 22';
	PUT;
	PUT;
	PUT 'Atte.';
	Put 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;
FILENAME OUTBOX CLEAR;

