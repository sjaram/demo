
DATA _null_;


n='0';
Call symput("n", n);
RUN;

%put &n;


DATA _null_;
periodo_actual = input(put(intnx('month',today(),&n.,'begin'),yymmn6. ),$10.) ;
periodo_1 = input(put(intnx('month',today(),&n.-1,'begin'),yymmn6. ),$10.) ;
dia_actual= put(intnx('month',today(),&n.,'same'),yymmddn8.); 

 
Call symput("periodo_actual", periodo_actual);
Call symput("periodo_1", periodo_1);
Call symput("dia_actual", dia_actual);

RUN;

%put &dia_actual;
%put &periodo_actual;
%put &periodo_1;

/* Grupos de facturación por clientes */

LIBNAME SFA  	ORACLE PATH='REPORITF.WORLD' SCHEMA='SFADMI_ADM' USER='JABURTOM'  PASSWORD='JABU#_1107' /*dbmax_text=7025*/;
LIBNAME R_bopers ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='JABURTOM' PASSWORD='JABU#_1107';
LIBNAME R_botgen ORACLE PATH='REPORITF.WORLD' SCHEMA='BOTGEN_ADM' USER='JABURTOM' PASSWORD='JABU#_1107';
LIBNAME MPDT  	ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='JABURTOM'  PASSWORD='JABU#_1107';




proc sql;
create table grupos_fact as
select b.pemid_gls_nro_dct_ide_k as rut,
a.GRUPOLIQ as grupo_facturacion,
case when a.GRUPOLIQ=4 then 5
when a.GRUPOLIQ=5 then 10
when a.GRUPOLIQ=6 then 15
when a.GRUPOLIQ=1 then 20
when a.GRUPOLIQ=2 then 25
when a.GRUPOLIQ=3 then 30
when a.GRUPOLIQ=7 then 5
else 0 end as vencimiento_pago,
case when a.GRUPOLIQ=4 then '18/20-5'
when a.GRUPOLIQ=5 then '25-10'
when a.GRUPOLIQ=6 then '30-15'
when a.GRUPOLIQ=1 then '5-20'
when a.GRUPOLIQ=2 then '10-25'
when a.GRUPOLIQ=3 then '15-30'
when a.GRUPOLIQ=7 then '18/20-5'
else '0-0' end as periodo_facturacion
from MPDT.MPDT007 as a
inner join  R_bopers.BOPERS_MAE_IDE as b
on input(trim(a.identcli),best.) = b.pemid_nro_inn_ide
where fecbaja = '0001-01-01' and producto not in ('8','12','13' )
and a.GRUPOLIQ not in (0) 
;quit;



proc sql;
create table log_mes_actual as
select rut,min(fecha_logueo)format=date9. as primer_log,count(distinct fecha_logueo) as cantidad_login_dist_dia
from publicin.logeo_int_&periodo_actual.
group by rut
;quit;


proc sql;
create table login_tc as 
select 
a.*,
case when b.rut is not null then 1 else 0 end as hizo_log,
b.primer_log as primer_login,
b.cantidad_login_dist_dia
from grupos_fact as a
left join log_mes_actual as b
on input(a.rut,best.)=b.rut
;quit;


proc sql;
Create table grupos_facturacion_tc as 
select grupo_facturacion,
max(vencimiento_pago) as vencimiento_pago,
count(rut) as cantidad_clientes,
count(case when hizo_log=1 then rut end) as cantidad_log,
round(avg(case when hizo_log=1 then cantidad_login_dist_dia end ),.1) as frecuencia_log_acum,
count(case when hizo_log=1 and day(primer_login)<=5 then rut end ) as login_5,
count(case when hizo_log=1  and day(primer_login)<=10 then rut end ) as login_10,
count(case when hizo_log=1  and day(primer_login)<=15 then rut end ) as login_15,
count(case when hizo_log=1  and day(primer_login)<=20 then rut end ) as login_20,
count(case when hizo_log=1  and day(primer_login)<=25 then rut end ) as login_25,
count(case when hizo_log=1 and day(primer_login)<=31  then rut end ) as login_30
from WORK.login_tc /*    Modificar     */
where input(rut,best.) in ( select distinct rut from publicin.act_tr_&periodo_1. where VU_IC=1 and saldo_contable>0)
group by grupo_facturacion
;quit;






DATA _null_;


n='0';
Call symput("n", n);
RUN;

%put &n;


