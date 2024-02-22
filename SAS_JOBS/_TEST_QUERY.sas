%Let Periodo_Proceso=25; 		/* para correr un nuevo periodo CAMBIAR AQUÍ */

proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202112'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202112'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202112'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202112	/* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);


/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=26; 	
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202111'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202111'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202111'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202111	/* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);

/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=27; 	
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202110'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202110'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202110'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202110	/* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);


/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=28; 	
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202109'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202109'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202109'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202109	/* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);




/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=29; 	
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202108'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202108'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202108'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202108	/* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);


/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=30; 	
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202107'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202107'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202107'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202107	/* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);




/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=31; 	
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202106'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202106'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202106'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202106	/* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);




/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=32; 	
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202105'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202105'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202105'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202105	/* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);




/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=33; 	
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202104'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202104'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202104'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202104	/* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);





/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=34; 	
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202103'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202103'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202103'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202103	/* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);





/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=35; 	
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202102'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202102'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202102'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202102	/* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);




/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=36; 	
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202101'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202101'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202101'		/* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202101	/* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);


/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=37;  
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202012'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202012'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202012'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202012 /* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);


/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=38;  
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202011'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202011'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202011'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202011 /* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);


/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=39;  
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202010'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202010'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202010'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202010 /* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);


/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=40;  
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202009'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202009'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202009'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202009 /* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);


/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=41;  
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202008'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202008'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202008'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202008 /* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);


/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=42;  
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202007'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202007'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202007'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202007 /* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);


/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=43;  
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202006'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202006'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202006'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202006 /* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);


/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=44;  
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202005'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202005'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202005'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202005 /* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);


/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=45;  
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202004'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202004'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202004'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202004 /* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);


/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=46;  
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202003'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202003'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202003'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202003 /* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);


/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=47;  
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202002'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202002'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202002'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202002 /* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);


/* para correr un nuevo periodo CAMBIAR AQUÍ */
%Let Periodo_Proceso=48;  
proc datasets library=WORK kill noprint;
run;
quit;

proc sql noprint;
select sum(filesize)/1024**3 into: tam_tabla_gb
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202001'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &tam_tabla_gb;

proc sql noprint;
select ceil(sum(filesize)/1024**3) into: stop
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202001'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &stop;

proc sql noprint;
select nobs into: REG
from dictionary.tables
where libname='RESULT'
and memname='UNIVERSO_PANES_202001'   /* para correr un nuevo periodo CAMBIAR AQUÍ */
;QUIT;

%put &REG;

%macro cortar(stop,REG,tam_tabla_gb,Periodo_Proceso);

%do i=1 %to &stop.;

proc sql;
create table corte_&i. as 
select *,
0 as codmar, 
0 as indtipt, 
0 as tipo_tarjeta_rsat, 
0 as panant 
from RESULT.UNIVERSO_PANES_202001 /* para correr un nuevo periodo CAMBIAR AQUÍ */
where monotonic() between (&i.-1)*ceil(&reg./&tam_tabla_gb.)+1 and &i.*ceil(&reg./&tam_tabla_gb.)
;QUIT;

%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(ciclos_universo_panes,corte_&i.,pre-raw,sasdata,-&Periodo_Proceso.); /* para correr un nueva tabla CAMBIAR AQUÍ */

proc sql;
drop table corte_&i.
;QUIT;

%end;
%mend cortar;

%cortar(&stop.,&reg.,&tam_tabla_gb.,&Periodo_Proceso.);

