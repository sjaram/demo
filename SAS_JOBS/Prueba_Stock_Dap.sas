
/*===============================================================================================================================================================*/
/*=== MACRO FECHAS ==============================================================================================================================================*/
/*===============================================================================================================================================================*/

data _null_;
date0 = input(put(intnx('month',today(),0,'same'),yymmn6. ),$10.);
date1 = input(put(intnx('month',today(),0,'same'),YYMMDDN8. ),$10.);
exec = compress(input(put(today(),yymmdd10.),$10.),"-",c);
Call symput("fechae", exec) ;
Call symput("periodo", date0);
Call symput("periodox", date1);
call symput('fechai',"TO_DATE('"||input(put(intnx('day',today(),-1,'same'),DDMMYYD10. ),$10.)||"','DD-MM-YYYY')");
call symput('fechap',"TO_DATE('"||input(put(intnx('day',today(),0,'same'),DDMMYYD10. ),$10.)||"','DD-MM-YYYY')");;RUN;

%put &periodo; /*periodo actual */
%put &fechai; /*fecha interes-dia anterior*/
%put &fechap;/*fecha proceso-dia actual*/
%put &periodox;/*periodo-dia actual*/
%put &fechae;/*fecha ejecucion proceso */
/*===============================================================================================================================================================*/
/*=== CONEXION FISA =============================================================================================================================================*/
/*===============================================================================================================================================================*/


%let mz_connect_BANCO=CONNECT TO ORACLE as BANCO(USER='RIPLEYC' PASSWORD='ri99pley'
PATH="  (DESCRIPTION = 
    (ADDRESS_LIST = 
      (ADDRESS = 
        (PROTOCOL = TCP)
        (Host = 192.168.10.31)
        (Port = 1521)
      )
    )
    (CONNECT_DATA = 
      (SID = ripleyc)
    )
  )
");

/********************************************************
Fecha de proceso es la fecha actual
Fecha interés corresponde a la fecha hábil anterior.
*********************************************************/


%let mz_connect_BANCO=CONNECT TO ORACLE as BANCO(USER='RIPLEYC' PASSWORD='ri99pley'
PATH="  (DESCRIPTION = 
    (ADDRESS_LIST = 
      (ADDRESS = 
        (PROTOCOL = TCP)
        (Host = 192.168.10.31)
        (Port = 1521)
      )
    )
    (CONNECT_DATA = 
      (SID = ripleyc)
    )
  )
");




