%macro ciclos;
%do i=10 %to 19; /*16*/
DATA _null_;
periodo = input(put(intnx('month',today(),-&i.,'same'),yymmn6. ),$10.);
Call symput("periodo", periodo);
RUN;
%put &periodo;
/*Exportación a AWS*/
%INCLUDE"/sasdata/users_BI/RESULTADOS/oradiag_user_bi/AWS/AWS_EXPORT_INCREM_PER_DIARIO.sas";
%INCREM_PER_DIARIO(sas_ppff_score_ref_tablon,result.score_ref_tablon_&periodo.,pre-raw,sasdata,-&i.);
%end;
%mend ciclos;
%ciclos;
