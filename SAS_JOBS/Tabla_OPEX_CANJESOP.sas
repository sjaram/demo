/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================    TABLA_OPEX_CANJESOP  			 ===============================*/

/* CONTROL DE VERSIONES
/* 2023-07-16 -- V07 -- Alejandra M.-- Se saco el left join con DCRM_DIM_MAE_ART_RTL porque no se trae nada de esa tabla*/
/* 2023-06-13 -- v06 -- Esteban P.	-- Se actualizan variables de gedcre.
/* 2023-05-15 -- v05 -- Sergio J.	-- Se agrega variable feche para arreglar export aws
/* 2023-04-21 -- v04 -- David V.	-- Export to aws + se quita control de errores old.
/* 2022-09-05 -- v03 -- Sergio J. 	-- Cambio de sbarrera.Codigos_CanjesOP por bsoto.
/* 2021-05-04 -- v02 -- Alejandra M.--  
				 -- Se cambia libreria de sbarrera a publicin.Codigos_Opex */

/*Información:
Tabla de Boletas con Opex y Canjes de Oportunidad RP

*/

DATA _null_;
per = put(intnx('mONth',today(),0,'end'), yymmn6.);
exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("Periodo",per);
Call symput("fechae",exec);
RUN;
%put &Periodo; 
%put &fechae;

/*#######################################################################################################*/
/*Proceso: Tabla de Boletas con Opex y Canjes de Oportunidad RP*/
/*#######################################################################################################*/

%put=======================================================================================;
%put [01] Unificar tabla de Codigos que se usara para filtrar desde venta cruzada;
%put=======================================================================================;

proc sql;
	create table work.Codigos_Opex_Canjes as 
		select 
			coalesce(a.Codigo,b.Codigo) as Codigo,
		case 
			when a.Codigo is not null and b.Codigo is not null then 'CANJE+OPEX' 
			when b.Codigo is not null then 'CANJE' 
			when a.Codigo is not null then 'OPEX' 
		end 
	as Tipo_Codigo,
		b.CANJE_OP_Ptos, 
		b.CANJE_OP_Copago 
	from ( 
		select distinct Codigo 
			from publicin.Codigos_Opex /*Tabla de Codigos OPEX*/
				) as a 
			full outer join ( 
				select 
					Cod_Promo as Codigo,
					max(PUNTOS) as CANJE_OP_Ptos,
					max(COPAGO) as CANJE_OP_Copago 
				from bsoto.Codigos_CanjesOP /*Tabla de Codigos Canjes Oportunidad*/
					group by 
						Cod_Promo 
						) as b 
						on (a.Codigo=b.Codigo) 
					order by 
						calculated Tipo_Codigo 
	;
quit;

