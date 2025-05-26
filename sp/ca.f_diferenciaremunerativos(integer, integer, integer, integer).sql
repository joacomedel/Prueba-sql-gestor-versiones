CREATE OR REPLACE FUNCTION ca.f_diferenciaremunerativos(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       rliqext record;
       rliqsueld record;
BEGIN
     --reemplazarparametros
     --(integer, integer, integer, integer, varchar)
     /* codliquidacion = $1;
     eltipo = $2;
     idpersona =  $3;
     elidconcepto = $4;
     laformula = $5; */
     elmonto = 0;

--- Buscar la liqidacion extraordinaria
    SELECT INTO rliqext FROM ca.liquidacionempleado WHERE idliquidacion = 536;
    IF FOUND THEN
            --- Liquidacion de sueldos sosunc
           SELECT INTO rliqsueld FROM ca.liquidacioncabecera WHERE idliquidacion = 535;
           IF FOUND THEN
               elmonto = rliqext.leimpbruto - rliqsueld.leimpbruto;

           END IF;
    END IF;
    return elmonto ;

END;
$function$
