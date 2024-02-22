
DATA _null_;
I_Actual  = input(put(intnx('month',today(),0,'begin' ),Date9.  ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
T_Actual = input(put(today()-1,Date9.),$10.);
datex	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*Mes Actual*/
datex1	= input(put(intnx('month',today(),0,'end'	),yymmn6.   ),$10.); /*Mes Actual*/
datey	= input(put(intnx('month',today(),-1,'end'	),yymmn6.   ),$10.); /*cambiar 0 a -1 para ver cierre mes anterior*/
exec	= compress(input(put(today(),yymmdd10.),$10.),"-",c);
exec1	= compress(input(put(intnx('month',today(),0,'begin' ),yymmdd10.  ),$10.),"-",c);
exec2	= compress(input(put(intnx('month',today(),0,'same' ),yymmdd10.  ),$10.),"-",c);

Call symput("inicio",I_Actual);
Call symput("termino",T_Actual);
Call symput("fechax1", datex1);
Call symput("fechax", datex);
Call symput("fechay", datey);
Call symput("fechae",exec);
Call symput("fechae1",exec1);
Call symput("fechae2",exec2);
 
RUN;

%put &inicio; 
%put &termino;
%put &fechax;
%put &fechax1;
%put &fechay; 
%put &fechae;
%put &fechae1;
%put &fechae2;
RUN;


PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_SAV_CAR_201 AS 
   SELECT DISTINCT t1.RUT_REAL, 
          /* MAX_of_DIAS_MORA */
            (MAX(t2.DIAS_MORA)) FORMAT=5. AS MAX_of_DIAS_MORA, 
          /* MAX_of_FEC_EX */
            (MAX(t2.FEC_EX)) AS MAX_of_FEC_EX,
			SALDO_MORA
      FROM JABURTOM.SAV_CAR_&fechax t1
           LEFT JOIN PUBLICIN.MORA_CAR t2 ON (t1.RUT_REAL = t2.RUT)
      WHERE t1.PILOTOS = 'FASTCO_TARGET'
      GROUP BY t1.RUT_REAL;
QUIT;




PROC SQL;
CREATE TABLE result.MORA_CALL AS
SELECT * FROM QUERY_FOR_SAV_CAR_201

;
QUIT;

/**/

proc export data=result.MORA_CALL 
OUTFILE="/sasdata/users94/ougarte/temp/MORA_CALL.CSV"
dbms=dlm replace;
delimiter=';';
PUTNAMES=yes;
RUN;



PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_SAV_CAR_201 AS 
   SELECT DISTINCT t1.RUT_REAL, 
          /* MAX_of_DIAS_MORA */
            (MAX(t2.DIAS_MORA)) FORMAT=5. AS MAX_of_DIAS_MORA, 
          /* MAX_of_FEC_EX */
            (MAX(t2.FEC_EX)) AS MAX_of_FEC_EX,
			SALDO_MORA
      FROM JABURTOM.SAV_CAR_&fechax t1
           LEFT JOIN PUBLICIN.MORA_CAR t2 ON (t1.RUT_REAL = t2.RUT)
      WHERE t1.PILOTOS = 'FASTCO_TARGET'
      GROUP BY t1.RUT_REAL;
QUIT;
