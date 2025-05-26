CREATE OR REPLACE FUNCTION ca.f_farmproporcionalhoras(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       rhorasjornada record;
BEGIN

      SELECT INTO rhorasjornada *
      FROM ca.conceptoempleado
      WHERE   idpersona= $3 and idliquidacion= $1 and idconcepto = 1136;

      UPDATE ca.conceptoempleado SET ceporcentaje =(rhorasjornada.cemonto/rhorasjornada.ceporcentaje)
      WHERE   idpersona= $3 and idliquidacion= $1 and idconcepto = 1044;

return 	rhorasjornada.cemonto;
END;


$function$
