CREATE OR REPLACE FUNCTION ca.cantempleadososu(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
      centrocosto integer;
      valor  double precision ;
      elmes integer;
      elanio integer;    
      cantemp double precision;
      
     
BEGIN
 SET search_path = ca, pg_catalog;
     elmes = $1;
     elanio=$2;
     centrocosto=$3;
     cantemp=0;
     valor=0;
 
 

SELECT  into   valor  sum(ca.cantempleados(elmes,elanio,idcentrocosto)) as cant
 FROM  public.centrocosto
where ccactivo and idcentrocosto<>2;

cantemp=valor;

  RAISE NOTICE 'cantidad empleados OSU  (%)',valor;
  
RETURN cantemp;
END;
$function$
