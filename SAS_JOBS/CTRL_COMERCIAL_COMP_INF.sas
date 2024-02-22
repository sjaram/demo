/*==========================================================================================*/
/*=============================	EQUIPO DATOS Y PROCESOS		================================*/
/*=============================	CTRL_COMERCIAL_COMP_INF		================================*/
/* CONTROL DE VERSIONES
/* 2021-10-14 ---- Primera versión
 */

/*==========================================================================================*/
DATA _null_;
	/* Variables Fechas de Ejecución */
	datePeriodoActual = input(put(intnx('month',today(),-1,'end' ),yymmn6. ),$10.);
	Call symput("VdateHOY", datePeriodoActual);
RUN;

%put &VdateHOY;

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*===============================	SUCURSAL_PREFERENTE		================================*/
PROC EXPORT DATA=publicin.SUCURSAL_PREFERENTE_&VdateHOY.
	OUTFILE='/sasdata/users94/user_bi/TRASPASO_DOCS/CTRL_COMERCIAL/SUCURSAL_PREFERENTE.csv'
	DBMS=dlm REPLACE;
	delimiter=';';
	PUTNAMES=YES;
RUN;

/* EXPORTAR DE SAS A UN FTP O SFTP */
filename server ftp 'SUCURSAL_PREFERENTE.csv' CD='/' 
	HOST='192.168.82.171' user='17457765K' pass='17457765K' PORT=21;

data _null_;
	infile '/sasdata/users94/user_bi/TRASPASO_DOCS/CTRL_COMERCIAL/SUCURSAL_PREFERENTE.csv';
	file server;
	input;
	put _infile_;
run;

/*===============================	SEGMENTO_COMERCIAL		================================*/
PROC EXPORT DATA=publicin.SEGMENTO_COMERCIAL
	OUTFILE='/sasdata/users94/user_bi/TRASPASO_DOCS/CTRL_COMERCIAL/SEGMENTO_COMERCIAL.csv'
	DBMS=dlm REPLACE;
	delimiter=';';
	PUTNAMES=YES;
RUN;

/* EXPORTAR DE SAS A UN FTP O SFTP */
filename server ftp 'SEGMENTO_COMERCIAL.csv' CD='/' 
	HOST='192.168.82.171' user='17457765K' pass='17457765K' PORT=21;

data _null_;
	infile '/sasdata/users94/user_bi/TRASPASO_DOCS/CTRL_COMERCIAL/SEGMENTO_COMERCIAL.csv';
	file server;
	input;
	put _infile_;
run;

/*===============================	CLIENTES_CON_SALDO		================================*/
/*PROC SQL NOERRORSTOP INOBS=10;*/
/*	CONNECT TO ORACLE (USER='AMARINAOC' PASSWORD='amarinaoc2017' path ='REPORITF.WORLD' );*/
/*	create table CLIENTES_CON_SALDO as*/
/*		select*/
/*			**/
/*		from connection to ORACLE(*/
/*			select */
/*				AL1.EVAAM_CIF_ID as id,*/
/*				AL1.EVAAM_NRO_CTT as nro_cttp,*/
/*				AL1.EVAAM_FCH_PRO as fecha_proceso,*/
/*				AL1.EVAAM_SLD_TTL as saldo_total,*/
/*				AL1.EVAAM_SLD_MOR as saldo_mora,*/
/*				AL1.EVAAM_DIA_MOR as dia_mora*/
/*			FROM SFRIES_ALT_MOR AL1*/
/*/`
*			where AL1.EVAAM_NRO_CTT like ('%100001047645')*/
*/
/*				where*/
/*					AL1.EVAAM_FCH_PRO =*/
/*					to_date(%str(%')&ind1.%str(%'),'dd/mm/yyyy')*/
/*					) A*/
/*	;*/

/*QUIT;

/*	Fecha ejecución del proceso	*/
data _null_;
	exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);
	Call symput("fechae", exec);
RUN;

%put &fechae;/*fecha ejecucion proceso */

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JONATHAN_GONZALEZ';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;

data _null_;
	FILENAME OUTBOX EMAIL
		FROM = ("&EDP_BI")
		TO = ("&DEST_3")
		CC = ("&DEST_1","&DEST_2") 
		SUBJECT = ("MAIL_AUTOM: Compartir información a Control Comercial (82.171)");
	FILE OUTBOX;
	PUT "Estimados:";
	PUT "	Se encuentran disponibles los archivos requeridos, con fecha: &fechae";
	PUT;
	PUT '	En FTP 192.168.82.171 - Nombres de archivos:';
	PUT '		- SUCURSAL_PREFERENTE.csv';
	PUT '		- SEGMENTO_COMERCIAL.csv';
	PUT;
	PUT;
	PUT 'Atte.';
	PUT 'Equipo Datos y Procesos BI';
	PUT;
RUN;

FILENAME OUTBOX CLEAR;

/*===============================	TIEMPO EJECUCIÓN		================================*/
/*	VARIABLE TIEMPO	- FIN	*/
data _null_;
	dur = datetime() - &tiempo_inicio;
	put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run;
