CREATE OR REPLACE FUNCTION ca.as_sosunc(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a contribuciones  seguridad social 
* PRE: el asiento debe estar creado
 Sosunc	select ca.as_conceptoasiento(#,&,202,1248,1249,1250
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
 
     SELECT INTO valor SUM(  as_conceptoasiento(elmes,elanio,202)  
				+ as_conceptoasiento(elmes,elanio,1248) 
				+ as_conceptoasiento(elmes,elanio,1249) 
				+ as_conceptoasiento(elmes,elanio,1250)
                                + as_conceptoasiento(elmes,elanio,1269) 
--Dani por pedido de JE 2025-05-05 no debe tener en cuenta el concepto 1119
                       --         + as_conceptoasiento(elmes,elanio,1119) 
                                + as_conceptoasiento(elmes,elanio,1270));	

      
     return valor;



END;
$function$
