/* cap input rows for the captured run */
options obs=100;

/* PESO_CHEK_RIPLEY.sas's %uso_tr_trx macro reads RESULT.USO_TR_MARCA_<yyyymm>,
   a per-month table populated upstream from a Redshift extract, for four
   rolling periods computed from TODAY() (this month, and 1/2/12 months
   back). We substitute small mock tables for whichever four periods the
   macro resolves today, built from the exact columns the script selects
   (lugar, nombre_division, departamento_fin, marca_tipo_tr, nombre_sucursal,
   tipo_compra, bol_vta, mto, dia_nro) so the GROUP BY / SUBSTR / CASE WHEN
   aggregation, UNION ALL, JOIN against PARAM_DEPTOS, and PROC TRANSPOSE
   pivot all run against real data shapes.

   Note on dia_nro: the script computes &dia_actual as (day-of-month of
   TODAY()) - 1 and keeps only rows with dia_nro <= &dia_actual, a
   partial-month-to-date filter. Mock rows use dia_nro values at or below
   that cutoff (with one row above it, to prove the filter is genuinely
   exercised rather than a no-op). */
libname result "%sysfunc(pathname(work))";

%macro _mock_uso_tr_marca(n);
  data _null_;
    periodo = input(put(intnx('month',today(),-&n.,'begin'),yymmn6.),$10.);
    call symput("_per&n", periodo);
  run;

  data result.uso_tr_marca_&&_per&n;
    length lugar $10 nombre_division $20 departamento_fin $10 marca_tipo_tr $6
           nombre_sucursal $30 tipo_compra $10;
    periodo = &&_per&n;
    input lugar $ nombre_division $ departamento_fin $ marca_tipo_tr $
          nombre_sucursal $ tipo_compra $ bol_vta mto dia_nro;
    datalines;
RCOM Division-Norte D1910001 TR Sucursal-Centro PRESENCIAL 1001 45000 0
RCOM Division-Norte D1910001 TR Sucursal-Centro PRESENCIAL 1002 32000 0
RCOM Division-Norte D1220001 CHECK Sucursal-Centro ONLINE 1003 18000 0
TIENDA Division-Sur D1030001 TR Sucursal-Oriente PRESENCIAL 2001 61000 0
TIENDA Division-Sur D1030001 NOTR Sucursal-Oriente PRESENCIAL 2002 9000 0
TIENDA Division-Sur . TR . ONLINE 2003 27500 22
;
  run;

  data result.uso_tr_marca_&&_per&n;
    set result.uso_tr_marca_&&_per&n;
    lugar = translate(lugar, ' ', '-');
    nombre_division = translate(nombre_division, ' ', '-');
    nombre_sucursal = translate(nombre_sucursal, ' ', '-');
  run;
%mend _mock_uso_tr_marca;

%_mock_uso_tr_marca(0);
%_mock_uso_tr_marca(1);
%_mock_uso_tr_marca(2);
%_mock_uso_tr_marca(12);
