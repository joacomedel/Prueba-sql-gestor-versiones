CREATE OR REPLACE FUNCTION ca.as_prestamo_apunc(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a contribuciones  seguridad social 
* PRE: el asiento debe estar creado
135
	Cta. Prestamo Apunc	select ca.as_conceptoasiento(#,&,1187) as monto 
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
 
     SELECT INTO valor SUM(  as_conceptoasiento(elmes,elanio,1187) 
			 
                             --+ as_conceptoasiento(elmes,elanio,)   
                          );	

      
     return valor;



END;
$function$
