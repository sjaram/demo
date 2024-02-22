data _null_; 
 FILENAME OUTBOX EMAIL  
 FROM  = ("ougarted@bancoripley.com")
 TO    = ("epielh@ripley.com", "dvasquez@bancoripley.com", "pmunozc@bancoripley.com")      
 CC    = ("ougarted@bancoripley.com","sjaram@bancoripley.com")   
      
 SUBJECT = ("Info: Proceso de Cierre - Logueos y Simulaciones");
 FILE OUTBOX;
 PUT ;
 PUT 'Ejecución correctamente los Procesos de Cierre:';
 PUT 'Logueos Diarios';
 PUT 'Simulaciones'; 
 PUT ;
 PUT ;
 PUT ;
 PUT ;
 PUT 'Atte.';
 PUT 'Equipo BI';
 PUT 'Gerencia de Marketing y Productos';
 PUT ;

 RUN;
