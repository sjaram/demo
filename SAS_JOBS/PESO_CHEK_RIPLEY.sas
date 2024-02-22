
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
values('D311', 'CALZADO Y ACCESORIOS', 'CALZADO HOMBRE MARCAS', 'BLANDOS')
values('D310', 'CALZADO Y ACCESORIOS', 'CALZADO HOMBRE MAS', 'BLANDOS')
values('D109', 'CALZADO Y ACCESORIOS', 'CALZADO JUVENIL', 'BLANDOS')
values('D312', 'CALZADO Y ACCESORIOS', 'CALZADO JUVENIL MARCAS', 'BLANDOS')
values('D313', 'CALZADO Y ACCESORIOS', 'CALZADO JUVENIL MAS', 'BLANDOS')
values('D309', 'CALZADO Y ACCESORIOS', 'CALZADO MUJER MARCA', 'BLANDOS')
values('D308', 'CALZADO Y ACCESORIOS', 'CALZADO MUJER MAS', 'BLANDOS')
values('D373', 'CALZADO Y ACCESORIOS', 'CARTERAS', 'BLANDOS')
values('D379', 'CALZADO Y ACCESORIOS', 'CHECK OUT CALZADO Y ACCESORIOS', 'BLANDOS')
values('D201', 'CALZADO Y ACCESORIOS', 'OPTICA', 'BLANDOS')
values('D160', 'CALZADO Y ACCESORIOS', 'RELOJERIA', 'BLANDOS')
values('D192', 'DEPORTE', 'BICICLETAS Y MAQUINAS', 'BLANDOS')
values('D380', 'DEPORTE', 'CHECK OUT DEPORTE', 'BLANDOS')
values('D371', 'DEPORTE', 'NIKE STORE', 'BLANDOS')
values('D325', 'DEPORTE', 'PROMOCIONES DEPORTE', 'BLANDOS')
values('D315', 'DEPORTE', 'TEXTIL MARCAS', 'BLANDOS')
values('D314', 'DEPORTE', 'TEXTIL MAS', 'BLANDOS')
values('D169', 'DEPORTE', 'TEXTIL OUTDOOR', 'BLANDOS')
values('D170', 'DEPORTE', 'TIEMPO LIBRE', 'BLANDOS')
values('D317', 'DEPORTE', 'ZAPATILLAS MARCA', 'BLANDOS')
values('D337', 'HOMBRE', 'BARBADOS HOMBRES', 'BLANDOS')
values('D339', 'HOMBRE', 'CACHAREL HOMBRES', 'BLANDOS')
values('D112', 'HOMBRE', 'CAMISERIA', 'BLANDOS')
values('D382', 'HOMBRE', 'CHECK OUT HOMBRE', 'BLANDOS')
values('D114', 'HOMBRE', 'COORDINADOS', 'BLANDOS')
values('D117', 'HOMBRE', 'CUEROS', 'BLANDOS')
values('D307', 'HOMBRE', 'INDEX HOMBRE', 'BLANDOS')
values('D143', 'HOMBRE', 'KENNETH STEVENS', 'BLANDOS')
values('D358', 'HOMBRE', 'LA DOLFINA', 'BLANDOS')
values('D140', 'HOMBRE', 'MARCAS', 'BLANDOS')
values('D394', 'HOMBRE', 'MARCAS CASUAL INT HOMBRE', 'BLANDOS')
values('D393', 'HOMBRE', 'MARCAS CASUAL NACIONAL HOMBRE', 'BLANDOS')
values('D357', 'HOMBRE', 'MARCAS INT. HOMBRE', 'BLANDOS')
values('D302', 'HOMBRE', 'MARCAS JUVENIL HOMBRE', 'BLANDOS')
values('D396', 'HOMBRE', 'MARCAS JUVENIL INTERNACIONAL HOMBRE', 'BLANDOS')
values('D395', 'HOMBRE', 'MARCAS JUVENIL NACIONAL HOMBRE', 'BLANDOS')
values('D304', 'HOMBRE', 'MARCAS SPORT HOMBRE', 'BLANDOS')
values('D303', 'HOMBRE', 'MARQUIS HOMBRE', 'BLANDOS')
values('D142', 'HOMBRE', 'MAS', 'BLANDOS')
values('D323', 'HOMBRE', 'PEPE JEANS', 'BLANDOS')
values('D338', 'HOMBRE', 'REGATTA HOMBRES', 'BLANDOS')
values('D348', 'HOMBRE', 'ROBERT LEWIS HOMBRE', 'BLANDOS')
values('D163', 'HOMBRE', 'ROPA INTERIOR', 'BLANDOS')
values('D164', 'HOMBRE', 'SASTRERIA', 'BLANDOS')
values('D351', 'HOMBRE', 'SURF HOMBRES', 'BLANDOS')
values('D177', 'INFANTIL BLANDOS', 'BEBE', 'BLANDOS')
values('D403', 'INFANTIL BLANDOS', 'BOUTIQUES INFANTIL', 'BLANDOS')
values('D372', 'INFANTIL BLANDOS', 'COLLOKY', 'BLANDOS')
values('D124', 'INFANTIL BLANDOS', 'ESCOLAR', 'BLANDOS')
values('D401', 'INFANTIL BLANDOS', 'LICENCIAS BEBES', 'BLANDOS')
values('D399', 'INFANTIL BLANDOS', 'LICENCIAS NINA', 'BLANDOS')
values('D397', 'INFANTIL BLANDOS', 'LICENCIAS NINO', 'BLANDOS')
values('D138', 'INFANTIL BLANDOS', 'LOLOS', 'BLANDOS')
values('D402', 'INFANTIL BLANDOS', 'MARCAS NACIONAL BEBES', 'BLANDOS')
values('D400', 'INFANTIL BLANDOS', 'MARCAS NACIONAL NINA', 'BLANDOS')
values('D398', 'INFANTIL BLANDOS', 'MARCAS NACIONAL NINO', 'BLANDOS')
values('D300', 'INFANTIL BLANDOS', 'PROPIA BEBE NINA', 'BLANDOS')
values('D301', 'INFANTIL BLANDOS', 'PROPIA BEBE NINO', 'BLANDOS')
values('D152', 'INFANTIL BLANDOS', 'PROPIA NINA', 'BLANDOS')
values('D153', 'INFANTIL BLANDOS', 'PROPIA NINO', 'BLANDOS')
values('D176', 'INFANTIL BLANDOS', 'PROPIA RECIEN NACIDO', 'BLANDOS')
values('D162', 'INFANTIL BLANDOS', 'ROPA INT NINOS', 'BLANDOS')
values('D331', 'INFANTIL BLANDOS', 'ROPA INTERIOR ESCOLAR', 'BLANDOS')
values('D370', 'INFANTIL DUROS', 'CHECK OUT INFANTIL', 'BLANDOS')
values('D175', 'INFANTIL DUROS', 'JUGUETERIA', 'BLANDOS')
values('D340', 'INFANTIL DUROS', 'MOCHILAS ESCOLARES', 'BLANDOS')
values('D198', 'INFANTIL DUROS', 'PROMOCIONES INFANTIL', 'BLANDOS')
values('D161', 'INFANTIL DUROS', 'RODADOS', 'BLANDOS')
values('D166', 'MUJER', 'AZIZ', 'BLANDOS')
values('D330', 'MUJER', 'BARBADOS MUJER', 'BLANDOS')
values('D105', 'MUJER', 'BOUTIQUES MUJER', 'BLANDOS')
values('D125', 'MUJER', 'BRIGITTE NAUX', 'BLANDOS')
values('D320', 'MUJER', 'CACHAREL MUJER', 'BLANDOS')
values('D383', 'MUJER', 'CHECK OUT MUJER', 'BLANDOS')
values('D118', 'MUJER', 'CUEROS MUJER', 'BLANDOS')
values('D350', 'MUJER', 'DENIM TERCEROS MUJER', 'BLANDOS')
values('D129', 'MUJER', 'INDEX MUJER', 'BLANDOS')
values('D388', 'MUJER', 'MARCAS FORMAL INTER NACIONAL MUJER', 'BLANDOS')
values('D387', 'MUJER', 'MARCAS FORMAL NACIONAL MUJER', 'BLANDOS')
values('D392', 'MUJER', 'MARCAS JUVENIL INTERNACIONAL MUJER', 'BLANDOS')
values('D391', 'MUJER', 'MARCAS JUVENIL NACIONAL MUJER', 'BLANDOS')
values('D190', 'MUJER', 'MARCAS SPORT', 'BLANDOS')
values('D389', 'MUJER', 'MARCAS SPORT NACIONAL MUJER', 'BLANDOS')
values('D141', 'MUJER', 'MARQUIS MUJER', 'BLANDOS')
values('D324', 'MUJER', 'PEPE JEANS MUJER', 'BLANDOS')
values('D193', 'MUJER', 'PROMOCIONES MUJER', 'BLANDOS')
values('D159', 'MUJER', 'REGATTA MUJER', 'BLANDOS')
values('D167', 'MUJER', 'TALLAS GRANDES', 'BLANDOS')
values('D321', 'MUJER', 'TATIENNE', 'BLANDOS')
values('D342', 'MUJER', 'TRAJES DE BANO', 'BLANDOS')
values('D102', 'DECOHOGAR', 'ALFOMBRA', 'DUROS')
values('D364', 'DECOHOGAR', 'BANO', 'DUROS')
values('D363', 'DECOHOGAR', 'CAMA', 'DUROS')
values('D377', 'DECOHOGAR', 'CHECK OUT DECOHOGAR', 'DUROS')
values('D362', 'DECOHOGAR', 'COCINA', 'DUROS')
values('D360', 'DECOHOGAR', 'COLCHONERIA', 'DUROS')
values('D367', 'DECOHOGAR', 'COMPLEMENTOS DECO', 'DUROS')
values('D365', 'DECOHOGAR', 'DECORACION', 'DUROS')
values('D127', 'DECOHOGAR', 'GOURMET', 'DUROS')
values('D369', 'DECOHOGAR', 'MALETERIA', 'DUROS')
values('D386', 'DECOHOGAR', 'MASCOTAS', 'DUROS')
values('D361', 'DECOHOGAR', 'MESA', 'DUROS')
values('D149', 'DECOHOGAR', 'MUEBLERIA', 'DUROS')
values('D359', 'DECOHOGAR', 'MUEBLES', 'DUROS')
values('D151', 'DECOHOGAR', 'NAVIDAD', 'DUROS')
values('D195', 'DECOHOGAR', 'PROMOCIONES DECO', 'DUROS')
values('D366', 'DECOHOGAR', 'REGALOS', 'DUROS')
values('D411', 'DECOHOGAR', 'AUTOMOVIL', 'DUROS')
values('D103', 'ELECTRONICA', 'AUDIO', 'DUROS')
values('D200', 'ELECTRONICA', 'CUIDADO PERSONAL', 'DUROS')
values('D404', 'ELECTRONICA', 'ELECTRO MOVILIDADAD', 'DUROS')
values('D122', 'ELECTRONICA', 'ELECTRODOMESTICOS', 'DUROS')
values('D123', 'ELECTRONICA', 'ELECTRONICA MENOR', 'DUROS')
values('D128', 'ELECTRONICA', 'HERRAMIENTAS', 'DUROS')
values('D130', 'ELECTRONICA', 'INSTRUMENTOS MUSICALES', 'DUROS')
values('D136', 'ELECTRONICA', 'LINEA BLANCA', 'DUROS')
values('D171', 'ELECTRONICA', 'TV-VIDEO', 'DUROS')
values('D345', 'TECNOLOGIA', 'ACC. COMPUTACION', 'DUROS')
values('D347', 'TECNOLOGIA', 'ACC. ELECTRONICA-TELEF-FOTOGR', 'DUROS')
values('D384', 'TECNOLOGIA', 'CHECK OUT TECNOLOGIA', 'DUROS')
values('D113', 'TECNOLOGIA', 'COMPUTACION', 'DUROS')
values('D126', 'TECNOLOGIA', 'FOTOGRAFIA', 'DUROS')
values('D199', 'TECNOLOGIA', 'PROMOCIONES TECNOLOGIA', 'DUROS')
values('D191', 'TECNOLOGIA', 'TELEFONIA MOVIL', 'DUROS')
values('D172', 'TECNOLOGIA', 'VIDEOJUEGOS', 'DUROS')
values('D407', 'HOME IMPROVEMENT', 'HERRAMIENTAS', 'DUROS')
values('D408', 'HOME IMPROVEMENT', 'HOME OFFICE', 'DUROS')
values('D409', 'HOME IMPROVEMENT', 'ORGANIZACIÓN', 'DUROS')
values('D410', 'HOME IMPROVEMENT', 'ILUMINACION', 'DUROS')
values('D413', 'HOME IMPROVEMENT', 'MASCOTAS', 'DUROS')
values('D414', 'HOME IMPROVEMENT', 'CHECKOUT HOME IMPROVEMENT', 'DUROS')
values('D174', 'OTROS NEGOCIOS', 'ACCESORIOS VARON', 'OTROS NEGOCIOS')
values('D188', 'OTROS NEGOCIOS', 'CREDITO', 'OTROS NEGOCIOS')
values('D178', 'OTROS NEGOCIOS', 'INDUSTRIALIZACION', 'OTROS NEGOCIOS')
values('D355', 'OTROS NEGOCIOS', 'INSUMOS', 'OTROS NEGOCIOS')
values('D182', 'OTROS NEGOCIOS', 'INTERNET', 'OTROS NEGOCIOS')
values('D135', 'OTROS NEGOCIOS', 'LIBROS', 'OTROS NEGOCIOS')
values('D184', 'OTROS NEGOCIOS', 'MARKETING', 'OTROS NEGOCIOS')
values('D154', 'OTROS NEGOCIOS', 'NUESTRA CASA', 'OTROS NEGOCIOS')
values('D181', 'OTROS NEGOCIOS', 'PERU', 'OTROS NEGOCIOS')
values('D183', 'OTROS NEGOCIOS', 'PROMOCION', 'OTROS NEGOCIOS')
values('D179', 'OTROS NEGOCIOS', 'SERVICIOS', 'OTROS NEGOCIOS')
values('D426', 'MEJORAMIENTO DEL HOGAR', 'BANO Y COCINA', 'NUEVOS NEGOCIOS')
values('D405', 'OTROS NEGOCIOS', 'UNIFORME', 'S/I')
values('D194', 'ELECTROHOGAR', 'PROMOCIONES ELECTRONICA', 'S/I')
values('D101', 'MUJER', 'ACCESORIOS.', 'S/I')
values('D412', 'HOME IMPROVEMENT', 'CORTINAS', 'S/I')
values('D457', 'AUTOMOTRIZ', 'LIMPIEZA', 'NUEVOS NEGOCIOS')
values('D431', 'MEJORAMIENTO DEL HOGAR', 'ORGANIZACION', 'NUEVOS NEGOCIOS')
values('D430', 'MEJORAMIENTO DEL HOGAR', 'HOME OFFICE', 'NUEVOS NEGOCIOS')
values('D417', 'MASCOTAS', 'VIAJE PASEO Y VESTIMENTA', 'NUEVOS NEGOCIOS')
values('D432', 'MEJORAMIENTO DEL HOGAR', 'CONSTRUCCION Y FERRETERIA', 'NUEVOS NEGOCIOS')
values('D354', 'OTROS NEGOCIOS', 'VISUAL', 'S/I')
values('D418', 'MASCOTAS', 'HABITAT', 'NUEVOS NEGOCIOS')
values('D433', 'MEJORAMIENTO DEL HOGAR', 'HERRAMIENTAS Y MAQUINARIAS', 'NUEVOS NEGOCIOS')
values('D419', 'MASCOTAS', 'HIGIENE Y CUIDADO', 'NUEVOS NEGOCIOS')
values('D415', 'HOMBRES Y CALZADO', 'TEXTIL INTERNACIONAL', 'S/I')
values('D416', 'MASCOTAS', 'ENTRENAMIENTO DIVERSION Y ADIESTRAMIENTO', 'NUEVOS NEGOCIOS')
values('D420', 'MASCOTAS', 'NUTRICION', 'NUEVOS NEGOCIOS')
values('D427', 'MEJORAMIENTO DEL HOGAR', 'ILUMINACION', 'NUEVOS NEGOCIOS')
values('D428', 'MEJORAMIENTO DEL HOGAR', 'LIMPIEZA', 'NUEVOS NEGOCIOS')
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


