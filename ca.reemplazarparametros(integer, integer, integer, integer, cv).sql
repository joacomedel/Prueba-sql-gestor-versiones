CREATE OR REPLACE FUNCTION ca.reemplazarparametros(integer, integer, integer, integer, character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
/*
*PARAMETROS : $1 codliquidacion
              $2 eltipo
              $3 idpersona
              $4 idconcepto
              $5 laformuladeduc */
DECLARE

codliquidacion integer;
eltipo integer;
idpersona integer;
idconcepto integer;
laformula varchar;
BEGIN
     SET search_path = ca, pg_catalog;
     codliquidacion = $1;
     eltipo = $2;
     idpersona =  $3;
     idconcepto = $4;
     laformula = $5;

     laformula = replace(laformula, '#', codliquidacion);
     laformula = replace(laformula, '&',eltipo);
     laformula = replace(laformula, '?', idpersona);
     laformula = replace(laformula, '@', idconcepto);

return 	laformula;
END;
$function$
