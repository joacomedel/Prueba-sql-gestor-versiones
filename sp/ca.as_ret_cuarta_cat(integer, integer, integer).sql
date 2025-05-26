CREATE OR REPLACE FUNCTION ca.as_ret_cuarta_cat(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a contribuciones  seguridad social 
* PRE: el asiento debe estar creado
112
	Retenciones Ganancias 4 Categoria	select ca.as_conceptoasiento(#,&,989,1129,1130,1170,1190,1193,1196.
*/
DECLARE
    
      elmes integer;
      elanio integer;
      centrocosto integer;
      valor double precision;
     
BEGIN
   
     SET search_path = ca, pg_catalog;
     elmes = $1;  
     elanio = $2;
     centrocosto=$3;
 
     SELECT INTO valor SUM(  as_conceptoasiento(elmes,elanio,989) 
				+ as_conceptoasiento(elmes,elanio,1129)  
				+ as_conceptoasiento(elmes,elanio,1130)  
				+ as_conceptoasiento(elmes,elanio,1170)  
				+ as_conceptoasiento(elmes,elanio,1190)  
				+ as_conceptoasiento(elmes,elanio,1193)  
				+ as_conceptoasiento(elmes,elanio,1196)  
                             --+ as_conceptoasiento(elmes,elanio,)   
                          );	

      
     return valor;



END;
$function$
