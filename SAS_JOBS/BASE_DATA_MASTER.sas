/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================    BASE_DATA_MASTER				 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-12-06 -- V07 -- Sergio J.	--  Se agregan nuevos campos para planes
/* 2022-09-22 -- V06 -- Sergio J.	--  Se agregan los campos FECHA_LIMITE_PAGO y FECHA_FACTURACION
/* 2022-07-20 -- V05 -- Benjamin S.	--  Se agregan campos FECHA_VENCIMIENTO_PUNTOS, PUNTOS_A_CADUCAR y VIGENTE
/* 2022-07-20 -- V04 -- David V.	--  Ajuste a campo SALDORPUNTOS1 para que no salgan nulos y si un 0 cuando no tiene puntos.
/* 2022-03-09 -- V03 -- Sergio J.	--  Se eliminan los ruts <= a 1000000
/* 2021-08-11 -- V02 -- Sergio J. 	--  Campos dinamicos para campañas
/* 2021-04-16 -- V01 -- Pia O. 		--	Versión Original

Descripcion:
Genera la información de contactabilidad de los clientes, es el input del proceso DATAMASTER.
*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
proc sql; 
create table paso_1 as 
select rut
from publicin.base_trabajo_email
union
select clirut
from publicin.fonos_movil_final
;quit;

proc sql noprint;
delete * from paso_1
where rut <=1000000;
quit;

options cmplib=sbarrera.funcs;
proc sql noprint outobs=1;
select 
  sb_mover_anomesdia(input(SB_AHORA('AAAAMMDD'),best.),-1) /*Si Periodo=0, usar periodo del dia anterior*/
  /*Si Periodo=0, usar periodo del dia anterior*/
 as fecha 
into :Fecha_saldo 
from sashelp.vmember
;quit;
 
proc sql noprint outobs=1;
select 
 sb_mover_anomes(floor(input(SB_AHORA('AAAAMMDD'),best.)/100),1) /*Si Periodo=0, usar periodo del dia anterior*/
  /*Si Periodo=0, usar periodo del dia anterior*/
 as fecha 
into :Fecha_saldo2 
from sashelp.vmember
;quit;

proc sql;
create table base_data_master as 
select 
d.paterno as  APELLIDO,
e.CALLE AS DIRECCION,
b.EMAIL,
a.rut AS ID_USUARIO,
d.primer_nombre AS NOMBRE,
C.TELEFONO  as TELEFONO_MOVIL,
e.NUMERO AS DIRECCION_NUM,
e.REGION,
e.COMUNA,
f.SEGMENTO,
put(COALESCE(g.SALDO_RPTOS,-1),commax10.) AS SALDORPUNTOS1,
cats(substr(cats(&Fecha_saldo),7,2),'/',substr(cats(&Fecha_saldo),5,2),'/',substr(cats(&Fecha_saldo),1,4)) AS FECHASALDO,
cats('01/',substr(cats(&Fecha_saldo2),5,2),'/',substr(cats(&Fecha_saldo2),1,4)) as FECHA_VENCIMIENTO_PUNTOS,
put(COALESCE(g.SALDO_VENCER,-1),commax10.) AS PUNTOS_A_CADUCAR,
"1" as VIGENTE
from paso_1 a 
left join publicin.base_trabajo_email b
on (a.rut=b.rut)
left join publicin.fonos_movil_final c
on (a.rut=c.clirut)
left join publicin.base_nombres d
on (a.rut=d.rut)
left join publicin.direcciones e
on (a.rut=e.rut)
left join publicin.segmento_comercial f
on (a.rut=f.rut)
left join result.saldo_rptos_disp g
on (a.rut=g.rut)
;quit;

proc sql;
create index id_usuario on base_data_master (id_usuario)
;quit;

proc sql;
create table base_data_master_2 as 
select a.*,
b.final_ptos_a,
b.ptos_nvos,
b.segmento_anio_anterior,
b.segmento_loyalty,
b.segmento_1,
b.segmento_2,
b.segmento_plan,
b.segmento_final,
b.SI_TAM,
b.SI_CC,
b.SI_MC_CHEK,
b.SI_TD,
b.SI_TR
from base_data_master a
left join result.dm_productos_segmentos b
on a.id_usuario=b.rut;
quit;

data publicin.base_data_master;
set base_data_master_2;
run;

/* VARIABLE TIEMPO - FIN */
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
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
quit;

%put &=EDP_BI;	%put &=DEST_1;	%put &=DEST_2;	%put &=DEST_3;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1", "&DEST_2", "&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso BASE_DATA_MASTER");
FILE OUTBOX;
 	PUT "Estimados:";
 	put "		Proceso BASE_DATA_MASTER, ejecutado con fecha: &fechaeDVN";  
    PUT;
    PUT;
    PUT 'Proceso Vers. 07';
    PUT;
    PUT;
    PUT 'Atte.';
    PUT 'Equipo Arquitectura de Datos y Automatización BI';
    PUT;
RUN;
FILENAME OUTBOX CLEAR;
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
