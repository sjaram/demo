/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROC_BASE_SALDO_PISO_12		================================*/
/* CONTROL DE VERSIONES

/* 2021-02-23 -- V2 -- Sergio J.
					-- Nueva clave: "{sas002}AC224E474B8742BD13124A965275013020A60F8D15DCC25A52A5D43F49A76B4D"

/* 2020-11-25 -- V2 -- Sergio J.
					-- Nueva clave: "{sas002}AC224E474B8742BD13124A965275013020A60F8D15DCC25A52A5D43F49A76B4D"

/* 2020-07-30 -- V1 -- Benjamin S. --
					-- Nueva query de Benjamín

/* 2020-07-29 -- V0 -- Benjamin S. --  
					-- Original + tiempo y envío de correo
*/
/*==================================================================================================*/

/*	DECLARACIÓN VARIABLE TIEMPO		*/
%let tiempo_inicio= %sysfunc(datetime()); /* inicio del proceso de conteo*/

/*	PARA DIFERENCIAR ARCHIVOS DE SALIDA	*/
proc format;
   picture cust_dt other = '%0Y%0m%0d%0H%0M%0S' (datatype=datetime);
RUN;
data test;
    dt = datetime();
    call symputx("dt",strip(put(dt,cust_dt.)));

RUN;
%put &dt.;

/*==================================================================================================*/
/*	INICIO // PROGRAMA GENERADO POR PM		*/
proc sql;
 
connect to SQLSVR as mydb
      (datasrc="SQL_Datawarehouse" user="user_sas" 
		password="{sas002}AC224E474B8742BD13124A965275013020A60F8D15DCC25A52A5D43F49A76B4D");
 
create table work.Base_query_ant as
select * 
from connection to mydb ( /*Query de conexion Loyalty*/
 Select  a.documentnumber, a.[CREATIONDATE], max(a.[POINTSBALANCE]) as Saldo 
from  [db2].[LOYALTY_NOVEDADES] a
  inner join
  (select documentnumber, max([CREATIONDATE]) as ULT_FPROC 
from [db2].[LOYALTY_NOVEDADES] group by documentnumber) b
  on a.documentnumber=b.documentnumber and
  a.[CREATIONDATE]=b.ULT_FPROC
  GRoup by a.documentnumber, a.[CREATIONDATE]
 
 
) as conexion
 
;quit;



proc sql;
 
connect to SQLSVR as mydb
      (datasrc="SQL_Datawarehouse" user="user_sas" 
		password="{sas002}AC224E474B8742BD13124A965275013020A60F8D15DCC25A52A5D43F49A76B4D");
 
create table work.Base_query_nva as
select * 
from connection to mydb ( /*Query de conexion Loyalty*/
Select 
	DocumentNumber,
	Sum(Saldo) As Saldo
From
	(
    Select
		DocumentNumber,
        Case
            When TransactionType = 'Bonifica' And Status = '1' And ExpirationValue = 0 Then TransactionDate  
            When TransactionType = 'Bonifica' And Status = '3' And ExpirationValue = 0 Then LastUpdateDate
            When TransactionType = 'Bonifica' And Status = '1' And ExpirationValue <> 0 Then DateAdd(Month, -1, Cast(Cast(ExpirationDate As Varchar(50)) As Date)) 
            When TransactionType = 'Canje' And Status = '1' Then TransactionDate 
            When TransactionType = 'Canje' And Status = '3' Then LastUpdateDate 
            End As Fecha_Evento,
		Case
            When TransactionType = 'Bonifica' And Status = '1' And ExpirationValue = 0 Then Quantity 
            When TransactionType = 'Bonifica' And Status = '3' And ExpirationValue = 0 Then Quantity * -1 
            When TransactionType = 'Bonifica' And Status = '1' And ExpirationValue <> 0 Then ExpirationValue * -1 
            When TransactionType = 'Canje' And Status = '1' Then NumberPoints * -1 
            When TransactionType = 'Canje' And Status = '3' Then NumberPoints 
			End As Saldo
	From
		(
		Select DocumentNumber,
TransactionType,
Status,
ExpirationValue,
NumberPoints,
TransactionDate,
LastUpdateDate,
Quantity,
ExpirationDate
		From db2.Loyalty_Novedades
		union
		Select DocumentNumber,
TransactionType,
Status,
ExpirationValue,
NumberPoints,
TransactionDate,
LastUpdateDate,
Quantity,
ExpirationDate
		From db2.Loyalty_Novedades_especial
	    

		) As TotalNovedades
	) As ObtenciónSaldos
Where Cast(Cast(Fecha_Evento As Varchar(50)) As Date) <= Cast(Cast(GETDATE() As Varchar(50)) As Date)
Group by DocumentNumber
Order By DocumentNumber

 
 
) as conexion
 
