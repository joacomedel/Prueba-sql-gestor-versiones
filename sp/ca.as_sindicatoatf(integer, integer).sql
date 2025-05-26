CREATE OR REPLACE FUNCTION ca.as_sindicatoatf(integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/*
* Inicializa el asiento correspondiente a sindicato ATF
* PRE: el asiento debe estar creado

*/
DECLARE
      
     
      respuesta record;
    
     elmes integer;
	elanio integer;
      laformula varchar;
	
BEGIN
   
     SET search_path = ca, pg_catalog;
     elmes=$1;
elanio=$2;
   

 /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble

  */

    select into respuesta 	case when nullvalue(sum(ceporcentaje* cemonto)) then 0 else sum(ceporcentaje* cemonto) end as calculo
    from ca.conceptoempleado
	natural join ca.liquidacion
	where
		(idconcepto=34 or idconcepto=1130)  and limes=elmes  and lianio=elanio;


return 	respuesta.calculo;
END;
$function$
