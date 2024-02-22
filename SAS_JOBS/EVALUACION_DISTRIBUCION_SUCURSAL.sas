
%let libreria=result;

%macro DIST_SUC_MOVIL12(n,libreria);
DATA _null_;
periodo_1 = input(put(intnx('month',today(),-&n.,'begin'),yymmn6. ),$10.) ;

Call symput("periodo_1", periodo_1);

RUN;

%put &periodo_1;


/* venta_&periodo_1 */
PROC SQL;
   CREATE TABLE venta AS 
   SELECT t1.Periodo, 
          t1.Nombre_Sucursal,
		  t1.NOMBRE_DIVISION,
          t1.DEPARTAMENTO_FIN,
          /* SUM_of_Mto */
            (SUM(t1.Mto)) AS Mto_TOTAL,
			sum(case when marca_tipo_tr='TR' then mto else 0 end) as mto_tr
      FROM RESULT.USO_TR_MARCA_&periodo_1 t1
      GROUP BY t1.Periodo,
               t1.Nombre_Sucursal,
			   t1.NOMBRE_DIVISION,
			   t1.DEPARTAMENTO_FIN
;QUIT;



%if (%sysfunc(exist(&libreria..DIST_SUC_MOVIL12))) %then %do;
 
%end;
%else %do;
PROC  SQL;
CREATE TABLE &libreria..DIST_SUC_MOVIL12 
(
periodo	 num,
Nombre_Sucursal char(99),
NOMBRE_DIVISION char(99),
DEPARTAMENTO_FIN char(99),
Mto_TOTAL num,
mto_tr_SUCURSAL num
)
;quit;
%end;

proc sql;
delete *
from &libreria..DIST_SUC_MOVIL12 
where periodo=&periodo_1
;QUIT;

proc sql;
insert into &libreria..DIST_SUC_MOVIL12
select *
from venta
;QUIT;


proc sql;
create table &libreria..DIST_SUC_MOVIL12  as 
select 
*
from &libreria..DIST_SUC_MOVIL12 
;QUIT;

%mend DIST_SUC_MOVIL12;

%DIST_SUC_MOVIL12(	0, &Libreria.	);
%DIST_SUC_MOVIL12(	1, &Libreria.	);


PROC SQL noprint;
DROP TABLE venta
;quit;





