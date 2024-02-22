/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	ONBOARDING_TR_TARJETAS	================================*/
/* CONTROL DE VERSIONES
/* 2023-07-06 -- v09 -- Sergio J .	--  Se excluye sucursal 105 de capta salida para quitar captados de TAM CHEK
/* 2022-12-20 -- v08 -- Sergio J .	--  Cambio en nombre de campo de tipo_tr a tipo_tarjeta
/* 2022-11-08 -- v07 -- Sergio J .	--  Cambio de directorio a campaign
/* 2022-10-28 -- v06 -- Sergio J .	--  Nuevo codigo de exporacion a AWS
/* 2022-09-13 -- v05 -- David V.	--  Actualización export to AWS
/* 2022-08-02 -- v04 -- René F. 	--  Se incorporan 'TAM_CERRADA','TAM_CUOTAS' al proceso.
/* 2022-05-09 -- v03 -- David V. 	--  Se actualizar códigos en correos de notificación.
/* 2022-05-03 -- v02 -- David V. 	--  Tabla final se deja en librería comunicaciones para consultas y análisis en SAS posteriores
/* 2021-10-28 -- v01 -- Valentina M.--  
					 -- Versión Original
/* INFORMACIÓN:
	Onboarding, trae los captados totales desde los 3 meses hasta el día anterior y pega variables, 
		facturación, cuenta, vigente, etc.
	Se utiliza para onboarding informativo y luego se piensa utilizar para campañas.
*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());
/*	VARIABLE LIBRERÍA			*/
%let libreria_1  = libcomun;
options validvarname=any;

DATA _null;
	INI = put(intnx('month',today(),-3,'same'),date9.);
	INI_FISA = put(intnx('month',today(),-3,'same'),ddmmyy10.);
	FIN_FISA = put(intnx('day',today(),-1,'same'),ddmmyy10.);
	periodo_act= input(put(intnx('month',today(),0,'same'),yymmn6. ),$10.);
	Call symput("INI", INI);
	Call symput("INI_FISA", INI_FISA);
	Call symput("FIN_FISA", FIN_FISA);
	Call symput("periodo_act", periodo_act);
RUN;

%put &INI;
%put &INI_FISA;
%put &FIN_FISA;
%put &periodo_act;

/* captados Control comercial*/
proc sql;
	create table captados as 
		select DISTINCT 
			rut_cliente as rut,
			cuenta,
			producto,
			codent,
			centalta,
		case 
			when cod_sucursal=39 and via IN ('HOMEBANKING','HOMEBAN') THEN 'ONLINE' 
			ELSE 'PRESENCIAL' 
		END 
	AS TIPO_CAPTA,
		FECHA FORMAT=MMDDYY10. as FECHA_CAPTACION
	FROM RESULT.CAPTA_SALIDA 
		WHERE PRODUCTO IN ('TR','TAM','TAM_CERRADA','TAM_CUOTAS','CAMBIO DE PRODUCTO','MASTERCARD_BLACK')
		AND FECHA >="&INI"d 
		AND cod_sucursal NE 105
		group by 
			rut_cliente,
			cuenta,
			producto,
			codent,
			centalta,
			FECHA
		ORDER BY RUT_CLIENTE
	;
QUIT;

/*Conexion a FISA*/
%let path_ora      = '(DESCRIPTION =(ADDRESS_LIST =(ADDRESS =(PROTOCOL = TCP)(Host = 192.168.10.31)(Port = 1521)))(CONNECT_DATA = (SID = ripleyc)))';
%let user_ora      = 'RIPLEYC';
%let pass_ora      = 'ri99pley';
%let conexion_ora  = ORACLE PATH=&path_ora. USER=&user_ora. PASSWORD=&pass_ora.;
%put &conexion_ora.;
LIBNAME DBLIBORA     &conexion_ora. insertbuff=10000 readbuff=10000;

%put--------------------------------------------------------------------------------------------------;
%put [03.1] Extraer Movimientos de debito totales;

%put--------------------------------------------------------------------------------------------------;

