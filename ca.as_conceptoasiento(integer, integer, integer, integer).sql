CREATE OR REPLACE FUNCTION ca.as_conceptoasiento(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a aquellos en los cuales solo se debe sumar lo dscontado en calidad de dos conceptos en particular
* PRE: el asiento debe estar creado

*/
DECLARE
            laformula varchar;
      elmes integer;
      elanio integer;
      elconcepto1 integer;
       elconcepto2 integer;
      respuesta record;
      liqcomple record;
      respuestaaux record;
      calculoaux double precision;
BEGIN
   
     SET search_path = ca, pg_catalog;
     elmes = $1;  
     elanio=$2;
elconcepto1=$3;
elconcepto2=$4;
 /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble

  */

 SELECT  INTO calculoaux	case when nullvalue(sum(ceporcentaje* cemonto)) then 0 else
     sum(ceporcentaje* cemonto) end as calculoaux
     FROM  ca.conceptoempleado
     NATURAL JOIN  ca.liquidacion
     NATURAL JOIN  ca.liquidacioncabecera
     WHERE (idconcepto=elconcepto1 or idconcepto=elconcepto2 ) 
   --and limes= elmes and lianio =  elanio;
    and extract (month FROM (lifechapago))=elmes and extract (year FROM (lifechapago))=elanio;



return calculoaux;

END;
$function$