%if %eval(&dia_actual.= 1) %then %do;
%uso_tr_trx(n=1, id_mes=1, dia= &dia_actual., table_name = uso_tr_m0);
%uso_tr_trx(n=2, id_mes=2, dia= &dia_actual., table_name = uso_tr_1m);
%uso_tr_trx(n=3, id_mes=3, dia= &dia_actual., table_name = uso_tr_2m);
%uso_tr_trx(n=13, id_mes=4, dia= &dia_actual., table_name = uso_tr_12m);

%end;
%else %do;
%uso_tr_trx(n=0, id_mes=1, dia= &dia_actual., table_name = uso_tr_m0);
%uso_tr_trx(n=1, id_mes=2, dia= &dia_actual., table_name = uso_tr_1m);
%uso_tr_trx(n=2, id_mes=3, dia= &dia_actual., table_name = uso_tr_2m);
%uso_tr_trx(n=12, id_mes=4, dia= &dia_actual., table_name = uso_tr_12m);
%end;


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


PROC EXPORT DATA =  WORK.apertura_dptos_div
OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/apertura_dptos_div.csv"
DBMS=dlm REPLACE;
delimiter=';';
PUTNAMES=YES;
RUN;


%macro envio_email();
DATA _null_;
fecha = put(intnx('day',today(),-1),yymmdd8. ) ;
Call symput("fecha", fecha) ;
run;

data _null_;
FILENAME OUTBOX EMAIL
SUBJECT="MAIL_AUTOM: Actualizacion Peso Chek en Rcom y Tienda MVP1"
FROM = ("equipo_datos_procesos_bi@bancoripley.com")
TO = ("CMUNOZO@BANCORIPLEY.COM", "fhott@bancoripley.com", "marellanob@bancoripley.com")
CC = ("sjaram@bancoripley.com","nverdejog@bancoripley.com", "rbarral@bancoripley.com", "rarcosm@bancoripley.com", "pperezd@bancoripley.com", "iortizs@bancoripley.com")
attach =("/sasdata/users94/user_bi/TRASPASO_DOCS/apertura_dptos_div.csv" content_type="excel")
Type    = 'Text/Plain';

FILE OUTBOX;
PUT 'Estimados:';
PUT ; 
PUT "Se adjunta archivo de Participacion de CHEK en Ripley.com y Ripley Tienda";  
PUT ; 
PUT "Datos actualizados al &fecha.";  
PUT ; 
PUT 'Atte.';
Put 'Data Analytics';
RUN;
FILENAME OUTBOX CLEAR;
%mend envio_email;

%envio_email();

