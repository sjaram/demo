/*==================================================================================================*/
/*==================================	EQUIPO DE FECTURACION Y MDP		================================*/
/*============================= Proceso Suscripciones PEC ===============================*/
/* CONTROL DE VERSIONES
/* 2023-06-15 -- V2 -- Esteban P.	 -- Ignacio plaza realiza cambios en rutas de sftp.
/* 2023-05-31 -- V1 -- Ignacio Plaza --  
					-- Versión Original

/******************************* Validar Proceso ************************************/


/****************************** Comenzar Proceso ************************************/
%let n=0;
DATA _null_;
fecha = put(today(),yymmddn8.);
	INI_num = put(intnx('month',today(),-&n.-1,'begin'),yymmddn8.);
	FIN_num = put(intnx('month',today(),-&n.,'end'),yymmddn8.);
	Call symput("fecha", fecha);
	Call symput("INI_num", INI_num);
	Call symput("FIN_num", FIN_num);
RUN;

%put &fecha;
%put &INI_NUM;
%put &FIN_num;

/*==================================================================================================*/
/*                            Suscripciones PEC                                                     */
/*==================================================================================================*/ 

proc sql;
connect to ODBC as myconn (user="ripley-bi" password="biripley00"
DATASRC="BR-BACKENDHB"
);
create table PATRouteMapVIEW as
select
*,
input(put(datepart(fechaaccion), yymmddn8.), 8.) as fecha
from connection to myconn
( SELECT  *
from PATRouteMapVIEW
);
disconnect from myconn

;quit;

proc sql;
create table PATRouteMapVIEW_&fecha. as
select *
from PATRouteMapVIEW
where fecha between &INI_NUM. and &FIN_num.
;quit;


proc sql;
connect to ODBC as myconn (user="ripley-bi" password="biripley00"
DATASRC="BR-BACKENDHB"
);
create table PECRouteMapAddAccountView as
select *,
input(put(datepart(fechaaccion), yymmddn8.), 8.) as fecha
from connection to myconn
( SELECT  *
from PECRouteMapAddAccountView
);
disconnect from myconn;
quit;

proc sql;
create table PECRouteMapAddAccount_&fecha. as
select *
from PECRouteMapAddAccountView
where fecha between &INI_NUM. and &FIN_num.
;quit;


proc sql;
connect to ODBC as myconn (user="ripley-bi" password="biripley00"
DATASRC="BR-BACKENDHB"
);
create table PECRouteMapPayAccountView as
select *,
input(put(datepart(fechaaccion), yymmddn8.), 8.) as fecha
from connection to myconn
( SELECT  *
from PECRouteMapPayAccountView
);
disconnect from myconn;
quit;

proc sql;
create table PECRouteMapPayAccount_&fecha. as
select *
from PECRouteMapPayAccountView
where fecha between &INI_NUM. and &FIN_num.
;quit;

PROC EXPORT DATA=PATRouteMapVIEW_&fecha.
DBMS=xlsx 
OUTFILE= "/sasdata/users94/user_bi/TRASPASO_DOCS/PATRouteMapVIEW_&fecha..xlsx"
replace;
;RUN;
 
PROC EXPORT DATA=PECRouteMapAddAccount_&fecha.
DBMS=xlsx 
OUTFILE= "/sasdata/users94/user_bi/TRASPASO_DOCS/PECRouteMapAddAccount_&fecha..xlsx"
replace;
;RUN;

PROC EXPORT DATA=PECRouteMapPayAccount_&fecha. 
DBMS=xlsx 
OUTFILE= "/sasdata/users94/user_bi/TRASPASO_DOCS/PECRouteMapPayAccount_&fecha..xlsx"
replace;
;RUN;

proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

%put &=EDP_BI;



Filename myEmail EMAIL    
    Subject = "DATALOG PAT y PEC: &fecha."
    From    = ("&EDP_BI.") 
    To      = ("pmunozc@bancoripley.com", "narenas@bancoripley.com",
			   "cramirezs@bancoripley.com", "vjfriasc@bancoripley.com")
    CC      = ("IPLAZAM@bancoripley.com")
	attach =("/sasdata/users94/user_bi/TRASPASO_DOCS/PATRouteMapVIEW_&fecha..xlsx" content_type="xlsx") 
	attach =("/sasdata/users94/user_bi/TRASPASO_DOCS/PECRouteMapAddAccount_&fecha..xlsx" content_type="xlsx") 
	attach =("/sasdata/users94/user_bi/TRASPASO_DOCS/PECRouteMapPayAccount_&fecha..xlsx" content_type="xlsx") 
    Type    = 'Text/Plain';

 

Data _null_; File myEmail; 
PUT "Estimados,";
PUT " ";
PUT "Adjunto Datalog de PAT y PEC para el periodo anterior y el presente: &fecha.";
PUT "Saludos.";
PUT " ";
PUT 'Atte.';
Put 'Equipo de Facturacion y MDP';
PUT ;
PUT ;
PUT ;
;RUN;

 


filename myfile "/sasdata/users94/user_bi/TRASPASO_DOCS/PATRouteMapVIEW_&fecha..xlsx" ;
data _null_;
rc=fdelete("myfile");
;run;
filename myfile clear;

filename myfile "/sasdata/users94/user_bi/TRASPASO_DOCS/PECRouteMapAddAccount_&fecha..xlsx";
data _null_;
rc=fdelete("myfile");
;run;
filename myfile clear;

filename myfile "/sasdata/users94/user_bi/TRASPASO_DOCS/PECRouteMapPayAccount_&fecha..xlsx";
data _null_;
rc=fdelete("myfile");
;run;
filename myfile clear;
