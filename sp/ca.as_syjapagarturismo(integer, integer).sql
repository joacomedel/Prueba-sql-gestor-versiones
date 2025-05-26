CREATE OR REPLACE FUNCTION ca.as_syjapagarturismo(integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a sueldos y jornales a pagar
* PRE: el asiento debe estar creado

*/
DECLARE
        centrocosto integer;   
        laformula varchar;
        elmes integer;
        elanio integer;
        montoneto double precision;
        montonetoaux double precision;
	montoctacteasist double precision;
        montoctaprestamasist double precision;
        montoturismo double precision;
        montocuotaplanpago double precision;
        montototal double precision;
	
	
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



     select into montoturismo  ca.as_conceptoasiento(elmes,elanio,360);
  
   
     montototal =  round(montoturismo::numeric,3);



return montototal;
END;
$function$
