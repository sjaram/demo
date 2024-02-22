/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================    DIRECCIONES					  	 ===============================*/
/* CONTROL DE VERSIONES
/* 2022-12-16 -- v03 -- David V.	-- Corrección a delete en aws, proceso bulk.
/* 2022-12-07 -- v02 -- David V.	-- Actualización export to aws, apuntando a raw.
/* 2022-11-30 -- v01 -- David V.	-- Actualización export to aws
/* 0000-00-00 -- v00 -- Original	-- 
*/

/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/

GOPTIONS ACCESSIBLE;
/*LIBNAME R_bopers ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='PMANRIQUEZD' PASSWORD='PMAN#_1407'; */

LIBNAME R_bopers ORACLE PATH='REPORITF.WORLD' SCHEMA='BOPERS_ADM' USER='AMARINAOC' PASSWORD='amarinaoc2017';

PROC SQL;
/*CONNECT TO ORACLE as itf(PATH="REPORITF" USER='cnavar' PASSWORD= 'EPIE#_1116');*/
CREATE TABLE BASE_0 AS 
/*select  * from connection to itf(*/
   SELECT A.PEMID_GLS_NRO_DCT_IDE_K, 
          A.PEMID_DVR_NRO_DCT_IDE, 
          B.PEMDM_GLS_CAL_DML, 
          B.PEMDM_NRO_DML, 
          B.PEMDM_COD_UBC_1ER, 
          B.PEMDM_GLS_RST_DML, 
          B.PEMDM_COD_UBC_3ER, 
        B.PEMDM_FCH_ING_REG, 
        B.PEMDM_FCH_FIN_ACL, 
        B.PEMID_NRO_INN_IDE_K,
		B.PEMDM_COD_APP_FIN_ACL,
		case when PEMDM_COD_TIP_DML = 1 then 'part' else 'lab' end as tipo_dire
	
      FROM R_BOPERS.BOPERS_MAE_IDE A
INNER JOIN R_BOPERS.BOPERS_MAE_DML B ON A.PEMID_NRO_INN_IDE = B.PEMID_NRO_INN_IDE_K
WHERE B.PEMDM_COD_DML_PPA = 1
AND  B.PEMDM_COD_NEG_DML = 1 ;

QUIT;


PROC SQL;
   CREATE TABLE BASE_1 AS 
   SELECT PEMID_GLS_NRO_DCT_IDE_K, 
          PEMID_DVR_NRO_DCT_IDE, 
          PEMDM_GLS_CAL_DML, 
          PEMDM_NRO_DML, 
          PEMDM_COD_UBC_1ER, 
          PEMDM_GLS_RST_DML, 
          PEMDM_COD_UBC_3ER, 
          (MAX(PEMDM_FCH_ING_REG)) FORMAT=DATETIME20. AS MAX_of_PEMDM_FCH_ING_REG, 
      
            (MAX(PEMDM_FCH_FIN_ACL)) FORMAT=DATETIME20. AS MAX_of_PEMDM_FCH_FIN_ACL, 
          PEMID_NRO_INN_IDE_K,
		  tipo_dire
      FROM BASE_0        
WHERE PEMDM_COD_APP_FIN_ACL NOT = 70 
      GROUP BY PEMID_GLS_NRO_DCT_IDE_K, PEMID_DVR_NRO_DCT_IDE, PEMDM_GLS_CAL_DML, PEMDM_NRO_DML,
               PEMDM_COD_UBC_1ER, PEMDM_GLS_RST_DML, PEMDM_COD_UBC_3ER, PEMID_NRO_INN_IDE_K;
QUIT;


PROC SQL;
   CREATE TABLE FECHA_MAX AS 
   SELECT /* MAX_of_MAX_OF_PEMDM_FCH_FIN_ACL */
            (MAX(t1.MAX_OF_PEMDM_FCH_FIN_ACL)) FORMAT=DATETIME20. AS MAX_of_MAX_OF_PEMDM_FCH_FIN_ACL, 
          t1.PEMID_GLS_NRO_DCT_IDE_K
      FROM WORK.BASE_1 AS t1
      GROUP BY t1.PEMID_GLS_NRO_DCT_IDE_K;
QUIT;


