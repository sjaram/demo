/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	MORA_4D_CIERRE				================================*/

/* CONTROL DE VERSIONES
/* 2023-10-11	-- V2 	--	Esteban P.	--	Se añade export para tabla mora_4d
/* 2021-10-28 	-- V1	-- Pedro M.		--  
				-- Versión Original
/* INFORMACIÓN:


*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
%let libreria=RESULT;

%macro mora_4d(i,libreria);

	DATA _NULL_;
		periodo=input(put(intnx('month',today(),-&i.,'end'),yymmn6. ),$10.);
		date0 = input(put(intnx('month',today(),-&i.,'end'),ddmmyy10. ),$10.);
		call symput("periodo",periodo);
		call symput("ultdia",date0);
	run;

	%put &periodo;
	%put &ultdia;

	PROC SQL NOERRORSTOP;
		CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );
		create table &libreria..Mora_4d_&periodo. as
			select
				*
			from connection to ORACLE(
				select
					cast(AL2.PEMID_GLS_NRO_DCT_IDE_K as INT) as rut,
					AL1.EVAAM_NRO_CTT as contrato,
					AL1.EVAAM_FCH_PRO as fecha_proceso,
					AL1.EVAAM_SLD_TTL as saldo_total,
					AL1.EVAAM_SLD_MOR as saldo_mora,
					AL1.EVAAM_DIA_MOR as dia_mora

				FROM SFRIES_ALT_MOR AL1
					inner join BOPERS_MAE_IDE AL2
						on(AL2.PEMID_NRO_INN_IDE=AL1.EVAAM_CIF_ID)
					where
						AL1.EVAAM_FCH_PRO =to_date(%str(%')&ultdia. %str(%'),'dd/mm/yyyy')
						and AL1.EVAAM_DIA_MOR>=4
						) A
		;
	QUIT;

%mend mora_4d;

%mora_4d(1,&libreria.);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_INCREM_PER_DIARIO.sas";
%DELETE_INCREM_PER_DIARIO(sas_mdpg_mora_4d,raw,sasdata,-1);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_mdpg_mora_4d,result.mora_4d_&periodo.,raw,sasdata,-1);

/*==================================================================================================*/
/*==================================	TIEMPO Y ENVÍO DE EMAIL		================================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;

/*	Fecha ejecución del proceso	*/
data _null_;
	execDVN = input(put(intnx('month',today(),-1,'end'),yymmn6. ),$10.);
	Call symput("fechaeDVN", execDVN);
RUN;

%put &fechaeDVN;/*fecha ejecucion proceso */

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PEDRO_MUNOZ';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'ALEJANDRA_MARINAO';
	SELECT EMAIL into :DEST_4 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;

data _null_;
	FILENAME OUTBOX EMAIL
		FROM 	= ("&EDP_BI")
		TO 		= ("&DEST_1","&DEST_2","&DEST_3","&DEST_4")
		SUBJECT	="MAIL_AUTOM: CIERRE MORA 4D %sysfunc(date(),yymmdd10.)";
	FILE OUTBOX;
	PUT 'Estimados:';
	PUT "	Proceso MORA 4D, ejecutado con éxito al cierre: &fechaeDVN";
	PUT;
	PUT "Tabla resultante en: RESULT.MORA_4D_&fechaeDVN";
	PUT;
	PUT 'Vers.01';
	PUT;
	PUT;
	PUT;
	PUT 'Atte.';
	PUT 'Equipo Datos y Procesos BI';
	PUT;
RUN;

FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