/* moviemitnos de cuenta vista: cargos y abonos MAYORES A 1 PESO*/
PROC SQL;
	CONNECT TO ORACLE (USER=&user_ora. PASSWORD=&pass_ora. path =&path_ora. );
	create table SB_MOV_CUENTA_VISTA2  as
		select 
			*,
		CASE 
			when tmo_tipotra='C' then 
		case 
			WHEN DESCRIPCION IN ('VALOR EFECTIVO','EN EFECTIVO') AND GLS_TRANSAC ='DEPOSITO' AND  SI_ABR<>1  THEN 'Depósitos en Efectivo' 
			WHEN DESCRIPCION IN ('CON DOCUMENTOS') AND GLS_TRANSAC ='DEPOSITO' AND SI_ABR<>1 THEN 'Depósitos con Documento' 
			WHEN DESCRIPCION IN ('TRANSFERENCIA DESDE OTROS BANCOS') AND  SI_ABR<>1 THEN 'TEF Recibidas' 
			WHEN DESCRIPCION IN ('DESDE OTROS BANCOS') AND  SI_ABR<>1 THEN 'TEF Recibidas' 
			WHEN DESCRIPCION IN ('DESDE OTROS BANCOS') AND  SI_ABR=1 THEN 'Abono de Remuneraciones' 
			WHEN DESCRIPCION IN ('DESDE OTROS BANCOS') AND  SI_ABR<>1 and DESC_NEGOCIO CONTAINS 'Proveedores' THEN 'TEF Recibidas' 
			WHEN DESCRIPCION IN ('POR REGULARIZACION') AND  SI_ABR<>1 THEN 'Otros (pago proveedores)' 
			WHEN DESCRIPCION IN ('DESDE LINEA DE CREDITO') AND GLS_TRANSAC ='TRASPASO DE FONDOS' AND  SI_ABR<>1 THEN 'Traspaso desde LCA'
			WHEN DESCRIPCION IN ('AVANCE DESDE TARJETA DE CREDITO BANCO RIPLEY') AND  SI_ABR<>1 THEN 'Avance desde Tarjeta Ripley' 
			WHEN DESCRIPCION IN ('DEVOLUCION COMISION') AND  SI_ABR<>1 THEN 'DEVOLUCION COMISION' 
			WHEN DESCRIPCION IN ('POR TRANSFERENCIA  DE LCA A CTA VISTA') AND  SI_ABR<>1 THEN 'Traspaso desde LCA' 
			else 'OTROS ABONOS' 
		end 
			else ''
			END 
		AS Descripcion_Abono,
			CASE 
				when tmo_tipotra='D' then 
			CASE
				WHEN DESCRIPCION IN ('COMPRA NACIONAL') THEN 'Compras Redcompra' 
				WHEN DESCRIPCION IN ('COMPRA NACIONAL MCD') THEN 'Compras Redcompra MCD' 
				WHEN DESCRIPCION IN ('COMPRA INTERNACIONAL') THEN 'Compras Internacionales' 
				WHEN DESCRIPCION IN ('COMPRA INTERNACIONAL MCD') THEN 'Compras Internacionales MCD' 
				WHEN DESCRIPCION IN ('CARGO POR PEC') THEN 'PEC' 
				WHEN DESCRIPCION IN ('GIRO CAJERO AUTOMATICO') THEN 'Giros ATM' 
				when DESCRIPCION IN ('GIRO ATM INTERNACIONAL MCD') then 'Giros internacional MCD'
				when DESCRIPCION IN ('GIRO ATM NACIONAL MCD') then 'Giros ATM MCD'
				WHEN DESCRIPCION IN ('GIRO POR CAJA') THEN 'Giros Caja' 
				WHEN DESCRIPCION IN ('GIRO INTERNACIONAL') THEN 'Giro Internacional' 
				WHEN DESCRIPCION IN ('TRANSFERENCIA A OTROS BANCOS') THEN 'TEF emitidas Otros Bancos'
				WHEN DESCRIPCION IN ('PAGO TARJETA DE CREDITO') THEN 'Pago de Tarjeta' 
				WHEN DESCRIPCION IN ('A CUENTA BANCO RIPLEY','POR TRASPASO A CUENTA')  THEN 'Pago LCA' 
				WHEN DESCRIPCION IN ('COSTO DE MANTENCION MENSUAL CUENTA VISTA') then 'Comision planes' 
				else 'OTROS CARGOS' 
			end 
				else ''
				END 
			AS Descripcion_Cargo 
				from connection to ORACLE
					( select 
						CAST(SUBSTR(c2.cli_identifica,1,length(c2.cli_identifica)-1) AS INT)  rut,
						SUBSTR(c2.cli_identifica,length(c2.cli_identifica),1)  dv,
						cast(TO_CHAR( c1.tmo_fechor,'YYYYMM') as INT) as PERIODO,
						cast(TO_CHAR( c1.tmo_fechor,'YYYYMMDD') as INT) as CodFecha,
						c1.tmo_numcue as CUENTA, 
						c1.tmo_fechcon as FECHACON, 
						c1.tmo_fechor as FECHA, 
						c1.rub_desc as DESCRIPCION, 
						c1.tmo_val as MONTO, 
						c1.con_libre as Desc_negocio, 
						c1.tmo_codmod, 
						c1.tmo_tipotra, 
						c1.tmo_rubro, 
						c1.tmo_numtra, 
						c1.tmo_numcue, 
						c1.tmo_codusr, 
						c1.tmo_codusr, 
						c1.tmo_sec, 
						c1.tmo_codtra, 
						(
					SELECT cod_destra 
						FROM tgen_codtrans 
							WHERE cod_tra = tmo_codtra AND cod_mod = tmo_codmod 
					) as gls_transac,
						case 
							when c1.tmo_tipotra='D' then 'CARGO' 
							when c1.tmo_tipotra='C' then 'ABONO' 
						end 
					as Tipo_Movimiento,
						case 
							when c1.tmo_rubro = 1 and c1.tmo_codtra = 30 and c1.con_libre like 'Depo%' then 1 
							else 0 
						end 
					as Marca_DAP,
						case 
							when c1.tmo_tipotra='C' 
							and c1.rub_desc='DESDE OTROS BANCOS' 
							and ( 
							c1.con_libre like '%Remuneraciones%' OR 
							c1.con_libre like '%Anticipos%' OR 
							c1.con_libre like '%Sueldos%')  then 1 
							ELSE 0 
						END 
					as SI_ABR ,
						CASE 
							WHEN  c1.tmo_tipotra='C' and c1.rub_desc='DESDE OTROS BANCOS' 
							and ( c1.con_libre like '%Remuneraciones%' OR c1.con_libre like '%Anticipos%' OR c1.con_libre like '%Sueldos%')
							AND c1.con_libre like '%BANCO RIPLEY%' THEN 'BANCO RIPLEY' 
							WHEN  c1.tmo_tipotra='C' and c1.rub_desc='DESDE OTROS BANCOS' 
							and ( c1.con_libre like '%Remuneraciones%' OR c1.con_libre like '%Anticipos%' OR c1.con_libre like '%Sueldos%')
							AND c1.con_libre like '%CAR S.A.%' THEN 'CAR' 
							WHEN  c1.tmo_tipotra='C' and c1.rub_desc='DESDE OTROS BANCOS' 
							and ( c1.con_libre like '%Remuneraciones%' OR c1.con_libre like '%Anticipos%' OR c1.con_libre like '%Sueldos%')
							AND c1.con_libre like '%RIPLEY STORE%' THEN 'RIPLEY STORE' 
							WHEN  c1.tmo_tipotra='C' and c1.rub_desc='DESDE OTROS BANCOS' 
							and ( c1.con_libre like '%Remuneraciones%' OR c1.con_libre like '%Anticipos%' OR c1.con_libre like '%Sueldos%')
							AND ( 
							c1.con_libre NOT like ('%RIPLEY STORE%') or 
							c1.con_libre NOT like ('%CAR S.A.%') or 
							c1.con_libre NOT like ('%BANCO RIPLEY%') 
							) THEN 'OTROS BANCOS' 
							else ''
						END 
					AS Descripcion_ABR,
						CASE 
							WHEN c1.tmo_tipotra='D' 
							and (c1.con_libre like '%Ripley%' OR c1.con_libre like '%RIPLEY%') 
							AND  c1.con_libre NOT like '%PAGO%' 
							THEN 'COMPRA_RIPLEY' 
						else ''
						END 
					AS COMPRA_RIPLEY
						from(select * from  tcap_tramon /*base de movimientos*/
							, TGEN_TRANRUBRO /*base descriptiva (para complementar movimientos)*/
							, tcap_concepto /*base descriptiva (para complementar movimientos)*/
						where rub_mod    = tmo_codmod /*unificacion de base de movs con rubro*/
							and rub_tra      = tmo_codtra /*unificacion de base de movs con rubro*/
							and rub_rubro    = tmo_rubro /*unificacion de base de movs con rubro*/
							and con_modulo(+)  = tmo_codmod /*unificacion de base de movs con con_*/
							and con_rubro(+)   = tmo_rubro /*unificacion de base de movs con con_*/
							and con_numtran(+) = tmo_numtra /*unificacion de base de movs con con_*/
							and con_cuenta (+) = tmo_numcue /*unificacion de base de movs con con_*/
							and con_codusr(+)  = tmo_codusr /*unificacion de base de movs con con_*/
							and con_sec(+)     = tmo_sec /*unificacion de base de movs con con_*/
							and con_transa(+)  = tmo_codtra /*unificacion de base de movs con con_*/
							/*FILTROS DE MOVIMIENTOS*/
							and tmo_tipotra in ('D','C') /*D=Cargo, C=Abono*/
							and tmo_codpro = 4 
							and tmo_codtip = 1 
							and tmo_modo = 'N' 
							and tmo_val > 1 /*solo montos mayores a 1 peso (mov de prueba)*/
							and tmo_fechor >= to_date(%str(%')&ini_fisa.%str(%'),'dd/mm/yyyy')
							and tmo_fechor <= to_date(%str(%')&fin_fisa.%str(%'),'dd/mm/yyyy')
							/*FINAL: QUERY DESDE OPERACIONES*/
							)  C1  
						left join ( 
							SELECT distinct cli_identifica ,vis_numcue  
								from tcli_persona /*MAESTRA DE CLIENTES BANCO*/
									,tcap_vista /*SALDOS CUENTAS VISTAS */
								where cli_codigo=vis_codcli 
									and vis_mod=4/*cuenta vista*/
									and (VIS_PRO=4/*CV*/ or VIS_PRO=40/*LCA*/) 
									and vis_tip=1  /*persona no juridica*/
									AND (vis_status='2' or vis_status='9') /*solo aquellas con estado vigente o cerrado*/
									)  C2 
									on (c1.tmo_numcue=c2.vis_numcue) 
									);
	disconnect from ORACLE;
