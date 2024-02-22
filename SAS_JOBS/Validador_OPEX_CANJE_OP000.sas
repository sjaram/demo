

/*Fecha Inicial de la etapa*/
PROC SQL outobs=1 noprint;   
select 
infoerr as temp_error
into :temp_error
from result.tbl_estado_proceso
where nombre_proceso = 'TABLA_OPEX_CANJESOP'
order by fecha desc
;QUIT;

%put &temp_error;

%macro mensaje_correo(error) ;
	   	
	FILENAME output EMAIL
	SUBJECT= "Ejecución de Proceso Opex CanjeOP"
	FROM= "SJARAM@BANCORIPLEY.com"
	TO= ("SJARAM@BANCORIPLEY.com", "dvasquez@bancoripley.com", "BSOTOV@bancoripley.com")
	CT= "text/html" /* Required for HTML output */ ;
	FILENAME mail EMAIL TO="erik.tilanus@planet.nl"
 	SUBJECT="HTML OUTPUT" CONTENT_TYPE="text/html";
	ODS LISTING CLOSE;
	ODS HTML  path="/sasdata/users94/user_bi" file = "Validador_OPEX_CANJEOP.lst" (URL=none) BODY=output STYLE=sasweb;
	TITLE JUSTIFY=left
	&temp_error;
	PROC PRINT DATA=result.vista_email  NOOBS;
	RUN;
	ODS HTML CLOSE;
	ODS LISTING;

%mend mensaje_correo;

%mensaje_correo;








