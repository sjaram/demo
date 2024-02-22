PROC EXPORT DATA=RESULT.CTAVTA1_STOCK
   OUTFILE='/sasdata/users94/user_bi/TRASPASO_DOCS/CTRL_COMERCIAL/CTAVTA1_STOCK.csv'
   DBMS=dlm REPLACE;
   delimiter=';';
   PUTNAMES=YES;
RUN;

PROC EXPORT DATA=PUBLICIN.LNEGRO_CAR
   OUTFILE='/sasdata/users94/user_bi/TRASPASO_DOCS/CTRL_COMERCIAL/LNEGRO_CAR.csv'
   DBMS=dlm REPLACE;
   delimiter=';';
   PUTNAMES=YES;
RUN;

PROC EXPORT DATA=RESULT.STOCK_CC
   OUTFILE='/sasdata/users94/user_bi/TRASPASO_DOCS/CTRL_COMERCIAL/STOCK_CC.csv'
   DBMS=dlm REPLACE;
   delimiter=';';
   PUTNAMES=YES;
RUN;


       filename server ftp 'CTAVTA1_STOCK.csv' CD='/' 
       HOST='192.168.82.171' user='17457765K' pass='17457765K' PORT=21;

data _null_;
       infile '/sasdata/users94/user_bi/TRASPASO_DOCS/CTRL_COMERCIAL/CTAVTA1_STOCK.csv' ;
       file server;
       input;
       put _infile_;
run;

       filename server ftp 'LNEGRO_CAR.csv' CD='/' 
       HOST='192.168.82.171' user='17457765K' pass='17457765K' PORT=21;

data _null_;
       infile '/sasdata/users94/user_bi/TRASPASO_DOCS/CTRL_COMERCIAL/LNEGRO_CAR.csv' ;
       file server;
       input;
       put _infile_;
run;

       filename server ftp 'STOCK_CC.csv' CD='/' 
       HOST='192.168.82.171' user='17457765K' pass='17457765K' PORT=21;

data _null_;
       infile '/sasdata/users94/user_bi/TRASPASO_DOCS/CTRL_COMERCIAL/STOCK_CC.csv' ;
       file server;
       input;
       put _infile_;
run;