proc sql;
&mz_connect_BANCO;
create table work.Stock as
SELECT *
from  connection to BANCO(
SELECT            pda_cuenta codigo_operacion
    ,acc_mod         pda_mod
    ,acc_pro         pda_pro
    ,acc_tip         pda_tip
    ,PDA_FECHAPER    fecha_apertura
    ,PDA_STATUS
    ,acc_moneda    moneda
    ,PDA_CODSUC    codigo_sucursal
    ,PDA_CODOFI    codigo_oficina
    ,PDA_CLIENTEP  codigo_cliente
    ,PDA_FECVEN    fecha_vencimiento
    ,PDA_FECVALOR
    ,PDA_FECIERRE  fecha_cierre
    ,PDA_FECRENOV  fecha_renovacion
    ,cli_catdeudor
    ,pkg_generico_rep.capital_deposito(pda_cuenta,&fechai.) capital_vigente
    ,pkg_generico_rep.interes_deposito(pda_cuenta,&fechai.) interes_vigente
    ,pda_ejecutivo codigo_ejecutivo
    ,pda_capital   capital
    ,pda_plazo       plazo
    ,pda_tasa        tasa
    ,pda_tasapac     tasa_pactada
    ,cli_identifica  rut_cliente
    ,cli_nombre      nombre_cliente
    ,cli_tipoper
    ,emp_nombre      nombre_ejecutivo
    ,des_descripcion    cargo_ejecutivo
    FROM tpla_cuenta
        ,tcli_persona
        ,tpla_accrual
        ,tgen_empleado
        ,tgen_usuario
        ,tgen_desctabla
    WHERE pda_clientep                  = cli_codigo
    AND pda_cuenta                      = acc_cuenta
    AND trunc(pda_fechaper)            <= &fechap
    AND pda_status  not in('0','S','A')
    AND ( pda_fecierre is null or trunc(pda_fecierre) >= &fechap)
    AND (trunc(acc_fecha) = &fechai. or trunc(acc_fecha) = pda_fecrenov )
    AND pkg_generico_rep.deposito_en_ventana( pda_cuenta,&fechap ) = 'N'
    AND pda_ejecutivo    = usr_codigo
    AND emp_codigo       = usr_codemp
    AND emp_tabcargo     = des_codtab
    AND emp_cargo        = des_codigo
union
   SELECT pda_cuenta   codigo_operacion
         ,pda_mod
         ,pda_pro
         ,pda_tip
         ,PDA_FECHAPER  fecha_apertura
         ,PDA_STATUS
         ,PDA_MONEDA    moneda
         ,PDA_CODSUC    codigo_sucursal
         ,PDA_CODOFI    codigo_oficina
         ,PDA_CLIENTEP  codigo_cliente
         ,PDA_FECVEN    fecha_vencimiento
         ,PDA_FECVALOR
         ,PDA_FECIERRE  fecha_cierre
         ,PDA_FECRENOV  fecha_renovacion
         ,cli_catdeudor
         ,pkg_generico_rep.capital_deposito(pda_cuenta,&fechai.) capital_vigente
         ,pkg_generico_rep.interes_deposito(pda_cuenta,&fechai.) interes_vigente
         ,pda_ejecutivo   codigo_ejecutivo
         ,pda_capital     capital
         ,pda_plazo       plazo
         ,pda_tasa        tasa
         ,pda_tasapac     tasa_pactada
         ,cli_identifica  rut_cliente
         ,cli_nombre      nombre_cliente
         ,cli_tipoper
         ,emp_nombre      nombre_ejecutivo
         ,des_descripcion cargo_ejecutivo
       FROM tpla_cuenta
           ,tcli_persona
           ,tgen_empleado
           ,tgen_usuario
           ,tgen_desctabla
      WHERE pda_clientep       = cli_codigo
      AND (pda_pro             <> 99 or
          (pda_pro = 99 and pda_status IN ('E','D') and  pda_fecrenov <=  &fechap) or
          (pda_pro = 99 and pda_status in ('E','D') and pda_fecven > &fechai.) or
          (pda_pro = 99 and pda_status = '9' and pda_statusant  in ('E','D') and pda_fecven = &fechap)
          )
      AND trunc(pda_fechaper)  <= &fechap
      AND pda_status  not in('0','S','A')
      AND ( pda_fecierre is null or trunc(pda_fecierre) >= &fechap)
      AND pkg_generico_rep.deposito_en_ventana( pda_cuenta,&fechap) = 'S'
      AND pda_ejecutivo    = usr_codigo
      AND emp_codigo       = usr_codemp
      AND emp_tabcargo     = des_codtab
      AND emp_cargo        = des_codigo --;
---------------------------------------------------- inicio 20121107 : sramos ----------------------------------------------------
minus
(
     SELECT
         pda_cuenta      codigo_operacion
        ,acc_mod         pda_mod
        ,acc_pro         pda_pro
        ,acc_tip         pda_tip
        ,PDA_FECHAPER    fecha_apertura
        ,PDA_STATUS
        ,acc_moneda      moneda
        ,PDA_CODSUC      codigo_sucursal
        ,PDA_CODOFI      codigo_oficina
        ,PDA_CLIENTEP    codigo_cliente
        ,PDA_FECVEN      fecha_vencimiento
        ,PDA_FECVALOR
        ,PDA_FECIERRE    fecha_cierre
        ,PDA_FECRENOV    fecha_renovacion
        ,cli_catdeudor
        ,pkg_generico_rep.capital_deposito(pda_cuenta,&fechai.) capital_vigente
        ,pkg_generico_rep.interes_deposito(pda_cuenta,&fechai.) interes_vigente
        ,pda_ejecutivo   codigo_ejecutivo
        ,pda_capital     capital
        ,pda_plazo       plazo
        ,pda_tasa        tasa
        ,pda_tasapac     tasa_pactada
        ,cli_identifica  rut_cliente
        ,cli_nombre      nombre_cliente
        ,cli_tipoper
        ,emp_nombre      nombre_ejecutivo
        ,des_descripcion cargo_ejecutivo
    FROM tpla_cuenta  A
        ,tcli_persona
        ,tpla_accrual
        ,tgen_empleado
        ,tgen_usuario I
        ,tgen_desctabla
        ,BR_DESCTABLA H --sramos
    WHERE     pda_clientep   = cli_codigo
    AND       pda_cuenta     = acc_cuenta
    AND trunc(pda_fechaper) <= &fechap
    AND       pda_status  not in('0','S','A')
    AND (     pda_fecierre is null or trunc(pda_fecierre) >= &fechap)
    AND (trunc(acc_fecha) = &fechai. or trunc(acc_fecha) = pda_fecrenov )
    AND pkg_generico_rep.deposito_en_ventana(pda_cuenta,&fechap ) = 'N'
    AND       pda_ejecutivo  = usr_codigo
    AND       emp_codigo     = usr_codemp
    AND       emp_tabcargo   = des_codtab
    AND       emp_cargo      = des_codigo
    AND A.PDA_PRO||LPAD(A.PDA_TIP,2,0) = H.CODIGO and H.codigotab = 120 and H.entidad='BANCO'   --sramos
    AND A.pda_ejecutivo <> 9 and a.PDA_NIVELSEC > 90                          --sramos
  union
   SELECT
      pda_cuenta    codigo_operacion
     ,pda_mod
     ,pda_pro
     ,pda_tip
     ,PDA_FECHAPER    fecha_apertura
     ,PDA_STATUS
     ,PDA_MONEDA      moneda
     ,PDA_CODSUC      codigo_sucursal
     ,PDA_CODOFI      codigo_oficina
     ,PDA_CLIENTEP    codigo_cliente
     ,PDA_FECVEN      fecha_vencimiento
     ,PDA_FECVALOR
     ,PDA_FECIERRE    fecha_cierre
     ,PDA_FECRENOV    fecha_renovacion
     ,cli_catdeudor
     ,pkg_generico_rep.capital_deposito(pda_cuenta,&fechai.) capital_vigente
     ,pkg_generico_rep.interes_deposito(pda_cuenta,&fechai.) interes_vigente
     ,pda_ejecutivo   codigo_ejecutivo
     ,pda_capital     capital
     ,pda_plazo       plazo
     ,pda_tasa        tasa
     ,pda_tasapac     tasa_pactada
     ,cli_identifica  rut_cliente
     ,cli_nombre      nombre_cliente
     ,cli_tipoper
     ,emp_nombre      nombre_ejecutivo
     ,des_descripcion cargo_ejecutivo
     FROM tpla_cuenta  A
         ,tcli_persona
         ,tgen_empleado
         ,tgen_usuario I
         ,tgen_desctabla
         ,BR_DESCTABLA H --sramos
      WHERE pda_clientep       = cli_codigo
      AND (pda_pro             <> 99 or
          (pda_pro = 99 and pda_status IN ('E','D') and  pda_fecrenov <=  &fechap) or
          (pda_pro = 99 and pda_status in ('E','D') and pda_fecven > &fechai.) or
          (pda_pro = 99 and pda_status = '9' and pda_statusant  in ('E','D') and pda_fecven = &fechap)
          )
      AND trunc(pda_fechaper) <= &fechap
      AND pda_status  not in('0','S','A')
      AND ( pda_fecierre is null or trunc(pda_fecierre) >= &fechap)
      AND pkg_generico_rep.deposito_en_ventana(pda_cuenta,&fechap) = 'S'
      AND pda_ejecutivo        = usr_codigo
      AND emp_codigo           = usr_codemp
      AND emp_tabcargo         = des_codtab
      AND emp_cargo            = des_codigo
      and A.PDA_PRO||LPAD(A.PDA_TIP,2,0) = H.CODIGO and H.codigotab = 120 and H.entidad='BANCO' --sramos
      and a.pda_ejecutivo <> 9 and a.PDA_NIVELSEC > 90                            --sramos
);
) as X
;QUIT;

