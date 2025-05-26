CREATE OR REPLACE FUNCTION public.resumenimputacionunc(bigint, smallint, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
       laliquidacion  bigint;
       eltipodoc  smallint;
       elnumdoc  varchar;

-- $1 = idnomenclador, $2 = Nombre de la tabla a actualizar
	
BEGIN
     laliquidacion  = $1;
     eltipodoc = $2;
     elnumdoc =$3;
	 return resultado;
END;
$function$
