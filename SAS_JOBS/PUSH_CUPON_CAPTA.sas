options validvarname=any;
LIBNAME bopers ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=BOPERS_ADM  USER='SAS_USR_BI' PASSWORD='SAS_23072020';

filename server ftp 'CAPTA_SALIDA.txt' CD='/'
       HOST='192.168.82.171' user='118732448' pass='118732448' PORT=21;
data _null_;   infile server;
    file '/sasdata/users94/user_bi/TRASPASO_DOCS/CAPTA_SALIDA.txt';
    input;
    put _infile_;
    run;

/*carga del archivo, se realiza de esta manera para tener control en el formato de las variables*/
data WORK.CAPTA_SALIDA;
	infile '/sasdata/users94/user_bi/TRASPASO_DOCS/CAPTA_SALIDA.txt' delimiter=';' MISSOVER DSD lrecl=32767 firstobs=2 ;     /*modificar ftp de origen*/
	informat PERIODO best32.;
	informat RUT_CLIENTE best32.;
	informat COD_PROD best32.;
	informat PRODUCTO $18.;
	informat RUT_VENDEDOR best32.;
	informat RUT_CAPTADOR best32.;
	informat RUT_ASISTENTE best32.;
	informat COD_SUCURSAL best32.;
	informat COD_CANAL best32.;
	informat CANAL $20.;
	informat FECHA yymmdd10.;
	informat ORIGEN $9.;
	informat INTERNET best32.;
	informat LINEA_CREDITO best32.;
	informat ADICIONALES best32.;
	informat CODENT $10.;
	informat CENTALTA $10.;
	informat CUENTA $12.;
	informat CONCRECION best32.;
	informat NRO_TERMINAL best32.;
	informat HORA_OFERTA time20.3;
	informat HORA_INICIO_VENTA time20.3;
	informat HORA_ENTREGA_PRODUCTO time20.3;
	informat VIA $7.;
	informat NRO_SOLICITUD best32.;
	informat ID_OFERTA best32.;
	format PERIODO best12.;
	format RUT_CLIENTE best12.;
	format COD_PROD best12.;
	format PRODUCTO $18.;
	format RUT_VENDEDOR best12.;
	format RUT_CAPTADOR best12.;
	format RUT_ASISTENTE best12.;
	format COD_SUCURSAL best12.;
	format COD_CANAL best12.;
	format CANAL $20.;
	format FECHA yymmdd10.;
	format ORIGEN $9.;
	format INTERNET best12.;
	format LINEA_CREDITO best12.;
	format ADICIONALES best12.;
	format CODENT $10.;
	format CENTALTA $10.;
	format CUENTA $12.;
	format CONCRECION best12.;
	format NRO_TERMINAL best12.;
	format HORA_OFERTA time20.3;
	format HORA_INICIO_VENTA time20.3;
	format HORA_ENTREGA_PRODUCTO time20.3;
	format VIA $7.;
	format NRO_SOLICITUD best12.;
	format ID_OFERTA best12.;
	input                                                                  
		PERIODO                                                    
		RUT_CLIENTE                                                
		COD_PROD                                                   
		PRODUCTO  $                                                
		RUT_VENDEDOR                                               
		RUT_CAPTADOR                                               
		RUT_ASISTENTE                                              
		COD_SUCURSAL                                               
		COD_CANAL                                                  
		CANAL  $                                                   
		FECHA                                                                                                                                                        
		ORIGEN  $                                                  
		INTERNET                                                   
		LINEA_CREDITO                                              
		ADICIONALES                                                
		CODENT                                                     
		CENTALTA                                                   
		CUENTA                                                     
		CONCRECION                                                 
		NRO_TERMINAL                                               
		HORA_OFERTA                                                
		HORA_INICIO_VENTA                                          
		HORA_ENTREGA_PRODUCTO                                      
		VIA  $                                                     
		NRO_SOLICITUD                                              
		ID_OFERTA                                                  
	;
run;

