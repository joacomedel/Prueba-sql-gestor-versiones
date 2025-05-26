CREATE OR REPLACE FUNCTION ca.as_retenciones4cat(integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/*
* Inicializa el asiento correspondiente a inpaco
* PRE: el asiento debe estar creado

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

    SELECT INTO respuesta	case when nullvalue(sum(ceporcentaje* cemonto)) then 0 else sum(ceporcentaje* cemonto) end as calculo
    FROM  ca.conceptoempleado
	NATURAL JOIN ca.liquidacion
	WHERE (idconcepto=989 or idconcepto=1129 or idconcepto=1130 ) and limes =elmes and lianio =elanio;

return respuesta.calculo;

END;
$function$
