CREATE OR REPLACE FUNCTION ca.sumaconceptoliquidacion(integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
        monto DOUBLE PRECISION;
BEGIN
/* elcodliquidacion = $1  ;
   elidconcepto = $2;
*/

    SELECT  INTO monto SUM(montoemp)
    FROM (
        SELECT (cemonto * ceporcentaje)as montoemp
        FROM ca.conceptoempleado
        NATURAL JOIN ca.concepto
        WHERE idliquidacion =$1 and idconcepto=$2
        
    )as t;
    IF nullvalue(monto) THEN monto = 0; END IF;

return monto;

END;

$function$
