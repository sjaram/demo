/*UNIVERSO DE CONTRATOS*/
%let n=0;
%LET LIBRERIA=result;
DATA _NULL_;
fecha_ant = put(intnx('day', today(),-&n.-7,  'begin'), yymmddn8.);
fecha = put(intnx('day', today(),-&n.-1,  'begin'), yymmddn8.);
periodo = input(put(intnx('month',today(),-&n.,'end'),yymmn6. ),$10.);
periodo_ant = input(put(intnx('month',today(),-&n.-1,'end'),yymmn6. ),$10.);
FIN_rsat= put(intnx('day', today(),-&n.-1,  'begin'), yymmdd10.);
ini_rsat= put(intnx('day', today(),-&n.-7,  'begin'), yymmdd10.);
FIN_mora= put(intnx('day', today(),-&n.-2,  'begin'), ddmmyy10.);
Call symput("fecha_ant", fecha_ant);
Call symput("fecha", fecha);
Call symput("periodo", periodo);
Call symput("periodo_ant", periodo_ant);
Call symput("ini_rsat", ini_rsat);
Call symput("FIN_mora", FIN_mora);
RUN;

%put &fecha_ant;
%put &fecha;
%put &periodo;
%put &periodo_ant;
%put &ini_rsat;
%put &FIN_mora;



proc sql;
create table uso_tr as
select distinct rut_cpd as rut,
SUM(case when MARCA_TIPO_TR ="TR" THEN 1 END) AS COMPRA_TR,
SUM(case when MARCA_TIPO_TR <>"TR" THEN 1 END) AS COMPRA_OMP,
SUM(case when sucursal=39 then 1 else 0 end) as SI_COM,
SUM(case when sucursal<>39 then 1 else 0 end) as SI_TDA
from result.uso_tr_marca_&periodo_ant.
where fecha between &fecha_ant. and &fecha. and rut_cpd between 1000000 and 49000000
AND tipo_compra="COMPRA"
GROUP BY 
RUT_CPD
union 

select distinct rut_cpd as rut,
SUM(case when MARCA_TIPO_TR ="TR" THEN 1 END) AS COMPRA_TR,
SUM(case when MARCA_TIPO_TR <>"TR" THEN 1 END) AS COMPRA_OMP,
SUM(case when sucursal=39 then 1 else 0 end) as SI_COM,
SUM(case when sucursal<>39 then 1 else 0 end) as SI_TDA
from result.uso_tr_marca_&periodo.
where fecha between &fecha_ant. and &fecha. and rut_cpd between 1000000 and 49000000
AND tipo_compra="COMPRA"
GROUP BY 
RUT_CPD
;quit;

PROC SQL;
CREATE TABLE USO_TR2 AS
SELECT
RUT,
SUM(COMPRA_TR) AS COMPRA_TR,
SUM(COMPRA_OMP) AS COMPRA_OMP,
CASE WHEN CALCULATED COMPRA_TR>0 THEN 1 ELSE 0 END AS SI_TR,
CASE WHEN CALCULATED COMPRA_OMP>0 THEN 1 ELSE 0 END AS SI_OMP,
CASE WHEN SI_COM>0 THEN 1 ELSE 0 END AS SI_COM,
CASE WHEN SI_TDA>0 THEN 1 ELSE 0 END AS SI_TDA
FROM USO_TR
GROUP BY
RUT
;QUIT;

PROC SQL;
CREATE TABLE USO_LUGAR AS
SELECT 
*,
"TOTAL" AS LUGAR
FROM USO_TR2
OUTER UNION CORR

SELECT 
*,
"TDA" AS LUGAR
FROM USO_TR2
WHERE SI_TDA=1
OUTER UNION CORR

SELECT 
*,
"COM" AS LUGAR
FROM USO_TR2
WHERE SI_COM=1
;QUIT;

PROC SQL;
CREATE TABLE LUGAR AS
SELECT 
DISTINCT LUGAR
FROM USO_LUGAR
;QUIT;

PROC SQL;
CREATE TABLE LUGAR AS
SELECT
*,
MONOTONIC() AS IND
FROM LUGAR
;QUIT;

