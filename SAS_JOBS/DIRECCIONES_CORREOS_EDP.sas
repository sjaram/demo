/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	DIRECCIONES_CORREOS_EDP		================================*/
/* CONTROL DE VERSIONES
/* 2023-03-03 -- v20-- David V. -- Se actualiza correo del nuevo Subg BI, Subg Digital y nuevos integrantes BI Digital.
/* 2022-12-01 -- v19-- David V. -- Se agregan variables de alumnos en práctica y otros de equipo Alianzas/SPOS.
/* 2022-11-23 -- v18-- Sergio J.-- Se agrega a Loreto Palma
/* 2022-10-05 -- v17-- David V. -- Actualización con las últimas salidas y entradas del equipo. 
/* 2022-07-01 -- v16-- David V. -- Reemplazo correo de Pía por el de Andrea
/* 2022-06-29 -- v15-- David V. -- Se agrega al jefe digital, a PM Chek y quita a Jonathan Gonzalez
/* 2022-05-09 -- v14-- David V. -- Eliminar correos de personas que ya no están y crear codigos nuevos
/* 2022-04-13 -- v13-- David V. -- Se agrega correo de atorresm@bancoripley.com',		'SUBGERENT_CNL_DIGITAL
/* 2022-03-30 -- v12-- David V. -- Actualización por salida de Pía, Vale y Coni
/* 2022-03-29 -- v11-- David V. -- Actualización
/* 2021-12-16 -- v10-- David V. -- Se agrega a Diego y actualiza variables de mail equipo Campañas

/* INFORMACIÓN:
	Programa que unifica las direcciones de correos para envíos automáticos del sistema

	(IN) Tablas requeridas o conexiones a BD:
	- Ninguna

	(OUT) Tablas de Salida o resultado:
	- result.EDP_BI_DESTINATARIOS

*/

/*	VARIABLE TIEMPO	- INICIO	*/
%let tiempo_inicio= %sysfunc(datetime());

/*	VARIABLE LIBRERÍA			*/
%let libreria=RESULT;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/

proc sql;
	DROP table result.EDP_BI_DESTINATARIOS 
;quit;

proc sql;
	create table result.EDP_BI_DESTINATARIOS (
	EMAIL CHAR(50), 
	CODIGO char(50),
	AREA CHAR (50) 
	)
;quit;
proc sql;
	insert into result.EDP_BI_DESTINATARIOS  
/*		CORREOS GRUPALES	*/
		values('equipo_datos_procesos_bi@bancoripley.com','EDP_BI','BI')
		values('icomercial@ripley.com','GRUPO_BI','BI')

/*		EQUIPO BI	*/
		values('pfuenzalidam@bancoripley.com',	'PAOLA_FUENZALIDA','BI')
		values('dvasquez@bancoripley.com',		'DAVID_VASQUEZ','BI')
		values('dvasquez923@gmail.com',			'DAVID_GMAIL','BI')
		values('kmartinez@ripley.com',			'KARINA_MARTINEZ','BI')
		values('amarinao@bancoripley.com',		'ALEJANDRA_MARINAO','BI')
		values('bsotov@bancoripley.com',		'BENJAMIN_SOTO','BI')
		values('jaburtom@ripley.com',			'JOSE_ABURTO','BI')
/*		values('mguzmans@bancoripley.com',		'MAURICIO_GUZMAN','BI')*/
		values('nlagosg@bancoripley.com',		'NICOLE_LAGOS','BI')
		values('pmunozc@bancoripley.com',		'PEDRO_MUNOZ','BI')
		values('sjaram@bancoripley.com',		'SERGIO_JARA','BI')
		values('gherrerab@bancoripley.com',		'GERARDO_HERRERA','BI')
		values('pquinteroc@bancoripley.com',	'PATRICIO_QUINTERO','BI')
/*		values('jgonzalezma@bancoripley.com',	'JONATHAN_GONZALEZ','BI')*/
		values('tmilateguav@bancoripley.com',	'THOMAS_MILATEGUA','BI')
		values('lmontalbab@bancoripley.com',	'LUCAS_MONTALBA','BI')

		values('gherrerab@bancoripley.com',		'GERENTE_ANALYTICS','BI')
		values('pfuenzalidam@bancoripley.com',	'SUBG_GOBIERNO_DAT','BI')
		values('amarinao@bancoripley.com',		'PM_GOBIERNO_DAT_1','BI')
		values('fsotoga@bancoripley.com',		'PM_GOBIERNO_DAT_2','BI')
