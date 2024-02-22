/*Prueba para mover archivos a S3*/

/*Hacer un put en una ruta especifica con conexión mediante archivo de configuración*/
PROC S3 config="/sasdata/users94/user_bi/TRASPASO_DOCS/.tks3.conf"; /*Ruta donde está el archivo de config.*/
/*	PUT "/sasdata/users_BI/PUBLICA_IN/EDP_CATASTRO_TABLAS.sas7bdat"  "s3://br-dm-prod-us-east-1-837538682169-sas-backup/bigdata/sas/EDP_CATASTRO_TABLAS.sas7bdat"; /*Mover el archivo desde una ruta sas hacia un bucket s3*/
LIST "s3://br-dm-prod-us-east-1-837538682169-sas-backup/bigdata/sas/"; /*Listar la ruta para que te muestre que contiene*/
run;
