/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	CONTACT_QUIERO_SER_CLIENTE	================================*/
/* CONTROL DE VERSIONES
/* 2022-03-31 -- V4 -- Esteban P. -- Se actualizan los correos de Pía por PM_CONTACTABILIDAD y se deja fuera vmartinezf.
/* 2021-04-13 -- V3 -- Pia O -- SE AGREGA BASE DE DATOS ACUMULADA DE EMAIL (SIN VARIABLE DE FECHA) y casillas mas escritas desde analisis de webbula 
/* 2020-11-25 -- V2 -- PIA -- SE AGREGA FILTROS DE EMAIL Y SE MANDA A LIBRERIA PUBLICIN
/* 2020-11-25 -- V1 -- David V. --  
					-- Versión Original
/* INFORMACIÓN:
	Programa que toma los datos desde "Quiero ser Cliente"

	(IN) Tablas requeridas o conexiones a BD:
	- PUBLICIN.XXXX
	- RESULT.XXXX
	- DVASQUEZ.XXXX

	(OUT) Tablas de Salida o resultado:
	- &libreria..QUIERO_SER_CLIENTE_HB_E_&VdatePeriodo
	- &libreria..QUIERO_SER_CLIENTE_HB_F_&VdatePeriodo
	- &libreria..QUIERO_SER_CLIENTE_HB_E
	- &libreria..QUIERO_SER_CLIENTE_HB_F
	
*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria=PUBLICIN;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/

LIBNAME QANEWHB ORACLE  PATH="QANEW.WORLD"  SCHEMA=HBPRI_ADM  USER=RIPLEYC  PASSWORD='ri99pley';

%LET PERIODO=201901;
%LET PERIODO2=202011;

/*7 minutos*/
PROC SQL ;
CREATE TABLE CAPTA_HB AS
select distinct (INPUT(LEFT(SUBSTR(LEFT(COMPRESS(COMPRESS(SOLPD_COD_RUT_USR,'.'),'-')),1,LENGTH(LEFT(COMPRESS(COMPRESS(SOLPD_COD_RUT_USR,
            '.'),'-')))-1)),BEST.)) AS RUT,
                case when SOLPD_COD_PRD = '8' then  'Tarjeta Ripley Mastercard'
                 when SOLPD_COD_PRD = '9' then 'Tarjeta Ripley'
                 when SOLPD_COD_PRD = '98' then  'Tarjeta Ripley Mastercard'
                 when SOLPD_COD_PRD = '99' then 'Tarjeta Ripley' 
                 when SOLPD_COD_PRD = '300' then 'Cuenta Vista'
                    end as solicitud, 
                          datepart(SOLPD_FCH_CRC_AUD) format=yymmdd10. as FECHA,
                          SOLPD_NOM_MAI as email,
/*						  SOLPD_NRO_FON as telefono*/
						  input(SOLPD_NRO_FON,best.) AS TELEFONO
from QANEWHB.HBPRI_GTN_SOL_PRD
WHERE input(put(datepart(solpd_fch_crc_aud),yymmddn8.),best.) BETWEEN &PERIODO*100+01 AND &PERIODO2*100+31
and SOLPD_COD_PRD in ('8','9','98','99','300')
;QUIT;



/**********************************************************************************************/
/*******	UNA VEZ EXTRAIDA LA DATA DE LA TABLA, EJECUTAR ESTE PROCESO 				*******/ 
/******* 	PARA ACTUALIZAR TABLA 		 				*******/
/**********************************************************************************************/

DATA _null_;
/* Fecha Periodo */
datePeriodo	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
Call symput("VdatePeriodo", datePeriodo);

RUN;
%put &VdatePeriodo;

