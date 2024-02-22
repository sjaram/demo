DATA _null_;
datex = input(put(intnx('month',today(),-1,'end'),yymmn6.),$10.);    
datex12 = input(put(intnx('month',today(),-13,'end'),yymmn6.),$10.);    

Call symput("datex", datex);
Call symput("datex12", datex12);
RUN;

%put &datex;
%put &datex12;


/*INSTANCIA MAESTRA_CAR */
proc sql;
   connect to ODBC as MISGTN (DATASRC="BR-MISGTN" user="nlagosg" password="{SAS002}7183730115E4691046F2820058130A68");
create table clientes_con_saldo as 
SELECT * FROM connection to MISGTN(
   SELECT COUNT(DISTINCT RUT) AS CANTIDAD_RUT, &datex as periodo 
FROM [MIS\PRODRIGUEZV].GTN_&datex)
UNION ALL
SELECT * FROM connection to MISGTN(
   SELECT COUNT(DISTINCT RUT) AS CANTIDAD_RUT,  &datex12 as periodo
FROM [MIS\PRODRIGUEZV].GTN_&datex12)
;
quit;


/* PERIODOS */
PROC SQL;
DELETE FROM RESULT.clientes_con_saldo WHERE PERIODO IN (&datex,&datex12);
QUIT;

proc sql;

INSERT INTO RESULT.clientes_con_saldo  
select * from clientes_con_saldo;
quit;