QUIT;

/* fecha ultimo abono*/
proc sql;
	create table  Max_fecha as 
		select distinct 
			rut, 
			cuenta,
			datepart(MAX(fecha)) FORMAT=DATE9. as fecha 
		from SB_MOV_CUENTA_VISTA2
			where tipo_movimiento='ABONO' 
				GROUP BY RUT, CUENTA 
	;
quit;

/* ABONOS CV*/
PROC SQL;
	CREATE TABLE ABONO AS 
		SELECT DISTINCT 
			RUT,
			MONTO as monto_abono,
			cuenta, 
			datepart(fecha) FORMAT=DATE9. as fecha 
		FROM  SB_MOV_CUENTA_VISTA2  AS A 
			WHERE tipo_movimiento='ABONO' 
				group by rut, cuenta 
	;
QUIT;

/* cruce para obtener la fecha y monto del ultimo abono*/
proc sql;
	create table abono2 as 
		select distinct 
			a.rut,
			a.cuenta,
			a.fecha ,
			sum(b.monto_abono ) as monto_abono 
		from max_fecha as a 
			left join abono as b 
				on (a.cuenta=b.cuenta) and (a.fecha=b.fecha) /* on con fecha es para traer el monto del ultimo abono, si se quiere la suma total quitar la fecha */
	where a.rut is not null 
		group by a.rut, a.cuenta, a.fecha 
	;
