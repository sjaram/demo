/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	PROC_SPOS_AUT_CIERRE 			 ===============================*/

/* CONTROL DE VERSIONES
/* 2023-02-01 -- v14 -- David V.	-- Corrección a tabla de paso final para cierres
/* 2023-01-30 -- v13 -- David V.	-- Se cambia campo indcruce a String, por error en procesamiento.
/* 2022-12-29 -- v12 -- David V.	-- Se agrega tablas de paso para reproceso manual más acotado.
/* 2022-11-16 -- v11 -- David V.	-- Actualizado tabla de salida, se quita texto _spos
/* 2022-11-08 -- v10 -- David V.	-- Se actualizar export a AWS, según nuevas definiciones a RAW.
/* 2022-10-25 -- v09 -- Ale Marinao	-- Se agrego nuevas parametrias de Tarjetas.
/* 2022-08-26 -- v08 -- Ale Marinao	-- Se agrega campo Cliente
/* 2022-07-29 -- v07 -- Ale Marinao	-- Actualización por parte de governance, según investigación y validación con Tecnocom.
/* 2021-09-14 -- v06 -- Pedro M.	-- Modificación con modelo entregado por tecnocom
/* 2020-09-29 -- v04 -- Ale Marinao	-- Punto <04: Entregable>, agrega un campo y actualiza el case when
/* 2020-09-01 -- v00 -- 			-- Tabla resultante se cambia de Result a Publicin
/* 2020-08-28 -- v00 -- 		 	-- Versión renovada
/*
/* Tiempo Aprox de Ejecución 12 min

/* VARIABLE TIEMPO - INICIO */
%let tiempo_inicio= %sysfunc(datetime());
options validvarname=any;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
%let LIBRERIA=PUBLICIN;