PROC SQL;
CREATE TABLE USO_LUGAR2 AS
SELECT 
T1.*,
T2.IND
FROM USO_LUGAR AS T1
LEFT JOIN LUGAR AS T2 ON (T1.LUGAR=T2.LUGAR)
;QUIT;

/* CONTRATOS */
PROC SQL NOERRORSTOP; 
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table cuentas  as
select *
from connection to ORACLE(
select
cast(B.PEMID_GLS_NRO_DCT_IDE_K as INT)  RUT,
A.CODENT,
A.CENTALTA,
A.CUENTA,
a.FECALTA  FECALTA_CTTO,
a.FECBAJA  FECBAJA_CTTO,
a.PRODUCTO,
a.SUBPRODU,
a.CONPROD
from MPDT007 a
INNER JOIN BOPERS_MAE_IDE B
ON A.IDENTCLI=B.PEMID_NRO_INN_IDE
where a.producto not in ('08','12','13') and 
(FECBAJA='0001-01-01' or FECBAJA between %str(%')&ini_rsat.%str(%') and 
%str(%')&fin_rsat.%str(%')) and
FECALTA<=%str(%')&ini_rsat.%str(%')
) A
;QUIT;


/*plasticos*/

PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table Panes as 
select * 
from connection to ORACLE(
select 
cast(B.PEMID_GLS_NRO_DCT_IDE_K as INT)  RUT,
A.CODENT,
A.CENTALTA,
A.CUENTA,
A.CALPART,
A.CODENT||A.CENTALTA||A.CUENTA  CTTO,
C.FECALTA  FECALTA_CTTO,
C.FECBAJA  FECBAJA_CTTO,
G.NUMPLASTICO,
G.PAN,
G.FECCADTAR,
G.INDULTTAR,
G.NUMBENCTA,
G.FECALTA  FECALTA_TR,
G.FECBAJA  FECBAJA_TR,
G.INDSITTAR,
g.CODMAR,
g.INDTIPT,
J.DESTIPT  TIPO_TARJETA_RSAT,
H.DESSITTAR,
G.FECULTBLQ,
g.CODBLQ,
g.TEXBLQ,
SUBSTR(G.PAN,13,4)  PAN2, 
A.CODENT||A.CENTALTA||A.CUENTA|| SUBSTR(G.PAN,13,4)   CONTRATO_PAN
FROM GETRONICS.MPDT013 A /*CONTRATO de Tarjeta*/
INNER JOIN GETRONICS.MPDT007 C /*CONTRATO*/
ON (A.CODENT=C.CODENT) AND (A.CENTALTA=C.CENTALTA) AND (A.CUENTA=C.CUENTA) 
INNER JOIN BOPERS_MAE_IDE B ON 
A.IDENTCLI=B.PEMID_NRO_INN_IDE
INNER JOIN GETRONICS.MPDT009 G /*Tarjeta*/ 
ON (A.CODENT=G.CODENT) AND (A.CENTALTA=G.CENTALTA) AND (A.CUENTA=G.CUENTA) AND (A.NUMBENCTA=G.NUMBENCTA)
INNER JOIN GETRONICS.MPDT063 H 
ON (G.CODENT=H.CODENT) AND (G.INDSITTAR=H.INDSITTAR)
LEFT JOIN GETRONICS.MPDT060 I 
ON (G.CODBLQ=I.CODBLQ)
left join GETRONICS.MPDT026 J
on(j.CODMAR=G.codmar) and (J.INDTIPT=G.INDTIPT)
where c.producto not in ('08','12','13') and G.INDULTTAR='S' and G.FECBAJA='0001-01-01' and A.CALPART='TI' and G.INDSITTAR=5
)
;QUIT;

PROC SQL;
CREATE TABLE PANES2 AS 
SELECT *,
INPUT(CATS((SUBSTR(FECALTA_CTTO,1,4)),SUBSTR(FECALTA_CTTO,6,2),SUBSTR(FECALTA_CTTO,9,2)),BEST.) AS FECALTA_CTTO2
FROM PANES
;QUIT;


PROC SQL;
CREATE TABLE MAX_FECHA AS 
SELECT 
	t1.RUT,  
	max(t1.FECALTA_CTTO2) as FECALTA_CTTO2
