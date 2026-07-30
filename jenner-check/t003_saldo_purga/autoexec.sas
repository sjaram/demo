/* cap input rows for the captured run */
options obs=100;

/* Saldo_Purga.sas reads two Oracle tables (PSFC1.T7542700 = points-available
   ledger, PSFC1.T7542600 = enrollment ledger) via a hardcoded LIBNAME PSFC1
   ORACLE connection, and writes its result into PUBLICIN, another
   production libname. We substitute both source tables with small mock
   data built from the exact columns the script selects (CODCUENT, TIPOPUNT,
   CANTPUNT, SALULTEX, FECULTAC, FECHPROC, CHEQDATA, FECHALTA, FECHBAJA) and
   point PUBLICIN at a local WORK-backed libname, so the script's own
   INPUT/SUBSTR/LEFT JOIN logic runs unmodified. The export path is
   redirected from the hardcoded /sasdata/... path to a relative ./output/
   directory checked into this bundle. */
libname psfc1 "%sysfunc(pathname(work))";
libname publicin "%sysfunc(pathname(work))";

data psfc1.t7542700;
  length CODCUENT $10 TIPOPUNT $2 FECULTAC $8 FECHPROC $8 CHEQDATA $1;
  input CODCUENT $ TIPOPUNT $ CANTPUNT SALULTEX FECULTAC $ FECHPROC $ CHEQDATA $;
  datalines;
11111111 01 1500 1500 20191228 20191231 N
22222222 01 800 800 20191215 20191231 N
33333333 02 200 200 20191220 20191231 N
44444444 01 3200 3200 20191230 20191231 S
55555555 01 0 0 20191201 20191231 N
;
run;

data psfc1.t7542600;
  length CODCUENT $10 FECHALTA $8 FECHBAJA $8;
  input CODCUENT $ FECHALTA $ FECHBAJA $;
  datalines;
11111111 201805 .
22222222 201911 .
33333333 201703 .
44444444 202002 .
66666666 201601 20191115
;
  if fechbaja = "." then fechbaja = "";
run;
