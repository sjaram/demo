	%let libreria=result;

	/*==================================================================================================*/
/*==================================    EQUIPO DATOS Y PROCESOS        ================================*/
/*==================================    EMAIL_AUTOM_PANEL_MAESTRO         ================================*/
/* CONTROL DE VERSIONES
/* 2023-06-13 ---- v5 -- Esteban P. -- Actualización de credenciales gedcre.
/* 2023-02-08 ---- v3 -- PEDRO M. 	-- SE CAMBIA JUNTE DE DATOS A USO_TR
/* 2023-03-15 ---- v4 -- IGNACIO P. -- SE MODIFICA MACRO, DEJANTO 0 Y 1 A CORRER

*/
/*==================================================================================================*/

	%macro PANEL_MAESTRO_TRDA(n,libreria);
	DATA _null_;
	PERIODO = input(put(intnx('month',today(),-&n.,'end'),yymmn6. ),$10.);
    PERIODO_2 = input(put(intnx('month',today(),-&n.-1,'end'),yymmn6. ),$10.);
	Call symput("periodo", PERIODO);
	Call symput("PERIODO_2", PERIODO_2);
	RUN;

	%put &periodo;
	%put &PERIODO_2;


	%put==================================================================================================;
	%put [02] Extraer Base de ventas Tienda en &Periodo. con Variables Relevantes ;
	%put==================================================================================================;



	proc sql;


	create table work.Detalle_Vtas_TDA as 
	SELECT 
	*
	from  result.uso_tr_marca_&periodo.
	;QUIT;


	%put===========================================================================================;
	%put [03] VENTA Tmp &periodo.con PLAZO y DIFERIDO ;
	%put===========================================================================================;

	%let mz_connect_zeus=CONNECT TO ODBC as zeus(datasrc="creditoprd" user="CONSULTA_CREDITO" password="crdt#0806");
	 

	proc sql ;
	&mz_connect_zeus;
	create table VTA_UM AS 
	SELECT B.*,(INPUT(B.CODIGO_ARTICULO,BEST13.)) FORMAT=13. AS SKU,
	CAT(B.SUCURSAL+10000,' ',B.COD_FCH_CPV,' ',B.NRO_CAJA_NUMERICO,' ',B.NRO_DOCTO) AS BOLETA

	FROM connection to zeus(
	SELECT 
	FLOOR(COD_FCH_CPV/100) as Periodo,
	A.RUT_TITULAR,
	A.COMPRADOR_PAGADOR AS RUT,

	A.DESMAR AS TIPO_TR,
	A.SUCURSAL,
	A.COD_FCH_CPV,
	A.NRO_CAJA_NUMERICO,


	A.CODIGO_TRX,
	/*
	A.CODMAR,
	A.PRODUCTO,
	A.COD_FCH_CPV-100*floor(A.COD_FCH_CPV/100) as Dia_Nro,
	A.FECHA,
	*/
	A.NRO_DOCTO,
	A.UNIDADES,
	A.NRO_ITEM,

	A.NRO_MESES_DIFERIDO,
	A.PLAZO,

	A.DIRECCION_E_S,
	(CASE WHEN A.DIRECCION_E_S = 1 THEN -(A.PRECIO_ARTICULO - A.DESCUENTO_BOLETA - A.DESCUENTO_ARTICULO)
	ELSE (A.PRECIO_ARTICULO - A.DESCUENTO_BOLETA - A.DESCUENTO_ARTICULO)
	END ) AS MONTO_TRX, 
	A.MONTO_CAPITAL_1 AS MONTO_CAPITAL, 
	A.MONTO_INTERESES_1 AS MONTO_INTERESES,

	A.CODIGO_ARTICULO,
	A.COD_DEPTO,
	A.COD_LINEA,
	A.TIPO_TRX

	FROM GEDCRE_CREDITO.TRX_HEADER_DET_TAR_ADM  A 

	WHERE (A.COD_FCH_CPV BETWEEN 100*&Periodo+01 AND 100*&Periodo+31)
	AND A.TIPO_TRX in (1,3) /*compras Y NOTAS DE CREDITO*/
	/* AND A.CODMAR IN (1,2)  TARJETA RIPLEY 2	TARJETA MASTERCARD*/
	AND A.CODIGO_TRX NOT IN (39,401,402,89,90,93) 

	) B
	;QUIT;


	%put-------------------------------------------------------------------------------------------;
	%put [05] CRUCE MAE ARTICULO Y HEADER POR BOLETA y RUT;
	%put-------------------------------------------------------------------------------------------;