proc sql;
create table CAPTA_AYER as
select RUT_CLIENTE as 'CLIENTE-ID_USUARIO'n, 1 as 'CAMPANA-IND_RUT_DUP_CAMP'n, 
fecha,
'OUvtWfa0bXQHOTstpMvq' as 'CAMPANA-ID_BENEFICIO'n,
via,
producto
from WORK.CAPTA_SALIDA
where FECHA >= intnx('day',today(),-1)
and VIA = 'HOMEBAN' 
and PRODUCTO in ('CUENTA CORRIENTE','CAMBIO_DE_PRODUCTO_MC_BLACK','CAMBIO DE PRODUCTO','MASTERCARD_BLACK','TAM','TAM_CERRADA','TAM_CUOTAS','TR','CC')
order by fecha
;quit;

proc sql;
create table CAPTA_AYER_DV as
select
'CLIENTE-ID_USUARIO'n,
fecha,
catx('','CLIENTE-ID_USUARIO'n, PEMID_DVR_NRO_DCT_IDE) as 'CLIENTE-ID_USUARIO_DV'n, 
'CAMPANA-IND_RUT_DUP_CAMP'n,
'CAMPANA-ID_BENEFICIO'n,
via,
producto
from CAPTA_AYER A
INNER join BOPERS.BOPERS_MAE_IDE B
ON A.'CLIENTE-ID_USUARIO'n = input(B.PEMID_GLS_NRO_DCT_IDE_K,best.)
;quit;


/*fecha para el campcode */
data _null_;
length fechacc $8.;
fechacc = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechacc", fechacc) ;
RUN;
%put &fechacc;

/*	=======================	INICIO CODIGO CAMPAÑAS PARTE 1 - EMAIL ============= */
%let USUARIO 	= EDP;
data _null_;
CAMPCODE = compress(cat("&fechacc","CPTBNF")," ",);
Call symput("CAMPCODE", CAMPCODE);
run;
%let MI_CORREO 	= equipo_datos_procesos_bi@bancoripley.com;
%let CAMPANA 	= CAPTA_CUPON;
%let CAMP_AREA 	= CPT;
%let CAMPCODE 	= &fechacc.CPTBNF;
%let CAMP_PROD 	= BNF;
%let BASE_LIB	= WORK.;
%let BASE_TAB	= CAPTA_AYER_DV;

%put &USUARIO;		%put &CAMPCODE;		%put &MI_CORREO;		%put &CAMPANA;
%put &CAMP_AREA;	%put &CAMP_PROD;	%put &BASE_LIB;			%put &BASE_TAB;

OPTIONS VALIDVARNAME=ANY;

DATA _null_;
hoy= compress(tranwrd(put(INTNX('DAY',today() , 0),mmddyy10.),"-",""));
Call symput("fecha", hoy);
RUN;

%put &fecha;

proc sql;
Create table CARGA_CUPON_CAPTA (
	'CAMPANA-CAMPCODE'n 	CHAR(20), 		/* OBLIGATORIO SMS / PUSH / EMAIL */
	'CAMPANA-AREA'n 		CHAR(20), 		/* SMS / PUSH / EMAIL */
	'CAMPANA-PRODUCTO'n 	CHAR(20), 		/* SMS / PUSH / EMAIL */
	'CAMPANA-CAMPANA'n 		CHAR(20), 		/* OBLIGATORIO SMS / PUSH / EMAIL */
	'CAMPANA-FECHA'n 		CHAR(38), 		/* SMS / PUSH / EMAIL */
	'CAMPANA-CUSTOMERID'n 	NUMERIC(38),	/* SMS / PUSH / EMAIL */
	'CAMPANA-CANAL'n CHAR(50), /* SMS / PUSH / EMAIL */
	'CAMPANA-RUT_PUSH'n 	CHAR(38), 	
	'CAMPANA-ID_USUARIO'n 	NUMERIC(38),	/* OBLIGATORIO SMS / PUSH / EMAIL */
	'CLIENTE-ID_USUARIO'n NUMERIC(38),	/* OBLIGATORIO SMS / PUSH / EMAIL */
	'CAMPANA-IND_RUT_DUP_CAMP'n NUMERIC(38),
	'CAMPANA-ID_BENEFICIO'n  CHAR(200)
)
;quit;