proc sql;
	connect to SQLSVR as mydb
		(datasrc="SQL_Datawarehouse" user="user_sas" PASSWORD="{sas002}AC224E474B8742BD13124A965275013020A60F8D15DCC25A52A5D43F49A76B4D");
	create table work.OPEX_CANJESOP as
		select  a.TXMVC_RUT_DST as rut,
			input(put(datepart(a.TXMVC_FCH_TRN_K),yymmddn8.),best.) as Fecha,
			a.TXMVC_COD_SUC_K as Codigo_Sucursal, 
			cat(a.TXMVC_COD_SUC_K+10000,' ',input(put(datepart(a.TXMVC_FCH_TRN_K),yymmddn8.),best.),' ',input(a.TXMVC_GLS_CAJ_K,best.),' ',a.TXMVC_NRO_TRN_K) as BOLETA,
			a.TXMVC_NRO_ITM_K as Nro_Item,
			a.TXMVC_COD_PRM_K as Codigo,
			INPUT(LEFT(put(a.TXMVC_MNT_DST,7.)),BEST.) as DCTO ,
			b.Tipo_Codigo, /*OPEX o CANJE*/
	b.CANJE_OP_Ptos, /*traerse ademas ptos correspondientes a oportunidad*/
	b.CANJE_OP_Copago /*traerse ademas copago correspondientes a oportunidad*/
	from connection to mydb ( /*Query de conexion Loyalty*/
		select 
			cast(SUBSTRING(CONVERT(VARCHAR(10), TXMVC_FCH_TRN_K, 111),1,4) as int)*100+cast(SUBSTRING(CONVERT(VARCHAR(10), TXMVC_FCH_TRN_K, 111),6,2) as int) as fec1,
			TXMVC_RUT_DST,
			TXMVC_FCH_TRN_K,
			TXMVC_COD_SUC_K,
			TXMVC_GLS_CAJ_K,
			TXMVC_NRO_DCT_K as TXMVC_NRO_TRN_K,
			TXMVC_NRO_ITM_K,
			TXMVC_COD_PRM_K,
			TXMVC_MNT_DST,*
		from db2.CRBDTX_MOV_VTA_CRZ a 
			where TXMVC_NRO_ITM_K>0   and cast(SUBSTRING(CONVERT(VARCHAR(10), TXMVC_FCH_TRN_K, 111),1,4) as int)*100+cast(SUBSTRING(CONVERT(VARCHAR(10), TXMVC_FCH_TRN_K, 111),6,2) as int)=&Periodo
				) as a
			inner join work.Codigos_Opex_Canjes as b /*Tabla de Codigos Unificada*/
	on (a.TXMVC_COD_PRM_K=b.CODIGO)
	where  INPUT(LEFT(put(A.TXMVC_MNT_DST,7.)),BEST.)>0 /*extrañamente algunos registros vienen con DCTO=0*/
	;
quit;

/*Eliminar tabla de paso*/
PROC SQL;
	drop table work.Codigos_Opex_Canjes 

	;
QUIT;

%put=======================================================================================;
%put [03] Para Ripley.com Rescatar OPEX;
%put=======================================================================================;

%put---------------------------------------------------------------------------------------;
%put [03.1] Extraccion de TRXs de Ripley.com desde Venta Detalle Articulo;

%put---------------------------------------------------------------------------------------;
%let mz_connect_zeus=CONNECT TO ODBC as zeus(datasrc="creditoprd" user="CONSULTA_CREDITO" password="crdt#0806");

PROC SQL;
	&MZ_CONNECT_ZEUS;
	CREATE TABLE work.Vta_TDA_online AS 
		SELECT * 

		FROM CONNECTION TO ZEUS(

		SELECT 
			B.DDMDT_RUT_CLI AS rut,
			B.DDMTD_FCH_DIA AS Fecha,
			B.DDMSU_COD_SUC-10000 as Codigo_Sucursal,
			B.DDMSU_COD_SUC||' '||B.DDMTD_FCH_DIA||' '||DCMDT_NRO_TML||' '||DCMDT_NRO_DCT  AS BOLETA,
			B.DCMDT_NRO_ITM AS Nro_ITEM,
			B.DDMAR_COD_SKU_ART AS SKU  
		FROM GEDCRE_CREDITO.DCRM_COS_MOV_TRN_DET_VTA_ART as B 
/*			LEFT JOIN GEDCRE_CREDITO.DCRM_DIM_MAE_ART_RTL as D 
				ON (B.DDMAR_COD_SKU_ART=D.DDMAR_COD_SKU_ART) */
			WHERE B.DDMSU_COD_NEG=1 
				AND B.DCMDT_COD_CMR_ASO=1
				AND B.DCMDT_COD_TRN NOT IN(39,401,402,89,90,93) 
				AND B.DDMSU_COD_SUC NOT IN (10993,10990) 
				AND B.DCMDT_COD_TIP_TRN=1  /*SOLO COMPRAS*/
				and B.DDMSU_COD_SUC=10039 
				and B.DDMTD_FCH_DIA<=100*&Periodo+31 
				and B.DDMTD_FCH_DIA>=100*&Periodo+01 

				) as C

	;
