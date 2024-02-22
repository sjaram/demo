/**********************************************************************************************/
/*******  UNA VEZ IMPORTADO EL ARCHIVO ENVIADO DESDE RETAIL, EJECUTAR ESTE PROCESO *******/
/*******  OBSERVAR QUE FECHA SE XX/XX/XXXX *********/ 
/******* PARA ACTUALIZAR TABLA POLAVARR.BASE_EMAIL_COM_&VdatePeriodo2                  *******/
/******* 2 horas aprox                                                                                *******/
/**********************************************************************************************/

/* ------ CONTROL DE VERSIONES ------ */
/* 2022-04-05 -- V2 -- Esteban P. -- Se actualizan los correos: Se reemplaza a PIA_OLAVARRIA por PM_CONTACTABILIDAD y se elimina a vmartinezf.

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria=PUBLICIN;

options validvarname=any;

DATA _null_;
/* Fecha Periodo */
datePeriodo2    = input(put(intnx('month',today(),0,'end' ),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
Call symput("VdatePeriodo2", datePeriodo2);

dateDIA	= compress(substr(put(today(),ddmmyy10.),7,4)||substr(put(today(),ddmmyy10.),4,2)||substr(put(today(),ddmmyy10.),1,2));
Call symput("VdateDIA", dateDIA);

RUN;
%put &VdatePeriodo2; 
%put &VdateDIA;

proc import datafile='/sasdata/users94/user_bi/CONT_FORMU/RIPLEY_CHILE_DATABASE.CSV'
	dbms=dlm out=base_ripley_com replace;
	delimiter=',';
	getnames=yes;
run;

PROC SQL ;
   CREATE TABLE RIPLEY_CHILE_DATABASE_ORD AS 
   SELECT Email, 
          input(LOGONID,best.) as RUT, 
          'Last Modified Date'n as FECHA_ULT_MOD, 
          'Open Date'n AS FECHA_OPEN,
          'Clicked Date'n AS FECHA_CLICK
      FROM base_ripley_com                   /*ACTUALIZAR NOMBRE AQUI Y EN EL WORK*/
;QUIT;


PROC SQL;
   CREATE TABLE RIPLEY_CHILE_DATABASE_A AS 
   SELECT t1.Email, 
          t1.RUT, 
          t1.FECHA_ULT_MOD,
            /*input(cat((SUBSTR('Opt In Date'n,7,4)),(SUBSTR('Opt In Date'n,4,2)),(SUBSTR('Opt In Date'n,1,2))) ,BEST10.) AS FECHA_NUM*/
            input(cat((SUBSTR(FECHA_ULT_MOD,7,4)),(SUBSTR(FECHA_ULT_MOD,4,2)),(SUBSTR(FECHA_ULT_MOD,1,2))) ,BEST10.) AS FECHA_NUM
      FROM RIPLEY_CHILE_DATABASE_ORD t1
;QUIT;


PROC SQL;
   CREATE TABLE &libreria..BASE_EMAIL_COM_&VdatePeriodo2 AS 
   SELECT t1.RUT,
            upcase(t1.Email) as EMAIL, 
          DHMS((MDY(INPUT(SUBSTR(PUT(t1.FECHA_NUM,BEST8.),5,2),BEST4.),
                  INPUT(SUBSTR(PUT(t1.FECHA_NUM,BEST8.),7,2),BEST4.),
                  INPUT(SUBSTR(PUT(t1.FECHA_NUM,BEST8.),1,4),BEST4.))),0,0,0) FORMAT=datetime20. AS FECHA_ACTUALIZACION

      FROM WORK.RIPLEY_CHILE_DATABASE_A t1
     Where t1.RUT is not missing
;
QUIT;

proc sql;
create table BASE_EMAIL_COM_DEPASO as
SELECT    t1.RUT, 
        upcase(t1.Email) as EMAIL, 
        t1.FECHA_ACTUALIZACION,
          1 AS sequencia,
          'RETAIL_COM' AS ORIGEN
     FROM &libreria..BASE_EMAIL_COM_&VdatePeriodo2 t1
/*              WHERE T1.RUT < 99999999 AND T1.RUT > 100*/
/*   GROUP BY RUT HAVING RUT > 100 AND RUT < 99999999*/
;quit;

PROC SQL;
CREATE INDEX RUT ON BASE_EMAIL_COM_DEPASO  (RUT);
QUIT;

proc sql;
create table BASE_EMAIL_COM_FMAX AS
SELECT    DISTINCT RUT, 
        EMAIL, 
        MAX(T1.FECHA_ACTUALIZACION) FORMAT = DATETIME20. AS FECHA_ACTUALIZACION,
        t1.SEQUENCIA,
        T1.ORIGEN
    FROM BASE_EMAIL_COM_DEPASO t1
GROUP BY RUT
;quit;

PROC SQL;
CREATE INDEX RUT ON BASE_EMAIL_COM_FMAX  (RUT);
QUIT;

proc sql;
create table &libreria..BASE_EMAIL_COM_&VdatePeriodo2 AS
SELECT    DISTINCT T2.RUT, 
        T1.EMAIL, 
          input(put(datepart(t2.FECHA_ACTUALIZACION),yymmddn8.),best.) as FECHA_ACT,
        T2.SEQUENCIA,
        T2.ORIGEN
    FROM BASE_EMAIL_COM_DEPASO T1 INNER JOIN BASE_EMAIL_COM_FMAX t2
     ON (T1.RUT = T2.RUT AND T1.FECHA_ACTUALIZACION = T2.FECHA_ACTUALIZACION)
     WHERE T2.RUT IS NOT MISSING AND T2.RUT < 99999999 AND T2.RUT > 10000
	AND t1.email not LIKE	('.-%')				AND t1.email not LIKE	('%.')
	AND t1.email not LIKE	('-%')				AND t1.email not CONTAINS 	('XXXXX')
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

proc sort data=&libreria..BASE_EMAIL_COM_&VdatePeriodo2 out=&libreria..BASE_EMAIL_COM_&VdatePeriodo2 nodupkeys dupout=WORK.duplicados_RUT;               /* cambiado desde result */
by rut;
run;

PROC SQL;
CREATE INDEX RUT ON &libreria..BASE_EMAIL_COM_&VdatePeriodo2  (RUT);
QUIT;





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
SUBJECT = ("MAIL_AUTOM: Proceso CONTACT_RIPLEY_COM");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso CONTACT_RIPLEY_COM, ejecutado con fecha: &fechaeDVN";  
 put ; 
 put ; 
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 01'; 
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


/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/