FROM WORK.PANES2 t1
group by
	t1.RUT
;QUIT;

proc sql;
create table PANES3 as
select 
t1.RUT,  
t1.FECALTA_CTTO2,
t2.CODENT,
t2.CENTALTA,
t2.CUENTA,	
t2.CALPART,
t2.CTTO,
t2.FECALTA_CTTO,
t2.FECBAJA_CTTO,
t2.FECCADTAR,
t2.CODBLQ
from MAX_FECHA as t1
left join PANES2 as t2 on (t1.RUT=t2.RUT and t1.FECALTA_CTTO2=t2.FECALTA_CTTO2)
;quit;


/*bloqueo asociado al contrato*/

PROC SQL;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
CREATE TABLE BLOQUEOS AS 
SELECT * FROM CONNECTION TO ORACLE(
SELECT A.CODENT, A.CENTALTA, A.CUENTA, A.CODBLQ,
B.DESBLQ,B.DESBLQRED,B.INDAPLEMISOR,B.CONTCUR
FROM MPDT178 A
INNER JOIN MPDT060 B ON A.CODBLQ=B.CODBLQ 
INNER JOIN (
	SELECT A.CODENT, A.CENTALTA, A.CUENTA, MAX(B.CONTCUR) MAX_FEC
	FROM MPDT178 A
	INNER JOIN MPDT060 B ON A.CODBLQ=B.CODBLQ
	WHERE A.LINEA = '0000'
	GROUP BY A.CODENT, A.CENTALTA, A.CUENTA
	) C ON A.CODENT=C.CODENT AND A.CENTALTA=C.CENTALTA AND A.CUENTA=C.CUENTA AND B.CONTCUR=C.MAX_FEC
WHERE A.LINEA = '0000'
)A
;QUIT;

PROC SQL;
   CREATE TABLE BLOQUEOS2 AS 
   SELECT DISTINCT
		  t1.CODENT, 
          t1.CENTALTA, 
          t1.CUENTA,
		  cats(CODENT, CENTALTA, CUENTA) as CTTO,
          t1.CODBLQ, 
          t1.DESBLQ, 
          t1.DESBLQRED, 
          t1.INDAPLEMISOR
      FROM WORK.BLOQUEOS t1
;QUIT;


/* mora del dia anterior */

PROC SQL NOERRORSTOP ;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
create table mora as
select *
from connection to ORACLE(
select
b.evaam_nro_ctt,
EVAAM_DIA_MOR
from SFRIES_ALT_MOR b
where b.EVAAM_FCH_PRO =
to_date(%str(%')&FIN_mora.%str(%'),'dd/mm/yyyy')
) A
;QUIT;

%macro EVALUADOR;
proc sql noprint;
select 
max(ind) as stop
into:stop
from USO_LUGAR2
;QUIT;

%let stop=&stop;
%put------------------------------------------------------------------------------------------;
%put [1.1] EVALUACION DESAGREGADA POR LUGAR (TOTAL | TDA | COM);
%put------------------------------------------------------------------------------------------;
%do i=1 %to &stop. ;

PROC SQL;
CREATE TABLE CRUZA_1 AS
SELECT 
T1.RUT,
T1.SI_TR,
T1.SI_OMP,
T1.LUGAR,
T1.IND,
CASE WHEN T2.RUT IS NOT NULL THEN 1 ELSE 0 END AS SI_CTTO
FROM (SELECT * FROM USO_LUGAR2 WHERE IND=&i.) AS T1
LEFT JOIN (SELECT DISTINCT RUT FROM cuentas) AS T2 ON (T1.RUT=T2.RUT)
GROUP BY 
T1.RUT,
T1.SI_TR,
T1.SI_OMP,
T1.LUGAR,
T1.IND
;QUIT;



/* CRUZA DE PANES CON MORA Y BLOQUEOS, PARA LUEGO DEJAR UNICOS RUT
Y CRUZAR CON USO*/

PROC SQL;
CREATE TABLE CRUZA2 AS
SELECT 
T1.*,

CASE WHEN (T2.CTTO IS NOT NULL) OR (T1.CODBLQ<>80) THEN 1 ELSE 0 END AS SI_BLOQUEO_DURO,