DATA _null_;
	datei 	= input(put(intnx('month',today(),-1,'begin' ),yymmdd10.),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
	datef	= input(put(intnx('month',today(),-1,'end'	),yymmdd10.),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
	datex	= input(put(intnx('month',today(),-1,'end'	),yymmn6.),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
	exec	= compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechai", datei);
	Call symput("fechaf", datef);
	Call symput("Periodo", datex);
	Call symput("fechae",exec);
RUN;

%put &fechai;
%put &fechaf;
%put &Periodo;
%put &fechae;


PROC SQL NOERRORSTOP;
CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
	create table AUT_TC_SPOS as
		select 
			input(compress(T.fectrn,'-'),best.) as Fecha, 
			T.Hora, 
			floor(input(compress(T.fectrn,'-'),best.)/100) as Periodo, 
			input(T.codcom,best32.) format=20. as codigo_COMERCIO_MPDT,
			input(T.codcom2,best32.) format=20. as codigo_comercio, 
			T.NOMCOM AS Nombre_Comercio, 
			T.DESACT AS Actividad_Comercio,
			T.IMPTRN AS VENTA_TARJETA,
			T.CODPAIS, 
			T.TOTCUOTAS, 
			T.PAN,
			T.CODACT,
			T.PORINT,
			T.CODENT, 
			T.CENTALTA, 
			T.CUENTA,
			T.TIPO_TARJETA,
		(LEFT(SUBSTR(T.PAN,13,4))) as PAN2, 
			CATS(T.CODENT,T.CENTALTA,T.CUENTA,calculated PAN2) as CONTRATO_PAN,
			SUBSTR(T.MODENTDAT,1,2) as Ind_PAN,
			T.FINANCIAMIENTO,
			T.TASA,
			T.PRESENCIAL,
			T.FRANQUICIA,
			T.TIPOFAC, 
			T.CODRESPU,

			T.NUMAUT,
			T.SIAIDCD,
			T.NACIONAL, 

			T.TRANSACCION, 
			T.codmar, 
			T.indtipt, 
			T.destipt,
			T.LINEA, 
			T.DESLINEA, 
			T.DESC_FRANQUICIA, 
			T.DESTIPFAC,
			T.SIGNO, 
			T.VALOR_CUOTA,
			T.BRUTO, 
			/*T.PIE format=commax9.,*/
	(input(T.TASA_CARENCIA, best.)/10000)*1 as Tasa_Carencia,
	T.Meses_Carencia,
	(input(T.INTERES_CARENCIA,best24.))*1 as Interes_Carencia,
	T.MODENTDAT, 
	T.IDTERM, 
	T.LUGAR

	from connection to ORACLE( 
		SELECT 
			A.fectrn, 
			a.hortrn as Hora, 
			A.codent,  
			A.centalta,  
			A.cuenta,
			a.INDDEBCRE, 
			A.pan,
			A.CODRESPU,
			a.numaut,
			A.SIAIDCD, 
			A.CODPAIS, 
			CASE WHEN a.CODPAIS=152 THEN 'NACIONAL' ELSE 'INTERNACIONAL' END AS NACIONAL, 
				a.CODCOM,
				case when substr(a.CODCOM,1,4)='5970' then  substr(a.CODCOM,5,length(a.CODCOM)) else a.CODCOM end as codcom2,
					a.nomcom,
					a.codact,
					g.desact, 
					/*a.Sucursal,*/
					a.MODENTDAT, 
					a.IDTERM, 

						CASE WHEN SUBSTR(A.MODENTDAT,10,1) = '0' THEN 'PRESENCIAL' 
WHEN SUBSTR(A.MODENTDAT,10,1) <> '0' AND A.IDTERM  like '%ORACLE%'  THEN 'PAT' 
WHEN A.MODENTDAT IS NULL THEN 'SIN INFORMACION'
ELSE 'NO PRESENCIAL' END AS PRESENCIAL,

						CASE WHEN ( TIPOMSGON = 1220 AND CODPROON =  200000)  THEN 'NOTA CREDITO' ELSE 'COMPRA' END AS TRANSACCION, 
							a.codmar, 
							a.indtipt, 
							b.destipt, 

						CASE WHEN a.CODMAR=1  AND A.INDTIPT in (1,3,9,11) then 'TR'
						WHEN A.CODMAR=2  AND A.INDTIPT in (1,6,7,10,14) then 'TAM' 
						WHEN A.CODMAR=2  AND A.INDTIPT in (8) then 'MASTERCARD DEBITO'
						WHEN A.CODMAR=2	 AND A.INDTIPT	in (13) then 'DEBITO CTACTE'
						WHEN A.CODMAR=2	 AND A.INDTIPT	in (12) then 'MASTERCARD CHEK'
						WHEN A.CODMAR=4  AND A.INDTIPT in (1) then 'MAESTRO DEBITO' end as TIPO_TARJETA,

								D.LINEA, 
								E.DESLINEA,
								A.TIPFRAN AS FRANQUICIA ,   
								C.desfra as DESC_FRANQUICIA, 
								A.TIPOFAC, 
								D.DESTIPFAC,
								D.SIGNO, 
								A.TOTCUOTAS, 
								CASE     
									WHEN A.TOTCUOTAS = 0 THEN 'REVOLVING'
									WHEN A.TOTCUOTAS > 0 AND A.TOTCUOTAS < 2   THEN 'NO FINANCIABLE (1 CUOTA)'
									WHEN A.TOTCUOTAS >=2 THEN 'FINANCIABLE (2 O MAS CUOTAS)'
									ELSE 'SIN INFO' END AS FINANCIAMIENTO , /* TOTCUOTAS DEFINE SI ES COMPRA EN CUOTAS O REVOLVING*/
CASE WHEN D.SIGNO='-' THEN A.IMPTRN*(-1) ELSE A.IMPTRN END AS IMPTRN , /*IMPORTE DE LA TRANSACCIÓN*/
	A.PORINT, 
	CASE WHEN a.PORINT = 0 THEN 'SIN INTERES' ELSE 'CON INTERES' END AS TASA, 
		TO_NUMBER(SUBSTR(A.datadi,61,15),999999999999999) as VALOR_CUOTA, 
		CASE WHEN A.totcuotas > 0 AND D.SIGNO='+' THEN SUBSTR(A.datadi,61,15) * A.totcuotas ELSE A.IMPTRN END AS BRUTO,
		CASE WHEN D.SIGNO='-' THEN COALESCE(F.entrada,0)*(-1) ELSE COALESCE(F.entrada,0) END AS PIE , /*IMPORTE DE LA TRANSACCIÓN*/
			substr(a.datadi,88,7) as Tasa_Carencia,
			A.mescarcuo as Meses_Carencia,
			substr(A.datadi,168,15) as Interes_Carencia,
			CASE 
				WHEN D.LINEA='0052' THEN 'SAV'
				WHEN D.LINEA='0051' THEN 'AV'
				WHEN D.LINEA in ('0050','0053','0000') AND A.TIPFRAN<>4  THEN 'SPOS'
				WHEN D.LINEA in ('0050','0053','0000') AND A.CODCOM='000000000000001' THEN 'TIENDA'
				WHEN D.LINEA IS null AND A.CODCOM<>'000000000000001'  THEN 'SPOS'
				WHEN D.LINEA IS null AND A.TIPFRAN=4 THEN 'TIENDA'
				WHEN D.LINEA IS null AND A.TIPFRAN IN (6,7,1007) THEN 'SPOS'
				ELSE 'OTRO' END AS LUGAR

				FROM GETRONICS.MPDT004 A ,GETRONICS.MPDT026 B, GETRONICS.MPDT131 C, GETRONICS.MPDT044 D, GETRONICS.MPDT042 E,
					GETRONICS.MPDT205 F,GETRONICS.MPDT039 G

					WHERE A.FECTRN BETWEEN  %str(%')&fechai.%str(%') AND %str(%')&fechaf.%str(%')   /* PERIODO A CONSIDERAR (FECHA INICIO Y FECHA FIN)*/

						AND (
						(A.CODRESPU = 0 /*TRANSACCION APROBADA*/ AND A.INDANUL = 0 /*NO ANULADA*/) 
						OR (A.CODRESPU = 900 /*COMUNICACION ACEPTADA*/ AND A.INDANUL = 0 /*NO ANULADA*/) 
						OR (A.CODRESPU = 182 /*TRANSACCION DEVUELTA AND A.INDANUL = 1 *//*ANULADA*/)   /*AUTORIZADAS CORRECTAMENTE*/
						OR (A.indcruce = '1' AND A.INDANUL = 1))    /*AUTORIZADAS CORRECTAMENTE*/

						AND A.INDDEBCRE= 1    /*Indicador del tipo de tarjeta 1 es SOLO TRANSACCIONES DE CREDITO,2 es solo Debito*/
						AND D.LINEA in ('0050','0053','0000') 
						AND A.CODCOM<>'000000000000001'
						AND (   
						( TIPOMSGON = 1200 AND CODPROON =       0 ) OR   /* SOLO COMPRAS*/
						( TIPOMSGON = 1200 AND CODPROON =   10000 ) OR 
						( TIPOMSGON = 1200 AND CODPROON =   40000 ) OR 
						( TIPOMSGON = 1200 AND CODPROON = 340000 ) OR 

						( TIPOMSGON = 1420 AND CODPROON =          0 ) OR /* AVANCES*/
						( TIPOMSGON = 1420 AND CODPROON =   10000 ) OR 
						( TIPOMSGON = 1420 AND CODPROON =   40000 ) OR 
						( TIPOMSGON = 1420 AND CODPROON =  340000) OR  

						( TIPOMSGON = 1220 AND CODPROON =           0) OR  /*AVANCE REVOLVING*/
						( TIPOMSGON = 1220 AND CODPROON =    10000) OR 
						( TIPOMSGON = 1220 AND CODPROON =    40000) OR     
						( TIPOMSGON = 1220 AND CODPROON =  340000)
		)

		and A.codent = B.codent 
		and A.codmar = B.codmar  
		and A.indtipt = B.indtipt 

		and a.tipfran = C.tipfran 
		and C.codidioma = 1 

		and A.codent = D.codent 
		and a.INDNORCOR = d.INDNORCOR  
		AND A.TIPOFAC = D.TIPOFAC 

		and D.codent = E.codent(+) 
		AND D.LINEA = E.LINEA(+)

		and a.codent = F.codent(+)
		and a.centalta = F.centalta(+)
		and a.cuenta = F.cuenta(+)
		and a.siaidcd = F.siaidcd(+)

		and a.codent = g.codent 
		and a.codact = g.codact

		) T

	;
quit;



LIBNAME MPDT  ORACLE PATH='REPORITF.WORLD' SCHEMA='GETRONICS' USER='AMARINAOC' PASSWORD='amarinaoc2017';
LIBNAME BOPERS ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='AMARINAOC' PASSWORD='amarinaoc2017';

PROC SQL;
	create table COMPRAS_AUT_&Periodo. AS 
		select 
			Fecha, 
			A.Hora, 
			A.Periodo,
			A.codigo_COMERCIO_MPDT,
			A.codigo_comercio, 
			A.Nombre_Comercio, 
			A.Actividad_Comercio,
			(INPUT((c.PEMID_GLS_NRO_DCT_IDE_K ),BEST32.)) AS RUT,
			A.VENTA_TARJETA,
			A.CODPAIS, 
			A.TOTCUOTAS, 
			A.PAN,
			A.CODACT,
			A.PORINT,
			A.CODENT, 
			A.CENTALTA, 
			A.CUENTA,
			A.TIPO_TARJETA,
			A.PAN2, 
			A.CONTRATO_PAN,
CASE WHEN A.PRESENCIAL IN ('PRESENCIAL','SIN INFORMACION')  THEN 0
WHEN  A.PRESENCIAL IN ('NO PRESENCIAL','PAT') THEN 1 end as si_digital,
		A.Ind_PAN,
		A.FINANCIAMIENTO,
		A.TASA,
		A.PRESENCIAL,
		A.FRANQUICIA,
		A.TIPOFAC, 
		A.CODRESPU,
		C.PEMID_DVR_NRO_DCT_IDE as DV,
		A.NUMAUT,
		A.SIAIDCD,
		A.NACIONAL, 
		A.TRANSACCION, 
		A.codmar, 
		A.indtipt, 
		A.destipt as Tipo_Tarjeta_RSAT,
	
	CASE WHEN F.NUMBENCTA=1 THEN 'TI' ELSE 'BE' END AS CLIENTE,
		A.LINEA, 
		A.DESLINEA, 
		A.DESC_FRANQUICIA, 
		A.DESTIPFAC,
		A.SIGNO, 
	CASE 
		WHEN PORINT<>0 THEN (A.BRUTO-A.VENTA_TARJETA) 
		ELSE 0 
	END 
AS MG_FIN,
	A.VALOR_CUOTA,
	A.BRUTO, 
	A.TASA_CARENCIA,
	A.Meses_Carencia,
	A.Interes_Carencia,
	A.MODENTDAT, 
	A.IDTERM
FROM AUT_TC_SPOS a
	LEFT JOIN MPDT.MPDT007 b on (a.cuenta=b.cuenta) and (a.centalta=b.centalta) and (a.codent=b.codent) 
	LEFT JOIN BOPERS.BOPERS_MAE_IDE  c ON (INPUT((b.IDENTCLI),BEST32.))=C.PEMID_NRO_INN_IDE
	LEFT JOIN MPDT.MPDT009 F ON (A.codent = F.CODENT AND A.centalta = F.centalta AND A.cuenta = F.cuenta AND A.pan = F.pan)
	;
QUIT;

%put==================================================================================================;
%put NOTAS DE CREDITO DESDE APROBACIONES;
%put==================================================================================================;

PROC SQL NOERRORSTOP;
	CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
	create table NC_SPOS_&Periodo. as
		select 
			(INPUT(COMPRESS(fecfac,"-"),YYMMDD10.)) FORMAT=DATE9. as FECHA,
			'00:00:00' as Hora,
			&Periodo. as PERIODO,
			input(codcom,best32.) format=20. as codigo_COMERCIO_MPDT,
			input(codcom,best32.) format=20. as codigo_comercio,
			NOMCOMRED as Nombre_Comercio,
			DESACT as Actividad_Comercio,
			RUT,
		CASE 
			WHEN SIGNO='-' THEN IMPFAC*(-1) 
			ELSE IMPFAC 
		END 
	AS VENTA_TARJETA,
		CODPAIS,
		TOTCUOTAS,
		PAN,
		CODACT,
		0 as PORINT,
		CODENT,
		CENTALTA,
		CUENTA,
		TIPO_TARJETA,
	(LEFT(SUBSTR(PAN,13,4))) as PAN2, 
		CATS(CODENT,CENTALTA,CUENTA,calculated PAN2) as CONTRATO_PAN,
		SUBSTR(MODENTDAT,1,2) as Ind_PAN,
	CASE     
		WHEN TOTCUOTAS = 0 THEN 'REVOLVING'
		WHEN TOTCUOTAS > 0 AND TOTCUOTAS < 2   THEN 'NO FINANCIABLE (1 CUOTA)'
		WHEN TOTCUOTAS >=2 THEN 'FINANCIABLE (2 O MAS CUOTAS)'
		ELSE 'SIN INFO'
	END 
AS FINANCIAMIENTO ,
	'' as TASA,
CASE 
	WHEN SUBSTR(MODENTDAT,10,1) = '0' THEN 'PRESENCIAL'
 	WHEN MODENTDAT IS MISSING THEN 'PRESENCIAL' 
	WHEN SUBSTR(MODENTDAT,10,1) <> '0' AND IDTERM  like '%ORACLE%'  THEN 'PAT' 
	ELSE  'NO PRESENCIAL' 
END AS PRESENCIAL,
tipfran as FRANQUICIA,
TIPOFAC,
' ' as CODRESPU,
DV,
NUMAUT,
SIAIDCD,
CASE 
WHEN CODPAIS=152 THEN 'NACIONAL' 
ELSE 'INTERNACIONAL' 
END 
AS NACIONAL, 
CASE 
WHEN (SIGNO='-')  THEN 'NOTA CREDITO' 
ELSE 'COMPRA' 
END 
AS TRANSACCION, 
CODMAR,
INDTIPT,
DESTIPT AS Tipo_Tarjeta_RSAT,
LINEA,
DESLINEA,
DESFRA as DESC_FRANQUICIA,
DESTIPFAC,
SIGNO,
CASE 
WHEN SIGNO='-' THEN IMPFAC*(-1) 
END 
AS VALOR_CUOTA , 
0 as MG_FIN,
0 AS Tasa_Carencia,
0 AS MESES_CARENCIA,
0 AS Interes_Carencia,
CASE 
WHEN SIGNO='-' THEN IMPFAC*(-1) 
END 
AS BRUTO,/*por ser NC*/
	MODENTDAT,
	IDTERM,
	Lugar,
	CASE WHEN NUMBENCTA=1 THEN 'TI' ELSE 'BE' END AS CLIENTE
	from connection to ORACLE( 
		select 
			cast(G.PEMID_GLS_NRO_DCT_IDE_K as INT) AS RUT,
			G.PEMID_DVR_NRO_DCT_IDE as DV,
			A.codent,
			A.centalta,
			A.cuenta,
			A.codpais,
			A.TOTCUOTAS,
			A.fecfac,
			A.PAN,
			A.NUMAUT,/*Número de autorización*/
			A.SIAIDCD,
			A.CODCOM,
			A.nomcomred,
			A.codact,
			D.desact,
			F.CODMAR,
			F.INDTIPT,
			J.DESTIPT,

			CASE 
				WHEN F.CODMAR=1 AND F.INDTIPT 	in (1,3,9,11) then 'TR'
				WHEN F.CODMAR=2	 AND F.INDTIPT	in (1,6,7,10,14) then 'TAM'
				WHEN F.CODMAR=2	 AND F.INDTIPT	in (8) then 'MASTERCARD DEBITO'
				WHEN F.CODMAR=2	 AND F.INDTIPT	in (13) then 'DEBITO CTACTE'
				WHEN F.CODMAR=2	 AND F.INDTIPT	in (12) then 'MASTERCARD CHEK'
				WHEN F.CODMAR=4	 AND F.INDTIPT	in (1) then 'MAESTRO DEBITO' 
			end 
			as TIPO_TARJETA, 

				A.linea,
				H.DESLINEA,
				A.tipfran,/*Tipo de franquicia*/
				I.DESFRA,
				A.tipofac,/*Tipo de factura*/
				E.DESTIPFAC,
				E.INDNORCOR,/*Indicador de normal o correctora: 0 - Normal  1 – Correctora*/
				E.signo,/*Signo del importe (+/-)*/
	A.IMPFAC, /*Importe de la factura, es el capital*/
A.ENTRADA,/*Entrada:
	(pie). Importe que corresponde a la parte de la compra que el cliente abona en efectivo en cajA. Tiene carácter informativo*/
	X.MODENTDAT,
	X.IDTERM,
	CASE 
		WHEN A.CODCOM <> '000000000000001' THEN 'SPOS' 
		ELSE 'TIENDA' 
	END 
	AS LUGAR,
F.NUMBENCTA
		/*Movimientos del Extracto de Crédito*/
	from GETRONICS.mpdt012 A
		/*Autorizacines*/
	LEFT JOIN GETRONICS.MPDT004 X ON A.SIAIDCD=X.SIAIDCD
		/* relacion para obtener los datos del contrato a partir del movimiento */
	LEFT JOIN GETRONICS.MPDT007 B ON (A.codent = B.codent and A.centalta=B.centalta and A.cuenta = B.cuenta)
		/* relacion para obtener la descripción del codigo de actividad ISO */
	LEFT JOIN GETRONICS.MPDT039 D ON (A.codent = D.codent and A.codact=D.codact)
		/*relacion para obtener la marca y el tipo de tarjeta*/
	LEFT JOIN GETRONICS.MPDT009 F ON (A.codent=F.CODENT AND A.centalta=F.centalta AND A.cuenta=F.cuenta AND A.pan=F.pan)
		/*relacion para determinar el rut asociado al titular del contrato*/
	LEFT JOIN BOPERS_MAE_IDE G ON G.PEMID_NRO_INN_IDE= B.identcli
		/*relacion para poder filtrar las facturas de compras*/
	LEFT JOIN GETRONICS.MPDT044 E ON (A.tipofac=E.tipofac and A.indnorcor=E.indnorcor ) /*Indicador de factura informativa (S/N)*/
		/*Franquicias*/
	LEFT JOIN GETRONICS.MPDT131 I ON (A.TIPFRAN = I.TIPFRAN AND I.CODIDIOMA='1')  
		/* relacion para obtener los conceptos de comisiones asociadas al movimiento*/
	left join GETRONICS.MPDT151 C ON (A.codent=C.codent and A.centalta= C.centalta and A.cuenta=C.cuenta and A.clamon=C.clamon and A.numextcta = C.numextcta and A.nummovext = C.nummovext and C.tipimp = 2 and C.codconeco= 200) 
		/*Tipos de Tarjeta*/
	LEFT JOIN GETRONICS.MPDT026 J ON (J.codent=F.codent AND J.CODMAR=F.CODMAR AND J.INDTIPT=F.INDTIPT )  
		/*DESCRIPCION TIPOS DE LINEAS*/
	LEFT JOIN GETRONICS.MPDT042 H ON (A.CODENT=H.CODENT AND A.LINEA=H.LINEA)
		/*filtros adicionales*/
	where A.tipofac not in (210,115,117) /*210 RepactaciONes, 115 y 117 CARGO REGULARIZACION SIR */
	AND A.CODCOM <> '000000000000001' /*para spos */
	AND A.LINEA in ('0050', '0053', '0000') /* solo linea de compras */
	AND A.indnorcor = 0
	/*AND A.tipfran <> 9999 and A.tipfran <> 8006  and A.tipfran <> 0   se excluyen franquicias de ajustes */
	AND ( ( E.tipofacsist = 1500 and A.indmovanu = 0) or (a.tipofac = 1515 and A.indmovanu = 2))
	AND A.fecfac BETWEEN  %str(%')&fechai.%str(%') AND %str(%')&fechaf.%str(%')  /*aqui se debe indicar el rango de busqueda de transacciones revolving */
	) T ;
quit;

proc sql;
	create table NC_APROB_&Periodo. as
		select input(put(FECHA,yymmddn8.),best.) as Fec_Num,
			Hora,
			PERIODO,
			codigo_COMERCIO_MPDT,
			codigo_comercio,
			Nombre_Comercio,
			Actividad_Comercio,
			RUT,
			VENTA_TARJETA,
			CODPAIS,
			TOTCUOTAS,
			PAN,
			CODACT,
			PORINT,
			CODENT,
			CENTALTA,
			CUENTA,
			TIPO_TARJETA,
			PAN2, 
			CONTRATO_PAN,

CASE WHEN PRESENCIAL IN ('PRESENCIAL','SIN INFORMACION')  THEN 0
WHEN  PRESENCIAL IN ('NO PRESENCIAL','PAT') THEN 1 end as si_digital,
		Ind_PAN,
		FINANCIAMIENTO,
		TASA ,
		PRESENCIAL,
		FRANQUICIA,
		TIPOFAC,
		CODRESPU,
		DV,
		NUMAUT,
		SIAIDCD,
		NACIONAL, 
		TRANSACCION, 
		CODMAR,
		INDTIPT,
		Tipo_Tarjeta_RSAT,
		CLIENTE,
		LINEA,
		DESLINEA,
		DESC_FRANQUICIA,
		DESTIPFAC,
		SIGNO,
		MG_FIN,
		VALOR_CUOTA,
		BRUTO,/*por ser NC*/
	Tasa_Carencia,
	MESES_CARENCIA,
	Interes_Carencia,
	MODENTDAT,
	IDTERM
	FROM NC_SPOS_&Periodo.
	;
quit;

%put==================================================================================================;
%put creacion union de Autorizacion compras con Notas de credito Aprobacion;
%put==================================================================================================;

proc sql;
	create table work.SPOS_AUT_DE_PASO (
/*	create table &libreria..SPOS_AUT_VN_&PERIODO. (*/
		Fecha	Num,	
		Hora	Char(8),
		Periodo	Num,	
		codigo_COMERCIO_MPDT Num,
		codigo_comercio	Num,
		Nombre_Comercio	Char(50),
		Actividad_Comercio	Char(50),
		RUT	Num,	
		VENTA_TARJETA Num,	
		CODPAIS	Num,
		TOTCUOTAS Num,
		PAN	Char(22),
		CODACT	Num,
		PORINT Num,
		CODENT Char(4),
		CENTALTA Char(4),
		CUENTA	Char(15),
		Tipo_Tarjeta Char(10),	
		PAN2 Char(22),
		CONTRATO_PAN Char(200),
		si_digital Num,	
		Ind_PAN	Char(2),
		FINANCIAMIENTO Char(30),
		TASA Char(11),
		PRESENCIAL Char(30),
		FRANQUICIA	Num,
		TIPOFAC	Num,
		CODRESPU Char(3),

		/*Campos Nuevos*/

		DV Char(1),
		NUMAUT Char(10),
		SIAIDCD	Char(20),
		NACIONAL Char(20),
		TRANSACCION	Char(20),
		CODMAR Num,
		INDTIPT	Num,
		Tipo_Tarjeta_RSAT	Char(30),
		Cliente Char(10),
		LINEA Char(4),
		DESLINEA Char(30),
		DESC_FRANQUICIA	Char(30),
		DESTIPFAC Char(30),
		SIGNO Char(1),
		MG_FIN Num,
		VALOR_CUOTA	Num,
		BRUTO Num,
		Tasa_Carencia Num,
		MESES_CARENCIA Num,
		Interes_Carencia Num,
		MODENTDAT Char(15),
		IDTERM Char(16)
		
		)
	;
QUIT;

proc sql;
	insert into work.SPOS_AUT_DE_PASO
/*	insert into &libreria..SPOS_AUT_VN_&PERIODO.*/
		select *
			from COMPRAS_AUT_&Periodo.
	;
QUIT;

proc sql;
	insert into work.SPOS_AUT_DE_PASO
/*	insert into &libreria..SPOS_AUT_VN_&PERIODO.*/
		select *
			from NC_APROB_&Periodo.
	;
QUIT;

%put==================================================================================================;
%put creacion union de Autorizacion compras con Notas de credito Aprobacion;
%put==================================================================================================;

PROC SQL NOERRORSTOP;
	CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
	create table COMERCIOS_PAT  as 
		select * 
			from connection to ORACLE( 
				select 
					t1.TGDTG_GLS_CCN_K,
					cast(t1.TGDTG_GLS_CCN_K as INT) COD_TG300,
					t1.TGDTG_GLS_COO_UNO,
					t1.TGDTG_GLS_LAR_UNO,
					t1.TGDTG_FCH_ACL_REG,
					t1.tgetg_cor_tbl_k,
					t2.TGMDO_GLS_DOM 
				from botgen_det_tbl_gra t1
					LEFT JOIN BOTGEN_MOV_DOM t2
						on t1.TGDTG_COD_COO_CIN=t2.TGMDO_COD_DOM_K
					WHERE t1.tgetg_cor_tbl_k in (300,320) 
						and t2.TGMMD_COD_MAC_DOM_K = 1925
						) A
	;
QUIT;

PROC SQL;
	CREATE TABLE work.SPOS_AUT_DE_PASO AS 
/*	CREATE TABLE &libreria..SPOS_AUT_VN_&PERIODO. AS */
		SELECT
			A.Fecha,
			A.Hora,
			A.Periodo,
			A.codigo_COMERCIO_MPDT,
			A.codigo_comercio,
			A.Nombre_Comercio,
			A.Actividad_Comercio,
			A.RUT,
			A.VENTA_TARJETA,
			A.CODPAIS,
			A.TOTCUOTAS,
			A.PAN,
			A.CODACT,
			A.PORINT,
			A.CODENT,
			A.CENTALTA,
			A.CUENTA,
			A.Tipo_Tarjeta,
			A.PAN2,
			A.CONTRATO_PAN,
			A.si_digital,
			A.Ind_PAN,
			A.FINANCIAMIENTO,
			A.TASA,
			A.PRESENCIAL,
			A.FRANQUICIA,
			A.TIPOFAC,
			A.CODRESPU,
			B.TGDTG_GLS_COO_UNO,
			B.TGDTG_GLS_LAR_UNO,
			B.TGMDO_GLS_DOM,
			B.TGDTG_FCH_ACL_REG,
			/*Variables Nuevas*/
	A.DV,
	A.NUMAUT,
	A.SIAIDCD,
	A.NACIONAL,
	A.TRANSACCION,
	A.CODMAR,
	A.INDTIPT,
	A.Tipo_Tarjeta_RSAT,
	A.CLIENTE,
	A.LINEA,
	A.DESLINEA,
	A.DESC_FRANQUICIA,
	A.DESTIPFAC,
	A.SIGNO,
	A.MG_FIN,
	A.VALOR_CUOTA,
	A.BRUTO,
	A.Tasa_Carencia,
	A.MESES_CARENCIA,
	A.Interes_Carencia,
	A.MODENTDAT,
	A.IDTERM
	FROM work.SPOS_AUT_DE_PASO A LEFT JOIN COMERCIOS_PAT as B ON (A.codigo_comercio=B.COD_TG300)
/*	FROM &libreria..SPOS_AUT_VN_&PERIODO. A LEFT JOIN COMERCIOS_PAT as B ON (A.codigo_comercio=B.COD_TG300)*/
		ORDER BY A.Fecha ASC,RUT ASC
	;
QUIT;

PROC SQL;
	CREATE TABLE &libreria..SPOS_AUT_EARQ_&PERIODO. AS 
		SELECT * FROM work.SPOS_AUT_DE_PASO 
	;
QUIT;

PROC SQL;
	CREATE TABLE &libreria..SPOS_AUT_&PERIODO. AS 
		SELECT * FROM &libreria..SPOS_AUT_EARQ_&PERIODO. 
	;
QUIT;

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================        EXPORT_TO_AWS - INI          ===============================*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_spos_aut,raw,sasdata,-1);

/*Exportación a AWS*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_spos_aut,&libreria..spos_aut_&periodo.,raw,sasdata,-1);

/*==============================        EXPORT_TO_AWS - END          ===============================*/
/*==================================================================================================*/

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/

/*	FECHA DEL PROCESO	*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_SPOS';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_GOBIERNO_DAT_1';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;

/* VARIABLE TIEMPO - FIN */
data _null_;
dur = datetime() - &tiempo_inicio;
put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
/*TO = ("&DEST_1")*/
TO = ("&DEST_4","&DEST_5")
CC = ("&DEST_1", "&DEST_2", "&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso PROC_SPOS_AUT_CIERRE");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "		Proceso PROC_SPOS_AUT_CIERRE, ejecutado con fecha: &fechaeDVN";  
 PUT "  	Información disponible en SAS: &libreria..SPOS_AUT_&PERIODO.";  
 PUT ; 
 PUT ;
 PUT ;
 PUT 'Proceso Vers. 14'; 
 PUT;
 PUT;
 PUT 'Atte.';
 PUT 'Equipo Arquitectura de Datos y Automatización BI';
 PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
