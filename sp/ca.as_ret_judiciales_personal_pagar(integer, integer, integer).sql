CREATE OR REPLACE FUNCTION ca.as_ret_judiciales_personal_pagar(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a contribuciones  seguridad social 
* PRE: el asiento debe estar creado
110
	Retenciones Judiciales al personal a pagar	select ca.as_conceptoasiento(#,&,1094,1213) as mo...
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
 
     SELECT INTO valor SUM(  as_conceptoasiento(elmes,elanio,1094) 
			 
                             + as_conceptoasiento(elmes,elanio,1213)   
                             + as_conceptoasiento(elmes,elanio,1259)  
                          );	

      
     return valor;



END;
$function$
