/*Version 2*/

LIBNAME R_bopers ORACLE READBUFF=1000 INSERTBUFF=1000 PATH="REPORITF.WORLD" SCHEMA=BOPERS_ADM USER='SAS_USR_BI' PASSWORD='SAS_23072020';
PROC SQL INOBS=10;
CREATE TABLE result.A_ESTEBAN_PROCESO_VALIDA AS
SELECT DISTINCT input(ide.PEMID_GLS_NRO_DCT_IDE_K,best.) AS RUT,
ide.pemid_nro_inn_ide AS IDINTERNO,
dml.PEMDM_NRO_SEQ_DML_K AS SEQ_ID,
compress(upcase(t2.PEMMA_GLS_DML_MAI)) AS EMAIL length=50,
input(put(datepart(t2.PEMMA_FCH_FIN_ACL),yymmddn8.),best.) AS FECHA_ACT,
t2.PEMMA_COD_EST_LCL AS ESTADO_ACT_VER,
(t2.PEMMA_NRO_SEQ_MAI_K) AS SEQUENCIA,
CASE WHEN t2.PEMMA_GLS_USR_FIN_ACL = 'HB-APP' then 'BOPERS_HB'
WHEN t2.PEMMA_GLS_USR_FIN_ACL = 'APP' then 'BOPERS_APP'
ELSE 'BOPERS_CCSS' END as ORIGEN
FROM r_BOPERS.BOPERS_MAE_IDE ide, r_BOPERS.bopers_mae_dml dml,
r_BOPERS.bopers_rel_ing_lcl lcl, r_BOPERS.BOPERS_MAE_MAI t2
WHERE t2.PEMMA_COD_EST_LCL NOT = 6
and lcl.peril_cod_tip_lcl_dos_k = 4 and
lcl.peril_cod_tip_lcl_uno_k = 1 and
lcl.peril_nro_seq_lcl_uno_k = dml.PEMDM_NRO_SEQ_DML_K and
lcl.pemid_nro_inn_ide_k=ide.pemid_nro_inn_ide and
dml.pemid_nro_inn_ide_k=ide.pemid_nro_inn_ide and
dml.PEMDM_COD_DML_PPA=1 and
dml.pemdm_cod_tip_dml = 1 and
dml.pemdm_cod_neg_dml = 1 and
t2.PEMID_NRO_INN_IDE_K = ide.pemid_nro_inn_ide and
t2.PEMMA_NRO_SEQ_MAI_K = lcl.PERIL_NRO_SEQ_LCL_DOS_K
ORDER BY 1
;QUIT;
