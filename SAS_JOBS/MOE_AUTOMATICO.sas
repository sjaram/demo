/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	MOE_AUTOMATICO		 ===============================*/
/* CONTROL DE VERSIONES
/* 2023-08-24 -- v03 -- David V.		--  Se separa correo con P.Comercial, diferente archivo sin Nro. Tarjetas.
/* 2023-08-24 -- v02 -- David V.		--  Se agrega al equipo P.Comercial al correo de salida.
/* 0000-00-00 -- v01 -- xxxxxxxz		--  Versión Original

*/

%let n=0;

DATA _null_;
	fecha = put(today(),yymmddn8.);
	Call symput("fecha", fecha);
RUN;

%put &fecha;

/*extraccion del archivo*/
PROC SQL NOERRORSTOP;
	CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
	create table MOE_&fecha.  as 
		select * 
			from connection to ORACLE( 
				select b.NOMBRE as nombre_archivo,
					a.*
				from SFPACI_ADM.SFPACI_MOE a
					inner join (select * 
						from (
							select *
								from SFPACI_ADM.SFPACI_ARCHIVO
									where nombre like '%MOE%'
										) a
									inner  join  (select 
										max(FCH_CRC_AUD) as FCH_CRC_AUD
									from SFPACI_ADM.SFPACI_ARCHIVO
										where nombre like '%MOE%') b
											on(a.FCH_CRC_AUD=b.FCH_CRC_AUD)) b
											on(a.ID_ARCHIVO = b.ID_ARCHIVO)

											) A
	;
QUIT;

PROC EXPORT DATA=MOE_&fecha.
	DBMS=xlsx 
	OUTFILE= "/sasdata/users94/user_bi/TRASPASO_DOCS/MOE_&fecha..xlsx"
	replace;
	;
RUN;

proc sql noprint;
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	%put &=EDP_BI;

	Filename myEmail EMAIL    
	Subject = "MOE: &fecha."
	From    = ("&EDP_BI.") 
	To      = ("pmunozc@bancoripley.com", "narenas@bancoripley.com","cramirezs@bancoripley.com","vjfriasc@bancoripley.com")
	CC      = ("iplazam@bancoripley.com","&EDP_BI.")
	attach =("/sasdata/users94/user_bi/TRASPASO_DOCS/MOE_&fecha..xlsx" content_type="xlsx") 
	Type    = 'Text/Plain';

Data _null_;
	File myEmail;
	PUT "Estimados,";
	PUT " ";
	PUT "Adjunto archivo MOE: &fecha.";
    PUT;
    PUT;
    PUT 'Proceso Vers. 03';
    PUT;
    PUT;
    PUT 'Atte.';
	PUT 'Equipo de Facturacion y MDP';
	PUT;
	;
RUN;


filename myfile "/sasdata/users94/user_bi/TRASPASO_DOCS/MOE_&fecha..xlsx";
data _null_;
	rc=fdelete("myfile");
	;
run;

filename myfile clear;



proc sql;
create table MOE_2_&fecha. as
select
 NOMBRE_ARCHIVO
,ID_ARCHIVO	
,DEIC_TIPO_REG
,DEIC_COD_CRED	
,DEIC_ID_SERVICIO	
,DEIC_MONTO_TOPE	
,DEIC_MONE_CODIGO_TOPE	
,DEIC_MONTO_APORTE	
,DEIC_RUT	
/*,DEIC_TARJETA	*/
/*,DEIC_FEC_EXPIRA	*/
,DEIC_USUARIO	
,DEIC_NOM_FANTASIA	
,DEIC_RUBRO	
,DEIC_GLOSA_RUBRO	
,DEIC_COD_RESP	
,DEIC_GLOSA_RESP	
,DEIC_RUT_VENDEDOR	
,DEIC_SIN_USO	
,USR_AUD	
,TML_AUD	
,FCH_CRC_AUD	
,FCH_MDC_AUD	
,CNL_EST
from MOE_&fecha.
;quit;


PROC EXPORT DATA=MOE_2_&fecha.
	DBMS=xlsx 
	OUTFILE= "/sasdata/users94/user_bi/TRASPASO_DOCS/MOE_2_&fecha..xlsx"
	replace;
	;
RUN;

proc sql noprint;
	SELECT EMAIL into :EDP_BI 
		FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	%put &=EDP_BI;
	Filename myEmail EMAIL    
	Subject = "MOE: &fecha."
	From    = ("&EDP_BI.") 
		To      = ("esanhuezam@bancoripley.com","colavedo@bancoripley.com")
		CC      = ("&EDP_BI.","jbaeza@bancoripley.com")
		attach =("/sasdata/users94/user_bi/TRASPASO_DOCS/MOE_2_&fecha..xlsx" content_type="xlsx") 
		Type    = 'Text/Plain';

Data _null_;
	File myEmail;
	PUT "Estimados,";
	PUT " ";
	PUT "Adjunto archivo MOE: &fecha.";
    PUT;
    PUT;
    PUT 'Proceso Vers. 03';
    PUT;
    PUT;
    PUT 'Atte.';
    PUT 'Equipo Arquitectura de Datos y Automatización BI';
    PUT;
	;
RUN;


filename myfile "/sasdata/users94/user_bi/TRASPASO_DOCS/MOE_2_&fecha..xlsx";
data _null_;
	rc=fdelete("myfile");
	;
run;

filename myfile clear;