DATA _null_;
periodo_actual = input(put(intnx('month',today(),&n.,'begin'),yymmn6. ),$10.) ;
periodo_12 = input(put(intnx('month',today(),&n.-12,'begin'),yymmn6. ),$10.) ;
periodo_2 = input(put(intnx('month',today(),&n.-2,'begin'),yymmn6. ),$10.) ;
periodo_1 = input(put(intnx('month',today(),&n.-1,'begin'),yymmn6. ),$10.) ;
periodo_3 = input(put(intnx('month',today(),&n.-3,'begin'),yymmn6. ),$10.) ;
periodo_4 = input(put(intnx('month',today(),&n.-4,'begin'),yymmn6. ),$10.) ;
periodo_5 = input(put(intnx('month',today(),&n.-5,'begin'),yymmn6. ),$10.) ;
periodo_6 = input(put(intnx('month',today(),&n.-6,'begin'),yymmn6. ),$10.) ;
periodo_7 = input(put(intnx('month',today(),&n.-7,'begin'),yymmn6. ),$10.) ;
periodo_8 = input(put(intnx('month',today(),&n.-8,'begin'),yymmn6. ),$10.) ;
periodo_9 = input(put(intnx('month',today(),&n.-9,'begin'),yymmn6. ),$10.) ;
periodo_10 = input(put(intnx('month',today(),&n.-10,'begin'),yymmn6. ),$10.) ;
periodo_11 = input(put(intnx('month',today(),&n.-11,'begin'),yymmn6. ),$10.) ;
periodo_siguiente = input(put(intnx('month',today(),1,'end'),yymmn6.),$10.);
primer_dia= put(intnx('month',today(),&n.,'begin'),yymmddn8.); 
ultimo_dia= put(intnx('month',today(),&n.,'end'),yymmddn8.);
primer_dia_1m = put(intnx('month',today(),&n.-1,'begin'),yymmddn8.); 
new_actual=cats(input(put(intnx('month',today(),&n.,'begin'),yymmn6. ),$10.),'_NEW');
new_1=cats(input(put(intnx('month',today(),&n.-1,'begin'),yymmn6. ),$10.),'_NEW');

per = put(intnx('month',today(),&n.,'end'), yymmn6.);
INI=put(intnx('month',today(),&n.,'begin'), date9.);
FIN=put(intnx('month',today(),&n.,'end'), date9.);
fec_proceso=put(intnx('day',today(),0,'same'), yymmddn8.);
INI_NUM=put(intnx('month',today(),&n.,'begin'), yymmddn8.);
FIN_NUM=put(intnx('month',today(),&n.,'end'), yymmddn8.);
ini_char = put(intnx('month',today(),&n.,'begin'),ddmmyy10.);
fin_char = put(intnx('month',today(),&n.,'end'),ddmmyy10. );
ini_fisa=put(intnx('month',today(),&n.,'begin'), DDMMYY10.);
fin_fisa=put(intnx('month',today(),&n.,'end'), DDMMYY10.);

 
Call symput("periodo_actual", periodo_actual);
Call symput("periodo_12", periodo_12);
Call symput("periodo_2", periodo_2);
Call symput("periodo_1", periodo_1);
Call symput("periodo_3", periodo_3);
Call symput("periodo_4", periodo_4);
Call symput("periodo_5", periodo_5);
Call symput("periodo_6", periodo_6);
Call symput("periodo_7", periodo_7);
Call symput("periodo_8", periodo_8);
Call symput("periodo_9", periodo_9);
Call symput("periodo_10", periodo_10);
Call symput("periodo_11", periodo_11);
Call symput("periodo_siguiente", periodo_siguiente);
Call symput("primer_dia",primer_dia);
Call symput("ultimo_dia",ultimo_dia);
Call symput("primer_dia_1m",primer_dia_1m);
call symput("periodo",per);
call symput("INI",INI);
call symput("FIN",FIN);
call symput("INI_NUM",INI_NUM);
call symput("FIN_NUM",FIN_NUM);
call symput("fec_proceso",fec_proceso);
call symput("INI_char",INI_char);
call symput("fin_char",fin_char);
call symput("ini_fisa",ini_fisa);
call symput("fin_fisa",fin_fisa);
call symput("new_actual",new_actual);
call symput("new_1",new_1);
RUN;


%put &periodo_actual;
%put &periodo_12;
%put &periodo_3;
%put &periodo_2;
%put &periodo_1;
%put &periodo_4;
%put &periodo_5;
%put &periodo_6;
%put &periodo_7;
%put &periodo_8;
%put &periodo_9;
%put &periodo_10;
%put &periodo_11;
%put &periodo_siguiente;
%put &primer_dia;
%put &ultimo_dia;
%put &primer_dia_1m;
%put &periodo;
%put &INI;
%put &FIN;
%put &INI_NUM;
%put &FIN_NUM;
%put &fec_proceso;
%put &INI_char;
%put &fin_char;
%put &ini_fisa;
%put &fin_fisa;
%put &new_actual;
%put &new_1;







/*Saldo CC*/

