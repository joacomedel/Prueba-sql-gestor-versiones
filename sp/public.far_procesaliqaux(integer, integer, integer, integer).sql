CREATE OR REPLACE FUNCTION public.far_procesaliqaux(integer, integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
--record
	 cursorpendientes refcursor;
     unpendiente record;
    
--VARIABLES
    
    
BEGIN

/*select * from far_procesaliqaux(167200,2020,2814,99)*/


/*genera los pendientes*/
     perform far_generapendienteliquidacionauditoria($1,$2);   
   /*busca  cada pendiente ...*/
   
    OPEN cursorpendientes FOR  SELECT * FROM far_ordenventaliquidacionauditada 
          WHERE    nroregistro = $1 AND  anio = $2 
		  AND idliquidacion = $3 AND  idcentroliquidacion = $4 
           AND not ovlaprocesado  
	  ORDER BY idordenventaliquidacionauditada; 
		  
        
     FETCH cursorpendientes into unpendiente;
     WHILE  found LOOP 
     /*procesa cada pendiente*/
     
     perform far_procesar_pendienteliquidacionauditoria(unpendiente.idordenventaliquidacionauditada); 
         
      FETCH cursorpendientes into unpendiente;
     end loop;
     close cursorpendientes;
        
              
     /*al final procesar las de reci*/
     perform far_procesaliquidacionordenreci($1,$2);
     
    
              
return 	true;
END;
$function$