PROC SQL;
   CREATE TABLE BASE2 AS 
   SELECT t2.PEMID_GLS_NRO_DCT_IDE_K, 
          t2.PEMID_DVR_NRO_DCT_IDE, 
          t2.PEMDM_GLS_CAL_DML, 
          t2.PEMDM_NRO_DML, 
          t2.PEMDM_COD_UBC_1ER, 
          t2.PEMDM_GLS_RST_DML, 
          t2.PEMDM_COD_UBC_3ER, 
          t2.MAX_OF_PEMDM_FCH_ING_REG, 
          t2.MAX_OF_PEMDM_FCH_FIN_ACL, 
          t2.PEMID_NRO_INN_IDE_K,
		   t2.tipo_dire
      FROM WORK.FECHA_MAX AS t1, WORK.BASE_1 AS t2
      WHERE (t1.MAX_of_MAX_OF_PEMDM_FCH_FIN_ACL = t2.MAX_OF_PEMDM_FCH_FIN_ACL
AND t1.PEMID_GLS_NRO_DCT_IDE_K =  t2.PEMID_GLS_NRO_DCT_IDE_K)
;QUIT;


PROC SQL;
   CREATE TABLE BASE3 AS 
   SELECT t1.PEMID_GLS_NRO_DCT_IDE_K, 
          t1.PEMID_DVR_NRO_DCT_IDE, 
          t1.PEMDM_GLS_CAL_DML, 
          t1.PEMDM_NRO_DML, 
          t1.PEMDM_COD_UBC_1ER, 
          t1.PEMDM_GLS_RST_DML, 
          t1.PEMDM_COD_UBC_3ER, 
          t1.MAX_OF_PEMDM_FCH_ING_REG, 
          t1.MAX_OF_PEMDM_FCH_FIN_ACL, 
          t1.PEMID_NRO_INN_IDE_K, 
		  t1.tipo_dire,
          t2.Tgmug_Nom_Ubc_Geo
      FROM WORK.BASE2 AS t1 LEFT JOIN 
RESULT.COMUNAS AS t2 ON (t1.PEMDM_COD_UBC_3ER = t2.Tgmug_Cod_Ubc_Geo_K);
QUIT;


LIBNAME R_botgen ORACLE PATH='REPORITF.WORLD' SCHEMA='BOTGEN_ADM' USER='AMARINAOC' PASSWORD='amarinaoc2017';


PROC SQL;
   CREATE TABLE REGIONES_COMO_DEBE_SER AS 
   SELECT t1.TGMUG_COD_UBC_GEO_K, 
          t1.TGMUG_NOM_UBC_GEO
      FROM R_BOTGEN.BOTGEN_MAE_UBC_GEO t1
      WHERE t1.TGMPA_COD_PAI_K = 152 AND t1.TGMDP_COD_DVS_K = 1;
QUIT;


PROC SQL;
   CREATE TABLE BASE4 AS 
   SELECT t1.PEMID_GLS_NRO_DCT_IDE_K, 
          t1.PEMID_DVR_NRO_DCT_IDE, 
          t1.PEMDM_GLS_CAL_DML, 
          t1.PEMDM_NRO_DML, 
          t1.PEMDM_COD_UBC_1ER, 
          t1.PEMDM_GLS_RST_DML, 
          t1.PEMDM_COD_UBC_3ER, 
          t1.MAX_OF_PEMDM_FCH_ING_REG, 
          t1.MAX_OF_PEMDM_FCH_FIN_ACL, 
          t1.PEMID_NRO_INN_IDE_K,
		  t1.tipo_dire, 
          t1.Tgmug_Nom_Ubc_Geo, 
          t2.TGMUG_NOM_UBC_GEO AS Tgmug_Nom_Ubc_Geo1
      FROM WORK.BASE3 AS t1
LEFT JOIN REGIONES_COMO_DEBE_SER AS t2 ON (t1.PEMDM_COD_UBC_1ER = t2.TGMUG_COD_UBC_GEO_K);
QUIT;


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

proc sql ;
&mz_connect_BANCO;
	create table REGION_FISA as
	SELECT *
	from  connection to BANCO(
	select f.des_codigo codigo,
	       f.des_descripcion region
	  from tgen_zonageo a,
	       tgen_desctabla f
	where a.zon_tabdistrito = f.des_codtab
	   and a.zon_distrito = f.des_codigo
	group by f.des_codigo, f.des_descripcion
	)
;QUIT;


