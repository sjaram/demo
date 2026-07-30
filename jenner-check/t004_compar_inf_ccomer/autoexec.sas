/* cap input rows for the captured run */
options obs=100;

/* COMPAR_INF_CCOMER.sas exports three production tables (RESULT.CTAVTA1_STOCK,
   PUBLICIN.LNEGRO_CAR, RESULT.STOCK_CC -- current-account stock, a
   blacklist-flag table, and credit-card stock) and then FTPs each CSV to an
   internal host. We substitute small mock tables for the three RESULT/
   PUBLICIN sources and drop the FTP transfer step (no reasonable
   substitute for a private FTP endpoint); the PROC EXPORT calls that
   produce the CSVs -- this script's actual data-producing logic -- run
   unmodified, with the outfile paths redirected from the hardcoded
   /sasdata/... path to a relative ./output/ directory. */
libname result "%sysfunc(pathname(work))";
libname publicin "%sysfunc(pathname(work))";

data result.ctavta1_stock;
  length cuenta $10 sucursal $20;
  input cuenta $ sucursal $ saldo;
  datalines;
CT0001001 Sucursal-Centro 150000
CT0001002 Sucursal-Oriente 82000
CT0001003 Sucursal-Centro 0
;
run;
data result.ctavta1_stock;
  set result.ctavta1_stock;
  sucursal = translate(sucursal, ' ', '-');
run;

data publicin.lnegro_car;
  length rut $10 motivo $20;
  input rut $ motivo $ fecha_ingreso :yymmdd8.;
  format fecha_ingreso yymmdd8.;
  datalines;
11111111 MORA-VENCIDA 20191001
22222222 FRAUDE-CONFIRMADO 20191115
;
run;
data publicin.lnegro_car;
  set publicin.lnegro_car;
  motivo = translate(motivo, ' ', '-');
run;

data result.stock_cc;
  length cuenta $10 tipo_tarjeta $10;
  input cuenta $ tipo_tarjeta $ cupo_disponible;
  datalines;
CT0002001 TC 500000
CT0002002 TD 0
CT0002003 TC 125000
;
run;