/*		values('eapinoh@bancoripley.com',		'PM_GOBIERNO_DAT_3','BI')*/
		values('fsotoga@bancoripley.com',		'PM_CONTACTABILIDAD','BI')


		values('gvallejosa@bancoripley.com',	'SUBG_BI','BI')

		values('jaburtom@ripley.com',			'JEFE_BI_PPFF','BI')
		values('rfonsecaa@bancoripley.com',		'PM_BI_PPFF_1','BI')
		values('bmartinezg@bancoripley.com',	'PM_BI_PPFF_2','BI')
		values('jgunckele@bancoripley.com',		'PM_BI_PPFF_3','BI')
		values('nreyesc@bancoripley.com',		'PM_BI_PPFF_4','BI')
/*		values('mguzmans@bancoripley.com',		'PM_BI_PPFF_3','BI')*/

		values('nlagosg@bancoripley.com',		'JEFE_CLIENTES','BI')
		values('bsotov@bancoripley.com',		'PM_CLIENTES_1','BI')
		values('kmartinez@ripley.com',			'PM_CLIENTES_2','BI')

		values('pmunozc@bancoripley.com',		'JEFE_BI_SPOS','BI')
		values('iplazam@bancoripley.com',		'PM_BI_SPOS_1','BI')
		values('kgonzalezi@bancoripley.com',	'PM_BI_SPOS_2','BI')

/*		EQUIPO DIGITAL	*/
		values('rarcosm@bancoripley.com',		'JEFE_BI_DIGITAL','BI')
		values('nverdejog@bancoripley.com',		'PM_BI_DIGITAL_1','BI')
/*		values('gossag@bancoripley.com',		'PM_BI_CHEK_1','BI')*/
		values('rgonzalezs@bancoripley.com',	'PM_BI_CHEK_1','BI')
		values('lmartinezc@bancoripley.com',	'PM_BI_CHEK_2','BI')

		values('pquinteroc@bancoripley.com',	'SUBG_ARQ_DAT','BI')
		values('dvasquez@bancoripley.com',		'JEFE_ARQ_DAT','BI')
		values('sjaram@bancoripley.com',		'PM_ARQ_DAT_1','BI')
		values('eapinoh@bancoripley.com',		'PM_ARQ_DAT_2','BI')
		values('lmontalbab@bancoripley.com',	'JEFE_DATOS','BI')
		values('jmonteso@bancoripley.com',		'PM_DATOS_1','BI')
/*		values('tmilateguav@bancoripley.com',	'PM_DATOS_2','BI')*/
		 
/*		EQUIPO CAMPAÑAS	*/
/*		values('solivas@bancoripley.com',		'DIEGO_GARCIA_CAMP','CAMPANAS')*/
		values('solivas@bancoripley.com',		'JEFATURA_CAMP','CAMPANAS')
		values('dvasquez@bancoripley.com',		'DAVID_VASQUEZ_CAMP','CAMPANAS')
		values('sjaram@bancoripley.com',		'SERGIO_JARA_CAMP','CAMPANAS')
/*		values('fguerreroc@bancoripley.com',	'FELIPE_GUERRERO_CAMP','CAMPANAS')*/
		values('acolmenaresp@bancoripley.com',	'PM_CAMP_1','CAMPANAS')
		values('asaavedra@celmedia.cl',			'PM_CAMP_2','CAMPANAS')
		values('davilaf@bancoripley.com',		'PM_CAMP_3','CAMPANAS')
/*		values('x@bancoripley.com',				'PM_CAMP_3','CAMPANAS')*/

