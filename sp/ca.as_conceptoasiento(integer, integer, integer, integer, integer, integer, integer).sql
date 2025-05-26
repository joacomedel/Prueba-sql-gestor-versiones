CREATE OR REPLACE FUNCTION ca.as_conceptoasiento(integer, integer, integer, integer, integer, integer, integer)
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
 /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble

  */

   laformula=concat(' select
	case when nullvalue(sum(ceporcentaje* cemonto)) then 0 else
 sum(ceporcentaje* cemonto) end as calculo
from ca.conceptoempleado 
	natural join ca.liquidacion
		where 
		
		(idconcepto=',elconcepto1,'or idconcepto=',elconcepto2, ' or idconcepto=',elconcepto3,' or idconcepto=',elconcepto4,' or idconcepto=',elconcepto5,') and limes=',elmes,' and lianio=',elanio);




EXECUTE laformula INTO respuesta;

return respuesta.calculo;
END;
$function$