PROC SQL;
   CREATE TABLE RESULT.DETALLE_STOCK_DAP_2_&periodox AS 
   SELECT t1.*, &fechae as FEC_EX
      FROM WORK.STOCK t1;
QUIT;

PROC SQL;
   CREATE TABLE PUBLICIN.prueba_STOCK_DAP_2_&periodo AS 
   SELECT t1.CAPITAL_VIGENTE as Capital_Vigente,
   INPUT((SUBSTR(t1.RUT_CLIENTE,1,(LENGTH(t1.RUT_CLIENTE)-1))),BEST.) AS RUT,
   t1.CODIGO_OPERACION as Operacion,
   t1.PLAZO as Plazo, 
          t1.TASA format=BEST5. as Tasa, 
          t1.TASA_PACTADA as Tasa_Pactada,
		  t1.FECHA_APERTURA as Fecha_Apertura,
		  t1.FECHA_RENOVACION as Fecha_de_Renovacion,
		  case when  t1.CLI_TIPOPER=1 then 'PERSONAS NATURALES' 
when t1.CLI_TIPOPER=2 then 'PERSONAS JURIDICAS' end as Composicion_Institucional,
t1.NOMBRE_CLIENTE as Nombre,
t1.Nombre_Ejecutivo,
t1.CODIGO_SUCURSAL as Sucursal,
t1.FEC_EX
      FROM RESULT.DETALLE_STOCK_DAP_2_&periodox t1 /*origen query fisa*/
;QUIT;

proc sqL;
drop table STOCK
;QUIT;



/*******************************************************************************/
/*******************************************************************************/
/*******************************************************************************/
/*******************************************************************************/