T3.EVAAM_DIA_MOR AS DIA_MORA
FROM PANES3 AS T1
LEFT JOIN BLOQUEOS2 AS T2 ON (T1.CTTO=T2.CTTO)
LEFT JOIN mora AS T3 ON (T1.CTTO=T3.EVAAM_NRO_CTT)
WHERE T1.RUT IN (SELECT RUT FROM CRUZA_1)
;QUIT;

PROC SQL;
   CREATE TABLE CRUZA3 AS 
   SELECT DISTINCT
		  t1.RUT, 
          t1.FECCADTAR, 
          t1.CODBLQ, 
          t1.DIA_MORA,
		  t1.SI_BLOQUEO_DURO,
		  case when CODBLQ=80 then 1 else 0 end as SI_BLOQUEO_80,
		  case when CODBLQ=1 then 1 else 0 end as SI_BLOQUEO_1,
		  case when CODBLQ=2 then 1 else 0 end as SI_BLOQUEO_2,
		  case when CODBLQ=4 then 1 else 0 end as SI_BLOQUEO_4,
		  case when CODBLQ=40 then 1 else 0 end as SI_BLOQUEO_40,
		  case when CODBLQ=43 then 1 else 0 end as SI_BLOQUEO_43,
		  case when CODBLQ NOT IN (80, 1, 2, 4, 40, 43) then 1 else 0 end as SI_BLOQUEO_DIST_D,
		  case when FECCADTAR<&periodo. then 1 else 0 end as SI_VENCIDOS
      FROM WORK.CRUZA2 t1
;QUIT;

/* OJO SOLUCION PARCHE */
PROC SQL;
   CREATE TABLE CRUZA4 AS 
   SELECT DISTINCT
		  t1.RUT, 
          SUM(t1.SI_BLOQUEO_DURO) AS SI_BLOQUEO_DURO, 
          SUM(t1.SI_BLOQUEO_80) AS SI_BLOQUEO_80, 
          SUM(t1.SI_BLOQUEO_1) AS SI_BLOQUEO_1, 
          SUM(t1.SI_BLOQUEO_2) AS SI_BLOQUEO_2, 
          SUM(t1.SI_BLOQUEO_4) AS SI_BLOQUEO_4, 
          SUM(t1.SI_BLOQUEO_40) AS SI_BLOQUEO_40, 
          SUM(t1.SI_BLOQUEO_43) AS SI_BLOQUEO_43, 
          SUM(t1.SI_BLOQUEO_DIST_D) AS SI_BLOQUEO_DIST_D, 
          SUM(t1.SI_VENCIDOS) AS SI_VENCIDOS, 
          MAX(t1.DIA_MORA) AS DIA_MORA
      FROM WORK.CRUZA3 t1
	GROUP BY
	RUT
;QUIT;

PROC SQL;
   CREATE TABLE CRUZA5 AS 
   SELECT t1.RUT, 
          CASE WHEN t1.SI_BLOQUEO_DURO>=1 THEN 1 ELSE 0 END AS SI_BLOQUEO_DURO, 
          CASE WHEN t1.SI_BLOQUEO_80>=1 THEN 1 ELSE 0 END AS SI_BLOQUEO_80, 
          CASE WHEN t1.SI_BLOQUEO_1>=1 THEN 1 ELSE 0 END AS SI_BLOQUEO_1, 
          CASE WHEN t1.SI_BLOQUEO_2>=1 THEN 1 ELSE 0 END AS SI_BLOQUEO_2, 
          CASE WHEN t1.SI_BLOQUEO_4>=1 THEN 1 ELSE 0 END AS SI_BLOQUEO_4, 
          CASE WHEN t1.SI_BLOQUEO_40>=1 THEN 1 ELSE 0 END AS SI_BLOQUEO_40, 
          CASE WHEN t1.SI_BLOQUEO_43>=1 THEN 1 ELSE 0 END AS SI_BLOQUEO_43, 
          CASE WHEN t1.SI_BLOQUEO_DIST_D>=1 THEN 1 ELSE 0 END AS SI_BLOQUEO_DIST_D, 
          CASE WHEN t1.SI_VENCIDOS>=1 THEN 1 ELSE 0 END AS SI_VENCIDOS, 
          t1.DIA_MORA
      FROM WORK.CRUZA4 t1
