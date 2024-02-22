/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================    BASE_DATA_MASTER_ONBOARDING	================================*/

/* CONTROL DE VERSIONES
/* 2022-04-27 ---- V01 -- David V. -- Inicialmente igual al BASE_DATA_MASTER pero desde base email sin filtros sernac y suprimidos

Descripcion:
Genera la información de contactabilidad de los clientes, es el input del proceso DATAMASTER, para ONBOARDING.
*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*	VARIABLE LIBRERÍA			*/
%let libreria_1  = PUBLICIN; /*PUBLICIN*/
options validvarname=any;
options cmplib=sbarrera.funcs;

proc sql;
	create table paso_1 as 
		select rut
			from &libreria_1..BASE_TRABAJO_EMAIL_ONB
				union
			select clirut
				from publicin.fonos_movil_final
	;
quit;

proc sql;
	delete * from paso_1
		where rut <=1000000;
quit;

proc sql noprint outobs=1;
	select 
		sb_mover_anomesdia(input(SB_AHORA('AAAAMMDD'),best.),-1) /*Si Periodo=0, usar periodo del dia anterior*/

		/*Si Periodo=0, usar periodo del dia anterior*/
		as fecha 
			into :Fecha_saldo 
				from sashelp.vmember
		;
quit;

proc sql;
	create table &libreria_1..BASE_DATA_MASTER_ONB as 
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
			put(g.SALDO_RPTOS,commax10.) AS SALDORPUNTOS1,
			cats(substr(cats(&Fecha_saldo),7,2),'/',substr(cats(&Fecha_saldo),5,2),'/',substr(cats(&Fecha_saldo),1,4)) AS FECHASALDO
		from paso_1 a 
			left join &libreria_1..BASE_TRABAJO_EMAIL_ONB b
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
	;
quit;

/* VARIABLE TIEMPO - FIN */
data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;

/*==================================	FECHA DEL PROCESO  			================================*/
data _null_;
	execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechaeDVN", execDVN);
RUN;

%put &fechaeDVN;

/*==================================	EMAIL CON CASILLA VARIABLE	================================*/
proc sql noprint;
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;

data _null_;
	FILENAME OUTBOX EMAIL
		FROM = ("&EDP_BI")
		TO = ("&DEST_1", "&DEST_2")
		SUBJECT = ("MAIL_AUTOM: Proceso BASE_DATA_MASTER_ONBOARDING");
	FILE OUTBOX;
	PUT "Estimados:";
	put "		Proceso BASE_DATA_MASTER_ONBOARDING, ejecutado con fecha: &fechaeDVN";
	put "		Tabla generada: &libreria_1..BASE_DATA_MASTER_ONB";
	PUT;
	PUT;
	put 'Proceso Vers. 01';
	PUT;
	PUT;
	PUT 'Atte.';
	Put 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;

FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
