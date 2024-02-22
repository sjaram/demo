/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================		BANCO_SECUNDARIO		================================*/
/* CONTROL DE VERSIONES
/* 2021-06-03 -- V1 -- Sebastián Barrera --  
					-- Original + detalles para automatización por parte de David

/* INFORMACIÓN:
	Proceso que mediante un análisis entrega los bancos secundarios que pueden tener nuestros clientes.

	(IN) Tablas requeridas o conexiones a BD:
	- 

	(OUT) Tablas de Salida o resultado:
 	- 
*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/ 

/*#########################################################################################*/
/*Proceso de Creacion Indicador Banco Secundario*/
/*#########################################################################################*/

/********************************** Comenzar Proceso ***************************************/
/*PARAMETROS::*/
/*:::::::::::::::::::::::*/
DATA _null_;
/* Variables Fechas de Ejecución */
datePeriodoAnterior = input(put(intnx('month',today(),-1,'end' ),yymmn6. ),$10.);
Call symput("VdateANT", datePeriodoAnterior);
RUN;
%put &VdateANT;

%let Periodo=&VdateANT; /*periodo al que se extraera la info*/
%let Ventana_Tiempo=6; /*ventana de tiempo hacia atras que se considerara*/
%let Base_Entregable=%nrstr('PUBLICIN.Sgdo_Bco'); /*Base entregable con mayuscula*/
/*:::::::::::::::::::::::*/


options cmplib=sbarrera.funcs; /*comando necesario para invocar funciones dentro de proc sql*/
%put &periodo;

%put==========================================================================================;
%put [01] Extraccion de Bases de TEFs (solo campos relevantes);
%put==========================================================================================;

%put------------------------------------------------------------------------------------------;
%put [01.0] Conversion de Fechas en formato necesario;
%put------------------------------------------------------------------------------------------;



PROC SQL noprint outobs=1;   

select 
100*SB_mover_anomes(&Periodo,-1*(&Ventana_Tiempo-1))+01 as Periododia_desde,
SB_mover_anomesdia(100*SB_mover_anomes(&Periodo,1)+01,-1) as Periododia_hasta 
into :Periododia_desde,:Periododia_hasta 
from sashelp.vmember

;QUIT;




PROC SQL noprint outobs=1;   

select 
cat(substr(compress(put(&Periododia_desde,best.)),7,2),'/',substr(compress(put(&Periododia_desde,best.)),5,2),'/',substr(compress(put(&Periododia_desde,best.)),1,4)) as Fecha1_desde,
cat(substr(compress(put(&Periododia_hasta,best.)),7,2),'/',substr(compress(put(&Periododia_hasta,best.)),5,2),'/',substr(compress(put(&Periododia_hasta,best.)),1,4)) as Fecha1_hasta 
into :Fecha1_desde,:Fecha1_hasta
from sashelp.vmember

;QUIT;
%let Fecha1_desde="&Fecha1_desde";
%let Fecha1_hasta="&Fecha1_hasta";



%put------------------------------------------------------------------------------------------;
%put [01.1] Conexion a FISA;
%put------------------------------------------------------------------------------------------;


%let mz_connect_BANCO=CONNECT TO ORACLE as BANCO(USER='RIPLEYC' PASSWORD='ri99pley'
PATH="  (DESCRIPTION = 
    (ADDRESS_LIST = 
      (ADDRESS = 
        (PROTOCOL = TCP)
        (Host = 192.168.10.31)
        (Port = 1521)
      )
    )
    (CONNECT_DATA = 
      (SID = ripleyc)
    )
  )
");



%put------------------------------------------------------------------------------------------;
%put [01.2] Base de TEFs: Unificada;
%put------------------------------------------------------------------------------------------;



