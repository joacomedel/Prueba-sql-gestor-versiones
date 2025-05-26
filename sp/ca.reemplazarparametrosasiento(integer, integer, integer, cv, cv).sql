CREATE OR REPLACE FUNCTION ca.reemplazarparametrosasiento(integer, integer, integer, character varying, character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/*
*PARAMETROS : $1 mes
              $2 anio
              $3 idcentrocosto
              $4 nroctacble
              $5 la formula              */
DECLARE

mes integer;
anio integer;
idtipoliquidacion integer;
idcentrocosto integer;
nroctacble varchar;
laformula varchar;
BEGIN
     SET search_path = ca, pg_catalog;
     mes = $1;
     anio = $2;
     idcentrocosto =  $3;
     nroctacble = $4;
     laformula =$5;


     laformula = replace(laformula, '#', mes);
     laformula = replace(laformula, '&',anio);
     laformula = replace(laformula, '@', idcentrocosto);
     laformula = replace(laformula, '$', nroctacble);

return 	laformula;
END;
$function$