PROC SQL;
   	   CREATE TABLE HOMOLOGACION AS 
	   SELECT t1.CODIGO AS CODIGO_FISA, 
	    CASE WHEN T1.CODIGO=1 THEN 731
		WHEN T1.CODIGO=2 THEN 732
		WHEN T1.CODIGO=3 THEN 733
		WHEN T1.CODIGO=4 THEN 734
		WHEN T1.CODIGO=5 THEN 735
		WHEN T1.CODIGO=6 THEN 736
		WHEN T1.CODIGO=7 THEN 737
		WHEN T1.CODIGO=8 THEN 738
		WHEN T1.CODIGO=9 THEN 739
		WHEN T1.CODIGO=10 THEN 740
		WHEN T1.CODIGO=11 THEN 741
		WHEN T1.CODIGO=12 THEN 742
		WHEN T1.CODIGO=13 THEN 743
		WHEN T1.CODIGO=14 THEN 744
		WHEN T1.CODIGO=15 THEN 745
		WHEN T1.CODIGO=16 THEN 746 END AS CODIGO_HOMOLOGADO
      FROM WORK.REGION_FISA T1 
  ;
QUIT;

PROC SQL;
	   CREATE TABLE HOMOLOGACION_FINAL AS 
	   SELECT t1.CODIGO_FISA, 
	          t1.CODIGO_HOMOLOGADO,
			  CASE WHEN t1.CODIGO_FISA=16 THEN 'REGION ÑUBLE' ELSE T2.TGMUG_NOM_UBC_GEO END AS REGION

	      FROM WORK.HOMOLOGACION t1 LEFT JOIN REGIONES_COMO_DEBE_SER t2 
	                                 ON (T1.CODIGO_HOMOLOGADO=T2.TGMUG_COD_UBC_GEO_K);
QUIT;

PROC SQL;
	   CREATE TABLE BASE5 AS 
	   SELECT t1.PEMID_GLS_NRO_DCT_IDE_K, 
	          t1.PEMID_DVR_NRO_DCT_IDE, 
	          t1.PEMDM_GLS_CAL_DML, 
	          t1.PEMDM_NRO_DML, 
	          t1.PEMDM_COD_UBC_1ER, 
	          t1.PEMDM_GLS_RST_DML, 
	          t1.PEMDM_COD_UBC_3ER, 
	          t1.MAX_OF_PEMDM_FCH_ING_REG, 
	          t1.MAX_OF_PEMDM_FCH_FIN_ACL, 
	          t1.PEMID_NRO_INN_IDE_K,
	 		  t1.tipo_dire, 
	          t1.Tgmug_Nom_Ubc_Geo, 
	          t1.Tgmug_Nom_Ubc_Geo1, 
	          T2.CODIGO_HOMOLOGADO,
	          t2.Region
	      FROM WORK.BASE4 AS t1 
	LEFT JOIN HOMOLOGACION_FINAL AS t2 ON (t1.PEMDM_COD_UBC_1ER = t2.CODIGO_HOMOLOGADO);
QUIT;

PROC SQL;
   CREATE TABLE DIRECCIONES_ITF AS 
   SELECT input( t1.PEMID_GLS_NRO_DCT_IDE_K, bestx.) LABEL="RUT_CLIENTE" AS RUT_CLIENTE, 
          t1.PEMID_DVR_NRO_DCT_IDE LABEL="DV" AS DV, 
          t1.PEMDM_GLS_CAL_DML LABEL="CALLE" AS CALLE, 
          t1.PEMDM_NRO_DML LABEL="NUMERO" AS NUMERO, 
/*          t1.PEMDM_COD_UBC_1ER LABEL="COD_REGION_ITF" AS COD_REGION_ITF, */

          t1.PEMDM_GLS_RST_DML LABEL="RESTO_DOMICILIO" AS RESTO_DOMICILIO, 
          t1.MAX_OF_PEMDM_FCH_FIN_ACL LABEL="FECHA_ACTUALIZACION" AS FECHA_ACTUALIZACION, 
          t1.PEMDM_COD_UBC_3ER LABEL="COD_COMUNA_ITF" AS COD_COMUNA_ITF, 
          t1.Tgmug_Nom_Ubc_Geo LABEL="COMUNA" AS COMUNA, 
		  T1.CODIGO_HOMOLOGADO,
          t1.REGION
      FROM WORK.BASE5 AS t1
      WHERE t1.PEMDM_GLS_CAL_DML NOT IN ('PRUEBA', 'ALTA EXPRESS','ALTA PLATAFORMA COMERCIAL')
