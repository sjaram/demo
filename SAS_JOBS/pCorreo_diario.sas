data _null_; 
 FILENAME OUTBOX EMAIL  
 FROM  = ("ougarted@bancoripley.com")
 TO    = ("epielh@ripley.com", "dvasquez@bancoripley.com", "pmunozc@bancoripley.com")      
 CC    = ("ougarted@bancoripley.com","sjaram@bancoripley.com")   
 

sjaram@bancoripley.com
        
 SUBJECT = ("Info: Ejecución Logueos internet diarios - Simulaciones y Kpi Internet Tableau.");
 FILE OUTBOX;
 PUT ;
 PUT ;
 PUT 'Se Ejecutaron correctamente los Siguientes Procesos';
 PUT ;
 PUT 'Logueos Diarios';
 PUT 'Simulaciones'; 
 PUT 'KPI Internet';
 PUT 'Remarketin';
 PUT ;
 PUT ;
 PUT 'Atte.';
 PUT 'Equipo BI';
 PUT 'Gerencia de Marketing y Productos';
 PUT ;
 PUT ;
 RUN;
