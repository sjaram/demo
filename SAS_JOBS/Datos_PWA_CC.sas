DATA _null_;
%LET N=31;
dia_actual_menos_31 = input(put(intnx('day',today(),0-&N.,'same'),date9. ),$10.) ;
dia_actual_menos_1 = input(put(intnx('day',today(),-1,'same'),date9. ),$10.) ;	
Call symput("dia_menos_30", dia_actual_menos_31);
Call symput("dia_anterior", dia_actual_menos_1);
RUN;
%put &dia_menos_30;
%put &dia_anterior;

LIBNAME libbehb ODBC  DATASRC="BR-BACKENDHB"  SCHEMA=dbo  USER="ripley-bi"  PASSWORD="biripley00"; 

proc sql;
create table work.INTERNET_SIMULACIONES_PWA as 
select 
Token
      ,Rut
      ,PrimerVencimiento
      ,Producto
      ,MontoSimulado
      ,CostoTotal
      ,Cuotas
      ,ValorCuota
      ,Cae
      ,ITE
      ,Comision
      ,InteresMensual
      ,PrecioSeguro
      ,Canal
      ,Dispositivo
      ,FechaSimulación
      ,''  as Comercio
      ,'' as Sucursal
      ,'' as Terminal
      ,'' as TotemID
from LIBBEHB.SIMULATIONAVSAVVIEW 
where datepart('Fechasimulación'n)>= "&dia_menos_30."d and datepart('Fechasimulación'n)<= "&dia_anterior."d 
;quit;


PROC EXPORT DATA =  work.INTERNET_SIMULACIONES_PWA
/*OUTFILE="/sasdata/users94/user_bi/unica/INPUT-TR_CAMPANAS-&USUARIO..csv"*/
OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/PWA/INTERNET_SIMULACIONES_PWA.csv"
DBMS=dlm REPLACE;
delimiter=';';
PUTNAMES=YES;
RUN;

 

/* EXPORTAR DE SAS A UN FTP O SFTP */ 
       filename server ftp 'INTERNET_SIMULACIONES_PWA.csv' CD='/' 
       HOST='192.168.82.171' user='17457765K' pass='17457765K' PORT=21;
data _null_;
       infile '/sasdata/users94/user_bi/TRASPASO_DOCS/PWA/INTERNET_SIMULACIONES_PWA.csv' ;
       file server;
       input;
       put _infile_;
run;


proc sql;
create table work.SIMULACIONES_PWA_CONSUMO as 
select
 ID
      ,Token
      ,Rut
      ,Producto
      ,MontoLiquido
      ,FechaSimulacion
      ,Cuotas
      ,ValorCuota
      ,InteresMensual
      ,CAE
      ,CostoTotal
      ,ITE
      ,GastosNotariales
      ,MontoBruto
      ,PrimerVencimiento
      ,DiasDiferidos
      ,SeguroDesgravamen
      ,SeguroVida
      ,Canal
      ,Dispositivo
      ,Comercio
      ,Sucursal
      ,Terminal
      ,TotemID
      ,Origen
      ,DisponibleConsumo
from LIBBEHB.SimulationPersonalLoanView
where datepart(Fechasimulacion)>= "&dia_menos_30."d and datepart(Fechasimulacion)<= "&dia_anterior."d 
;quit;


  PROC EXPORT DATA =  work.SIMULACIONES_PWA_CONSUMO
/*OUTFILE="/sasdata/users94/user_bi/unica/INPUT-TR_CAMPANAS-&USUARIO..csv"*/
OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/PWA/SIMULACIONES_PWA_CONSUMO.csv"
DBMS=dlm REPLACE;
delimiter=';';
PUTNAMES=YES;
RUN;

 

/* EXPORTAR DE SAS A UN FTP O SFTP */ 
       filename server ftp 'SIMULACIONES_PWA_CONSUMO.csv' CD='/' 
       HOST='192.168.82.171' user='17457765K' pass='17457765K' PORT=21;
data _null_;
       infile '/sasdata/users94/user_bi/TRASPASO_DOCS/PWA/SIMULACIONES_PWA_CONSUMO.csv' ;
       file server;
       input;
       put _infile_;
run;

/*
proc sql;
create table work.INTERNET_SIMULA_DAP as 
SELECT  datepart(Fechasimulacion) as fecha,
COUNT(*) as VALOR
 FROM LIBBEHB.SimulationDapView
 WHERE datepart(Fechasimulacion)>= "&dia_menos_30."d and datepart(Fechasimulacion)<= "&dia_anterior."d 
 GROUP BY datepart(Fechasimulacion)
 ;quit;
*//*Fuente de datos:   */



