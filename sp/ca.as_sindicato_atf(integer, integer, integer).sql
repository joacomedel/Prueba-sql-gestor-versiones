CREATE OR REPLACE FUNCTION ca.as_sindicato_atf(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a contribuciones  seguridad social 
* PRE: el asiento debe estar creado
Sindicato ATF	select ca.as_conceptoasiento(#,&,34,1110,1164,1138,1163
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
 
     SELECT INTO valor SUM(  as_conceptoasiento(elmes,elanio,34)  
				+  as_conceptoasiento(elmes,elanio,1110)
				+  as_conceptoasiento(elmes,elanio,1164)
				+  as_conceptoasiento(elmes,elanio,1138)
				+  as_conceptoasiento(elmes,elanio,1163));	

      
     return valor;



END;
$function$
