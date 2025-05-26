CREATE OR REPLACE FUNCTION ca.sumaconceptoliquidacionmesanio(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
        monto DOUBLE PRECISION;
        elmes integer;
        elanio integer;
        elidconcepto integer;
BEGIN
     elmes = $1;
     elanio = $2;
     elidconcepto = $3;

    SELECT  INTO monto SUM(montoemp)
    FROM (
        SELECT (cemonto * ceporcentaje)as montoemp
        FROM ca.conceptoempleado
        NATURAL JOIN ca.concepto
        NATURAL JOIN ca.liquidacion
        WHERE
--lianio= elanio and  limes = elmes 
extract (month FROM (lifechapago))=elmes and extract (year FROM (lifechapago))=elanio 
and idconcepto=elidconcepto

    )as t;
    IF nullvalue(monto) THEN monto = 0; END IF;

return monto;

END;
$function$
