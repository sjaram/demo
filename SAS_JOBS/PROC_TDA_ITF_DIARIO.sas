/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================	PROC_TDA_ITF_DIARIO	 		 	 ===============================*/

/* CONTROL DE VERSIONES
/* 2023-06-08 -- v13 -- Esteban P	-- Se corrige el nombre de una variable inexistente para exportación dentro de la macro final.
/* 2023-03-28 -- v12 -- Pedro M.	-- Se agrega envío a ftp control comercial
/* 2022-12-21 -- v11 -- Sergio J.	-- Se cambia ppff a mdpg en la exportación a aws
/* 2022-11-16 -- v10 -- David V.	-- Agregar campo periodo en la salida de la tabla
/* 2022-11-11 -- v08 -- Sergio J.	-- Se elimina una coma que producía error en la ejecución
/* 2022-11-08 -- v07 -- David V.	-- Se actualizar export a AWS, a RAW.
/* 2022-11-08 -- v06 -- David V.	-- Se quita numero de cuenta que estaba en duro
/* 2022-11-08 -- v05 -- David V.	-- Se actualizar export a AWS, según nuevas definiciones a PRE-RAW.
/* 2022-10-25 -- v04 -- Ale Marinao	-- Se agrego nuevas parametrias de Tarjetas.
/* 2022-08-26 -- v03 -- Ale Marinao	-- Se agrego el campo cliente.
/* 2022-07-29 -- v02 -- Ale Marinao	-- Actualización por parte de governance, según investigación y validación con Tecnocom.
/* 2020-07-07 -- v01 -- 			-- Se actualiza usuario conexión a REPORITF (AMARINAOC)
/*

/* VARIABLE TIEMPO - INICIO */
%let tiempo_inicio= %sysfunc(datetime());
options validvarname=any;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
%let LIBRERIA=PUBLICIN;