/*		values('cnunezm@bancoripley.com',		'CESAR_NUNEZ','BI')*/
/*		values('ougarted@bancoripley.com',		'OSVALDO_UGARTE','BI')*/
/*		values('xzamorac@bancoripley.com',		'XIMENA_ZAMORA','BI')		*/
/*		values('cnavarrov@bancoripley.com',		'CAROLINA_NAVARRO','BI')*/
/*		values('sbarrera@bancoripley.com',		'SEBASTIAN_BARRERA','BI')*/
/*		values('amunozme@bancoripley.com',		'ANA_MUNOZ','BI')*/
/*		values('epielh@ripley.com',				'EDMUNDO_PIEL','BI')*/
/*		values('mgarrigav@bancoripley.com',		'MARIO_GARRIGA','BI')*/
/*		values('vmartinezf@bancoripley.com',	'VALENTINA_MARTINEZ','BI')*/
/*		values('cceleryc@bancoripley.com',		'CONSTANZA_CELERY','BI')*/
/*		values('polavarriac@bancoripley.com',	'PIA_OLAVARRIA','BI')*/

/*		EQUIPO PRODUCTO	*/
/*		values('jdonoson@bancoripley.com',		'JUAN_PABLO_DONOSO','PPFF')*/
		values('jvaldebenitot@bancoripley.com',	'JOSE_VALDEBENITO','PPFF')
/*		values('ediazl@bancoripley.com',		'EDUARDO_DIAZ','PPFF')*/
		values('lpalmam@bancoripley.com',		'LORETO_PALMA','PPFF')
		values('cparedesp@bancoripley.com',		'CLAUDIA_PAREDES','PPFF')
		values('cperezv@bancoripley.com',		'CRISTIAN_PEREZ','PPFF')
		values('carteagas@bancoripley.com',		'CONSUELO_ARTEAGA','PPFF')
		values('mibarboureo@bancoripley.com',	'PPFF_PM_CONSUMO','PPFF')
/*		values('fblancoo@bancoripley.com',		'PPFF_PM_CONSUMO','PPFF')*/
		values('mperezt@bancoripley.com',		'PPFF_PM_PASIVOS','PPFF')
		values('ivivancom@bancoripley.com',		'PPFF_JEFE_PASIVOS','PPFF')
		values('tfarres@bancoripley.com',		'PPFF_PM_AVANCE','PPFF')

/*		values('','','PPFF')*/
/*		values('rlaizh@bancoripley.com','RODRIGO_LAIZ','PPFF')*/
/*		values('onavarreteg@ripley.com','OSCAR_NAVARRETE','PPFF')*/

/*		EQUIPO MEDIOS DE PAGOS*/
		values('mpincheira@ripley.com','MARCELA_PINCHEIRA','MDP')
		values('acortess@bancoripley.com','ALEJANDRA_CORTES','MDP')
		values('psallorenzop@bancoripley.com','PRISCILLA_SALLORENZO','MDP')
/*		values('mfreyss@bancoripley.com','MAXIME_FREYSS','MDP')*/
/*		values('mgonzaleze@bancoripley.com','MARIA_JOSE_GONZALEZ','MDP')*/

/*		OTROS VARIOS*/
		values('emoraless@ripley.com','EDUARDO_MORALES','DWH')
		values('jcisternaso@ripley.com','JOAQUIN_CISTERNAS','DWH')

/*		CLIENTES Y SEGMENTOS	*/
		values('fhott@bancoripley.com','FELIPE_HOTT','CLIENTES')
		values('fnorambuenag@ripley.com','FRANCISCA_NORAMBUENA','CLIENTES')
		values('gcaballerob@ripley.com','GONZALO_CABALLERO','CLIENTES')
		values('gmoreno@bancoripley.com','GONZALO_MORENO','CLIENTES')
		values('vtroncoso@bancoripley.com','VALENTIN_TRONCOSO','CLIENTES')
/*		values('mgaticab@bancoripley.com','MARIA_PAZ_GATICA','CLIENTES')*/
/*		values('fguerreroc@ripley.com','FELIPE_GUERRERO','CLIENTES')*/
		values('lbachelets@bancoripley.com','PM_SEGMENTOS_1','CLIENTES')
		values('fsalamancao@bancoripley.com','PM_SEGMENTOS_2','CLIENTES')
		values('aillanesa@bancoripley.com','JEFE_SEGMENTOS','CLIENTES')
		
