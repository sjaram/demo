PROC EXPORT DATA=RESULT.CTAVTA1_STOCK
   OUTFILE='./output/CTAVTA1_STOCK.csv'
   DBMS=dlm REPLACE;
   delimiter=';';
   PUTNAMES=YES;
RUN;

PROC EXPORT DATA=PUBLICIN.LNEGRO_CAR
   OUTFILE='./output/LNEGRO_CAR.csv'
   DBMS=dlm REPLACE;
   delimiter=';';
   PUTNAMES=YES;
RUN;

PROC EXPORT DATA=RESULT.STOCK_CC
   OUTFILE='./output/STOCK_CC.csv'
   DBMS=dlm REPLACE;
   delimiter=';';
   PUTNAMES=YES;
RUN;

proc print data=RESULT.CTAVTA1_STOCK noobs;
run;
proc print data=PUBLICIN.LNEGRO_CAR noobs;
run;
proc print data=RESULT.STOCK_CC noobs;
run;
