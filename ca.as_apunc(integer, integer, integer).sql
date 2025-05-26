CREATE OR REPLACE FUNCTION ca.as_apunc(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a contribuciones  seguridad social 
* PRE: el asiento debe estar creado
 Apunc	select ca.as_conceptoasiento(#,&,203,1144) as mon...
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
 
     SELECT INTO valor SUM(  as_conceptoasiento(elmes,elanio,203)  
				+ as_conceptoasiento(elmes,elanio,1144) );	

      
     return valor;



END;
$function$