/*		CALIDAD	*/
		values('mrodriguez@bancoripley.com','MAXIMILIANO_RODRIGUEZ','CALIDAD')
		values('rperez@bancoripley.com','RODRIGO_PEREZ','CALIDAD')
		values('mantonelli@bancoripley.com','MARCELO_ANTONELLI','CALIDAD')
		values('jriverosd@bancoripley.com','JOSE_RIVEROS','CALIDAD')
		values('cvillarrealo@bancoripley.com','CRISTIAN_VILLAREAL','CALIDAD')
		values('rperez@bancoripley.com','RODRIGO_PEREZ','CALIDAD')
		values('gparraguez@bancoripley.com','GABRIELA_PARRAGUEZ','CALIDAD')

/*		CCR	*/
		values('rbuguenoe@bancoripley.com','RODRIGO_BUGUENO','CCR')
		values('cecheverriarr@bancoripley.com','CRISTIAN_ECHEVERRIA','CCR')
		values('mgonzaleza@bancoripley.com','MARTA_GONZALEZ','CCR')
		values('mvargasc@bancoripley.com','MICHAEL_VARGAS','CCR')
		values('hlunaa@bancoripley.com','HECTOR_LUNA','CCR')

/*		SEGUROS	*/
		values('rmenac@ripley.com','RODRIGO_MENA','SEGUROS')

/*		SERNAC - PROYECTO 3	*/
		values('jbaezam@ripley.com','JHON_BAEZA','SEG_COMERCIAL')
		values('esanhuezam@ripley.com','ERIK_SANHUEZA','SEG_COMERCIAL')
		values('cavillarroel@ext.bancoripley.com','CAROLINA_VILLARROEL','QA')
		values('jrmartinez@bancoripley.com','JAIME_MARTINEZ','TI')

/*		SPOS & ALIANZAS	*/
		values('cacunab@ripley.com','CONI_ACUNA','SPOS')
		values('mmenesesc@bancoripley.com','MARTIN_MENESES','SPOS')
		values('mbentjerodts@bancoripley.com','MAGDA_BENTJERODT','SPOS')
		values('sfaz@bancoripley.com','SANTIAGO_FAZ','SPOS')
		values('mramirezb@bancoripley.com','MANUEL_RAMIREZ','SPOS')
		values('fmunozh@ripley.com','FABIOLA_MUNOZ','SPOS')
		values('lhernandezh@bancoripley.com','LIVIA_HERNANDEZ','SPOS')
/*		values('jagudom@bancoripley.com','PEPE_AGUDO','SPOS')*/
/*		values('jdiazm@bancoripley.com','JOSE_ANTONIO_DIAZ','SPOS')*/
		values('nencinas@bancoripley.com','ALUMNO_PRACTICA_1','SPOS')
		values('ccorreabc@bancoripley.com','ALUMNO_PRACTICA_2','SPOS')
		values('sfaz@bancoripley.com','GERENTE_ALIANZAS_SPOS','SPOS')
		values('bschmidtm@bancoripley.com','PM_ALIANZAS_1','SPOS')
		values('mbentjerodts@bancoripley.com','JEFE_ALIANZAS','SPOS')
		values('cruizs@bancoripley.com','SUBG_ALIANZAS','SPOS')

/*		DIGITAL	*/
		values('mgalazh@bancoripley.com',		'SUBGERENT_CNL_DIGITAL','DIGITAL')

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
	SELECT EMAIL into :EDP_BI FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';
	SELECT EMAIL into :DEST_1 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'JEFE_ARQ_DAT';
	SELECT EMAIL into :DEST_2 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_1';
	SELECT EMAIL into :DEST_3 FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'PM_ARQ_DAT_2';
quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1")
CC = ("&DEST_2","&DEST_3")
SUBJECT = ("MAIL_AUTOM: Proceso DIRECCIONES_CORREOS_EDP");
FILE OUTBOX;
	PUT "Estimados:";
	PUT "		Proceso DIRECCIONES_CORREOS_EDP, actualizado con fecha: &fechaeDVN";  
	PUT;
	PUT;
	PUT 'Proceso Vers. 21';
	PUT 'Último cambio: Se agrega a nueva PM Consumo y se quita a Eduardo Díaz';
	PUT;
	PUT;
	PUT 'Atte.';
	Put 'Equipo Arquitectura de Datos y Automatización BI';
	PUT;
RUN;
FILENAME OUTBOX CLEAR;

/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================================================================================*/
