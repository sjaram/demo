/*==================================================================================================*/
/*==================================	EQUIPO DATOS Y PROCESOS		================================*/
/*==================================	PROC_FIPERS_LIBRO_NEGRO		================================*/
/* CONTROL DE VERSIONES
/* 2020-05-27 ---- Original 
*/
/*==================================================================================================*/

LIBNAME FIPERS ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=FIPERS_ADM  USER='PMUNOZC' PASSWORD='pmun2102';

PROC SQL;
   CREATE TABLE RESULT.FIPERS_MAE_LIB_NEG AS
   SELECT t1.PEMLN_FCH_REG_K, 
          t1.PEMLN_GLS_NRO_DCT_IDE_K, 
          t1.PEMLN_NRO_SEQ_K, 
          t1.PEMLN_DVR_NRO_DCT_IDE, 
          t1.PEMLN_COD_TIP_DCT_IDE, 
          t1.PEMLN_NRO_INN_IDE, 
          t1.PEMLN_COD_USR, 
          t1.PEMLN_COD_ARE, 
          t1.PEMLN_GLS_NOM, 
          t1.PEMLN_GLS_APE_PAT, 
          t1.PEMLN_GLS_APE_MAT, 
          t1.PEMLN_COD_CAU, 
          t1.PEMLN_FCH_ALT, 
          t1.PEMLN_FCH_BAJ, 
          t1.PEMLN_EST_LNE, 
          t1.PEMLN_GLS_OBS, 
          t1.PEMLN_COD_APP_FIN_ACL, 
          t1.PEMLN_COD_PRO_FIN_ACL, 
          t1.PEMLN_GLS_USR_FIN_ACL, 
          t1.PEMLN_FCH_FIN_ACL, 
          t1.PEMLN_FCH_ING_REG
      FROM FIPERS.fipers_mae_lib_neg t1
	  WHERE t1.PEMLN_EST_LNE = 1;
QUIT;
