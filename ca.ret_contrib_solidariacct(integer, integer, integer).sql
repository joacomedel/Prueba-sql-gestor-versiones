CREATE OR REPLACE FUNCTION ca.ret_contrib_solidariacct(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a contribuciones  seguridad social 
* PRE: el asiento debe estar creado
 Ajuste Ret.Contrib.Solidaria CCT	select ca.as_conceptoasiento(#,&,1163) as monto 
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
     

     SELECT INTO valor SUM(  as_conceptoasiento(elmes,elanio,1163)  );	

      
     return valor;



END;
$function$