quit;

%let path_ora2       = '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=192.168.84.76)(PORT=1521))(CONNECT_DATA=(SERVER=dedicated)(SID=SEGCOM)))';
%let user_ora2        = 'PMUNOZC';
%let pass_ora2        = 'pmun3012';
%let conexion_ora2    = ORACLE PATH=&path_ora2. USER=&user_ora2. PASSWORD=&pass_ora2.;
%put &conexion_ora2.;
%put ###enlace entre fisa y RSAT ###;

PROC SQL NOERRORSTOP;
	CONNECT TO ORACLE (USER=&user_ora2. PASSWORD=&pass_ora2. path =&path_ora2. );
	create table mpdt666 as
		select
			CODENT1,
			CENTALTA1,
			CUENTA1,
			input(cuenta2,best.) as cv
		from connection to ORACLE
			(
		select * from MPDT666
			);
	disconnect from ORACLE;
QUIT;

proc sql;
	create table captados1 as 
		select distinct 
			a.*,
			b.cv 
		from captados as a 
			left join mpdt666 as b 
				on (a.cuenta=b.cuenta1)
	;
quit;

proc sql;
	create table final as 
		select distinct 
			A.RUT AS ID_USUARIO,
			A.PRODUCTO AS TIPO_TARJETA,
			A.TIPO_CAPTA AS TIPO_CAPTACION,
			A.FECHA_CAPTACION,
		case 
			when a.producto='CUENTA VISTA' and b.rut is not null and 
			b.monto_abono is not null then b.monto_abono 
			else 0 
		end 
	as ABONO_MONTO,
		b.FECHA FORMAT=MMDDYY10. as FECHA_ULTIMO_ABONO,
		a.codent,
		a.centalta, 
		a.cuenta,
		a.cv
	from captados1 as a 
		left join abono2 as b
			on (a.rut=b.rut) and (a.cv=b.cuenta)
		group by 
			a.rut,
			a.producto,
			a.tipo_capta,
			a.fecha_captacion,
			b.fecha,
			a.codent,
			a.centalta, 
			a.cuenta
	;
