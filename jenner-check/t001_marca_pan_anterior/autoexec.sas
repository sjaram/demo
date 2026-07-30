/* cap input rows for the captured run */
options obs=100;

/* MARCA_PAN_ANTERIOR.sas reads RESULT.UNIVERSO_PANES, a table populated
   upstream from an Oracle extract in the original pipeline. We substitute a
   small, representative sample built from the same columns the script
   selects (RUT, CODENT, CENTALTA, CUENTA, TIPO_TARJETA, Tipo_Tarjeta_RSAT,
   PAN, PANANT, NUMPLASTICO, CALPART, T_CTTO_VIGENTE, T_TR_VIG) so the
   script's GROUP BY / CASE WHEN / LEFT JOIN logic runs unmodified. */
libname result "%sysfunc(pathname(work))";

data result.universo_panes;
  length RUT 8 CODENT $4 CENTALTA $4 CUENTA $10 TIPO_TARJETA $20
         Tipo_Tarjeta_RSAT $10 PAN $16 PANANT $16 CALPART $2;
  input RUT CODENT $ CENTALTA $ CUENTA $ TIPO_TARJETA $ Tipo_Tarjeta_RSAT $
        PAN $ PANANT $ NUMPLASTICO CALPART $ T_CTTO_VIGENTE T_TR_VIG;
  datalines;
11111111 0001 0100 CT0001001 MASTERCARD-DEBITO TD 4001000000000001 . 1 TI 1 1
11111111 0001 0100 CT0001001 MASTERCARD-DEBITO TD 4001000000000011 4001000000000001 2 TI 1 1
22222222 0001 0100 CT0001002 MAESTRO-DEBITO TD 4001000000000002 . 1 TI 1 1
33333333 0001 0101 CT0001003 DEBITO-CTACTE CC 4001000000000003 . 1 TI 1 1
44444444 0002 0102 CT0001004 CREDITO-VISA TC 4001000000000004 . 1 TI 1 1
44444444 0002 0102 CT0001004 CREDITO-VISA TC 4001000000000014 4001000000000004 2 TI 1 1
55555555 0002 0103 CT0001005 CREDITO-MASTERCARD TC 4001000000000005 . 1 TI 0 1
66666666 0003 0104 CT0001006 MASTERCARD-DEBITO TD 4001000000000006 . 1 TT 1 1
77777777 0003 0105 CT0001007 DEBITO-CTACTE CC 4001000000000007 . 1 TI 1 0
;
run;

/* datalines can't carry embedded spaces in this list-input layout, so card
   type names are written with a hyphen above and normalized to the real
   space-separated values ('MASTERCARD DEBITO', etc.) that the script's CASE
   WHEN literals match against. */
data result.universo_panes;
  set result.universo_panes;
  TIPO_TARJETA = translate(TIPO_TARJETA, ' ', '-');
run;

