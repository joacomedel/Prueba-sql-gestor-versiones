CREATE OR REPLACE FUNCTION ca.as_uniformeinstitucional(integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/*
* Inicializa el asiento correspondiente a uniforme institucional 
* PRE: el asiento debe estar creado
*
*/
DECLARE
elmes integer;
	elanio integer;
      laformula varchar;
   
      respuesta record;

BEGIN
   
     SET search_path = ca, pg_catalog;
     elmes = $1;
     elanio=$2;
   

 /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble

  */


  SELECT INTO respuesta sum(ceporcentaje*cemonto) as calculo
  from ca.conceptoempleado
  NATURAL JOIN ca.liquidacion
  where idconcepto=1081 and limes =elmes and lianio =elanio;

return respuesta.calculo;

END;
$function$
