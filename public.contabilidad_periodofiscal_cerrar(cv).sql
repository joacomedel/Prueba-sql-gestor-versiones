CREATE OR REPLACE FUNCTION public.contabilidad_periodofiscal_cerrar(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	    resp boolean;
        rejercicio RECORD;
        rparam  RECORD;
        rfechas  RECORD;
        elidejercicio  bigint;
BEGIN
/**
Este SP cierra un periodo los 15 de cada mes
*/
  resp = false;
  EXECUTE sys_dar_filtros($1) INTO rparam;
  IF (extract(day from now())=15) THEN
       UPDATE contabilidad_ejerciciocontable SET eccerrado = now()
       WHERE nullvalue(eccerrado)
             and  extract(month from ecfechadesde ) = extract(month from now()) - 1;
        resp = true;
  END IF;
  return resp;
END;
$function$