quit;

proc sql;
	create table estado_cv as 
		select distinct 
			rut
		from result.ctavta1_stock
			where estado_cuenta='vigente'
	;
quit;

proc sql;
	create table final2 as 
		select 
			a.*,
		case 
			when a.tipo_tarjeta='CUENTA VISTA' and b.rut is not null then 'vigente' 
			when a.tipo_tarjeta='CUENTA VISTA' and b.rut is  null then 'cerrada' 
			when a.tipo_tarjeta<>'CUENTA VISTA' then 'sin_cv' 
		end 
	as ESTADO
		from final as a 
			left join estado_cv as b 
				on (a.id_usuario=b.rut)
	;
quit;

PROC SQL;
	CONNECT TO ORACLE AS CAMPANAS (PATH="REPORITF.WORLD" USER='KMARTINEZ' PASSWORD='kmar2102');
	CREATE TABLE retiro_debito AS 
		SELECT * FROM CONNECTION TO CAMPANAS(SELECT DISTINCT 
			mae.pcom_cod_ide_cli_k, 
			TAR.TAR_CAC_NRO_CTT_K NUMERO_CONTRATO,
			TAR.TAR_CAC_NRO_PAN_K NUMERO_TARJETA, 
			SUBSTR(PRD.PRD_CAC_NRO_CTT,9) NUMERO_CUENTA_VISTA,
			SOL.SOL_COD_IDE_CLI RUT_CLIENTE, 
			PER.PER_CAC_IDE_CLI_DV DV, 
			SOL.SOL_FCH_ALT_SOL  FECHA_SOLICITUD,
			SOL.SOL_COD_NRO_SOL_K NUMERO_SOLICITUD, 
			SOL.SOL_COD_EST_SOL ESTADO,
			TRUNC(MAE.PCOM_FCH_K) fecha_retiro, 
			MAE.PCOM_GLS_USR_CRC, 
			DET.PCOM_COC_SUC CODIGO_SUC
		FROM SFADMI_ADM.SFADMI_BCO_SOL SOL
			INNER JOIN SFADMI_ADM.SFADMI_BCO_TAR TAR
				ON TAR.TAR_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
			INNER JOIN SFADMI_ADM.SFADMI_BCO_PRD_SOL PRD
				ON TAR.TAR_COD_NRO_SOL_K = PRD.PRD_COD_NRO_SOL_K
				AND TAR.TAR_COD_TIP_PRD_K = PRD.PRD_COD_TIP_PRD_K
			INNER JOIN SFADMI_ADM.SFADMI_BCO_DAT_PER PER
				ON PRD.PRD_COD_NRO_SOL_K = PER.PER_COD_NRO_SOL_K
				AND SOL.SOL_COD_IDE_CLI = PER.PER_COD_IDE_CLI_K
			INNER JOIN FEPCOM_ADM.FEPCOM_MAE_REG_EVT MAE
				ON sol.SOL_NRO_INN_IDE  = mae.PCOM_COD_IDE_CLI_K
				AND MAE.PCOM_COD_EVT_K = 257 
				and  mae.PCOM_DESC_DOC = sol.sol_cod_ide_cli 
			INNER JOIN FEPCOM_ADM.fepcom_det_reg_evt DET
				ON mae.PCOM_NRO_SEQ_K = det.PCOM_NRO_SEQ_K and 
				det.PCOM_COD_EVT_K = 257 and 
				(det.PCOM_NRO_CTT = substr(TAR_CAC_NRO_CTT_K,1,4) || '-' || substr(TAR_CAC_NRO_CTT_K,5,4) || '-' || substr(TAR_CAC_NRO_CTT_K,9,12) or 
				det.PCOM_NRO_CTT = substr(TAR_CAC_NRO_CTT_K,9,12))
			WHERE 
				SUBSTR(TAR.TAR_COD_TIP_PRD_K,1,2) = '04'
				AND (SOL.SOL_COD_CLL_ACT = 14 OR SOL.SOL_COD_CLL_ANT = 14)
				AND SOL.SOL_COD_CLL_ADM = 2

				and sol.sol_fch_crc_sol between  to_date(%str(%')&INI_FISA.%str(%'),'dd/mm/yyyy') and to_date(%str(%')&fin_FISA.%str(%'),'dd/mm/yyyy')

				AND EXISTS (SELECT BTC_COD_NRO_SOL_K
			FROM SFADMI_ADM.SFADMI_BCO_BTC_SOL
				WHERE BTC_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
					AND BTC_COD_TIP_REG_K = 1
					AND BTC_COD_ETA_K = 102
					AND BTC_COD_EVT_K = 30)
					and exists (select t.Cuenta from mpdt009 t where 
					t.cuenta = substr(TAR_CAC_NRO_CTT_K,9,12) and 
					t.codent = substr(TAR_CAC_NRO_CTT_K,1,4) and 
					t.centalta = substr(TAR_CAC_NRO_CTT_K,5,4)
					and t.numbencta = 1 and t.numplastico > 1)
				ORDER BY  SOL.SOL_COD_NRO_SOL_K ASC

					)A
	;