proc sql;
create table vista as 
select  distinct Boleta,NRO_MESES_DIFERIDO,PLAZO,RUT_TITULAR,RUT from VTA_UM
;QUIT; 

	PROC SQL;
	CREATE TABLE VTA_TDA_TMP AS
	SELECT T1.*,
	COALESCE(A.NRO_MESES_DIFERIDO,0 ) AS NRO_MESES_DIFERIDO ,
	CASE WHEN  t1.Medio_Pago='TAR' then COALESCE(A.PLAZO,0) else A.PLAZO end AS PLAZO,
	CASE WHEN  CALCULATED NRO_MESES_DIFERIDO=0 THEN 'NORMAL' WHEN CALCULATED NRO_MESES_DIFERIDO>0 THEN 'DIFERIDO' ELSE 'OTRO' END AS TIPO_PAGO
	FROM Detalle_Vtas_TDA AS T1
	LEFT JOIN vista as A
	ON T1.BOLETA=A.BOLETA 

	;QUIT;



	%put---------------------------------------------------------------------------------------;
	%put [06] Pegar Division Y TRAMIFICACION DEL PLAZO &periodo.;
	%put---------------------------------------------------------------------------------------;


	proc sql;
	create table work.DETALLE3 as
	SELECT 
	a.*,
	CASE WHEN A.PLAZO BETWEEN 0 AND 3 THEN 'A.0-3'
	WHEN A.PLAZO BETWEEN 4 AND 6 THEN 'B.4-6'
	WHEN A.PLAZO BETWEEN 7 AND 12 THEN 'C.7-12'
	WHEN A.PLAZO BETWEEN 13 AND 18 THEN 'D.13-18'
	WHEN A.PLAZO BETWEEN 19 AND 24 THEN 'E.19-24'
	WHEN A.PLAZO BETWEEN 25 AND 35 THEN 'F.25-35'
	WHEN A.PLAZO BETWEEN 36 AND 48 THEN 'G.36-48'
	WHEN A.PLAZO>48 THEN 'H.OTRO' END AS PLAZO_CUOTAS
	from WORK.VTA_TDA_TMP as A 

	;QUIT;

	proc sql;
	create table detalle4 as 
	select 
	a.*,
	b.*
	from detalle3 as a 
	left join result.sku as b
	on(a.sku=b.sku)
	;QUIT;


	%put-------------------------------------------------------------------------------------------;
	%put [08] Guardar informacion en duro &periodo.;
	%put-------------------------------------------------------------------------------------------;

	%if (%sysfunc(exist(&LIBRERIA..PANEL_MAESTRO_TDA_1m))) %then %do;
	 
	%end;
	%else %do;
	PROC  SQL;
	CREATE TABLE &libreria..PANEL_MAESTRO_TDA_1m 
	(
	periodo	 num,
	Dia_Nro num,
	NRO_MESES_DIFERIDO num,
	TIPO_PAGO char(99),
	Medio_Pago char(99),
	PLAZO_CUOTAS char(99),
	PLAZO num,
	SKU num,
	DESCRIPCION_FIN char(99),
	DEPARTAMENTO char(99),
	LINEA char(99),
	MARCA char(99),
	JER_DIVISION char(99),
	BLANDO_DURO char(99),
	NOM_SUC char(99),
	LUGAR char(99),
	TIPO_TRX num,
	tipo_compra char(99),
	CLIENTES num,
	Boletas num,
	Bol_NC num,
	BOL_VTA num,
	Unidades num,
	MONTO num,
	MONTO_CAPITAL num,
	MG_FINANCIERO num
	)
	;quit;
	%end;

	proc sql;
	delete *
	from &libreria..PANEL_MAESTRO_TDA_1m 
	where periodo<=&PERIODO_2.
	;QUIT;

	proc sql;
	delete *
	from &libreria..PANEL_MAESTRO_TDA_1m 
	where periodo=&periodo.
	;QUIT;

	PROC SQL;
	insert into &LIBRERIA..PANEL_MAESTRO_TDA_1m 
	SELECT 
	t1.Periodo, 
	t1.Dia_Nro, 
	t1.NRO_MESES_DIFERIDO, 
	T1.TIPO_PAGO,
	T1.Medio_Pago,
	t1.PLAZO_CUOTAS,
	t1.PLAZO, 
	t1.SKU,
	T1.MOD_DESCRIPCION as DESCRIPCION_FIN,
	t1.DEPARTAMENTO_FIN as DEPARTAMENTO, 
	 cat(t1.COD_LINEA,'-',	t1.LIN_DESCRIPCION ) as  LINEA,
	t1.MAR_DESCRIPCION as marca, 
	t1.NOMBRE_DIVISION as JER_DIVISION,
	T1.BLANDO_DURO,
	t1.Nombre_Sucursal as NOM_SUC,
	T1.LUGAR,
	T1.TIPO_TRX,
	T1.tipo_compra,
	(COUNT(DISTINCT(t1.RUT_CPD))) as CLIENTES,
	( COUNT(DISTINCT(t1.BOL_VTA))-COUNT(DISTINCT(t1.BOL_NC)) )  AS Boletas, 
	(COUNT(DISTINCT(t1.BOL_NC))) AS Bol_NC,
	COUNT(DISTINCT(t1.BOL_VTA)) as BOL_VTA, 
	(SUM(t1.NRO_UNI)) FORMAT=8.0 AS Unidades, 
	(SUM(t1.Mto)) FORMAT=20. AS MONTO, 
	(SUM(t1.capital)) FORMAT=11. AS MONTO_CAPITAL, 
	(SUM(t1.MAG_FN)) FORMAT=11. AS MG_FINANCIERO
	FROM WORK.detalle4 t1
	GROUP BY 
	t1.Periodo, 
	t1.Dia_Nro, 
	t1.NRO_MESES_DIFERIDO, 
	T1.TIPO_PAGO,
	T1.Medio_Pago,
	t1.PLAZO_CUOTAS,
	t1.PLAZO, 
	t1.SKU,
	T1.MOD_DESCRIPCION ,
	t1.DEPARTAMENTO_FIN, 
	calculated LINEA,
t1.MAR_DESCRIPCION , 
		t1.NOMBRE_DIVISION,
	T1.BLANDO_DURO,
	t1.Nombre_Sucursal,
	T1.LUGAR,
	T1.TIPO_TRX,
	T1.tipo_compra
	;QUIT;

	proc sql;
	create table &libreria..PANEL_MAESTRO_TDA_1m  as 
	select 
	*
	from &libreria..PANEL_MAESTRO_TDA_1m 
	;QUIT;

	proc datasets library=WORK kill noprint;
run;
quit;

	%mend PANEL_MAESTRO_TRDA;

	%PANEL_MAESTRO_TRDA(	0	,	&libreria.	);		
	%PANEL_MAESTRO_TRDA(	1	,	&libreria.	);		


	
	
