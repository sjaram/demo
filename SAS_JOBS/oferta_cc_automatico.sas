DATA _NULL_;
carga=put(intnx('day',today(),0,'same'), yymmddn8.);

call symput("carga",carga);

run;

%put &carga;





PROC SQL ;
CONNECT TO ORACLE AS CAMPANAS (PATH="BRTEFGESTIONP.WORLD" USER='CAMP_COMERCIAL' PASSWORD='ccomer2409');
CREATE TABLE oferta_CC_&carga. AS 
SELECT * FROM CONNECTION TO CAMPANAS(
SELECT  CAMP_COD_CAMP_FK  CAMP
,CAMP_RUT_CLI  RUT 
,CAMP_DV_CLI 	 DV
,CAMP_COD_TIP_PROD	 TIP_PROD
,CAMP_COD_CND_PROD  CND_PROD
,CAMP_NOM_CLI 	 NOMBRES
,CAMP_APE_PAT_CLI  PATERNO
,CAMP_APE_MAT_CLI MATERNO
,CAMP_FLG_CAMP
FROM CBCAMP_MAE_OFERTAS 
WHERE 
CAMP_COD_TIP_PROD='13'
and CAMP_COD_CND_PROD='1301'
)A
;QUIT;


PROC EXPORT DATA=oferta_CC_&carga.
   OUTFILE="/sasdata/users94/user_bi/CC/oferta_CC_&carga..csv" 
   DBMS=dlm; 
   delimiter=';'; 
   PUTNAMES=YES; 
RUN;


/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

SELECT EMAIL into :DEST_3
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'ALEJANDRA_MARINAO';

SELECT EMAIL into :DEST_4
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'VALENTINA_MARTINEZ';
	
SELECT EMAIL into :DEST_5
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';
		
SELECT EMAIL into :DEST_6
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PPFF_PM_PASIVOS';
			
SELECT EMAIL into :DEST_7
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PPFF_JEFE_PASIVOS';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;
%put &=DEST_5;
%put &=DEST_6;
%put &=DEST_7;



data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_6","&DEST_7","bmartinezg@bancoripley.com")
CC = ("&DEST_1", "&DEST_2","&DEST_3", "&DEST_4", "&DEST_5")
ATTACH	= "/sasdata/users94/user_bi/CC/oferta_CC_&carga..csv" 
SUBJECT = ("Oferta Cta Cte - &carga.");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Se adjunta archivo de oferta Cta Cte con fecha &carga.";  
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
