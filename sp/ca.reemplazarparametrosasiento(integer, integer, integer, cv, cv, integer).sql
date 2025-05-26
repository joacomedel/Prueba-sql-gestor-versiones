CREATE OR REPLACE FUNCTION ca.reemplazarparametrosasiento(integer, integer, integer, character varying, character varying, integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/*
*PARAMETROS : $1 mes
              $2 anio
              $3 idcentrocosto
              $4 nroctacble
              $5 la formula    
	      $6 idasientosueldoctactble              */
DECLARE

mes integer;
anio integer;
idtipoliquidacion integer;
idasientosueldoctactble integer;
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
     idasientosueldoctactble=$6;


     laformula = replace(laformula, '#', mes);
     laformula = replace(laformula, '&',anio);
     laformula = replace(laformula, '@', idcentrocosto);
     laformula = replace(laformula, '$', nroctacble);
     laformula = replace(laformula, '%', idasientosueldoctactble);

return 	laformula;
END;
$function$
