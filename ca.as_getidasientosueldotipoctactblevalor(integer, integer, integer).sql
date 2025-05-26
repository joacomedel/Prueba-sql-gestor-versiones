CREATE OR REPLACE FUNCTION ca.as_getidasientosueldotipoctactblevalor(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Retorna el importe correspondiente al idasientosueldotipoctactble de
* la  liquidacion enviada por parametro
* 
*/
DECLARE
      monto double precision;

BEGIN

   
     SELECT INTO monto SUM(ascimporte)
     FROM  ca.asientosueldo
     NATURAL JOIN  ca.asientosueldotipoctactble
     NATURAL JOIN cuentascontables
     NATURAL JOIN centrocosto
     NATURAL JOIN ca.asientosueldotipo
     NATURAL JOIN ca.asientosueldoctactble
     WHERE limes=$1 AND lianio=$2
           AND idasientosueldotipo=5
                      --and nullvalue(asfecha)
           AND  ascactivo AND asvigente
           AND idasientosueldotipoctactble = $3
     GROUP BY ascactivo,idasientosueldo;	


return 	monto;
END;
$function$
