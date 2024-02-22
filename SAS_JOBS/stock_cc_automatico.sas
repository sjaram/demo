/* CONTROL DE VERSIONES */
/* -- 2023/06/22 -- V3 -- Esteban P. -- Actualización de output Benja Martinez, cambios en variables y filtros. */
/* -- 2023/06/05 -- V2 -- Esteban P. -- Se añade export a AWS */

DATA _NULL_;
carga=put(intnx('day',today(),0,'same'), yymmddn8.);

call symput("carga",carga);

run;

%put &carga;


%let path_ora      = '(DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SID = ripleyc)))'; 
%let user_ora      = 'RIPLEYC'; 
%let pass_ora      = 'ri99pley';
%let conexion_ora  = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 


PROC SQL  NOERRORSTOP;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );
create table Stock_Cuenta_corriente  as
select * from connection to ORACLE
( 
SELECT 
CAST(SUBSTR(a.cli_identifica,1,length(a.cli_identifica)-1) AS INT)  rut,
SUBSTR(a.cli_identifica,length(a.cli_identifica),1)  dv,
b.vis_numcue  cuenta, 
cast(TO_CHAR( b.vis_fechape,'YYYYMMDD') as INT) as FECHA_APERTURA,
cast(TO_CHAR( b.vis_fechape,'YYYYMM') as INT) as Periodo_apertura,
cast(TO_CHAR( b.VIS_FECHCIERR,'YYYYMMDD') as INT) as FECHA_CIERRE,
b.vis_status  estado,

CASE WHEN b.VIS_PRO=4 THEN 'CUENTA_VISTA'
     WHEN b.VIS_PRO=1 THEN 'CUENTA_CORRIENTE'
WHEN b.VIS_PRO=40 THEN 'LCA' END  DESCRIP_PRODUCTO,

CASE WHEN b.vis_status ='9' THEN 'cerrado' 
	when b.vis_status ='2' then 'vigente' 
	when b.vis_status='1' then 'nueva'
	when b.vis_status='3' then 'bloqueo depositos'
	when b.vis_status='4' then 'bloqueo retiros'
	when b.vis_status='5' then 'bloqueo total'
	when b.vis_status='6' then 'inactiva'
	when b.vis_status='7' then 'aviso cierre'
	when b.vis_status='8' then 'controlada'
	when b.vis_status='C' then 'clausurada' end as estado_cuenta,

b.VIS_SUC as SUCURSAL_APERTURA,
e.SUC_NOMBRE nombre_sucursal,
c.DES_CODIGO COD_CIERRE_CONTRATO,
c.DES_DESCRIPCION DESC_CIERRE_CONTRATO

 
from  tcap_vista  b 
inner join  tcli_persona   a
on(a.cli_codigo=b.vis_codcli) 
left join tgen_desctabla  c
on(b.VIS_CODTAB=c.DES_CODTAB) and     (b.VIS_CAUCIERR=c.DES_CODIGO)
left join TGEN_SUCURSAL e 
on(b.VIS_SUC=e.SUC_CODIGO)

where 
b.vis_mod=4
and (b.VIS_PRO=1)/*CTACTE*/
and b.vis_tip=1  /*PERSONA NO JURIDICA*/

) ;
disconnect from ORACLE;
QUIT;



proc sql;
create table stock_cc as 
select 
&CARGA. AS FECHA_PROCESO,
a.*,
CASE WHEN B.RUT IS NOT NULL THEN B.SEGMENTO ELSE 'S.I' END AS SEGMENTO_COMERCIAL,
CASE WHEN C.RUT IS NOT NULL THEN C.categoria_gse ELSE 'S.I' END AS GSE
from Stock_Cuenta_corriente as a
left join publicin.segmento_comercial as b
on a.rut=b.rut
left join rsepulv.gse_corp as c
on a.rut=c.rut

;quit; 



PROC SQL;
CREATE TABLE RESULT.STOCK_CC AS
SELECT *
FROM stock_cc
;QUIT;


/* export to aws */
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(sas_ppff_stock_cc,raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(sas_ppff_stock_cc,result.stock_cc,raw,sasdata,0);


/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_2
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

SELECT EMAIL into :DEST_3
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JOSE_ABURTO';


quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;




data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("bmartinezg@bancoripley.com")
CC = ("&DEST_1", "&DEST_2","&DEST_3")
SUBJECT = ("Stock Cta Cte - &carga.");
FILE OUTBOX;
 PUT "MAIL_AUTOM: Estimados:";
 put "  Proceso stock Cta Cte ejecutado con fecha &carga.";  
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