/* INSERT CAMPAÑA --> PUSH */
proc sql NOPRINT;
	INSERT INTO CARGA_CUPON_CAPTA
		('CAMPANA-CAMPCODE'n, 'CAMPANA-AREA'n, 'CAMPANA-PRODUCTO'n, 'CAMPANA-CAMPANA'n, 'CAMPANA-FECHA'n, 'CAMPANA-CUSTOMERID'n, 'CAMPANA-CANAL'n, 'CAMPANA-RUT_PUSH'n, 'CAMPANA-ID_USUARIO'n, 'CLIENTE-ID_USUARIO'n, 'CAMPANA-IND_RUT_DUP_CAMP'n, 'CAMPANA-ID_BENEFICIO'n)
	SELECT DISTINCT compress(cats("&fechacc",'CPT','BNF')), 'CPT', 'BNF', 'CAPTA CUPON',  "&FECHA.", 'CLIENTE-ID_USUARIO'n, 'PUSH', 'CLIENTE-ID_USUARIO_DV'n, 'CLIENTE-ID_USUARIO'n, 'CLIENTE-ID_USUARIO'n, 0, 'CAMPANA-ID_BENEFICIO'n
		from CAPTA_AYER_DV
	;
quit;

data _null_;
VAR = COMPRESS('INPUT-FIREBASE_cuponCapta_'||&fechacc.||'_1530.csv'," ",);
call symput("archivo",VAR);
run;

%put &archivo;

PROC SQL;
CREATE TABLE COUNT_DE_TABLA_TMP AS
SELECT COUNT('CAMPANA-ID_CLIENTE') AS CANTIDAD_DE_REGISTROS_CARGADOS
from CARGA_CUPON_CAPTA
;QUIT;

/*	EXPORT --> Generación archivo CSV */
PROC EXPORT DATA = CARGA_CUPON_CAPTA
	OUTFILE="/sasdata/users94/user_bi/unica/input/&archivo."
		DBMS=dlm REPLACE;
	delimiter=',';
	PUTNAMES=YES;
RUN;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(input_firebase_cupon_capta,pre-raw,oracloud/campaign,0);
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(input_firebase_cupon_capta,carga_cupon_capta,pre-raw,oracloud/campaign,0);


/* IDENTIFICADOR PARA EL EQUIPO CAMPAÑAS */
DATA null_;
ID = CAT("&CAMPCODE",' - ',"&CAMPANA");
Call symput("var_ID_CAMP", ID);
RUN;

%put &var_ID_CAMP;

/* ENVÍO DE CORREO CON MAIL VARIABLE */
proc sql noprint;
SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ_CAMP';
SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA_CAMP';
quit;

%put &=EDP_BI; %put &=DEST_1; %put &=DEST_2;

FILENAME output EMAIL
SUBJECT = "Campaña CAPTACIÓN BENFEFICO, depositada: &var_ID_CAMP."
FROM = ("&MI_CORREO")
TO = ("&DEST_2","&DEST_1","apinedar@bancoripley.com","msanhuezaa@bancoripley.com")
cc = ("solivas@bancoripley.com", "acolmenaresp@bancoripley.com")
CT= "text/html" /* Required for HTML output */ ;
ODS LISTING CLOSE;
ODS HTML BODY=output STYLE=sasweb;
TITLE JUSTIFY=left
"Les informo que se ha enviado la campaña CAPTACIÓN BENFEFICIO, &var_ID_CAMP.";
PROC PRINT DATA=WORK.COUNT_DE_TABLA_TMP NOOBS;
RUN;
ODS HTML CLOSE;
ODS LISTING;
/* ==================================| FIN CODIGO CAMPAÑAS PARTE 1 |==================================*/