/*TOMO FONO SIN EL 9 INICIAL, FECHA A NUMÉRICA Y EL EMAIL EN UPCASE*/
PROC SQL;
   CREATE TABLE QUIERO_SER_CLIENTE_HB_A AS 
   SELECT T1.RUT,
		  input(put(t1.FECHA,yymmddn8.),best.) as FECHA_ACT,
		  t1.FECHA AS FECHA_ORIGINAL,
		  COMPRESS(PUT(t1.TELEFONO-100000000* Floor(t1.TELEFONO/100000000),BEST.)) AS TELEFONO,
          upcase(t1.Email) 	AS EMAIL
      FROM work.CAPTA_HB t1  					/*ACTUALIZAR NOMBRE AQUI Y EN EL WORK*/

;QUIT;

/*  FILTROS A EMAIL */
PROC SQL;
   CREATE TABLE &libreria..QUIERO_SER_CLIENTE_HB_E_&VdatePeriodo AS  
   SELECT 	t1.RUT,
		  	t1.Email,
			T1.TELEFONO,
          	T1.FECHA_ACT,
			T1.FECHA_ORIGINAL
      FROM 	QUIERO_SER_CLIENTE_HB_A t1
	Where 	t1.RUT is not missing
			AND email not LIKE	('.-%')			AND email not LIKE	('%.')
	AND email not LIKE	('-%')				AND email not CONTAINS 	('XXXXX')
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
;
QUIT;

/*  CONVIERTO A FORMATO FECHA HOMOLOGADA Y FILTROS TELÉFONOS  */
PROC SQL;
   CREATE TABLE &libreria..QUIERO_SER_CLIENTE_HB_F_&VdatePeriodo AS 
   
   SELECT 	t1.RUT,
		  	t1.Email,
			input(T1.TELEFONO,best.) AS TELEFONO,
          	DHMS((MDY(INPUT(SUBSTR(PUT(t1.FECHA_ACT,BEST8.),5,2),BEST4.),
                  INPUT(SUBSTR(PUT(t1.FECHA_ACT,BEST8.),7,2),BEST4.),
                  INPUT(SUBSTR(PUT(t1.FECHA_ACT,BEST8.),1,4),BEST4.))),0,0,0) FORMAT=datetime20. AS FECHA_ACTUALIZACION,
			T1.FECHA_ORIGINAL
      FROM 	QUIERO_SER_CLIENTE_HB_A t1
;
QUIT;

/*Para obtener el mejor Email*/
/*AGREGO SECUENCIA Y ORIGEN, ADEMÁS DE RANGO DE RUTS VÁLIDOS*/
proc sql;
create table QUIERO_SER_CLIENTE_HB_E as
SELECT	t1.RUT, 
        upcase(t1.Email) as EMAIL, 
        t1.FECHA_ACT,
		10 AS SEQUENCIA,
		'QUIER_SR_CLI_HB' AS ORIGEN
  	FROM &libreria..QUIERO_SER_CLIENTE_HB_E_&VdatePeriodo t1 
	WHERE RUT > 100 AND RUT < 99999999 AND RUT IS NOT MISSING
;quit;


proc sql;
create table QUIERO_SER_CLIENTE_HB_E_MAX AS
SELECT	DISTINCT RUT, 
        EMAIL, 
        MAX(T1.FECHA_ACT) AS FECHA_ACT,
        t1.SEQUENCIA,
        T1.ORIGEN
    FROM QUIERO_SER_CLIENTE_HB_E t1
GROUP BY RUT
;quit;


proc sql;
create table QUIERO_SER_CLIENTE_HB_E_UNI AS
SELECT	DISTINCT T2.RUT, 
        T1.EMAIL, 
		T2.FECHA_ACT,
        T2.SEQUENCIA,
        T2.ORIGEN
    FROM QUIERO_SER_CLIENTE_HB_E T1 INNER JOIN QUIERO_SER_CLIENTE_HB_E_MAX t2
	ON (T1.RUT = T2.RUT AND T1.FECHA_ACT = T2.FECHA_ACT)
group by T2.RUT
order by 1
;quit;

