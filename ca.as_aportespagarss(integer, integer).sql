CREATE OR REPLACE FUNCTION ca.as_aportespagarss(integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a aportes a pagar seguridad social 
* PRE: el asiento debe estar creado

*/
DECLARE


      laformula1 varchar;
      laformula2 varchar;
      elmes integer;
	  elanio integer;
	  respuesta1 record;
	  respuesta2 record;
      respuesta1aux record;
	  respuesta2aux record;
      liqcomple record;
      condiciontope varchar;
      valorextraordinario1 double precision;
      valorextraordinario2 double precision;
	
BEGIN
   
     SET search_path = ca, pg_catalog;
      elmes = $1;  
     elanio = $2;
     valorextraordinario1 = 0;
     valorextraordinario2 = 0;

 /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble

  */

      SELECT  INTO respuesta1  sum(ceporcentaje* cemonto)  as calculo1
      FROM  ca.conceptoempleado
      NATURAL JOIN ca.concepto
      NATURAL JOIN ca.liquidacion
      NATURAL JOIN ca.liquidacioncabecera
      WHERE ( idconcepto=200 or idconcepto=201 or idconcepto=1147 or idconcepto=1148  or idconcepto=1246)
            -- and limes= elmes  and lianio=elanio ;
      and  extract (month FROM (lifechapago))=elmes and extract (year FROM (lifechapago))=elanio ; 
	

      SELECT  INTO  respuesta2  0.15*sum(ceporcentaje* cemonto) as calculo2
      FROM ca.conceptoempleado
      NATURAL JOIN ca.concepto
      NATURAL JOIN ca.liquidacion
      NATURAL JOIN ca.liquidacioncabecera
      WHERE ( idconcepto=1060 or idconcepto=35)
      --and limes=elmes  and lianio=elanio;
      and  extract (month FROM (lifechapago))=elmes and extract (year FROM (lifechapago))=elanio ; 
	


      return 	respuesta1.calculo1
                + respuesta2.calculo2;

END;
$function$
