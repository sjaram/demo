%macro CAMPAIGN(tbl1,tabla,bucket,dataset,i);
	DATA _null_;
		per = put(intnx('month',today(),&i.,'same'),yymmddn8. );
		Call symput("per", per);
	RUN;

	proc format;
		picture cust_dt other = '%0H%0M%0S' (datatype=datetime);
	RUN;

	data test;
		dt = datetime();
		call symputx("hhmmss",strip(put(dt,cust_dt.)));
	RUN;

	%put &hhmmss;

	data _null_;
		guid = uuidgen();
		Call symput("guid", guid)
		;
	run;

	%put &guid;
	filename output "/sasdata/users94/user_bi/EXP_AWS/&tbl1.&hhmmss..csv" encoding="utf-8";

	proc export data=&tabla.
		outfile=output
		dbms=dlm
		replace;
		delimiter=","
		;
	quit;

	%let cuenta=/br-dm-prod-us-east-1-837538682169;

	data _null_;
		VAR1=
			"&cuenta-&bucket./bigdata/&dataset./&tbl1./&tbl1._&per.";
		call symput("salida",VAR1)
		;
	run;

	%put &salida;

	data _null_;
		VAR2= COMPRESS("&salida."||"&hhmmss."||"_0-"||"&guid."||".csv"," ",);
		call symput("salidaFinal",VAR2)
		;
	run;

	PROC S3 config="/sasdata/users94/user_bi/TRASPASO_DOCS/.tks3.conf";
		PUT "/sasdata/users94/user_bi/EXP_AWS/&tbl1.&hhmmss..csv" 
			"&salidaFinal.";
		LIST "/br-dm-prod-us-east-1-837538682169-&bucket./bigdata/&dataset./&tbl1./"
		;
	run;
%mend CAMPAIGN;