;QUIT;



PROC SQL;
   CREATE TABLE salida AS 
   SELECT /*input(*/Rut_Cliente/*, best.) */AS RUT, 
          Calle AS CALLE, 
          Numero AS NUMERO, /*DEL ACCESS TIENE QUE VERIFIR EN FORMATO TEXTO*/
          Resto_Domicilio AS RESTO, 
          Cod_Comuna_ITF AS COD_COMUNA, 
          Comuna AS COMUNA, 
          CODIGO_HOMOLOGADO AS COD_REGION, 
		  FECHA_ACTUALIZACION as FECHA,
          REGION
      FROM DIRECCIONES_ITF
WHERE (CATS(CALLE,NUMERO)<>CATS('HUERFANOS','1052'))
AND (CATS(CALLE,NUMERO)<>CATS('BANDERA','84'));
QUIT;

PROC SQL;
	CREATE TABLE SALIDA AS 
	SELECT*
	FROM SALIDA
	WHERE CALLE NOT IS MISSING
	and upcase(CALLE) NOT IN ('FDFDFDDF',
	'BN',
	'111111',
	'AAAA',
	'GHF',
	'1111111',
	'CV',
	'HJFHFHJFJKVFN',
	'155454',
	'ASAS',
	'KKKK',
	'JJJ',
	'FFFF',
	'HHGHG',
	'XXXXXXXXXXX',
	'CC',
	'FFF',
	'NNN|',
'Sin direccion',
'XXX',
'SSS',
'XXXX',
'XX',
'AAA',
'222',
'1',
'1111',
'X',
'SSSS',
'XXXXX',
'NNNN',
'NNN',
'CCC',
'111',
'A',
'VVV',
'PJE',
'AAAAA',
'2',
'.',
'DDD',
'N',
'XXXXXXXX',
'XXXXXXXXX',
'VVVV',
'XXXXXXXXXX',
'XXXXXX',
'C',
'XXXXXXX',
'3',
'ABC',
'123',
'B',
'CCCCC',
'11',
'AAAAAA',
'OOO',
'4',
'HHHH',
'AAAAAAA',
'VVVVV',
'FDFDF',
'MM',
'SSSSSSS',
'FFFFF',
'BBBB',
'MMMMM',
'R',
'E',
'00',
'-----------33703',
'Sin direccion',
	'XXX',
	'SSS',
	'XXXX',
	'XX',
	'AAA',
	'222',
	'1',
	'1111',
	'X',
	'SSSS',
	'XXXXX',
	'NNNN',
	'NNN',
	'CCC',
	'111',
	'A',
	'VVV',
'PJE',
'AAAAA',
'2',
'.',
'DDD',
'N',
'XXXXXXXX',
'XXXXXXXXX',
'VVVV',
'XXXXXXXXXX',
'XXXXXX',
'C',
'XXXXXXX',
'3',
'ABC',
'123',
'B',
'CCCCC',
'11',
'AAAAAA',
'OOO',
'4',
'HHHH',
'AAAAAAA',
'VVVVV',
'FDFDF',
'MM',
'SSSSSSS',
'FFFFF',
'BBBB',
'MMMMM',
'R',
'E',
'00',
'LLLLL',
'O',
'CLL',
'LAS',
'MM',
'YYYYY',
'FFFFF',
'MMMMMM',
'NO EXISTE',
'GGGG'
'*',
'*****',
'*******************',
',',
',,,,',
',...',
',KKKK',
',KL',
',KLKLLK',
',KOP,',
'---',
'----',
'-----------------',
'-NNNN',
'.,?{{}{}?{}',
'..',
'...',
'...,0...',
'....',
'.....',
'..... S/N',
'......',
'.......',
'...........',
'....NKHKLKKKL',
'...0...',
'...}',
'..A',
'000',
'0000',
'0000.',
'00000',
'000000',
'0000000',
'00000000',
'000000000',
'0000000000',
'00000000000',
'000000000000',
'0000000000000',
'00000000000000',
'000000000000000',
'0000000000000000',
'00000000000000000000',
'00000000000000000000000000000000000',
'0000000OOOOO',
'00001',
'01',
'0001',
'00011',
'0002',
'11111',
'11111111',
'10',
'22',
'2222',
'5',
'55',
'555',
'7',
'AA',
'ASDGF',
'BBB',
'GGG',
'M',
'MMM',
'NN',
'OOOO',
'OOOOO',
'PE?OL',
'RRRRR',
'SS',
'XZXXX',
'XXXXXXXXXXXX',
'WWWWW',
'AAAAAAAA',
'AAAAAAAAA',
'AAAAAAAAAA',
'AAAAAAAAAAA',
'AAAAAAAAAAAA',
'AAAAAV',
'ASSSSSSS',
'ASSS',
'CALLLE',
'CALLLEJON',
'CALLLEJONES',
'CCCC',
'DDDD',
'DDDDD',
'DDDDDDD',
'DFDDD',
'EEE',
'EEEE',
'ELLLOLLI',
'FFFD',
'FFFFFFFF',
'FFFG',
'FGGG',
'FGGGH',
'FVFFF',
'GBBBBB',
'GGG',
'GGGGG',
'GGGGGGG',
'HHH',
'HHHHH',
'HHHHHHH',
'IIIIIII',
'IUUUUUU',
'JJJJ',
'JJJJJ',
'KKK',
'LLLL',
'LLLLKL',
'LLLLLLLLLLLLLLLLLLLL',
'MMM',
'MMMM',
'NNNJN',
'NNNNN',
'M',
'MMM',
'SSSSS',
'SS',
'IIIIIII',
'IJKJHKJKJ',
'FDSGTRYHTRS',
'AAAAAV:',
'XXXXXXXXXXXXXX')
	and rut > 1001
	AND RUT<99999999
	and COMUNA NOT IS MISSING
	;
	QUIT;

	