;QUIT;


proc sql noprint outobs=1;
select
max(input(substr(memname,11,6),best.)) as periodo_oferta_capta
into: periodo_oferta_capta
from DICTIONARY.COLUMNS
WHERE LIBNAME='RFONSECA'
AND MEMNAME LIKE '%CAPTA_CDP_%'
AND LENGTH(MEMNAME)=LENGTH('CAPTA_CDP_AAAAMM')
;QUIT;

%let periodo_oferta_capta=&periodo_oferta_capta;

%put &periodo_oferta_capta;


PROC SQL;
CREATE TABLE CRUZA6 AS 
SELECT
T1.*,

T2.SI_BLOQUEO_DURO, 
T2.SI_BLOQUEO_80, 
SI_BLOQUEO_1, 
SI_BLOQUEO_2, 
SI_BLOQUEO_4, 
SI_BLOQUEO_40, 
SI_BLOQUEO_43, 
SI_BLOQUEO_DIST_D, 
T2.SI_VENCIDOS, 
T2.DIA_MORA,

CASE WHEN T2.DIA_MORA BETWEEN 4 AND 90 THEN 1 ELSE 0 END AS MORA_MARCA,

CASE WHEN T3.RUT IS NOT NULL THEN 1 ELSE 0 END AS SI_OFERTA
FROM CRUZA_1 AS T1
LEFT JOIN CRUZA5 AS T2 ON (T1.RUT=T2.RUT)
LEFT JOIN (SELECT DISTINCT RUT FROM rfonseca.capta_cdp_&periodo_oferta_capta.) AS T3 ON (T1.RUT=T3.RUT)
;QUIT;

proc sql;
create table marcaje as 
select 
'01.TOTAL CLIENTES' as TIPO,
LUGAR,
SI_OFERTA as con_oferta,
count(RUT) as CLIENTES 
from cruza6
group by
LUGAR,
SI_OFERTA
outer union corr 

select 
'02.Clientes TR' as TIPO,
LUGAR,
SI_OFERTA as con_oferta,
count(RUT) as CLIENTES 
from cruza6
where (SI_CTTO=1) 
group by
LUGAR,
SI_OFERTA
outer union corr 

select 
case when (SI_TR=1 and SI_OMP=0) then  '04.Clientes con Compra SOLO TR' 
when (SI_TR=0 and SI_OMP=1) then  '05.Clientes con Compra SOLO OMP' 
when (SI_TR=1 and SI_OMP=1) then  '06.Clientes con Compra MIXTA' end  
as  TIPO,
LUGAR,
SI_OFERTA as con_oferta,
count(RUT) as CLIENTES 
from cruza6
where (SI_TR=1 or SI_OMP=1) 
group by 
LUGAR,
SI_OFERTA,
calculated tipo
outer union corr 

select 
'09.Mora de 4 a 90 días' as  TIPO,
LUGAR,
SI_OFERTA as con_oferta,
count(RUT) as CLIENTES 
from cruza6
where SI_TR=0 and SI_OMP=1 and SI_CTTO=1 and coalesce(DIA_MORA,0) between 4 and 90
group by 
LUGAR,
SI_OFERTA,
calculated tipo
outer union corr 

select 
'10.Vencido'  as TIPO,
LUGAR,
SI_OFERTA as con_oferta,
count(RUT) as CLIENTES 
from cruza6
where SI_TR=0 and SI_OMP=1 and SI_CTTO=1 and coalesce(DIA_MORA,0)<4 and 
coalesce(SI_VENCIDOS,0)=1
group by 
LUGAR,
SI_OFERTA,
calculated tipo
outer union corr 

select 
'11.BLOQUEO 80'  as TIPO,
LUGAR,
SI_OFERTA as con_oferta,
count(RUT) as CLIENTES 
from cruza6
where SI_TR=0 and SI_OMP=1 and SI_CTTO=1 and coalesce(DIA_MORA,0)<4 and 
coalesce(SI_VENCIDOS,0)=0 and coalesce(SI_BLOQUEO_80,0)=1
group by 
LUGAR,
SI_OFERTA,
calculated tipo
outer union corr 