QUIT;

PROC SQL;
	CONNECT TO ORACLE AS REPORTITF (PATH="REPORITF.WORLD" USER='KMARTINEZ' PASSWORD='kmar2102');
	CREATE TABLE RETIRO_PLASTICO AS 
		SELECT * 
			FROM CONNECTION TO REPORTITF
(
SELECT sol.sol_nro_inn_ide,
	TAR.TAR_CAC_NRO_CTT_K NUMERO_CONTRATO,
	TAR.TAR_CAC_NRO_PAN_K NUMERO_TARJETA,
	SOL.SOL_COD_IDE_CLI RUT_CLIENTE, 
	SOL.SOL_FCH_ALT_SOL FECHA_SOLICITUD,
	SOL.SOL_COD_NRO_SOL_K NUMERO_SOLICITUD, 
	sol.sol_cod_est_sol ESTADO, 
	TRUNC(MAE.PCOM_FCH_K) as fecha_retiro,
	MAE.PCOM_GLS_USR_CRC, 
	DET.PCOM_COC_SUC CODIGO_SUC
FROM SFADMI_BCO_SOL SOL 
	INNER JOIN SFADMI_BCO_TAR TAR
		ON TAR.TAR_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
	INNER JOIN FEPCOM_MAE_REG_EVT MAE
		ON sol.SOL_NRO_INN_IDE  = mae.PCOM_COD_IDE_CLI_K
		AND MAE.PCOM_COD_EVT_K in (15, 80, 230)  
		and  mae.PCOM_DESC_DOC = sol.sol_cod_ide_cli 
	INNER JOIN fepcom_det_reg_evt DET
		ON mae.PCOM_NRO_SEQ_K = det.PCOM_NRO_SEQ_K and 
		det.PCOM_COD_EVT_K in (15, 80, 230)  and 
		det.PCOM_NRO_CTT = substr(TAR_CAC_NRO_CTT_K,1,4) || '-' || substr(TAR_CAC_NRO_CTT_K,5,4) || '-' || substr(TAR_CAC_NRO_CTT_K,9,12)
	WHERE 

		SUBSTR(TAR.TAR_COD_TIP_PRD_K,1,2) = '01'
		AND SOL_FCH_CRC_SOL BETWEEN to_date(%str(%')&INI_FISA.%str(%'),'dd/mm/yyyy') and 
		to_date(%str(%')&fin_FISA.%str(%'),'dd/mm/yyyy')
		/*and  MAE.PCOM_FCH_K BETWEEN to_date(%str(%')&INI_FISA.%str(%'),'dd/mm/yyyy') and */

/*to_date(%str(%')&fin_FISA.%str(%'),'dd/mm/yyyy')*/
AND (SOL.SOL_COD_CLL_ACT = 14 OR SOL.SOL_COD_CLL_ANT = 14)
	AND SOL.SOL_COD_CLL_ADM = 2
	AND EXISTS (SELECT BTC_COD_NRO_SOL_K
	FROM SFADMI_BCO_BTC_SOL
	WHERE BTC_COD_NRO_SOL_K = SOL.SOL_COD_NRO_SOL_K
	AND BTC_COD_TIP_REG_K = 1
	AND BTC_COD_ETA_K = 102
	AND BTC_COD_EVT_K = 30)
	and  exists (select t.Cuenta from mpdt009 t where 
	t.cuenta = substr(TAR_CAC_NRO_CTT_K,9,12) and 
	t.codent = substr(TAR_CAC_NRO_CTT_K,1,4) and 
	t.centalta = substr(TAR_CAC_NRO_CTT_K,5,4)
	and t.numbencta = 1 and t.numplastico > 0)
	ORDER BY  SOL.SOL_COD_NRO_SOL_K ASC
	)A