DATA SALIDA;
	SET  SALIDA;
	IF RUT=LAG(RUT) THEN FILTRO =1; 
	ELSE FILTRO=0; 
RUN;

proc sql;
	delete * from SALIDA
	where FILTRO =1;
quit;


PROC SQL;
   CREATE TABLE DUPLICADOS AS 
   SELECT /* COUNT_of_RUT */
            (COUNT(t1.RUT)) AS COUNT_of_RUT, 
          /* COUNT DISTINCT_of_RUT */
            (COUNT(DISTINCT(t1.RUT))) AS COUNT_DISTINCT_of_RUT
      FROM WORK.SALIDA AS t1;
QUIT;


PROC SQL;
   CREATE TABLE DUPLICADOS_2 AS 
   SELECT RUT,(COUNT(t1.RUT)) AS COUNT_of_RUT
         
      FROM WORK.SALIDA AS t1
      GROUP BY t1.RUT
	HAVING (COUNT(t1.RUT))>1;
QUIT;


PROC SQL;
	CREATE TABLE ELIMINAR_2 AS 
	SELECT DISTINCT RUT
	FROM SALIDA
	GROUP BY RUT
	HAVING (COUNT(RUT)) > 1;
QUIT;

PROC SQL;
	DELETE * FROM SALIDA WHERE RUT IN (SELECT RUT FROM ELIMINAR_2);
QUIT;

	
PROC SQL;
	drop table result.DIRECCIONES ;
QUIT;

                     
PROC SQL;
	CREATE TABLE result.DIRECCIONES AS 
	SELECT*
	FROM salida
	WHERE COMUNA NOT IS MISSING

;
QUIT;

PROC SQL;
CREATE INDEX RUT ON result.DIRECCIONES(RUT);
QUIT;

PROC SQL;
   CREATE TABLE publicin.DIRECCIONES  AS 
   SELECT t1.*
      FROM result.DIRECCIONES t1;
QUIT;


PROC SQL;
	drop table result.DIRECCIONES;
QUIT;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

;*';*";*/;quit;run;
/*ODS _ALL_ CLOSE;*/

/*==================================================================================================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==============================    	EXPORT_TO_AWS - INI			 ===============================*/

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_DELETE_BULK.sas";
%DELETE_BULK(sas_ctbl_direcciones,raw,sasdata,0);

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT.sas";
%EXPORTACION(sas_ctbl_direcciones,publicin.DIRECCIONES,raw,sasdata,0);

/*==============================    	EXPORT_TO_AWS - END			 ===============================*/
/*==============================    EQUIPO ARQ. DATOS Y AUTOMATIZ.   ===============================*/
/*==================================================================================================*/
