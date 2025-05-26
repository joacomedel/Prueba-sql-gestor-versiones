CREATE OR REPLACE FUNCTION public.arraglarimputacionesctacte()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
       curdeudas refcursor;
       unadeuda RECORD;
       asentar boolean;

BEGIN

OPEN curdeudas FOR SELECT nrodoc,tipodoc
                          FROM malapictacte;

FETCH curdeudas INTO unadeuda;
WHILE  found LOOP
UPDATE cuentacorrientedeuda SET saldo = importe WHERE nrodoc = unadeuda.nrodoc AND tipodoc = unadeuda.tipodoc;
UPDATE cuentacorrientepagos SET saldo = importe WHERE nrodoc = unadeuda.nrodoc AND tipodoc = unadeuda.tipodoc;
DELETE FROM cuentacorrientedeudapago
       WHERE (iddeuda,idcentrodeuda) IN
       (SELECT iddeuda , idcentrodeuda
         FROM cuentacorrientedeuda
         WHERE nrodoc = unadeuda.nrodoc AND tipodoc = unadeuda.tipodoc
       );
SELECT INTO asentar * FROM asentarimputaciondescuentoctactev2(unadeuda.nrodoc,unadeuda.tipodoc);

FETCH curdeudas INTO unadeuda;
END LOOP;
close curdeudas;
RETURN 'true';
END;
$function$