/*	ACA QUDARÁN TODOS LOS EMAIL HASTA EL MINUTO	*/
proc sort data=QUIERO_SER_CLIENTE_HB_E_UNI out=&libreria..QUIERO_SER_CLIENTE_HB_E nodupkeys dupout=WORK.duplicados_RUT;			/* cambiado desde result */
by rut;
run;

PROC SQL;
CREATE INDEX rut ON &libreria..QUIERO_SER_CLIENTE_HB_E (RUT);
QUIT;

proc sql;
create table &libreria..QUIERO_SER_CLIENTE_HB_E_&VdatePeriodo AS 
	SELECT * FROM &libreria..QUIERO_SER_CLIENTE_HB_E
;quit;


/*Para obtener el mejor FONO*/
/*AGREGO SECUENCIA Y ORIGEN, ADEMÁS DE RANGO DE RUTS VÁLIDOS*/
proc sql;
create table QUIERO_SER_CLIENTE_HB_F as
SELECT	t1.RUT, 
        t1.TELEFONO, 
		T1.FECHA_ORIGINAL,
		0 AS SEQUENCIA, /* ES TOMADA COMO NOTA O SCORE EN LOS FONOS */
		'QUIER_SR_CLI_HB' AS ORIGEN
  	FROM &libreria..QUIERO_SER_CLIENTE_HB_F_&VdatePeriodo t1
	WHERE RUT > 100 AND RUT < 99999999
			AND t1.RUT is not missing AND 
			t1.TELEFONO BETWEEN 30000000 AND 99999999
			and t1.TELEFONO not in (99999999,88888888,77777777,66666666,55555555,44444444,
									33333333,22222222,11111111,00000000,98989898,89898989,
									88889999,99998888)
;quit;

proc sql;
create table QUIERO_SER_CLIENTE_HB_F_MAX AS
SELECT	DISTINCT T1.RUT, 
        T1.TELEFONO, 
		MAX(T1.FECHA_ORIGINAL) AS FECHA_ORIGINAL,
        t1.SEQUENCIA,
        T1.ORIGEN
    FROM QUIERO_SER_CLIENTE_HB_F t1
GROUP BY RUT
;quit;


proc sql;
create table QUIERO_SER_CLIENTE_HB_F_UNI AS
SELECT	DISTINCT T2.RUT, 
        t1.TELEFONO, 
        T1.FECHA_ORIGINAL as FECHA,
        T2.SEQUENCIA AS NOTA,
        T2.ORIGEN AS FUENTE
    FROM QUIERO_SER_CLIENTE_HB_F T1 INNER JOIN QUIERO_SER_CLIENTE_HB_F_MAX t2
	ON (T1.RUT = T2.RUT AND T1.FECHA_ORIGINAL = T2.FECHA_ORIGINAL)
	ORDER BY T1.FECHA_ORIGINAL 
;quit;


/*	ACA QUDARÁN TODOS LOS EMAIL HASTA EL MINUTO	*/
proc sort data=QUIERO_SER_CLIENTE_HB_F_UNI out=&libreria..QUIERO_SER_CLIENTE_HB_F nodupkeys dupout=WORK.duplicados_RUT;			/* cambiado desde result */
by rut;
run;

PROC SQL;
CREATE INDEX rut ON QUIERO_SER_CLIENTE_HB_F (RUT);
QUIT;

proc sql;
create table &libreria..QUIERO_SER_CLIENTE_HB_F_&VdatePeriodo AS
	SELECT * FROM QUIERO_SER_CLIENTE_HB_F
;quit;

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
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

SELECT EMAIL into :DEST_3
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_CONTACTABILIDAD';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_3")
CC = ("&DEST_1", "&DEST_2")
SUBJECT = ("MAIL_AUTOM: Proceso CONTACT_QUIERO_SER_CLIENTE");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso CONTACT_QUIERO_SER_CLIENTE, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put ; 
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 02'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
