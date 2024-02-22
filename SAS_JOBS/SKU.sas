proc sql ;
connect to SQLSVR as mydb
      (datasrc="SQL_Datawarehouse" user="user_sas" password="{sas002}AC224E474B8742BD13124A965275013020A60F8D15DCC25A52A5D43F49A76B4D");

create table work.SKU as
select  distinct *
from connection to mydb ( 
SELECT  
PRD_PRODUCTO,
PRV_PRODUCTOVTA,
DEP_COC_DVS,
DEP_DES_DVS,
PRD_DEPTO,
DEP_DESCRIPCION,
PRD_LINEA,
LIN_DESCRIPCION,

PRD_SUBLINEA,
SLI_DESCRIPCION,
/*MARCA*/
MAR_CODMARCA,
MAR_DESCRIPCION,
/**/
PRD_CODESTACION,
MOD_DESCRIPCION

from db2.GST_VMPRODUCTO_03 as t1
) as conexion 
;quit;

PROC SQL ;
CREATE TABLE result.SKU AS 
SELECT 
PRD_PRODUCTO,
input(PRD_PRODUCTO,best32.) format=20. as SKU_corto,
t1.PRV_PRODUCTOVTA,
input(PRV_PRODUCTOVTA,best32.) format=20. as SKU,
/*Division*/
DEP_COC_DVS,
DEP_DES_DVS,
/*Departamento*/ 
COALESCE(PRD_DEPTO,'SIN INF') AS PRD_DEPTO, 
COALESCE(DEP_DESCRIPCION,'SIN INF') AS DEP_DESCRIPCION, 
/*LINEA*/
COALESCE(PRD_LINEA,'SIN INF') AS PRD_LINEA, 
COALESCE(LIN_DESCRIPCION,'SIN INF') AS LIN_DESCRIPCION,
/*SUBLINEA*/
COALESCE(PRD_SUBLINEA,'SIN INF') AS PRD_SUBLINEA,
COALESCE(SLI_DESCRIPCION,'SIN INF') AS SLI_DESCRIPCION,
/*MARCA*/
COALESCE(MAR_CODMARCA,'SIN INF') AS MAR_CODMARCA,
COALESCE(MAR_DESCRIPCION,'SIN INF') AS MAR_DESCRIPCION,
/**/
COALESCE(PRD_CODESTACION,'SIN INF') AS PRD_CODESTACION,
MOD_DESCRIPCION

FROM SKU t1
where PRV_PRODUCTOVTA IS NOT MISSING
;QUIT;




