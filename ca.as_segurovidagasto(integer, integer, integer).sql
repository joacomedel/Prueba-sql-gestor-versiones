CREATE OR REPLACE FUNCTION ca.as_segurovidagasto(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a segurovidagasto
* PRE: el asiento debe estar creado

*/
DECLARE
	centrocosto integer;
	respuesta record;
	valor double precision;
	elmes integer;
	elanio integer;
	laformula varchar;
       
	
BEGIN
   
	SET search_path = ca, pg_catalog;
	elmes = $1;
	elanio = $2;
	valor = 0;
	centrocosto = $3;
 /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble

  */

	SELECT INTO  respuesta sum(
		                       ceporcentaje
		                       * cemonto 
		                       * CASE WHEN (centrocosto = 0 ) THEN 1      -- se aplica a todos los empleados y no interesa el % de asignacion al centro de costo
		                         ELSE  split_part(idcentrocosto, '|', 2)::double precision END
	                           )  as calculo
	FROM ca.conceptoempleado  
	natural join ca.concepto
	NATURAL JOIN ca.liquidacion
    NATURAL JOIN ca.liquidacioncabecera
	NATURAL JOIN ( 
		   SELECT idpersona, ca.dar_empleadocentrocosto(idpersona,centrocosto,
--concat(lianio,limes,'01')::date) 
to_timestamp(concat(elanio,'-',elmes,'-01') ,'YYYY-MM-DD')::date)
as idcentrocosto
		   FROM ca.liquidacioncabecera
		   NATURAL JOIN ca.liquidacion 
		   WHERE limes = elmes and lianio = elanio
and(idliquidaciontipo=1 or idliquidaciontipo=2)
	)as t
	WHERE  (idconcepto = 993 or idconcepto = 987 or idconcepto = 1189 or idconcepto = 1188)  
          -- and limes = elmes and lianio = elanio;
           and extract (month FROM (lifechapago))=elmes and extract (year FROM (lifechapago))=elanio ; 
	     --   and split_part(idcentrocosto, '|', 1) =  centrocosto
	
 


return 	respuesta.calculo;

END;
$function$