DATA _NULL_;
Call execute(
cat('
proc sql; 

&mz_connect_BANCO; 
create table work.TEFs as 
SELECT 

Nro_Cta_Origen,
Rut_Origen,
case 
when Cod_Bco_Origen=504 then ''BBVA'' 
when Cod_Bco_Origen=16 then ''BCI'' 
when Cod_Bco_Origen=28 then ''BICE'' 
when Cod_Bco_Origen=1 then ''BCH'' 
when Cod_Bco_Origen=55 then ''Consorcio'' 
when Cod_Bco_Origen=672 then ''COOPEUCH'' 
when Cod_Bco_Origen=27 then ''CorpBanca'' 
when Cod_Bco_Origen=507 then ''Desarrollo'' 
when Cod_Bco_Origen=12 then ''Estado'' 
when Cod_Bco_Origen=51 then ''Falabella'' 
when Cod_Bco_Origen=9 then ''Internacional'' 
when Cod_Bco_Origen=39 then ''Itau'' 
when Cod_Bco_Origen=53 then ''Ripley'' 
when Cod_Bco_Origen=37 then ''Santander'' 
when Cod_Bco_Origen=14 then ''ScotiaBank'' 
when Cod_Bco_Origen=49 then ''Security'' 
else ''Otros'' 
end as Bco_Origen, 
10000*year(datepart(Fecha_TEF))+100*month(datepart(Fecha_TEF))+day(datepart(Fecha_TEF)) as Fecha,
Monto_TEF as Monto,
Mensaje_TEF as Mensaje,
Nro_Cta_Destino,
Rut_Destino,
case 
when Cod_Bco_Destino=504 then ''BBVA'' 
when Cod_Bco_Destino=16 then ''BCI'' 
when Cod_Bco_Destino=28 then ''BICE'' 
when Cod_Bco_Destino=1 then ''BCH'' 
when Cod_Bco_Destino=55 then ''Consorcio'' 
when Cod_Bco_Destino=672 then ''COOPEUCH'' 
when Cod_Bco_Destino=27 then ''CorpBanca'' 
when Cod_Bco_Destino=507 then ''Desarrollo'' 
when Cod_Bco_Destino=12 then ''Estado'' 
when Cod_Bco_Destino=51 then ''Falabella'' 
when Cod_Bco_Destino=9 then ''Internacional'' 
when Cod_Bco_Destino=39 then ''Itau'' 
when Cod_Bco_Destino=53 then ''Ripley'' 
when Cod_Bco_Destino=37 then ''Santander'' 
when Cod_Bco_Destino=14 then ''ScotiaBank'' 
when Cod_Bco_Destino=49 then ''Security'' 
else ''Otros'' 
end as Bco_Destino 

from (

select 
''BOTEF_ADM.BOTEF_MOV_TRN_IFR'' as Base_Procedencia,
''TEfs Receptor Bco Ripley'' as Base_Descripcion, 
* 
from  connection to BANCO(

select 
MTIFR_NRO_CTA_ORE as Nro_Cta_Origen,
MTIFR_RUN_CLI_ORE as Rut_Origen, 
PBCO_IDE_FK as Cod_Bco_Origen,
MTIFR_FCH_ING_TRS as Fecha_TEF,
MTIFR_GLS_MOT_ORC_TRS as Mensaje_TEF,
MTIFR_MNT_ORC_TRS as Monto_TEF,
MTIFR_NRO_CTA_DTN as Nro_Cta_Destino,
MTIFR_RUN_CLI_DTN as Rut_Destino,
PBCO_IDED_FK as Cod_Bco_Destino 
from BOTEF_ADM.BOTEF_MOV_TRN_IFR 
where MTIFR_FLG_EST_TRS=2 /*TRXs correcta*/
and MTIFR_FCH_ING_TRS>=to_date(''',&Fecha1_desde,''',''dd/mm/yyyy'')
and MTIFR_FCH_ING_TRS<=to_date(''',&Fecha1_hasta,''',''dd/mm/yyyy'')

) as C1_Receptor

outer union corr 

select 
''BOTEF_ADM.BOTEF_MOV_TRN_IFO'' as Base_Procedencia,
''TEfs Emisor Bco Ripley'' as Base_Descripcion, 
* 
from  connection to BANCO(

select 
MTIFO_NRO_CTA_ORE as Nro_Cta_Origen,
MTIFO_RUN_CLI_ORE as Rut_Origen, 
PBCO_IDE_FK as Cod_Bco_Origen,
MTIFO_FCH_ING_TRS as Fecha_TEF,
MTIFO_GLS_MOT_ORC_TRS as Mensaje_TEF,
MTIFO_MNT_ORC_TRS as Monto_TEF,
MTIFO_NRO_CTA_DTN as Nro_Cta_Destino,
MTIFO_RUN_CLI_DTN as Rut_Destino,
PBCO_IDED_FK as Cod_Bco_Destino 
from BOTEF_ADM.BOTEF_MOV_TRN_IFO 
where MTIFO_FLG_EST_TRS=2 /*TRXs correcta*/
and MTIFO_GLS_MOT_ORC_TRS<>''PAGO TRX'' /*quitar pagos a tarjeta de credito desde CtaVta*/ 
and MTIFO_FCH_ING_TRS>=to_date(''',&Fecha1_desde,''',''dd/mm/yyyy'')
and MTIFO_FCH_ING_TRS<=to_date(''',&Fecha1_hasta,''',''dd/mm/yyyy'')

) as C2_Emisor 

) as X 

;QUIT;
')
);
run;


%put==========================================================================================;
%put [02] Generar tabla unificada de movimientos tefs agrupada por rut-banco;
%put==========================================================================================;


/*Se unifican movs como emisor y receptor, se consideran ambos como movs de uso*/

proc sql;

create table work.TEFs2 as 
select 
RUT,
Banco,
count(*) as Nro_TRXs,
count(distinct Fecha) as Nro_Dias_Distintos,
count(distinct floor(Fecha/100)) as Frecuencia,
sum(Monto) as Mto_TRXs,
max(floor(Fecha/100)) as Max_Fecha 
from (

select 
Rut_Origen as RUT,
Bco_Origen as Banco,
Fecha,
Monto 
from work.TEFs 

outer union corr 

select 
Rut_Destino as RUT,
Bco_Destino as Banco,
Fecha,
Monto 
from work.TEFs 

) as X
group by 
rut,
Banco

;quit;


/*Eliminar tabla de paso*/


proc sql;

drop table work.TEFs  

;quit;




%put==========================================================================================;
%put [03] Calcular Indicadores de Frecuencia, Recencia y Monto por Banco;
%put==========================================================================================;



proc sql;

create table work.TEFs3 as 
select 
rut,
max(case when Banco='BCH' then Frecuencia else 0 end) as F_BCH,
max(case when Banco='Santander' then Frecuencia else 0 end) as F_Santander,
max(case when Banco='Estado' then Frecuencia else 0 end) as F_Estado,
max(case when Banco='BCI' then Frecuencia else 0 end) as F_BCI,
max(case when Banco='BICE' then Frecuencia else 0 end) as F_BICE,
max(case when Banco='Itau' then Frecuencia else 0 end) as F_Itau,
max(case when Banco='Security' then Frecuencia else 0 end) as F_Security,
max(case when Banco='BBVA' then Frecuencia else 0 end) as F_BBVA,
max(case when Banco='ScotiaBank' then Frecuencia else 0 end) as F_ScotiaBank,
max(case when Banco='CorpBanca' then Frecuencia else 0 end) as F_CorpBanca,
max(case when Banco='Falabella' then Frecuencia else 0 end) as F_Falabella,
max(case when Banco='Ripley' then Frecuencia else 0 end) as F_Ripley,
max(case when Banco='Consorcio' then Frecuencia else 0 end) as F_Consorcio,
max(case when Banco='COOPEUCH' then Frecuencia else 0 end) as F_COOPEUCH,
max(case when Banco='Desarrollo' then Frecuencia else 0 end) as F_Desarrollo,
max(case when Banco='Internacional' then Frecuencia else 0 end) as F_Internacional,
max(case when Banco='Otros' then Frecuencia else 0 end) as F_Otros,

SB_meses_entre(max(case when Banco='BCH' then Max_Fecha else 0 end),&Periodo) as R_BCH,
SB_meses_entre(max(case when Banco='Santander' then Max_Fecha else 0 end),&Periodo) as R_Santander,
SB_meses_entre(max(case when Banco='Estado' then Max_Fecha else 0 end),&Periodo) as R_Estado,
SB_meses_entre(max(case when Banco='BCI' then Max_Fecha else 0 end),&Periodo) as R_BCI,
SB_meses_entre(max(case when Banco='BICE' then Max_Fecha else 0 end),&Periodo) as R_BICE,
SB_meses_entre(max(case when Banco='Itau' then Max_Fecha else 0 end),&Periodo) as R_Itau,
SB_meses_entre(max(case when Banco='Security' then Max_Fecha else 0 end),&Periodo) as R_Security,
SB_meses_entre(max(case when Banco='BBVA' then Max_Fecha else 0 end),&Periodo) as R_BBVA,
SB_meses_entre(max(case when Banco='ScotiaBank' then Max_Fecha else 0 end),&Periodo) as R_ScotiaBank,
SB_meses_entre(max(case when Banco='CorpBanca' then Max_Fecha else 0 end),&Periodo) as R_CorpBanca,
SB_meses_entre(max(case when Banco='Falabella' then Max_Fecha else 0 end),&Periodo) as R_Falabella,
SB_meses_entre(max(case when Banco='Ripley' then Max_Fecha else 0 end),&Periodo) as R_Ripley,
SB_meses_entre(max(case when Banco='Consorcio' then Max_Fecha else 0 end),&Periodo) as R_Consorcio,
SB_meses_entre(max(case when Banco='COOPEUCH' then Max_Fecha else 0 end),&Periodo) as R_COOPEUCH,
SB_meses_entre(max(case when Banco='Desarrollo' then Max_Fecha else 0 end),&Periodo) as R_Desarrollo,
SB_meses_entre(max(case when Banco='Internacional' then Max_Fecha else 0 end),&Periodo) as R_Internacional,
SB_meses_entre(max(case when Banco='Otros' then Max_Fecha else 0 end),&Periodo) as R_Otros,

max(case when Banco='BCH' then Mto_TRXs else 0 end) as M_BCH,
max(case when Banco='Santander' then Mto_TRXs else 0 end) as M_Santander,
max(case when Banco='Estado' then Mto_TRXs else 0 end) as M_Estado,
max(case when Banco='BCI' then Mto_TRXs else 0 end) as M_BCI,
max(case when Banco='BICE' then Mto_TRXs else 0 end) as M_BICE,
max(case when Banco='Itau' then Mto_TRXs else 0 end) as M_Itau,
max(case when Banco='Security' then Mto_TRXs else 0 end) as M_Security,
max(case when Banco='BBVA' then Mto_TRXs else 0 end) as M_BBVA,
max(case when Banco='ScotiaBank' then Mto_TRXs else 0 end) as M_ScotiaBank,
max(case when Banco='CorpBanca' then Mto_TRXs else 0 end) as M_CorpBanca,
max(case when Banco='Falabella' then Mto_TRXs else 0 end) as M_Falabella,
max(case when Banco='Ripley' then Mto_TRXs else 0 end) as M_Ripley,
max(case when Banco='Consorcio' then Mto_TRXs else 0 end) as M_Consorcio,
max(case when Banco='COOPEUCH' then Mto_TRXs else 0 end) as M_COOPEUCH,
max(case when Banco='Desarrollo' then Mto_TRXs else 0 end) as M_Desarrollo,
max(case when Banco='Internacional' then Mto_TRXs else 0 end) as M_Internacional,
max(case when Banco='Otros' then Mto_TRXs else 0 end) as M_Otros 

from work.TEFs2
group by 
rut

;quit;



/*Eliminar tabla de paso*/


proc sql;

drop table work.TEFs2  

;quit;



%put==========================================================================================;
%put [04] Normalizar Indicadores de RFM y Ponderar creando unico indicador por Banco;
%put==========================================================================================;



proc sql;

create table work.TEFs4 as 
select 
rut,
round(
0.5*SB_Valor_Interpolado(F_BCH,1,0,&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(R_BCH,1,&Ventana_Tiempo,0,0,1)+
0.2*SB_Valor_Interpolado(M_BCH,1,0,20000*&Ventana_Tiempo,0,1) 
,.001)
as Indicador_BCH,
round(
0.5*SB_Valor_Interpolado(F_Santander,1,0,&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(R_Santander,1,&Ventana_Tiempo,0,0,1)+
0.2*SB_Valor_Interpolado(M_Santander,1,0,20000*&Ventana_Tiempo,0,1)
,.001)
as Indicador_Santander,
round(
0.5*SB_Valor_Interpolado(F_Estado,1,0,&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(R_Estado,1,&Ventana_Tiempo,0,0,1)+
0.2*SB_Valor_Interpolado(M_Estado,1,0,20000*&Ventana_Tiempo,0,1)
,.001)
as Indicador_Estado,
round(
0.5*SB_Valor_Interpolado(F_BCI,1,0,&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(R_BCI,1,&Ventana_Tiempo,0,0,1)+
0.2*SB_Valor_Interpolado(M_BCI,1,0,20000*&Ventana_Tiempo,0,1)
,.001)
as Indicador_BCI,
round(
0.5*SB_Valor_Interpolado(F_BICE,1,0,&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(R_BICE,1,&Ventana_Tiempo,0,0,1)+
0.2*SB_Valor_Interpolado(M_BICE,1,0,20000*&Ventana_Tiempo,0,1)
,.001)
as Indicador_BICE,
round(
0.5*SB_Valor_Interpolado(F_Itau,1,0,&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(R_Itau,1,&Ventana_Tiempo,0,0,1)+
0.2*SB_Valor_Interpolado(M_Itau,1,0,20000*&Ventana_Tiempo,0,1)
,.001)
as Indicador_Itau,
round(
0.5*SB_Valor_Interpolado(F_Security,1,0,&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(R_Security,1,&Ventana_Tiempo,0,0,1)+
0.2*SB_Valor_Interpolado(M_Security,1,0,20000*&Ventana_Tiempo,0,1)
,.001)
as Indicador_Security,
round(
0.5*SB_Valor_Interpolado(F_BBVA,1,0,&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(R_BBVA,1,&Ventana_Tiempo,0,0,1)+
0.2*SB_Valor_Interpolado(M_BBVA,1,0,20000*&Ventana_Tiempo,0,1)
,.001)
as Indicador_BBVA,
round(
0.5*SB_Valor_Interpolado(F_ScotiaBank,1,0,&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(R_ScotiaBank,1,&Ventana_Tiempo,0,0,1)+
0.2*SB_Valor_Interpolado(M_ScotiaBank,1,0,20000*&Ventana_Tiempo,0,1)
,.001)
as Indicador_ScotiaBank,
round(
0.5*SB_Valor_Interpolado(F_CorpBanca,1,0,&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(R_CorpBanca,1,&Ventana_Tiempo,0,0,1)+
0.2*SB_Valor_Interpolado(M_CorpBanca,1,0,20000*&Ventana_Tiempo,0,1)
,.001)
as Indicador_CorpBanca,
round(
0.5*SB_Valor_Interpolado(F_Falabella,1,0,&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(R_Falabella,1,&Ventana_Tiempo,0,0,1)+
0.2*SB_Valor_Interpolado(M_Falabella,1,0,20000*&Ventana_Tiempo,0,1)
,.001)
as Indicador_Falabella,
round(
0.5*SB_Valor_Interpolado(F_Ripley,1,0,&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(R_Ripley,1,&Ventana_Tiempo,0,0,1)+
0.2*SB_Valor_Interpolado(M_Ripley,1,0,20000*&Ventana_Tiempo,0,1)
,.001)
as Indicador_Ripley,
round(
0.5*SB_Valor_Interpolado(F_Consorcio,1,0,&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(R_Consorcio,1,&Ventana_Tiempo,0,0,1)+
0.2*SB_Valor_Interpolado(M_Consorcio,1,0,20000*&Ventana_Tiempo,0,1)
,.001)
as Indicador_Consorcio,
round(
0.5*SB_Valor_Interpolado(F_COOPEUCH,1,0,&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(R_COOPEUCH,1,&Ventana_Tiempo,0,0,1)+
0.2*SB_Valor_Interpolado(M_COOPEUCH,1,0,20000*&Ventana_Tiempo,0,1)
,.001)
as Indicador_COOPEUCH,
round(
0.5*SB_Valor_Interpolado(F_Desarrollo,1,0,&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(R_Desarrollo,1,&Ventana_Tiempo,0,0,1)+
0.2*SB_Valor_Interpolado(M_Desarrollo,1,0,20000*&Ventana_Tiempo,0,1)
,.001)
as Indicador_Desarrollo,
round(
0.5*SB_Valor_Interpolado(F_Internacional,1,0,&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(R_Internacional,1,&Ventana_Tiempo,0,0,1)+
0.2*SB_Valor_Interpolado(M_Internacional,1,0,20000*&Ventana_Tiempo,0,1)
,.001)
as Indicador_Internacional,
round(
0.5*SB_Valor_Interpolado(F_Otros,1,0,&Ventana_Tiempo,0,1)+
0.3*SB_Valor_Interpolado(R_Otros,1,&Ventana_Tiempo,0,0,1)+
0.2*SB_Valor_Interpolado(M_Otros,1,0,20000*&Ventana_Tiempo,0,1)
,.001)
as Indicador_Otros 
from work.TEFs3

;quit;



/*Eliminar tabla de paso*/


proc sql;

drop table work.TEFs3  

;quit;


%put==========================================================================================;
%put [05] Determinar Principal Banco compartido y nro de otros Bancos;
%put==========================================================================================;





proc sql;

create table work.TEFs4 as 
select 
*,
case
when
Indicador_BCH>0 and 
Indicador_BCH>=Indicador_BCH and 
Indicador_BCH>=Indicador_Santander and 
Indicador_BCH>=Indicador_Estado and 
Indicador_BCH>=Indicador_BCI and 
Indicador_BCH>=Indicador_BICE and 
Indicador_BCH>=Indicador_Itau and 
Indicador_BCH>=Indicador_Security and 
Indicador_BCH>=Indicador_BBVA and 
Indicador_BCH>=Indicador_ScotiaBank and 
Indicador_BCH>=Indicador_CorpBanca and 
Indicador_BCH>=Indicador_Falabella and 
Indicador_BCH>=Indicador_Consorcio and 
Indicador_BCH>=Indicador_COOPEUCH and 
Indicador_BCH>=Indicador_Desarrollo and 
Indicador_BCH>=Indicador_Internacional and 
Indicador_BCH>=Indicador_Otros
then 'BCH'
when
Indicador_Santander>0 and 
Indicador_Santander>=Indicador_BCH and 
Indicador_Santander>=Indicador_Santander and 
Indicador_Santander>=Indicador_Estado and 
Indicador_Santander>=Indicador_BCI and 
Indicador_Santander>=Indicador_BICE and 
Indicador_Santander>=Indicador_Itau and 
Indicador_Santander>=Indicador_Security and 
Indicador_Santander>=Indicador_BBVA and 
Indicador_Santander>=Indicador_ScotiaBank and 
Indicador_Santander>=Indicador_CorpBanca and 
Indicador_Santander>=Indicador_Falabella and 
Indicador_Santander>=Indicador_Consorcio and 
Indicador_Santander>=Indicador_COOPEUCH and 
Indicador_Santander>=Indicador_Desarrollo and 
Indicador_Santander>=Indicador_Internacional and 
Indicador_Santander>=Indicador_Otros
then 'Santander'
when
Indicador_Estado>0 and 
Indicador_Estado>=Indicador_BCH and 
Indicador_Estado>=Indicador_Santander and 
Indicador_Estado>=Indicador_Estado and 
Indicador_Estado>=Indicador_BCI and 
Indicador_Estado>=Indicador_BICE and 
Indicador_Estado>=Indicador_Itau and 
Indicador_Estado>=Indicador_Security and 
Indicador_Estado>=Indicador_BBVA and 
Indicador_Estado>=Indicador_ScotiaBank and 
Indicador_Estado>=Indicador_CorpBanca and 
Indicador_Estado>=Indicador_Falabella and 
Indicador_Estado>=Indicador_Consorcio and 
Indicador_Estado>=Indicador_COOPEUCH and 
Indicador_Estado>=Indicador_Desarrollo and 
Indicador_Estado>=Indicador_Internacional and 
Indicador_Estado>=Indicador_Otros
then 'Estado'
when
Indicador_BCI>0 and 
Indicador_BCI>=Indicador_BCH and 
Indicador_BCI>=Indicador_Santander and 
Indicador_BCI>=Indicador_Estado and 
Indicador_BCI>=Indicador_BCI and 
Indicador_BCI>=Indicador_BICE and 
Indicador_BCI>=Indicador_Itau and 
Indicador_BCI>=Indicador_Security and 
Indicador_BCI>=Indicador_BBVA and 
Indicador_BCI>=Indicador_ScotiaBank and 
Indicador_BCI>=Indicador_CorpBanca and 
Indicador_BCI>=Indicador_Falabella and 
Indicador_BCI>=Indicador_Consorcio and 
Indicador_BCI>=Indicador_COOPEUCH and 
Indicador_BCI>=Indicador_Desarrollo and 
Indicador_BCI>=Indicador_Internacional and 
Indicador_BCI>=Indicador_Otros
then 'BCI'
when
Indicador_BICE>0 and 
Indicador_BICE>=Indicador_BCH and 
Indicador_BICE>=Indicador_Santander and 
Indicador_BICE>=Indicador_Estado and 
Indicador_BICE>=Indicador_BCI and 
Indicador_BICE>=Indicador_BICE and 
Indicador_BICE>=Indicador_Itau and 
Indicador_BICE>=Indicador_Security and 
Indicador_BICE>=Indicador_BBVA and 
Indicador_BICE>=Indicador_ScotiaBank and 
Indicador_BICE>=Indicador_CorpBanca and 
Indicador_BICE>=Indicador_Falabella and 
Indicador_BICE>=Indicador_Consorcio and 
Indicador_BICE>=Indicador_COOPEUCH and 
Indicador_BICE>=Indicador_Desarrollo and 
Indicador_BICE>=Indicador_Internacional and 
Indicador_BICE>=Indicador_Otros
then 'BICE'
when
Indicador_Itau>0 and 
Indicador_Itau>=Indicador_BCH and 
Indicador_Itau>=Indicador_Santander and 
Indicador_Itau>=Indicador_Estado and 
Indicador_Itau>=Indicador_BCI and 
Indicador_Itau>=Indicador_BICE and 
Indicador_Itau>=Indicador_Itau and 
Indicador_Itau>=Indicador_Security and 
Indicador_Itau>=Indicador_BBVA and 
Indicador_Itau>=Indicador_ScotiaBank and 
Indicador_Itau>=Indicador_CorpBanca and 
Indicador_Itau>=Indicador_Falabella and 
Indicador_Itau>=Indicador_Consorcio and 
Indicador_Itau>=Indicador_COOPEUCH and 
Indicador_Itau>=Indicador_Desarrollo and 
Indicador_Itau>=Indicador_Internacional and 
Indicador_Itau>=Indicador_Otros
then 'Itau'
when
Indicador_Security>0 and 
Indicador_Security>=Indicador_BCH and 
Indicador_Security>=Indicador_Santander and 
Indicador_Security>=Indicador_Estado and 
Indicador_Security>=Indicador_BCI and 
Indicador_Security>=Indicador_BICE and 
Indicador_Security>=Indicador_Itau and 
Indicador_Security>=Indicador_Security and 
Indicador_Security>=Indicador_BBVA and 
Indicador_Security>=Indicador_ScotiaBank and 
Indicador_Security>=Indicador_CorpBanca and 
Indicador_Security>=Indicador_Falabella and 
Indicador_Security>=Indicador_Consorcio and 
Indicador_Security>=Indicador_COOPEUCH and 
Indicador_Security>=Indicador_Desarrollo and 
Indicador_Security>=Indicador_Internacional and 
Indicador_Security>=Indicador_Otros
then 'Security'
when
Indicador_BBVA>0 and 
Indicador_BBVA>=Indicador_BCH and 
Indicador_BBVA>=Indicador_Santander and 
Indicador_BBVA>=Indicador_Estado and 
Indicador_BBVA>=Indicador_BCI and 
Indicador_BBVA>=Indicador_BICE and 
Indicador_BBVA>=Indicador_Itau and 
Indicador_BBVA>=Indicador_Security and 
Indicador_BBVA>=Indicador_BBVA and 
Indicador_BBVA>=Indicador_ScotiaBank and 
Indicador_BBVA>=Indicador_CorpBanca and 
Indicador_BBVA>=Indicador_Falabella and 
Indicador_BBVA>=Indicador_Consorcio and 
Indicador_BBVA>=Indicador_COOPEUCH and 
Indicador_BBVA>=Indicador_Desarrollo and 
Indicador_BBVA>=Indicador_Internacional and 
Indicador_BBVA>=Indicador_Otros
then 'BBVA'
when
Indicador_ScotiaBank>0 and 
Indicador_ScotiaBank>=Indicador_BCH and 
Indicador_ScotiaBank>=Indicador_Santander and 
Indicador_ScotiaBank>=Indicador_Estado and 
Indicador_ScotiaBank>=Indicador_BCI and 
Indicador_ScotiaBank>=Indicador_BICE and 
Indicador_ScotiaBank>=Indicador_Itau and 
Indicador_ScotiaBank>=Indicador_Security and 
Indicador_ScotiaBank>=Indicador_BBVA and 
Indicador_ScotiaBank>=Indicador_ScotiaBank and 
Indicador_ScotiaBank>=Indicador_CorpBanca and 
Indicador_ScotiaBank>=Indicador_Falabella and 
Indicador_ScotiaBank>=Indicador_Consorcio and 
Indicador_ScotiaBank>=Indicador_COOPEUCH and 
Indicador_ScotiaBank>=Indicador_Desarrollo and 
Indicador_ScotiaBank>=Indicador_Internacional and 
Indicador_ScotiaBank>=Indicador_Otros
then 'ScotiaBank'
when
Indicador_CorpBanca>0 and 
Indicador_CorpBanca>=Indicador_BCH and 
Indicador_CorpBanca>=Indicador_Santander and 
Indicador_CorpBanca>=Indicador_Estado and 
Indicador_CorpBanca>=Indicador_BCI and 
Indicador_CorpBanca>=Indicador_BICE and 
Indicador_CorpBanca>=Indicador_Itau and 
Indicador_CorpBanca>=Indicador_Security and 
Indicador_CorpBanca>=Indicador_BBVA and 
Indicador_CorpBanca>=Indicador_ScotiaBank and 
Indicador_CorpBanca>=Indicador_CorpBanca and 
Indicador_CorpBanca>=Indicador_Falabella and 
Indicador_CorpBanca>=Indicador_Consorcio and 
Indicador_CorpBanca>=Indicador_COOPEUCH and 
Indicador_CorpBanca>=Indicador_Desarrollo and 
Indicador_CorpBanca>=Indicador_Internacional and 
Indicador_CorpBanca>=Indicador_Otros
then 'CorpBanca'
when
Indicador_Falabella>0 and 
Indicador_Falabella>=Indicador_BCH and 
Indicador_Falabella>=Indicador_Santander and 
Indicador_Falabella>=Indicador_Estado and 
Indicador_Falabella>=Indicador_BCI and 
Indicador_Falabella>=Indicador_BICE and 
Indicador_Falabella>=Indicador_Itau and 
Indicador_Falabella>=Indicador_Security and 
Indicador_Falabella>=Indicador_BBVA and 
Indicador_Falabella>=Indicador_ScotiaBank and 
Indicador_Falabella>=Indicador_CorpBanca and 
Indicador_Falabella>=Indicador_Falabella and 
Indicador_Falabella>=Indicador_Consorcio and 
Indicador_Falabella>=Indicador_COOPEUCH and 
Indicador_Falabella>=Indicador_Desarrollo and 
Indicador_Falabella>=Indicador_Internacional and 
Indicador_Falabella>=Indicador_Otros
then 'Falabella'
when
Indicador_Consorcio>0 and 
Indicador_Consorcio>=Indicador_BCH and 
Indicador_Consorcio>=Indicador_Santander and 
Indicador_Consorcio>=Indicador_Estado and 
Indicador_Consorcio>=Indicador_BCI and 
Indicador_Consorcio>=Indicador_BICE and 
Indicador_Consorcio>=Indicador_Itau and 
Indicador_Consorcio>=Indicador_Security and 
Indicador_Consorcio>=Indicador_BBVA and 
Indicador_Consorcio>=Indicador_ScotiaBank and 
Indicador_Consorcio>=Indicador_CorpBanca and 
Indicador_Consorcio>=Indicador_Falabella and 
Indicador_Consorcio>=Indicador_Consorcio and 
Indicador_Consorcio>=Indicador_COOPEUCH and 
Indicador_Consorcio>=Indicador_Desarrollo and 
Indicador_Consorcio>=Indicador_Internacional and 
Indicador_Consorcio>=Indicador_Otros
then 'Consorcio'
when
Indicador_COOPEUCH>0 and 
Indicador_COOPEUCH>=Indicador_BCH and 
Indicador_COOPEUCH>=Indicador_Santander and 
Indicador_COOPEUCH>=Indicador_Estado and 
Indicador_COOPEUCH>=Indicador_BCI and 
Indicador_COOPEUCH>=Indicador_BICE and 
Indicador_COOPEUCH>=Indicador_Itau and 
Indicador_COOPEUCH>=Indicador_Security and 
Indicador_COOPEUCH>=Indicador_BBVA and 
Indicador_COOPEUCH>=Indicador_ScotiaBank and 
Indicador_COOPEUCH>=Indicador_CorpBanca and 
Indicador_COOPEUCH>=Indicador_Falabella and 
Indicador_COOPEUCH>=Indicador_Consorcio and 
Indicador_COOPEUCH>=Indicador_COOPEUCH and 
Indicador_COOPEUCH>=Indicador_Desarrollo and 
Indicador_COOPEUCH>=Indicador_Internacional and 
Indicador_COOPEUCH>=Indicador_Otros
then 'COOPEUCH'
when
Indicador_Desarrollo>0 and 
Indicador_Desarrollo>=Indicador_BCH and 
Indicador_Desarrollo>=Indicador_Santander and 
Indicador_Desarrollo>=Indicador_Estado and 
Indicador_Desarrollo>=Indicador_BCI and 
Indicador_Desarrollo>=Indicador_BICE and 
Indicador_Desarrollo>=Indicador_Itau and 
Indicador_Desarrollo>=Indicador_Security and 
Indicador_Desarrollo>=Indicador_BBVA and 
Indicador_Desarrollo>=Indicador_ScotiaBank and 
Indicador_Desarrollo>=Indicador_CorpBanca and 
Indicador_Desarrollo>=Indicador_Falabella and 
Indicador_Desarrollo>=Indicador_Consorcio and 
Indicador_Desarrollo>=Indicador_COOPEUCH and 
Indicador_Desarrollo>=Indicador_Desarrollo and 
Indicador_Desarrollo>=Indicador_Internacional and 
Indicador_Desarrollo>=Indicador_Otros
then 'Desarrollo'
when
Indicador_Internacional>0 and 
Indicador_Internacional>=Indicador_BCH and 
Indicador_Internacional>=Indicador_Santander and 
Indicador_Internacional>=Indicador_Estado and 
Indicador_Internacional>=Indicador_BCI and 
Indicador_Internacional>=Indicador_BICE and 
Indicador_Internacional>=Indicador_Itau and 
Indicador_Internacional>=Indicador_Security and 
Indicador_Internacional>=Indicador_BBVA and 
Indicador_Internacional>=Indicador_ScotiaBank and 
Indicador_Internacional>=Indicador_CorpBanca and 
Indicador_Internacional>=Indicador_Falabella and 
Indicador_Internacional>=Indicador_Consorcio and 
Indicador_Internacional>=Indicador_COOPEUCH and 
Indicador_Internacional>=Indicador_Desarrollo and 
Indicador_Internacional>=Indicador_Internacional and 
Indicador_Internacional>=Indicador_Otros
then 'Internacional'
when
Indicador_Otros>0 and 
Indicador_Otros>=Indicador_BCH and 
Indicador_Otros>=Indicador_Santander and 
Indicador_Otros>=Indicador_Estado and 
Indicador_Otros>=Indicador_BCI and 
Indicador_Otros>=Indicador_BICE and 
Indicador_Otros>=Indicador_Itau and 
Indicador_Otros>=Indicador_Security and 
Indicador_Otros>=Indicador_BBVA and 
Indicador_Otros>=Indicador_ScotiaBank and 
Indicador_Otros>=Indicador_CorpBanca and 
Indicador_Otros>=Indicador_Falabella and 
Indicador_Otros>=Indicador_Consorcio and 
Indicador_Otros>=Indicador_COOPEUCH and 
Indicador_Otros>=Indicador_Desarrollo and 
Indicador_Otros>=Indicador_Internacional and 
Indicador_Otros>=Indicador_Otros
then 'Otros'
else 'Otros'
end as Banco_Secundario,
case when Indicador_BCH>0 then 1 else 0 end+
case when Indicador_Santander>0 then 1 else 0 end+
case when Indicador_Estado>0 then 1 else 0 end+
case when Indicador_BCI>0 then 1 else 0 end+
case when Indicador_BICE>0 then 1 else 0 end+
case when Indicador_Itau>0 then 1 else 0 end+
case when Indicador_Security>0 then 1 else 0 end+
case when Indicador_BBVA>0 then 1 else 0 end+
case when Indicador_ScotiaBank>0 then 1 else 0 end+
case when Indicador_CorpBanca>0 then 1 else 0 end+
case when Indicador_Falabella>0 then 1 else 0 end+
case when Indicador_Consorcio>0 then 1 else 0 end+
case when Indicador_COOPEUCH>0 then 1 else 0 end+
case when Indicador_Desarrollo>0 then 1 else 0 end+
case when Indicador_Internacional>0 then 1 else 0 end+
case when Indicador_Otros>0 then 1 else 0 end 
as Nro_Bancos 
from work.TEFs4 
where calculated Nro_Bancos>0 /*quedarse solo con registros que transfieres al menos a otros bancos (no solo entre bco ripley)*/

;quit;



%put==========================================================================================;
%put [06] Vaciar resultados en tabla entregable final;
%put==========================================================================================;

/*rescatar Fecha del Proceso*/
PROC SQL noprint outobs=1;   

select 
SB_Ahora('DD/MM/AAAA_HH:MM') as Fecha_Proceso,
input(SB_Ahora('AAAAMMDD'),best.) as Fecha2_Proceso
into :Fecha_Proceso,:Fecha2_Proceso
from sashelp.vmember

;QUIT;

%let Fecha_Proceso="&Fecha_Proceso";

/*Vaciar en tabla entregable*/
DATA _NULL_;
Call execute(
cat('
proc sql; 

create table ',&Base_Entregable,'_',&Periodo,' as 
SELECT 
''',&Fecha_Proceso,''' as Fecha_Proceso, 
* 
from work.TEFs4  

;quit;
')
);
run;


/*Eliminar tabla de paso*/
proc sql;
	drop table work.TEFs4  
;quit;


/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; 

/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN) ;
RUN;
	%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

quit;

%put &=EDP_BI;
%put &=DEST_1;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1")
SUBJECT = ("MAIL_AUTOM: Proceso BANCO_SECUNDARIO");
FILE OUTBOX;
 PUT "Estimados:";
 put "  Proceso BANCO_SECUNDARIO, ejecutado con fecha: &fechaeDVN";  
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 01'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