select 
'12.BLOQUEO DURO'  as TIPO,
LUGAR,
SI_OFERTA as con_oferta,
count(RUT) as CLIENTES 
from cruza6
where SI_TR=0 and SI_OMP=1 and SI_CTTO=1 and coalesce(DIA_MORA,0)<4 and 
coalesce(SI_VENCIDOS,0)=0 and coalesce(SI_BLOQUEO_80,0)=0 and coalesce(SI_BLOQUEO_DURO,0)=1
group by 
LUGAR,
SI_OFERTA,
calculated tipo
outer union corr 

select 
'12.BLOQUEO DURO | 1 ROBO'  as TIPO,
LUGAR,
SI_OFERTA as con_oferta,
count(RUT) as CLIENTES 
from cruza6
where SI_TR=0 and SI_OMP=1 and SI_CTTO=1 and coalesce(DIA_MORA,0)<4 and 
coalesce(SI_VENCIDOS,0)=0and coalesce(SI_BLOQUEO_80,0)=0 and coalesce(SI_BLOQUEO_1,0)=1 and coalesce(SI_BLOQUEO_DURO,0)=1
group by 
LUGAR,
SI_OFERTA,
calculated tipo
outer union corr 

select 
'12.BLOQUEO DURO | 2 EXTRAVIO'  as TIPO,
LUGAR,
SI_OFERTA as con_oferta,
count(RUT) as CLIENTES 
from cruza6
where SI_TR=0 and SI_OMP=1 and SI_CTTO=1 and coalesce(DIA_MORA,0)<4 and 
coalesce(SI_VENCIDOS,0)=0 and coalesce(SI_BLOQUEO_80,0)=0 and coalesce(SI_BLOQUEO_2,0)=1  and coalesce(SI_BLOQUEO_DURO,0)=1
group by 
LUGAR,
SI_OFERTA,
calculated tipo
outer union corr 

select 
'12.BLOQUEO DURO | 4 DETERIORO'  as TIPO,
LUGAR,
SI_OFERTA as con_oferta,
count(RUT) as CLIENTES 
from cruza6
where SI_TR=0 and SI_OMP=1 and SI_CTTO=1 and coalesce(DIA_MORA,0)<4 and 
coalesce(SI_VENCIDOS,0)=0 and coalesce(SI_BLOQUEO_80,0)=0 and coalesce(SI_BLOQUEO_4,0)=1 and coalesce(SI_BLOQUEO_DURO,0)=1
group by 
LUGAR,
SI_OFERTA,
calculated tipo
outer union corr 

select 
'12.BLOQUEO DURO | 40 REEMISION'  as TIPO,
LUGAR,
SI_OFERTA as con_oferta,
count(RUT) as CLIENTES 
from cruza6
where SI_TR=0 and SI_OMP=1 and SI_CTTO=1 and coalesce(DIA_MORA,0)<4 and 
coalesce(SI_VENCIDOS,0)=0 and coalesce(SI_BLOQUEO_80,0)=0 and coalesce(SI_BLOQUEO_40,0)=1 and coalesce(SI_BLOQUEO_DURO,0)=1
group by 
LUGAR,
SI_OFERTA,
calculated tipo
outer union corr 

select 
'12.BLOQUEO DURO | 43 F. PREVENT'  as TIPO,
LUGAR,
SI_OFERTA as con_oferta,
count(RUT) as CLIENTES 
from cruza6
where SI_TR=0 and SI_OMP=1 and SI_CTTO=1 and coalesce(DIA_MORA,0)<4 and 
coalesce(SI_VENCIDOS,0)=0 and coalesce(SI_BLOQUEO_80,0)=0 and coalesce(SI_BLOQUEO_43,0)=1 and coalesce(SI_BLOQUEO_DURO,0)=1
group by 
LUGAR,
SI_OFERTA,
calculated tipo
outer union corr 