%let path_ora      = '(DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SID = ripleyc)))'; 
%let user_ora      = 'RIPLEYC'; 
%let pass_ora      = 'ri99pley';
%let conexion_ora  = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.; 
%put &conexion_ora.; 



PROC SQL ;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );
create table Saldos_Cuenta_corriente  as
select 
*
from connection to ORACLE( select 
CAST(SUBSTR(b.cli_identifica,1,length(b.cli_identifica)-1) AS INT)  rut,
cast(TO_CHAR( a.ACP_FECHA,'YYYYMMDD') as INT) as CodFecha,
a.ACP_FECHA, 
a.ACP_NUMCUE, 
sum(a.acp_salefe + a.acp_sal12h + a.acp_sal24h + a.acp_sal48h) as Saldo 
from tcap_acrpas  a
left join ( select 
distinct cli_identifica ,vis_numcue
from tcli_persona 
,tcap_vista 
where cli_codigo=vis_codcli 
and vis_mod=4
and (VIS_PRO=1) 
and vis_tip=1  
AND (vis_status='2' or vis_status='9')) b
on(a.ACP_NUMCUE=b.vis_numcue)
where a.acp_pro = 1 and a.acp_tip = 1 
and a.acp_fecha >=  to_date(%str(%')&ini_char.%str(%'),'dd/mm/yyyy')
and a.acp_fecha <= to_date(%str(%')&fin_char.%str(%'),'dd/mm/yyyy')
group by 
a.ACP_FECHA, 
a.ACP_NUMCUE,
b.cli_identifica
) ;
disconnect from ORACLE;
QUIT;


proc sql;
create table Saldos_Cuenta_corriente2 as
select 
a.*,
b.Saldo as Ultimo_Saldo 
from (
select 
ACP_NUMCUE as cuenta,
max(rut) as rut,
sum(case when Saldo>1 then 1 else 0 end) as Nro_Dias_Saldo_mayor_1,
sum(case when Saldo>1 then Saldo else 0 end) as SUM_SALDO_FECHA
from work.Saldos_Cuenta_corriente
group by 
ACP_NUMCUE 
) as a 
left join (
select distinct 
ACP_NUMCUE,
Saldo 
from Saldos_Cuenta_corriente
where CodFecha=(select max(CodFecha) from Saldos_Cuenta_corriente)
) as b 
on (a.cuenta=b.ACP_NUMCUE)

;QUIT;

proc sql;
create table saldo_cc as 
select rut,count(*) as  cant
from saldos_cuenta_corriente
where Saldo>1 and rut is not null
group by rut
;quit;



/* Saldo CV*/

proc sql   noprint inobs=1;
select 
put(cat(substr(put(&INI_NUM,8.),7,2),'/',substr(put(&INI_NUM,8.),5,2),'/',substr(put(&INI_NUM,8.),1,4)),$10. ) format=$10. as INI_CHAR,
put(cat(substr(put(&FIN_NUM,8.),7,2),'/',substr(put(&FIN_NUM,8.),5,2),'/',substr(put(&FIN_NUM,8.),1,4)),$10.)  format=$10. as FIN_CHAR
into
:INI_CHAR,
:FIN_CHAR
from pmunoz.codigos_capta_cdp
;QUIT;

%let INI_CHAR=&INI_CHAR;
%let FIN_CHAR=&FIN_CHAR;
%put &INI_CHAR;
%put &FIN_CHAR;





PROC SQL ;
CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );
create table SB_Saldos_Cuenta_Vista  as
select 
*
from connection to ORACLE( select 
CAST(SUBSTR(b.cli_identifica,1,length(b.cli_identifica)-1) AS INT)  rut,
cast(TO_CHAR( a.ACP_FECHA,'YYYYMMDD') as INT) as CodFecha,
a.ACP_FECHA, 
a.ACP_NUMCUE, 
sum(a.acp_salefe + a.acp_sal12h + a.acp_sal24h + a.acp_sal48h) as Saldo 
from tcap_acrpas  a
left join ( select 
distinct cli_identifica ,vis_numcue
from tcli_persona 
,tcap_vista 
where cli_codigo=vis_codcli 
and vis_mod=4
and (VIS_PRO=4 or VIS_PRO=40) 
and vis_tip=1  
AND (vis_status='2' or vis_status='9')) b
on(a.ACP_NUMCUE=b.vis_numcue)
where a.acp_pro = 4 and a.acp_tip = 1 
and a.acp_fecha >=  to_date(%str(%')&ini_char.%str(%'),'dd/mm/yyyy')
and a.acp_fecha <= to_date(%str(%')&fin_char.%str(%'),'dd/mm/yyyy')
group by 
a.ACP_FECHA, 
a.ACP_NUMCUE,
b.cli_identifica
) ;
disconnect from ORACLE;
QUIT;

