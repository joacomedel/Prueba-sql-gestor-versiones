CREATE OR REPLACE FUNCTION public.migrarconsumoscuentacorriente()
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
                      WHERE recibo.fecharecibo > '2007-10-20'
                      AND recibo.fecharecibo < '2007-11-20';

FETCH cursorconsumo into unconsumo;
WHILE found LOOP

SELECT INTO respuesta *  FROM asentarconsumoctacte(unconsumo.idrecibo,unconsumo.centro);
fetch cursorconsumo into unconsumo;
END LOOP;
close cursorconsumo;
RETURN respuesta;
END;
$function$