proc sql;
create table work.INTERNET_SIMULA_DAP as 
SELECT  created_at format=date9. as fecha,count(*) as valor
 FROM (select datepart(created_at)format=date9. as created_at,investmentsamount from  LIBBEHB.SimDAP)
 WHERE created_at>= "&dia_menos_30."d and created_at<= "&dia_anterior."d  and investmentsAmount is not null and investmentsamount not in ('0')
 GROUP BY created_at
 ;quit;

  PROC EXPORT DATA =  work.INTERNET_SIMULA_DAP
/*OUTFILE="/sasdata/users94/user_bi/unica/INPUT-TR_CAMPANAS-&USUARIO..csv"*/
OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/PWA/INTERNET_SIMULA_DAP.csv"
DBMS=dlm REPLACE;
delimiter=';';
PUTNAMES=YES;
RUN;

 

/* EXPORTAR DE SAS A UN FTP O SFTP */ 
       filename server ftp 'INTERNET_SIMULA_DAP.csv' CD='/' 
       HOST='192.168.82.171' user='17457765K' pass='17457765K' PORT=21;
data _null_;
       infile '/sasdata/users94/user_bi/TRASPASO_DOCS/PWA/INTERNET_SIMULA_DAP.csv' ;
       file server;
       input;
       put _infile_;
run;


proc sql;
create table work.BACKEND_AVSAV_VOUCHER as 
SELECT  Id
      ,Token
      ,Rut
      ,NumOperacion
      ,Producto
      ,MontoLiquido
      ,FechaCurse
      ,Cae
      ,Cuotas
      ,ValorCuota
      ,TasaMensual
      ,CostoTotal
      ,ITE
      ,TarjetaOrigen
      ,CuentaOrigen
      ,NombreDestino
      ,RutDestino
      ,TipoCuentaDestino
      ,CuentaDestino
      ,BancoDestino
      ,PrecioSeguro
      ,PrimerVencimiento
      ,Canal
      ,Dispositivo
      ,Autenticacion
      ,FechaCreacionRegistro
 FROM LIBBEHB.AvSavVoucherView
 WHERE datepart(Fechacurse)>= "&dia_menos_30."d and datepart(Fechacurse)<= "&dia_anterior."d 
 ;quit;

 PROC EXPORT DATA =  work.BACKEND_AVSAV_VOUCHER
/*OUTFILE="/sasdata/users94/user_bi/unica/INPUT-TR_CAMPANAS-&USUARIO..csv"*/
OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/PWA/BACKEND_AVSAV_VOUCHER.csv"
DBMS=dlm REPLACE;
delimiter=';';
PUTNAMES=YES;
RUN;

 

/* EXPORTAR DE SAS A UN FTP O SFTP */ 
       filename server ftp 'BACKEND_AVSAV_VOUCHER.csv' CD='/' 
       HOST='192.168.82.171' user='17457765K' pass='17457765K' PORT=21;
data _null_;
       infile '/sasdata/users94/user_bi/TRASPASO_DOCS/PWA/BACKEND_AVSAV_VOUCHER.csv' ;
       file server;
       input;
       put _infile_;
run;

proc sql;
create table work.PWA_CONSUMO as 
SELECT  ID
      ,Token
      ,Rut
      ,NumeroOperacion
      ,Producto
      ,MontoLiquido
      ,FechaCurse
      ,Cuotas
      ,ValorCuota
      ,InteresMensual
      ,CAE
      ,CostoTotal
      ,ITE
      ,GastosNotariales
      ,MontoBruto
      ,PrimerVencimiento
      ,DiasDiferidos
      ,SeguroDesgravamen
      ,SeguroVida
      ,RutDestino
      ,NombreDestino
      ,TipoCuentaDestino
      ,NumeroCuentaDestino
      ,BancoDestino
      ,Canal
      ,Dispositivo
      ,Autenticacion
      ,TelefonoSinacofi
      ,Email
      ,Comercio
      ,Sucursal
      ,Terminal
      ,TotemID
 FROM LIBBEHB.PersonalLoanView 
 WHERE datepart(Fechacurse)>= "&dia_menos_30."d and datepart(Fechacurse)<= "&dia_anterior."d 
 ;quit;

PROC EXPORT DATA =  work.PWA_CONSUMO
/*OUTFILE="/sasdata/users94/user_bi/unica/INPUT-TR_CAMPANAS-&USUARIO..csv"*/
OUTFILE="/sasdata/users94/user_bi/TRASPASO_DOCS/PWA/PWA_CONSUMO.csv"
DBMS=dlm REPLACE;
delimiter=';';
PUTNAMES=YES;
RUN;

 

/* EXPORTAR DE SAS A UN FTP O SFTP */ 
       filename server ftp 'PWA_CONSUMO.csv' CD='/' 
       HOST='192.168.82.171' user='17457765K' pass='17457765K' PORT=21;
data _null_;
       infile '/sasdata/users94/user_bi/TRASPASO_DOCS/PWA/PWA_CONSUMO.csv' ;
       file server;
       input;
       put _infile_;
run;
