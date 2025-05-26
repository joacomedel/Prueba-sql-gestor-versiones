CREATE OR REPLACE FUNCTION ca.as_conceptoasiento(integer, integer, integer, integer, integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/*
* Inicializa el asiento correspondiente a aquellos en los cuales solo se debe sumar lo dscontado en calidad de dos conceptos en particular
* PRE: el asiento debe estar creado

*/
DECLARE
            laformula varchar;
      elmes integer;
      elanio integer;
      elconcepto1 integer;
      elconcepto2 integer;
      elconcepto3 integer;
      elconcepto4 integer;
      elconcepto5 integer;
      elconcepto6 integer;
      respuesta record;
BEGIN
   
     SET search_path = ca, pg_catalog;
     elmes = $1;  
     elanio=$2;
elconcepto1=$3;
elconcepto2=$4;
elconcepto3=$5;
elconcepto4=$6;
elconcepto5=$7;
elconcepto6=$8;
 /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble

  */

    SELECT  INTO respuesta 	case when nullvalue(sum(ceporcentaje* cemonto)) then 0 else  sum(ceporcentaje* cemonto) end as calculo
    FROM  ca.conceptoempleado
	NATURAL JOIN ca.liquidacion
	WHERE (idconcepto=elconcepto1 or idconcepto=elconcepto2 or idconcepto=elconcepto3 or idconcepto=elconcepto4
      or idconcepto=elconcepto5 or idconcepto=elconcepto6) and limes=elmes and lianio=elanio;

return respuesta.calculo;
END;
$function$
