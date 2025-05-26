CREATE OR REPLACE FUNCTION ca.as_conceptoasiento(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a aquellos en los cuales solo se debe sumar lo dscontado en calidad de un concepto en particular
* PRE: el asiento debe estar creado

*/
DECLARE
      laformula varchar;
      laformulaaux varchar;
      elmes integer;
      elanio integer;
      elconcepto integer;
      respuesta record;
      respuestaaux record;
      liqcomple record;
      monto double precision;
BEGIN
   
     SET search_path = ca, pg_catalog;
     elmes = $1;  
     elanio=$2;
     elconcepto=$3;
 /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble

  */


      SELECT INTO monto case when nullvalue(sum(ceporcentaje* cemonto))
      THEN
          0
      ELSE
          sum(ceporcentaje* cemonto) end as monto
      FROM ca.conceptoempleado
	  NATURAL JOIN  ca.liquidacion
      NATURAL JOIN  ca.liquidacioncabecera
	 -- WHERE idconcepto=elconcepto  and limes=elmes and lianio=elanio;
      WHERE idconcepto=elconcepto  and extract (month FROM (lifechapago))=elmes and extract (year FROM (lifechapago))=elanio ;


       IF nullvalue(monto) THEN monto = 0; END IF;

       return monto;


END;
$function$
