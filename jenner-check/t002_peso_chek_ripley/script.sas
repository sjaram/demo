
/*Tablas de Parametros*/
options LOCALE=es_ES;

PROC SQL;
   CREATE TABLE WORK.PARAM_DEPTOS
       (COD_DEPTO char(4),
        DIVISION_GTN char(100),
        DEPARTAMENTO char(100),
        DIVISION_GTN3 char(100)
		);

INSERT INTO WORK.PARAM_DEPTOS
values('D378', 'BELLEZA', 'CHECK OUT BELLEZA', 'BLANDOS')
values('D115', 'BELLEZA', 'CORSETERIA', 'BLANDOS')
values('D116', 'BELLEZA', 'COSMETICOS', 'BLANDOS')
values('D134', 'BELLEZA', 'LENCERIA', 'BLANDOS')
values('D327', 'BELLEZA', 'PERFUMERIA SELECTIVA', 'BLANDOS')
values('D328', 'BELLEZA', 'PERFUMERIA SEMI-SELECTIVA', 'BLANDOS')
values('D155', 'BELLEZA', 'PERFUMES', 'BLANDOS')
values('D374', 'CALZADO Y ACCESORIOS', 'ACCESORIOS', 'BLANDOS')
values('D106', 'CALZADO Y ACCESORIOS', 'CALZADO DAMA', 'BLANDOS')
values('D107', 'CALZADO Y ACCESORIOS', 'CALZADO ESCOLAR', 'BLANDOS')
values('D108', 'CALZADO Y ACCESORIOS', 'CALZADO HOMBRE', 'BLANDOS')
values('D191', 'TECNOLOGIA', 'TELEFONIA MOVIL', 'DUROS')
values('D172', 'TECNOLOGIA', 'VIDEOJUEGOS', 'DUROS')
values('D103', 'ELECTRONICA', 'AUDIO', 'DUROS')
values('D122', 'ELECTRONICA', 'ELECTRODOMESTICOS', 'DUROS')
values('D188', 'OTROS NEGOCIOS', 'CREDITO', 'OTROS NEGOCIOS')
;
quit;


DATA _null_;
dia_actual= input(put(intnx('month',today(),0,'same'),day.),best16.)-1;
*dia_actual= 1;
Call symput("dia_actual", dia_actual);
RUN;


%macro uso_tr_trx(n=, dia= , id_mes= ,table_name=);
DATA _null_;
periodo = input(put(intnx('month',today(),-&n.,'begin'),yymmn6. ),$10.) ;
Call symput("periodo", periodo) ;
run;

proc sql;
	create table work.&table_name. as
	select
		periodo
		, &id_mes. as id_mes
		,lugar
		,nombre_division
		,SUBSTR(departamento_fin, 1, 4) as cod_depto
		,(case when marca_tipo_tr = 'CHECK' then 'CHEK'
			else marca_tipo_tr end) as marca_tipo_tr
		,nombre_sucursal
		,tipo_compra
		,(count(distinct bol_vta)) as q_boletas
		,(sum(mto)) as monto
	from result.uso_tr_marca_&periodo.
	where (1=1)
		and dia_nro <= &dia.
	group by periodo, (calculated id_mes), lugar, nombre_division, (calculated cod_depto),
			(calculated marca_tipo_tr), nombre_sucursal, tipo_compra;
quit;
%mend uso_tr_trx;


/* Bundle note: upstream branches on %eval(&dia_actual.=1) to decide whether
   this month counts as month-0 or month-1 of the rolling window; both
   branches call the same macro with four periods, so we exercise one branch
   (the %else arm) rather than depending on which day of the month the
   bundle happens to run on. */
%uso_tr_trx(n=0, id_mes=1, dia= &dia_actual., table_name = uso_tr_m0);
%uso_tr_trx(n=1, id_mes=2, dia= &dia_actual., table_name = uso_tr_1m);
%uso_tr_trx(n=2, id_mes=3, dia= &dia_actual., table_name = uso_tr_2m);
%uso_tr_trx(n=12, id_mes=4, dia= &dia_actual., table_name = uso_tr_12m);


proc sql;
CREATE TABLE WORK.USO_TR_MARCA AS
SELECT * FROM uso_tr_m0
UNION ALL
SELECT * FROM uso_tr_1m
UNION ALL
SELECT * FROM uso_tr_2m
UNION ALL
SELECT * FROM uso_tr_12m;
quit;


PROC SQL;
CREATE TABLE WORK.USO_TR_MARCA AS
SELECT
	t1.periodo
	, t1.lugar
	, t1.nombre_division
	, t1.cod_depto
	, t1.marca_tipo_tr
	, (CASE
		WHEN t1.nombre_sucursal IS missing OR t1.nombre_sucursal ='' THEN 'S/I'
		ELSE t1.nombre_sucursal
	END) AS nombre_sucursal
	, (CASE
		WHEN t2.division_gtn3 IS missing OR t2.division_gtn3 ='' THEN 'S/I'
		ELSE t2.division_gtn3
	END) AS division_gtn3
	, (CASE
		WHEN t2.division_gtn IS missing OR t2.division_gtn ='' THEN 'S/I'
		ELSE t2.division_gtn
	END) AS division_gtn
	, (CASE
		WHEN t1.id_mes = 4 THEN 'Anio_Pasado'
		WHEN t1.id_mes = 3 THEN 'Mes_Pasado'
		WHEN t1.id_mes = 2 THEN 'Mes_Ante_Pasado'
		ELSE 'Mes_Actual'
	END) AS fl_periodo
	, t1.monto
	, t1.q_boletas
FROM WORK.USO_TR_MARCA t1
LEFT JOIN WORK.PARAM_DEPTOS t2
	ON (t1.COD_DEPTO = t2.COD_DEPTO)
ORDER BY MARCA_TIPO_TR
;QUIT;

/*Agrupar tabla para sacar Venta Total Agrupada y Suma Boletas*/
/*DEPTO Y DIVISION*/
PROC SQL;
CREATE TABLE WORK.RESUMEN AS
SELECT
	marca_tipo_tr
	, lugar
	, division_gtn3
	, division_gtn
	, nombre_sucursal
	, fl_periodo
	, sum(monto) as monto format= DOLLARX20.0
	, sum(q_boletas) as q_boletas
FROM WORK.USO_TR_MARCA
GROUP BY 1,2,3,4,5,6;
QUIT;

/* Transponer la tabla y crear una nueva tabla transpuesta */
proc transpose data=WORK.RESUMEN out=tabla_transpuesta prefix=monto_ suffix=_monto;
    by marca_tipo_tr LUGAR division_gtn3 division_gtn nombre_sucursal;
    var monto;
    id fl_periodo;
run;

proc transpose data=WORK.RESUMEN out=tabla_transpuesta2 prefix=q_boletas_ suffix=_q_boletas;
    by marca_tipo_tr LUGAR division_gtn3 division_gtn nombre_sucursal;
    var q_boletas;
    id fl_periodo;
run;

/* Unir las dos tablas transpuestas */
data WORK.APERTURA_DPTOS_DIV;
    merge tabla_transpuesta tabla_transpuesta2;
    by marca_tipo_tr LUGAR division_gtn3 division_gtn nombre_sucursal;
    drop _NAME_;
run;


DATA WORK.APERTURA_DPTOS_DIV;
   set WORK.APERTURA_DPTOS_DIV;
   array variablesOfInterest _numeric_;
   do over variablesOfInterest;
      if variablesOfInterest=. then variablesOfInterest=0;
   END;
RUN;

proc print data=WORK.APERTURA_DPTOS_DIV noobs;
run;
