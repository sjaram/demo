LIBNAME BOTGEN ORACLE  READBUFF=1000  INSERTBUFF=1000  PATH="REPORITF.WORLD"  SCHEMA=BOTGEN_ADM  USER='SAS_USR_BI' PASSWORD='SAS_23072020';
/*LIBNAME BOTGEN ORACLE PATH='REPORITF.WORLD' SCHEMA='BOTGEN_ADM' USER='XXXXXX' PASSWORD='XXXXX';*/

/* 2022-06-15 -- V02-- Ale M.-- se actualizo zonas con el area de planificacion comercial ya que estaban muy desactualizadas*/

proc sql;
create table RESULT.MAESTRA_SUCURSALES as
SELECT
		tgmsu_cod_suc_k AS cod_suc,
		tgmsu_nom_suc AS nombre_tienda,
	case 
	when tgmsu_cod_suc_k in (10,23,32,45,46,76,79,88,97,99,542) then 'Centro'
	when tgmsu_cod_suc_k in ( 3,21,25,26,37,41,49,51,69,84,85,510,558,559,584) then 'NORTE'
	when tgmsu_cod_suc_k in (2,4,9,11,14,22,28,47,68,72,74,78,96,98,512,530) then 'SUR'
	when tgmsu_cod_suc_k in (0,7,12,16,18,19,29,34,48,57,71,557) then 'Santiago'
	else '' end as zona_retail,

	case 
	when tgmsu_cod_suc_k in (0,7,12,16,18,19,29,34,45,46,48,57,71,88,97,99,502,517,536,557) then 'Centro'
	when tgmsu_cod_suc_k in ( 3,10,21,25,26,37,41,49,51,69,79,84,85,510,558,559,584) then 'NORTE'
	when tgmsu_cod_suc_k in (2,4,9,11,14,22,23,28,32,47,68,72,74,76,78,96,98,512,529,530,542,543) then 'SUR'
	else '' end as zona,

	case 
	when tgmsu_cod_suc_k=0 then 'Santiago'
	when tgmsu_cod_suc_k=2 then 'Concepcion'
	when tgmsu_cod_suc_k=3 then 'Vi�a del Mar'
	when tgmsu_cod_suc_k=4 then 'Temuco'
	when tgmsu_cod_suc_k=7 then 'Las Condes'
	when tgmsu_cod_suc_k=9 then 'Concepcion'
	when tgmsu_cod_suc_k=10 then 'Los Andes'
	when tgmsu_cod_suc_k=11 then 'Concepcion'
	when tgmsu_cod_suc_k=12 then 'Las Condes'
	when tgmsu_cod_suc_k=14 then 'Puerto Montt'
	when tgmsu_cod_suc_k=16 then 'La Florida'
	when tgmsu_cod_suc_k=18 then 'Santiago'
	when tgmsu_cod_suc_k=19 then 'Santiago'
	when tgmsu_cod_suc_k=21 then 'Arica'
	when tgmsu_cod_suc_k=22 then 'Chillan'
	when tgmsu_cod_suc_k=23 then 'San Fernando'
	when tgmsu_cod_suc_k=25 then 'Valparaiso'
	when tgmsu_cod_suc_k=26 then 'Antofagasta'
	when tgmsu_cod_suc_k=28 then 'Talcahuano'
	when tgmsu_cod_suc_k=29 then 'Las Condes'
	when tgmsu_cod_suc_k=32 then 'Rancagua'
	when tgmsu_cod_suc_k=34 then 'Providencia'
	when tgmsu_cod_suc_k=37 then 'Vi�a del Mar'
	when tgmsu_cod_suc_k=41 then 'La Serena'
	when tgmsu_cod_suc_k=45 then 'Cerrillos'
	when tgmsu_cod_suc_k=46 then 'Puente Alto'
	when tgmsu_cod_suc_k=47 then 'Punta Arenas'
	when tgmsu_cod_suc_k=48 then 'Huechuraba'
	when tgmsu_cod_suc_k=49 then 'Iquique'
	when tgmsu_cod_suc_k=51 then 'Calama'
	when tgmsu_cod_suc_k=57 then 'La Florida'
	when tgmsu_cod_suc_k=68 then 'Temuco'
	when tgmsu_cod_suc_k=69 then 'Coquimbo'
	when tgmsu_cod_suc_k=71 then 'Las Reina'
	when tgmsu_cod_suc_k=72 then 'Los Angeles'
	when tgmsu_cod_suc_k=74 then 'Talca'
	when tgmsu_cod_suc_k=76 then 'Curico'
	when tgmsu_cod_suc_k=78 then 'Puerto Montt'
	when tgmsu_cod_suc_k=79 then 'La Calera'
	when tgmsu_cod_suc_k=84 then 'Copiapo'
	when tgmsu_cod_suc_k=85 then 'Quilpue'
	when tgmsu_cod_suc_k=88 then 'Maip�'
	when tgmsu_cod_suc_k=96 then 'Punta Arenas'
	when tgmsu_cod_suc_k=97 then 'Estacion Central'
	when tgmsu_cod_suc_k=98 then 'Valdivia'
	when tgmsu_cod_suc_k=99 then 'San Bernardo'
	when tgmsu_cod_suc_k=502 then 'Santiago'
	when tgmsu_cod_suc_k=510 then 'Iquique'
	when tgmsu_cod_suc_k=512 then 'Temuco'
	when tgmsu_cod_suc_k=517 then 'Las Condes'
	when tgmsu_cod_suc_k=529 then 'Talca'
	when tgmsu_cod_suc_k=530 then 'Valdivia'
	when tgmsu_cod_suc_k=536 then 'Santiago'
	when tgmsu_cod_suc_k=542 then 'Curico'
	when tgmsu_cod_suc_k=543 then 'Osorno'
	when tgmsu_cod_suc_k=557 then 'Las Condes'
	when tgmsu_cod_suc_k=558 then 'Coquimbo'
	when tgmsu_cod_suc_k=559 then 'Arica'
	when tgmsu_cod_suc_k=584 then 'Copiapo'
	else '' end as Comuna,

	case 
	when tgmsu_cod_suc_k=0 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=2 then 'REGION DEL BIO BIO'
	when tgmsu_cod_suc_k=3 then 'REGION DE VALPARAISO'
	when tgmsu_cod_suc_k=4 then 'REGION DE LA ARAUCANIA'
	when tgmsu_cod_suc_k=7 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=9 then 'REGION DEL BIO BIO'
	when tgmsu_cod_suc_k=10 then 'REGION DE VALPARAISO'
	when tgmsu_cod_suc_k=11 then 'REGION DEL BIO BIO'
	when tgmsu_cod_suc_k=12 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=14 then 'REGION DE LOS LAGOS'
	when tgmsu_cod_suc_k=16 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=18 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=19 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=21 then 'REGION DE ARICA Y PARINACOTA'
	when tgmsu_cod_suc_k=22 then 'REGION DE �UBLE'
	when tgmsu_cod_suc_k=23 then 'REGION DE O�HIGGINS'
	when tgmsu_cod_suc_k=25 then 'REGION DE VALPARAISO'
	when tgmsu_cod_suc_k=26 then 'REGION DE ANTOFAGASTA'
	when tgmsu_cod_suc_k=28 then 'REGION DEL BIO BIO'
	when tgmsu_cod_suc_k=29 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=32 then 'REGION DE O�HIGGINS'
	when tgmsu_cod_suc_k=34 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=37 then 'REGION DE VALPARAISO'
	when tgmsu_cod_suc_k=41 then 'REGION DE COQUIMBO'
	when tgmsu_cod_suc_k=45 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=46 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=47 then 'REGION DE MAGALLANES'
	when tgmsu_cod_suc_k=48 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=49 then 'REGION DE TARAPACA'
	when tgmsu_cod_suc_k=51 then 'REGION DE ANTOFAGASTA'
	when tgmsu_cod_suc_k=57 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=68 then 'REGION DE LA ARAUCANIA'
	when tgmsu_cod_suc_k=69 then 'REGION DE COQUIMBO'
	when tgmsu_cod_suc_k=71 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=72 then 'REGION DEL BIO BIO'
	when tgmsu_cod_suc_k=74 then 'REGION DEL MAULE'
	when tgmsu_cod_suc_k=76 then 'REGION DEL MAULE'
	when tgmsu_cod_suc_k=78 then 'REGION DE LOS LAGOS'
	when tgmsu_cod_suc_k=79 then 'REGION DE VALPARAISO'
	when tgmsu_cod_suc_k=84 then 'REGION DE ATACAMA'
	when tgmsu_cod_suc_k=85 then 'REGION DE VALPARAISO'
	when tgmsu_cod_suc_k=88 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=96 then 'REGION DE MAGALLANES'
	when tgmsu_cod_suc_k=97 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=98 then 'REGION DE LOS RIOS'
	when tgmsu_cod_suc_k=99 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=502 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=510 then 'REGION DE TARAPACA'
	when tgmsu_cod_suc_k=512 then 'REGION DE LA ARAUCANIA'
	when tgmsu_cod_suc_k=517 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=529 then 'REGION DEL MAULE'
	when tgmsu_cod_suc_k=530 then 'REGION DE LOS RIOS'
	when tgmsu_cod_suc_k=536 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=542 then 'REGION DEL MAULE'
	when tgmsu_cod_suc_k=543 then 'REGION DE LOS LAGOS'
	when tgmsu_cod_suc_k=557 then 'REGION METROPOLITANA'
	when tgmsu_cod_suc_k=558 then 'REGION DE COQUIMBO'
	when tgmsu_cod_suc_k=559 then 'REGION DE ARICA Y PARINACOTA'
	when tgmsu_cod_suc_k=584 then 'REGION DE ATACAMA'
	else '' end as region_suc

FROM BOTGEN.botgen_mae_suc
order by tgmsu_cod_suc_k asc
;