;quit;




proc sql;
create table work.Base_saldo_Piso12_&dt. as /*	ACTUALIZADO EQUIPO DATOS Y PROCESOS VS ORIGINAL	*/
select t1.documentnumber as rut,t1.saldo as Saldo_QueryAntigua,t3.saldo as Saldo_QueryNva,colaborador from Base_query_ant t1
inner join   (select rut,colaborador from publicin.dotacion where 'Gerencia 1'n ='Gerencia de Marketing y Productos') t2 on t1.documentnumber=t2.rut
left join Base_query_nva t3 on t1.documentnumber=t3.documentnumber
;quit;

/*	FINAL // PROGRAMA GENERADO POR PM		*/
/*==================================================================================================*/


/*   EXPORTAR SALIDA A FTP DE SAS   */
PROC EXPORT DATA	=	work.Base_saldo_Piso12_&dt.
   OUTFILE="/sasdata/users94/user_bi/para_mail/Base_saldo_Piso12_&dt..csv"
   DBMS=dlm;
   delimiter=';';
   PUTNAMES=YES;
RUN;

/*	UTILIZACIÓN VARIABLE TIEMPO	/ CUANTO SE DEMORÓ	*/
data _null_;
  dur = datetime() - &tiempo_inicio;
  put 30*'-' / ' DURACIÓN TOTAL:' dur time13.2 / 30*'-';
run; /*salida del proceso indicando el tiempo total */


/*	Fecha ejecución del proceso	*/
data _null_;
execDVN = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechaeDVN", execDVN) ;
RUN;
%put &fechaeDVN;/*fecha ejecucion proceso */

/*   ENVÍO DE CORREO CON MAIL VARIABLE   */
proc sql noprint;                              
SELECT EMAIL into :EDP_BI 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'EDP_BI';

SELECT EMAIL into :DEST_1 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'BENJAMIN_SOTO';

SELECT EMAIL into :DEST_2 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'DAVID_VASQUEZ';

SELECT EMAIL into :DEST_3 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'FELIPE_HOTT';

SELECT EMAIL into :DEST_4 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'FRANCISCA_NORAMBUENA';

SELECT EMAIL into :DEST_5 
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'GONZALO_CABALLERO';

SELECT EMAIL into :DEST_6
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'GONZALO_MORENO';

SELECT EMAIL into :DEST_7
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SEBASTIAN_BARRERA';

SELECT EMAIL into :DEST_8
	FROM result.EDP_BI_DESTINATARIOS WHERE CODIGO = 'SERGIO_JARA';

quit;

%put &=EDP_BI;
%put &=DEST_1;
%put &=DEST_2;
%put &=DEST_3;
%put &=DEST_4;
%put &=DEST_5;
%put &=DEST_6;
%put &=DEST_7;
%put &=DEST_8;

data _null_;
FILENAME OUTBOX EMAIL
FROM = ("&EDP_BI")
TO = ("&DEST_1","&DEST_3","&DEST_4","&DEST_5","&DEST_6")
/*TO = ("&DEST_1")*/
CC = ("&DEST_2","&DEST_7","&DEST_8")
ATTACH="/sasdata/users94/user_bi/para_mail/Base_saldo_Piso12_&dt..csv"
SUBJECT = ("MAIL_AUTOM: PROCESO BASE SALDO PISO 12");
FILE OUTBOX;
PUT "Estimados:";
PUT ; 
 put "Proceso Base de Saldo Piso 12, ejecutado con fecha: &fechaeDVN";  
 put ; 
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 put 'Proceso Vers. 02'; 
 PUT ;
 PUT ;
PUT 'Atte.';
Put 'Equipo Datos y Procesos BI';
PUT ;
PUT ;
PUT ;
RUN;
FILENAME OUTBOX CLEAR;