DATA _null_;
	datei 	= input(put(intnx('month',today(),0,'begin' ),yymmdd10.),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
	datef	= input(put(intnx('month',today(),0,'end'	),yymmdd10.),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
	datex	= input(put(intnx('month',today(),0,'end'	),yymmn6.),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
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
	create table CUOTA as
		select				
			PAN,				
			CODENT,				
			CENTALTA,				
			CUENTA,				
			RUT,				
		CASE 
			WHEN SIGNO='-' THEN IMPFAC*(-1) 
			ELSE IMPFAC 
		END 
	AS CAPITAL,				
		CASE 
			WHEN SIGNO='-' THEN ENTRADA*(-1) 
			ELSE ENTRADA 
		END 
	AS PIE,				
		TOTCUOTAS AS CUOTAS,				
		(INPUT(COMPRESS(FECFAC,"-"),YYMMDD10.)) FORMAT=YYMMDD10. AS FECHA,
		INPUT(NUMBOLETA,BEST.) AS DCTO,	
		INPUT(CODCOM,BEST.) AS COMERCIO,	
		INPUT(SUCURSAL,BEST.) AS SUCURSAL,				
		INPUT(CAJA,BEST.) AS CAJA,				
		NUMMESCAR AS DIFERIDO,				
	CASE 
		WHEN SIGNO='-' THEN MGFIN*(-1) 
		ELSE MGFIN 
	END 
AS MGFIN,				
	PORINT AS TASA,				
	PORINTCAR AS TASA_DIF,
	/*VARIABLES NUEVAS*/
	DV,				
	NUMAUT,				
	SIAIDCD,				
	CASE 
		WHEN (SIGNO='-')  THEN 'NOTA CREDITO' 
		ELSE 'COMPRA' 
	END 
	AS TRANSACCION, 				
		CODMAR,				
		INDTIPT,				
		DESTIPT,				
		TIPO_TARJETA,
	CASE WHEN NUMBENCTA=1 THEN 'TI' ELSE 'BE' END AS CLIENTE,	
		LINEA,				
		TIPFRAN AS FRANQUICIA,				
		DESFRA,				
		TIPOFAC,				
		DESTIPFAC,				
		SIGNO,				
		CASE     				
			WHEN TOTCUOTAS = 0 THEN 'REVOLVING'				
			WHEN TOTCUOTAS > 0 AND TOTCUOTAS < 2   THEN '1 CUOTA'				
			when TOTCUOTAS > 2  THEN '2 O MAS CUOTAS'  
			ELSE 'SIN INFO' 
		END 
		AS FINANCIAMIENTO,
			VALOR_CUOTA,				
			IMPTOTAL,				
			CASE 
				WHEN NUMMESCAR>0 THEN 1 
				ELSE 0 
			END 
			AS T_DIFERIDO				
				from connection to ORACLE( 
					select 
						cast(G.PEMID_GLS_NRO_DCT_IDE_K as INT) AS RUT,
						G.PEMID_DVR_NRO_DCT_IDE as DV,
						A.codent,
						A.centalta,
						A.cuenta,
						A.FECFAC,
						A.PAN,
						A.NUMAUT,
						A.NUMBOLETA,
						A.SIAIDCD,
						substr(A.sucursal,1,4) AS SUCURSAL,
						substr(A.sucursal,5,4) AS CAJA,
						A.CODCOM,
						A.NOMCOMRED,
						A.codact,
						E.desact,
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



							A.LINEA ,
							A.TIPFRAN,
							I.DESFRA,
							A.TIPOFAC,
							H.DESTIPFAC,
							H.INDNORCOR,
							H.SIGNO,
							A.IMPFAC, 
							A.ENTRADA,
							C.TOTCUOTAS,
							C.IMPCUOTA AS VALOR_CUOTA,
							C.Impinttotal as MGFIN,
							C.IMPTOTAL,
							C.PORINT,
							C.PORINTCAR,
							C.NUMMESCAR,
							X.MODENTDAT,
							X.IDTERM,
							F.NUMBENCTA,

							sum(coalesce((D.impbrueco - D.impboneco),0)) as COMISION
							/*Operaciones en Cuotas*/
							from GETRONICS.mpdt205 A 
								/*Autorizacines*/
								left join GETRONICS.MPDT004 X on A.SIAIDCD=X.SIAIDCD
									/*relacion para obtener los datos del contrato a partir del movimiento*/
									left join GETRONICS.MPDT007 B ON (A.CODENT=B.CODENT AND A.CENTALTA=B.CENTALTA AND A.CUENTA=B.CUENTA)
										/*relacion para obtener los datos de financiamiento de la operacion en cuotas*/
										LEFT JOIN GETRONICS.MPDT206 C  ON (A.codent=C.codent AND A.centalta=C.centalta AND A.cuenta=C.cuenta AND A.clamon=C.clamon AND A.numopecuo=C.numopecuo AND A.numfinan=C.numfinan )
											/*relacion para obtener los conceptos de comisiones asociadas al negocio en cuotas*/
											left join GETRONICS.MPDT208 D ON (A.codent=D.codent AND A.centalta=D.centalta AND A.cuenta = D.cuenta AND A.clamon = D.clamon AND A.numopecuo = D.numopecuo AND A.numfinan = D.numfinan)
												/*relacion para obtener la descripción del codigo de actividad ISO*/
												left join GETRONICS.MPDT039 E ON (A.codent=E.codent and A.codact=E.codact)
													/*relacion para obtener la marca y el tipo de tarjeta*/
													LEFT JOIN GETRONICS.MPDT009 F ON (A.codent=F.codent AND A.centalta = F.centalta AND A.cuenta = F.cuenta AND A.pan = F.pan)
														/*relacion para determinar el rut asociado al titular del contrato*/
														left join BOPERS_MAE_IDE G ON G.PEMID_NRO_INN_IDE = B.identcli
															/*relacion para poder filtrar las facturas de compras*/
															LEFT JOIN GETRONICS.MPDT044 H ON (A.codent = H.codent  AND A.tipofac = H.tipofac AND A.indnorcor = H.indnorcor AND H.indfacinf = 'N' )/*Indicador de factura informativa (S/N)*/

	/*Franquicias*/
	LEFT JOIN GETRONICS.MPDT131 I ON (A.TIPFRAN = I.TIPFRAN AND I.CODIDIOMA='1')  
		/*Tipos de Tarjeta*/
	LEFT JOIN GETRONICS.MPDT026 J ON (J.codent = F.codent AND J.CODMAR=F.CODMAR AND J.INDTIPT=F.INDTIPT )  

	WHERE A.tipofac not in (210,115,117) /*210 RepactaciONes, 115 y 117 RegularizaciONes sir*/
	AND A.LINEA in ('0050','0053','0000') /* solo linea de compras */
	AND A.tipfran <> 9999 and A.tipfran <> 8006  and A.tipfran <> 0 /*se excluyen franquicias de ajustes*/
	AND A.CODCOM = '000000000000001'
	AND a.FECFAC BETWEEN %str(%')&fechai.%str(%') AND %str(%')&fechaf.%str(%') 
	GROUP BY 
		G.PEMID_GLS_NRO_DCT_IDE_K,
		G.PEMID_DVR_NRO_DCT_IDE,
		A.codent,
		A.centalta,
		A.cuenta,
		A.FECFAC,
		A.PAN,
		A.NUMAUT,
		A.NUMBOLETA,
		A.SIAIDCD,
		substr(A.sucursal,1,4),
		substr(A.sucursal,5,4),
		A.CODCOM,
		A.NOMCOMRED,
		A.codact,
		E.desact,
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
	end,
						
		A.LINEA,
		A.TIPFRAN,
		I.DESFRA,
		A.TIPOFAC,
		H.DESTIPFAC,
		H.INDNORCOR,
		H.SIGNO,
		A.IMPFAC, 
		A.ENTRADA,
		C.TOTCUOTAS,
		C.IMPCUOTA,
		C.Impinttotal,
		C.IMPTOTAL,
		C.PORINT,
		C.PORINTCAR,
		C.NUMMESCAR,
		X.MODENTDAT,
		X.IDTERM,
		F.NUMBENCTA

		) 
;quit;

PROC SQL NOERRORSTOP;
	CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
	create table SINCUOTA as
		select PAN,				
			CODENT,				
			CENTALTA,				
			CUENTA,				
			RUT,				
		CASE 
			WHEN SIGNO='-' THEN IMPFAC*(-1) 
			ELSE IMPFAC 
		END 
	AS CAPITAL,				
		CASE 
			WHEN SIGNO='-' THEN ENTRADA*(-1) 
			ELSE ENTRADA 
		END 
	AS PIE,				
		TOTCUOTAS AS CUOTAS,				
		(INPUT(COMPRESS(FECFAC,"-"),YYMMDD10.)) FORMAT=YYMMDD10. AS FECHA,
		INPUT(NUMBOLETA,BEST.) AS DCTO,	
		INPUT(CODCOM,BEST.) AS COMERCIO,	
		INPUT(SUCURSAL,BEST.) AS SUCURSAL,				
		INPUT(CAJA,BEST.) AS CAJA,				
		0 AS DIFERIDO,				
		0 AS MGFIN,				
		0 AS TASA,				
		0 AS TASA_DIF,	
		DV,				
		NUMAUT,				
		SIAIDCD,				
	CASE 
		WHEN (SIGNO='-')  THEN 'NOTA CREDITO' 
		ELSE 'COMPRA' 
	END 
AS TRANSACCION, 				
	CODMAR,				
	INDTIPT,				
	DESTIPT,				
	TIPO_TARJETA,
	CASE WHEN NUMBENCTA=1 THEN 'TI' ELSE 'BE' END AS CLIENTE,	
	LINEA,				
	TIPFRAN AS FRANQUICIA,				
	DESFRA,				
	TIPOFAC,				
	DESTIPFAC,				
	SIGNO,				
CASE     				
	WHEN TOTCUOTAS = 0 THEN 'REVOLVING'				
	WHEN TOTCUOTAS > 0 AND TOTCUOTAS < 2   THEN '1 CUOTA'				
	when TOTCUOTAS > 2  THEN '2 O MAS CUOTAS'  
	ELSE 'SIN INFO' 
END 
AS FINANCIAMIENTO,
CASE 
	WHEN SIGNO='-' THEN IMPFAC*(-1) 
	ELSE IMPFAC 
END 
AS VALOR_CUOTA,				
CASE 
	WHEN SIGNO='-' THEN IMPFAC*(-1) 
	ELSE IMPFAC 
END 
AS IMPTOTAL,				
0 AS T_DIFERIDO
from connection to ORACLE( 
select 
	cast(G.PEMID_GLS_NRO_DCT_IDE_K as INT) AS RUT,
	G.PEMID_DVR_NRO_DCT_IDE as DV,
	A.codent,
	A.centalta,
	A.cuenta,
	A.fecfac,
	A.PAN,
	A.NUMAUT,/*Número de autorización*/
	A.NUMBOLETA,/*Número que asigna el Terminal en el momento de la operación.*/
	A.SIAIDCD,
	substr(A.sucursal,1,4) as sucursal,
	substr(A.sucursal,5,4) as caja,
	A.codcom,
	A.nomcomred,
	A.codact,
	A.TOTCUOTAS,
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
A.tipfran,/*Tipo de franquicia*/
I.DESFRA,
A.tipofac,/*Tipo de factura*/
E.DESTIPFAC,
E.INDNORCOR,/*Indicador de normal o correctora: 0 - Normal  1 – Correctora*/
E.signo,/*Signo del importe (+/-)*/
	A.IMPFAC, /*Importe de la factura*/
A.ENTRADA,/*Entrada:
	(pie). Importe que corresponde a la parte de la compra que el cliente abona en efectivo en cajA. Tiene carácter informativo*/
	X.MODENTDAT,
	X.IDTERM,
	F.NUMBENCTA,
	coalesce ((C.impbrueco - C.impboneco),0) as COMISION /*(Importe bruto calculado por el concepto económico)-(IMPBONECO:Importe bonificado sobre el cálculo del concepto económico)*/

	/*Movimientos del Extracto de Crédito*/
	from GETRONICS.mpdt012 A
		/*Autorizacines*/
	left join GETRONICS.MPDT004 X ON A.SIAIDCD = X.SIAIDCD
		/* relacion para obtener los datos del contrato a partir del movimiento */
	left join GETRONICS.MPDT007 B ON (A.codent = B.codent and A.centalta = B.centalta and A.cuenta = B.cuenta)
		/* relacion para obtener la descripción del codigo de actividad ISO */
	left join GETRONICS.MPDT039 D ON (A.codent = D.codent and A.codact  = D.codact)
		/*relacion para obtener la marca y el tipo de tarjeta*/
	left join GETRONICS.MPDT009 F ON (A.codent = F.CODENT AND A.centalta = F.centalta AND A.cuenta = F.cuenta AND A.pan = F.pan)
		/*relacion para determinar el rut asociado al titular del contrato*/
	left join BOPERS_MAE_IDE G ON G.PEMID_NRO_INN_IDE = B.identcli
		/*relacion para poder filtrar las facturas de compras*/
	left join GETRONICS.MPDT044 E ON (A.tipofac = E.tipofac and A.indnorcor = E.indnorcor and E.indfacinf = 'N') /*Indicador de factura informativa (S/N)*/

	/* relacion para obtener los conceptos de comisiones asociadas al movimiento*/
	left join GETRONICS.MPDT151 C ON (A.codent = C.codent and A.centalta = C.centalta and A.cuenta = C.cuenta and A.clamon = C.clamon and A.numextcta = C.numextcta and A.nummovext = C.nummovext and C.tipimp = 2 and C.codconeco= 200) 
		/*Franquicias*/
	LEFT JOIN GETRONICS.MPDT131 I ON (A.TIPFRAN=I.TIPFRAN AND I.CODIDIOMA='1')  
		/*Tipos de Tarjeta*/
	LEFT JOIN GETRONICS.MPDT026 J ON (J.codent=F.codent AND J.CODMAR=F.CODMAR AND J.INDTIPT=F.INDTIPT )  

		/*filtros adicionales*/
	where A.tipofac not in (210,115,117) /*210 RepactaciONes, 115 y 117 CARGO REGULARIZACION SIR */
	AND A.LINEA in ('0050', '0053','0000') /* solo linea de compras */
	AND A.indnorcor = 0 /*Indicador de normal o correctora: 0 - Normal  1 – Correctora*/

	/*AND A.indmovanu = 0
	Indicador de movimiento anulado:
	0 – Normal
	1 – Anulado
	2 – Pago por contrato
	El pago tiene desglose cuando INDMOVANU = 2 o INDMOVANU = 0 y ORIGENOPE = ‘PAGE’*/
	AND A.tipfran <> 9999 and A.tipfran <> 8006  and A.tipfran <> 0  /* se excluyen franquicias de ajustes */
	AND A.numcuota = 0 /*Sin Cuota*/
	AND E.tipofacsist = 2   /* solo compras*/
	AND A.CODCOM = '000000000000001'
	AND A.FECFAC BETWEEN %str(%')&fechai.%str(%') AND %str(%')&fechaf.%str(%') 
/*	and a.cuenta='000001531693'*/
	) 
	;
quit;

PROC SQL NOERRORSTOP;
	CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
	create table NC as
		select PAN,				
			CODENT,				
			CENTALTA,				
			CUENTA,				
			RUT,				
		CASE 
			WHEN SIGNO='-' THEN IMPFAC*(-1) 
			ELSE IMPFAC 
		END 
	AS CAPITAL,				
		CASE 
			WHEN SIGNO='-' THEN ENTRADA*(-1) 
			ELSE ENTRADA 
		END 
	AS PIE,				
		COALESCE(TOTCUOTAS,0) AS CUOTAS,				
		(INPUT(COMPRESS(FECFAC,"-"),YYMMDD10.)) FORMAT=YYMMDD10. AS FECHA,
		INPUT(NUMBOLETA,BEST.) AS DCTO,	
		INPUT(CODCOM,BEST.) AS COMERCIO,	
		INPUT(SUCURSAL,BEST.) AS SUCURSAL,				
		INPUT(CAJA,BEST.) AS CAJA,				
		0 AS DIFERIDO,				
		0 AS MGFIN,				
		0 AS TASA,				
		0 AS TASA_DIF,	
		DV,				
		NUMAUT,				
		SIAIDCD,				
	CASE 
		WHEN (SIGNO='-')  THEN 'NOTA CREDITO' 
		ELSE 'COMPRA' 
	END 
AS TRANSACCION, 				
	CODMAR,				
	INDTIPT,				
	DESTIPT,				
	TIPO_TARJETA,
	CASE WHEN NUMBENCTA=1 THEN 'TI' ELSE 'BE' END AS CLIENTE,
	LINEA,				
	TIPFRAN AS FRANQUICIA,				
	DESFRA,				
	TIPOFAC,				
	DESTIPFAC,				
	SIGNO,				
CASE     				
	WHEN TOTCUOTAS = 0 THEN 'REVOLVING'				
	WHEN TOTCUOTAS > 0 AND TOTCUOTAS < 2   THEN '1 CUOTA'				
	when TOTCUOTAS > 2  THEN '2 O MAS CUOTAS'  
	ELSE 'SIN INFO' 
END 
AS FINANCIAMIENTO,
CASE 
	WHEN SIGNO='-' THEN IMPFAC*(-1) 
	ELSE IMPFAC 
END 
AS VALOR_CUOTA,				
CASE 
	WHEN SIGNO='-' THEN IMPFAC*(-1) 
	ELSE IMPFAC 
END 
AS IMPTOTAL,				
0 AS T_DIFERIDO				
from connection to ORACLE( 
select 
	cast(G.PEMID_GLS_NRO_DCT_IDE_K as INT) AS RUT,
	G.PEMID_DVR_NRO_DCT_IDE as DV,
	A.codent,
	A.centalta,
	A.cuenta,
	A.fecfac,
	A.PAN,
	A.NUMAUT,/*Número de autorización*/
	A.NUMBOLETA,/*Número que asigna el Terminal en el momento de la operación.*/
	A.SIAIDCD,
	substr(A.sucursal,1,4) as sucursal,
	substr(A.sucursal,5,4) as caja,
	A.codcom,
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
A.tipfran,/*Tipo de franquicia*/
I.DESFRA,
A.tipofac,/*Tipo de factura*/
E.DESTIPFAC,
E.INDNORCOR,/*Indicador de normal o correctora: 0 - Normal  1 – Correctora*/
E.signo,/*Signo del importe (+/-)*/
	A.IMPFAC,/*Importe de la factura*/
A.ENTRADA,/*Entrada:
	(pie). Importe que corresponde a la parte de la compra que el cliente abona en efectivo en cajA. Tiene carácter informativo*/
	X.MODENTDAT,
	X.IDTERM,
	A.TOTCUOTAS,
	F.NUMBENCTA,
	coalesce ((C.impbrueco - C.impboneco),0) as COMISION /*(Importe bruto calculado por el concepto económico)-(IMPBONECO:Importe bonificado sobre el cálculo del concepto económico)*/

	/*Movimientos del Extracto de Crédito*/
	from GETRONICS.mpdt012 A
		/*Autorizacines*/
	left join GETRONICS.MPDT004 X ON A.SIAIDCD=X.SIAIDCD
		/* relacion para obtener los datos del contrato a partir del movimiento */
	left join GETRONICS.MPDT007 B ON (A.codent = B.codent and A.centalta=B.centalta and A.cuenta = B.cuenta)
		/* relacion para obtener la descripción del codigo de actividad ISO */
	left join GETRONICS.MPDT039 D ON (A.codent = D.codent and A.codact=D.codact)
		/*relacion para obtener la marca y el tipo de tarjeta*/
	left join GETRONICS.MPDT009 F ON (A.codent=F.CODENT AND A.centalta=F.centalta AND A.cuenta=F.cuenta AND A.pan=F.pan)
		/*relacion para determinar el rut asociado al titular del contrato*/
	left join BOPERS_MAE_IDE G ON G.PEMID_NRO_INN_IDE= B.identcli
		/*relacion para poder filtrar las facturas de compras*/
	left join GETRONICS.MPDT044 E ON (A.tipofac=E.tipofac and A.indnorcor=E.indnorcor ) /*Indicador de factura informativa (S/N)*/
		/*Franquicias*/
	LEFT JOIN GETRONICS.MPDT131 I ON (A.TIPFRAN = I.TIPFRAN AND I.CODIDIOMA='1')  
		/* relacion para obtener los conceptos de comisiones asociadas al movimiento*/
	left join GETRONICS.MPDT151 C ON (A.codent=C.codent and A.centalta= C.centalta and A.cuenta=C.cuenta and A.clamon=C.clamon and A.numextcta = C.numextcta and A.nummovext = C.nummovext and C.tipimp = 2 and C.codconeco= 200) 
		/*Tipos de Tarjeta*/
	LEFT JOIN GETRONICS.MPDT026 J ON (J.codent=F.codent AND J.CODMAR=F.CODMAR AND J.INDTIPT=F.INDTIPT )  

		/*filtros adicionales*/
	where A.tipofac not in (210,115,117) /*210 Repactaciones, 115 y 117 CARGO REGULARIZACION SIR */

	/*AND A.CODCOM <> '000000000000001' para spos */
	AND A.LINEA in ('0050', '0053', '0000') /* solo linea de compras */
	AND A.indnorcor = 0
	/*AND A.tipfran <> 9999 and A.tipfran <> 8006  and A.tipfran <> 0   se excluyen franquicias de ajustes */
	AND ( ( E.tipofacsist = 1500 and A.indmovanu = 0) or (a.tipofac = 1515 and A.indmovanu = 2))
	AND A.CODCOM = '000000000000001'
	AND A.FECFAC BETWEEN %str(%')&fechai.%str(%') AND %str(%')&fechaf.%str(%') 

	) 
	;
quit;

LIBNAME CAMP ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="BRTEFGESTIONP.WORLD"  SCHEMA=CAMP_ADM  USER='CAMP_COMERCIAL'  PASSWORD='ccomer2409';

proc sql;
	create table sucursal as 
		select distinct 
			c.CAMP_DAT_VALOR1 as codigo,
			c.CAMP_DAT_TEXTO1 as sucursal
		from CAMP.CBCAMP_PAR_TABLAS a
			INNER JOIN CAMP.CBCAMP_PAR_COLUMNAS B ON A.CAMP_COD_TABLA = B.CAMP_COD_TABLA_K
			INNER JOIN CAMP.CBCAMP_PAR_DATOS C ON A.CAMP_COD_TABLA = C.CAMP_COD_TABLA_K
				WHERE CAMP_COD_TABLA = 2
					order by codigo asc
	;
QUIT;

proc sql;
	create table work.TDA_ITF_&Periodo as
		/*	create table &libreria..TDA_ITF_VN_&Periodo as*/
	select 
		&fechae AS FEC_EX,
		D.PAN,
		D.CODENT,
		D.CENTALTA,
		D.CUENTA,
		D.RUT,
		D.CAPITAL,
		D.PIE,
		D.CUOTAS,
		D.FECHA,
		D.DCTO,
		D.COMERCIO,
		D.SUCURSAL,
		D.CAJA,
		D.DIFERIDO,
		D.MGFIN,
		D.TASA,
		D.TASA_DIF,
		D.DV,
		/*variables Nuevas*/
		CASE 
			WHEN D.SUCURSAL IS NOT MISSING THEN CATS(D.SUCURSAL,'.-',E.sucursal) ELSE 'SIN INFORMACION' 
		END 
		AS Nombre_SUC,
		CASE 
			WHEN D.SUCURSAL=39 THEN 'NO PRESENCIAL' 
			ELSE 'PRESENCIAL' 
		END 
		AS PRESENCIAL,
			D.NUMAUT,
			D.SIAIDCD,
			D.TRANSACCION,
			D.CODMAR,
			D.INDTIPT,
			D.DESTIPT as Tipo_Tarjeta_RSAT,
			D.TIPO_TARJETA,
			D.CLIENTE,
			D.LINEA,
			D.FRANQUICIA,
			D.DESFRA,
			D.TIPOFAC,
			D.DESTIPFAC,
			D.SIGNO,
			D.FINANCIAMIENTO,
			D.VALOR_CUOTA,
			D.IMPTOTAL,
			D.T_DIFERIDO
			from(
				select B.*
					from SINCUOTA B
						outer union corr
							select C.*
								from NC C
									outer union corr
										select A.*
											from CUOTA A
												) D 
												LEFT JOIN sucursal E on D.SUCURSAL=E.codigo
		;
quit;

proc sql;
	create table &libreria..TDA_ITF_&Periodo as
		/*	create table &libreria..TDA_ITF_VN_&Periodo as*/
	select *, &Periodo. as periodo from work.TDA_ITF_&Periodo
		;
quit;

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================        EXPORT_TO_AWS - INI          ===============================*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_mdpg_tda_itf,raw,sasdata,0);

/*Exportación a AWS*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_mdpg_tda_itf,&libreria..tda_itf_&periodo,raw,sasdata,0);

/*==============================        EXPORT_TO_AWS - END          ===============================*/
/*==================================================================================================*/

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*	FECHA DEL PROCESO	*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN);
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
	SUBJECT = ("MAIL_AUTOM: Proceso PROC_TDA_ITF_DIARIO");
	FILE OUTBOX;
	PUT "Estimados:";
	PUT "		Proceso TDA_ITF_DIARIO, ejecutado con fecha: &fechaeDVN";
	PUT "  		Información disponible en SAS: &libreria..TDA_ITF_&Periodo";
	PUT;
	PUT;
	PUT;
	PUT 'Proceso Vers. 13';
	PUT;
	PUT;
	PUT 'Atte.';
	PUT 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;

FILENAME OUTBOX CLEAR;

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

%macro envio_control_comercial (n);

	DATA _null_;
		periodo= input(put(intnx('month',today(),-&n.,'begin'),yymmn6. ),$10.);
		Call symput("periodo", periodo);
	RUN;

	%put &periodo;

	proc sql;
		create table tda_itf_&periodo. as 
			select 
				RUT	,
				CAPITAL	,
				PIE	,
				CUOTAS,
				year(FECHA)*10000+month(fecha)*100+day(fecha) as fecha,
				DCTO,
				COMERCIO,
				SUCURSAL,
				CAJA,
				MGFIN,
				TASA,
				NUMAUT
			from publicin.tda_itf_&periodo. 
		;
	QUIT;

	PROC EXPORT DATA=tda_itf_&periodo.
		OUTFILE="/sasdata/users94/user_bi/tda_itf_&periodo..csv" DBMS=dlm replace;
		delimiter=';';
		PUTNAMES=YES;
	RUN;

	filename server ftp "tda_itf_&periodo..csv" CD='/'
		HOST='192.168.82.171' user='17457765K' pass='17457765K' PORT=21;

	data _null_;
		infile "/sasdata/users94/user_bi/tda_itf_&periodo..csv";
		file server;
		input;
		put _infile_;
	run;

	proc sql;
		drop table tda_itf_&periodo.;
		;
	QUIT;

%mend envio_control_comercial;

%envio_control_comercial(0);
%envio_control_comercial(1);