proc sql;
create table work.SB_Saldos_Cuenta_Vista2 as
select 
a.*,
b.Saldo as Ultimo_Saldo 
from (
select 
ACP_NUMCUE as cuenta,
max(rut) as rut,
sum(case when Saldo>1 then 1 else 0 end) as Nro_Dias_Saldo_mayor_1,
sum(case when Saldo>1 then Saldo else 0 end) as SUM_SALDO_FECHA
from work.SB_Saldos_Cuenta_Vista 
group by 
ACP_NUMCUE 
) as a 
left join (
select distinct 
ACP_NUMCUE,
Saldo 
from work.SB_Saldos_Cuenta_Vista 
where CodFecha=(select max(CodFecha) from work.SB_Saldos_Cuenta_Vista)
) as b 
on (a.cuenta=b.ACP_NUMCUE)
;QUIT;

proc sql;
create table saldo_cv as 
select rut,count(*) as cant
from SB_Saldos_Cuenta_Vista
where Saldo>1 and rut is not null
group by rut
;quit;


proc sql;
create table cons_td as 
select  rut,'CC' as tipo
from saldo_cc
union
select  rut,'CV' as tipo from saldo_cv
;quit;


proc sql;
create table cons_td_tr as 
select a.rut,a.tipo,
case when b.rut is not null and a.tipo='CC' then 'CC+TAM/TR'
when b.rut is not null and a.tipo='CV' then 'CV+TAM/TR'
when b.rut is null and a.tipo='CC' THEN 'CC'
when b.rut is null and a.tipo='CV' THEN 'CV'
else 'No Cruza' end as segmentacion
from cons_td as a
left join ( select distinct rut from publicin.act_tr_&periodo_1. where VU_IC=1 and saldo_contable>0) as b
on a.rut=b.rut
;quit;


proc sql;
create table login_td as 
select 
a.rut,
a.tipo,
a.segmentacion,
case when b.rut is not null then 1 else 0 end as hizo_log,
b.primer_log,
b.cantidad_login_dist_dia
from cons_td_tr as a
left join log_mes_actual as b
on a.rut=b.rut
;quit;


proc sql;
Create table grupos_saldo_o_mov_td as 
select segmentacion,
count(rut) as cantidad_clientes,
count(case when hizo_log=1 then rut end) as cantidad_log,
round(avg(case when hizo_log=1 then cantidad_login_dist_dia end ),.1) as frecuencia_log_acum,
count(case when hizo_log=1 and day(primer_log)<=5 then rut end ) as login_5,
count(case when hizo_log=1  and day(primer_log)<=10 then rut end ) as login_10,
count(case when hizo_log=1  and day(primer_log)<=15 then rut end ) as login_15,
count(case when hizo_log=1  and day(primer_log)<=20 then rut end ) as login_20,
count(case when hizo_log=1  and day(primer_log)<=25 then rut end ) as login_25,
count(case when hizo_log=1 and day(primer_log)<=31  then rut end ) as login_30
from login_td 
group by segmentacion
;quit;


PROC EXPORT DATA =  work.grupos_saldo_o_mov_td
/*OUTFILE="/sasdata/users94/user_bi/unica/INPUT-TR_CAMPANAS-&USUARIO..csv"*/
OUTFILE="/sasdata/users94/user_bi/unica/input/grupos_saldo_o_mov_td.csv"
DBMS=dlm REPLACE;
delimiter=';';
PUTNAMES=YES;
RUN;

PROC EXPORT DATA =  work.grupos_facturacion_tc
/*OUTFILE="/sasdata/users94/user_bi/unica/INPUT-TR_CAMPANAS-&USUARIO..csv"*/
OUTFILE="/sasdata/users94/user_bi/unica/input/grupos_facturacion_tc.csv"
DBMS=dlm REPLACE;
delimiter=';';
PUTNAMES=YES;
RUN;




data _null_;
FILENAME OUTBOX EMAIL
SUBJECT="MAIL_AUTOM: Actualización Grupos de Facturación y Tenencia TD, con login  &dia_actual."
FROM = ("nverdejog@bancoripley.com")
TO = ("vmorah@bancoripley.com")
 CC      = ("nverdejog@bancoripley.com","rarcosm@bancoripley.com","mgalazh@bancoripley.com","tpiwonkas@bancoripley.com","apinedar@bancoripley.com")
attach =("/sasdata/users94/user_bi/unica/input/grupos_saldo_o_mov_td.csv" content_type="excel")
attach    =( "/sasdata/users94/user_bi/unica/input/grupos_facturacion_tc.csv" content_type="excel") 
	  Type    = 'Text/Plain';

FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
 put "Datos actualizados al &dia_actual.";  
 put ; 
 put ; 
 PUT ;
PUT 'Atte.';
Put 'Nicolás Verdejo';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