QUIT;

%put---------------------------------------------------------------------------------------;
%put [03.2] Cruce con Tabla de Precios SKUs con OPEX en .com;

%put---------------------------------------------------------------------------------------;

/*Se extraen todos los SKUs del Periodo*/
proc sql;
	connect to SQLSVR as mydb
		(datasrc="SQL_Datawarehouse" user="user_sas" PASSWORD="{sas002}AC224E474B8742BD13124A965275013020A60F8D15DCC25A52A5D43F49A76B4D");
	create table work.Precios_SKU_Fecha as
		select 
			sku,
			Fecha,
			offerPrice as Precio_OMP,
			cardprice as Precio_TC,
			offerprice-cardprice as DCTO  
		from connection to mydb ( /*Query de conexion Loyalty*/

		select 
			offerPrice,
			cardprice,
			cast(replace(fecha_carga,'-','') as int) as Fecha,
			sku  
		from db2.Precios_Productos_Publicados
			where cardprice>0 
				and offerprice-cardprice>0 
				and floor(cast(replace(fecha_carga,'-','') as int)/100)=&Periodo 

				) as conexion

	;
quit;

/*Se hace cruce*/
proc sql;
	create table work.opex_com as
		select distinct 
			a.*,
			b.DCTO 
		from work.Vta_TDA_online as a
			inner join (
				select 
					fecha,
					sku,
					min(DCTO) as DCTO
				from work.Precios_SKU_Fecha  
					group by 
						sku,
						fecha
						) as b
						on (a.sku=b.sku and a.fecha=b.fecha) 

	;
quit;

%put---------------------------------------------------------------------------------------;
%put [03.3] Unificar Tablas (Presencial + .com) adaptando Formato;

%put---------------------------------------------------------------------------------------;

proc sql;
	create table work.OPEX_CANJESOP2 as 
		select * 
			from (

			select 
				rut,
				Fecha,
				Codigo_Sucursal,
				BOLETA,
				Nro_Item,
				Codigo,
				DCTO,
				Tipo_Codigo,
				CANJE_OP_Ptos,
				CANJE_OP_Copago 
			from work.OPEX_CANJESOP 

			outer union corr 

			select 
				rut,
				Fecha,
				Codigo_Sucursal,
				BOLETA,
				Nro_Item,
				0 as Codigo,
				DCTO,
				'OPEX' as Tipo_Codigo,
				0 as CANJE_OP_Ptos,
				0 as CANJE_OP_Copago 
			from work.opex_com 

				) as x 

	;
quit;

%put=======================================================================================;
%put [04] Guardar Resultados en tabla entregable;
%put=======================================================================================;

proc sql;
CREATE TABLE PUBLICIN.OPEX_CANJESOP_&Periodo. AS 
SELECT 
&fechae. as Fecha_Proceso, 
*  
from work.OPEX_CANJESOP2  
;quit;

proc sql;
CREATE TABLE result.vista_email AS 
SELECT max(fecha) as Fecha_maxima,
count(*) as nro_registros 
from PUBLICIN.OPEX_CANJESOP_&Periodo.
;quit;

DATA _null_;
dateMES	= input(put(intnx('month',today(),0,'end'),yymmn6.),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
Call symput("fechaMES", dateMES);
RUN;
%put &fechaMES;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_tnda_opex_canjesop,publicin.OPEX_CANJESOP_&fechaMES.,raw,sasdata,0);


/*Eliminar tablas de paso*/
proc sql;
	drop table work.Precios_SKU_Fecha;
quit;

proc sql;
	drop table work.Vta_TDA_online;
quit;

proc sql;
	drop table work.opex_com;
quit;

proc sql;
	drop table work.OPEX_CANJESOP;
quit;

PROC SQL;
	drop table work.OPEX_CANJESOP2;
QUIT;
