DATA _null_;
datePeriodoActual = input(put(intnx('month',today(),0,'end' ),yymmn6. ),$10.);
Call symput("VdateHOY", datePeriodoActual);
RUN;
%put &VdateHOY;

%let libreria=RESULT;

proc sql;
	create table &libreria..GCO_CAMP_DVN_PUSH_&VdateHOY (
	NOMBRE_ARCHIVO CHAR(50), 
	CANTIDAD char(50)
	)
;quit;
