CREATE OR REPLACE FUNCTION public.migrarconsumoscuentacorrientev2()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Metodo que hacienta todos los consumos en la cuenta corriente seguin los recibos. */
DECLARE
cursorconsumo refcursor;
unconsumo RECORD;
respuesta Bool;

BEGIN
OPEN cursorconsumo FOR SELECT DISTINCT *
                      FROM recibo
                       WHERE recibo.fecharecibo >= '2007-12-25'
                      AND recibo.fecharecibo < '2008-01-25';

FETCH cursorconsumo into unconsumo;
WHILE found LOOP

SELECT INTO respuesta *  FROM asentarconsumoctactev2(unconsumo.idrecibo,unconsumo.centro,NULL);
fetch cursorconsumo into unconsumo;
END LOOP;
close cursorconsumo;
RETURN respuesta;
END;
$function$