;
QUIT;

proc sql;
	create table final3 as 
		select distinct 
			a.*,
		case 
			when a.tipo_captacion='PRESENCIAL'  then 1
			WHEN a.tipo_tarjeta='CUENTA VISTA' and a.tipo_captacion='ONLINE' and b.rut_cliente is not null then 1
			when a.tipo_tarjeta='CUENTA VISTA' and a.tipo_captacion='ONLINE' and b.rut_cliente is null then 0
			WHEN a.tipo_tarjeta<>'CUENTA VISTA' and a.tipo_captacion='ONLINE' and C.rut_cliente is not null then 1
			WHEN a.tipo_tarjeta<>'CUENTA VISTA' and a.tipo_captacion='ONLINE' and C.rut_cliente is null then 0
		END 
	AS RETIRO_PLASTICO
		from final2 as a 
			left join retiro_debito as b 
				on (a.id_usuario=input(b.rut_cliente,best.))
			left join retiro_PLASTICO as C 
				on (a.id_usuario=input(C.rut_cliente,best.))
	;
quit;

proc sql;
	create table panes as 
		select distinct 
			RUT,
			CODENT,
			CENTALTA,
			CUENTA,
			tipo_tarjeta,
			FECCADTAR*100+01 as fec_ven,
			CODBLQ,
			MOTIVO_BLOQUEO,
			T_TR_VIG,
			PAN
		from result.universo_panes 
			where INDULTTAR='S' and INDSITTAR=5 and CALPART='TI'
	;