select 
'12.BLOQUEO DURO | RESTO'  as TIPO,
LUGAR,
SI_OFERTA as con_oferta,
count(RUT) as CLIENTES 
from cruza6
where SI_TR=0 and SI_OMP=1 and SI_CTTO=1 and coalesce(DIA_MORA,0)<4 and 
coalesce(SI_VENCIDOS,0)=0 and coalesce(SI_BLOQUEO_80,0)=0 and coalesce(SI_BLOQUEO_DIST_D,0)=1 and coalesce(SI_BLOQUEO_DURO,0)=1
group by 
LUGAR,
SI_OFERTA,
calculated tipo
;QUIT;

PROC SQL;
CREATE TABLE marcaje2 AS 
SELECT 
*
FROM marcaje
OUTER UNION CORR

SELECT
'08.BLOQUEO BLANDO'  as TIPO,
LUGAR,
con_oferta,
sum(case when TIPO IN ('09.Mora de 4 a 90 días', '10.Vencido', 
				   '11.BLOQUEO 80') then CLIENTES end) as clientes
FROM marcaje
group by 
calculated tipo,
LUGAR,
con_oferta
;quit;

PROC SQL;
CREATE TABLE marcaje3 AS 
SELECT 
*
FROM marcaje2
OUTER UNION CORR

SELECT
'07.CLIENTES NO HABILITADOS'  as TIPO,
LUGAR,
con_oferta,
sum(case when TIPO IN ('12.BLOQUEO DURO', '12.BLOQUEO DURO', '08.BLOQUEO BLANDO', '08.BLOQUEO BLANDO')
	then CLIENTES end) as clientes
FROM marcaje2
group by 
calculated tipo,
LUGAR,
con_oferta
;quit;


PROC SQL;
CREATE TABLE marcaje4 AS 
SELECT 
*
FROM marcaje3
OUTER UNION CORR

SELECT
'03.Clientes con TR Habilitada'  as TIPO,
LUGAR,
con_oferta,
sum(case when TIPO IN ('02.Clientes TR') then CLIENTES end)
- sum(case when TIPO IN ('07.CLIENTES NO HABILITADOS') then CLIENTES end)as clientes
FROM marcaje3
group by 
calculated tipo,
LUGAR,
con_oferta
;quit;

proc sql;
create table marcaje4 as
select 
t1.*,
t2.ind
from marcaje4 as t1
LEFT JOIN LUGAR AS T2 ON (T1.LUGAR=T2.LUGAR)
;quit;

%if (%sysfunc(exist(CASCADA_SEMANAS_TDA))) %then %do;
 
%end;
%else %do;

PROC  SQL;
CREATE TABLE CASCADA_SEMANAS_TDA
(
TIPO CHAR(99),
LUGAR CHAR(99),
con_oferta INT,
CLIENTES INT,
IND INT
)
;quit;
%end;

PROC SQL;
delete *
from CASCADA_SEMANAS_TDA 
where ind=&i.
;QUIT;

PROC SQL;
insert into CASCADA_SEMANAS_TDA 
SELECT 
*
FROM marcaje4
;QUIT;

%end;
%mend EVALUADOR;
%EVALUADOR;

%if (%sysfunc(exist(&LIBRERIA..CASCADA_SEM_TDA_SAVE ))) %then %do;
%end;
%else %do;
PROC  SQL;
CREATE TABLE &LIBRERIA..CASCADA_SEM_TDA_SAVE 
(
FECHA_INICIO INT,
FECHA_FIN INT,
MARCA_FECHA CHAR(99),
TIPO CHAR(99),
LUGAR CHAR(99),
con_oferta INT,
CLIENTES INT,
IND INT
)
;quit;
%end;


PROC SQL;
DELETE * FROM &LIBRERIA..CASCADA_SEM_TDA_SAVE 
WHERE FECHA_INICIO=&fecha_ant. AND FECHA_FIN=&fecha. AND MARCA_FECHA=CATS(&fecha_ant.,' | | ',&fecha.)
;QUIT;


PROC SQL;
INSERT INTO &LIBRERIA..CASCADA_SEM_TDA_SAVE
SELECT 
&fecha_ant. AS FECHA_INICIO,
&fecha. AS FECHA_FIN,
CATS(&fecha_ant.,' | | ',&fecha.) AS MARCA_FECHA,
*
FROM CASCADA_SEMANAS_TDA
;QUIT;
