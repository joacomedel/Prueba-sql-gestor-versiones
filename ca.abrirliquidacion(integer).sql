CREATE OR REPLACE FUNCTION ca.abrirliquidacion(integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE

     idliq integer;

BEGIN
     idliq = $1;
     UPDATE ca.liquidacion SET lifecha =null,
                                lifechapagoaporte = null,
                                lifechapago = null
        WHERE  idliquidacion =idliq;
   
    UPDATE ca.conceptoempleado SET cemontofinal =0
        WHERE  idliquidacion =idliq;

     DELETE from ca.liquidacionempleado
        WHERE idliquidacion =idliq;

RETURN true;
END;
$function$