QUIT;

proc sql;
	create table panes2 as 
		select
			*,
			mdy(mod(int(fec_ven/100),100),mod(fec_ven,100),int(fec_ven/10000)) format=date9. as fec_ven2,
			put(intnx('month',calculated fec_ven2,0,'end'),mmddyy10.) as fec_ven_F
		from panes
	;
QUIT;

PROC SQL;
	CREATE TABLE TR_TARJETAS AS 
		SELECT DISTINCT 
			A.ID_USUARIO,
			A.TIPO_TARJETA,
			A.TIPO_CAPTACION,
			A.FECHA_CAPTACION,
			A.ABONO_MONTO,
			A.FECHA_ULTIMO_ABONO,
			A.RETIRO_PLASTICO,
		CASE 
			WHEN A.ESTADO<>'sin_cv' THEN a.estado
			when A.ESTADO='sin_cv' AND B.CODBLQ<>0 THEN B.MOTIVO_BLOQUEO 
			when A.ESTADO='sin_cv' AND B.CODBLQ=0 THEN 'sin_bloqueo' 
		END 
	AS ESTADO,
		b.fec_ven_F as FECHA_VENCIMIENTO
	FROM FINAL3 AS A 
		LEFT JOIN PANES2 AS B 
			ON (A.CUENTA=B.CUENTA) AND (A.ID_USUARIO=B.RUT)
	;
QUIT;

proc sql;
create table &libreria_1..tr_tarjetas as
select *
from TR_TARJETAS
where id_usuario not in (select rut from result.chek_inhibir_tam)
;quit;

PROC EXPORT DATA = &libreria_1..TR_TARJETAS
	OUTFILE="/sasdata/users94/user_bi/unica/input/INPUT-TR_TARJETAS-USER_BI.csv"
	DBMS=dlm REPLACE;
	delimiter=',';
	PUTNAMES=YES;
RUN;

/*EXPORTACION AWS*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(input_tr_tarjetas,raw,oracloud/campaign,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(input_tr_tarjetas,&libreria_1..TR_TARJETAS,raw,oracloud/campaign,0);


/* Tabla disponible en AWS, tabla salida proceso SAS */

/*==================================================================================================*/
/*==================================	TIEMPO Y ENVÍO DE EMAIL		================================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/


/*==================================	FECHA DEL PROCESO  			================================*/
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
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_BI_PPFF';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_SEGMENTOS';
	SELECT EMAIL into :DEST_5 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_SEGMENTOS_1';
	SELECT EMAIL into :DEST_6 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_BI_PPFF_1';
	SELECT EMAIL into :DEST_7 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFATURA_CAMP';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;	%put &=DEST_4;	%put &=DEST_5;	%put &=DEST_6;	%put &=DEST_7;

data _null_;
FILENAME OUTBOX EMAIL
FROM 	= ("&EDP_BI")
TO 		= ("&DEST_3","&DEST_4","&DEST_5", "&DEST_6", "&DEST_7")
CC 		= ("&DEST_1", "&DEST_2")
SUBJECT = ("MAIL_AUTOM: Proceso ONBOARDING TR TARJETAS");
FILE OUTBOX;
 PUT "Estimados:";
 PUT "		Proceso ONBOARDING TR TARJETAS, ejecutado con fecha: &fechaeDVN";  
 PUT "		Tabla generada: &libreria_1..TR_TARJETAS";
	PUT;
	PUT;
	put 'Proceso Vers. 09';
	PUT;
	PUT;
	PUT 'Atte.';
	Put 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
