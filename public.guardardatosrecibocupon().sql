CREATE OR REPLACE FUNCTION public.guardardatosrecibocupon()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

regrecibocupon CURSOR FOR SELECT * FROM temprecibocupon;
treccupon RECORD;
--variables
  idfp INTEGER;

BEGIN


open regrecibocupon;
FETCH regrecibocupon into treccupon;
      WHILE FOUND LOOP
            INSERT INTO recibocupon(idvalorescaja, autorizacion, nrotarjeta, monto, 
            cuotas, nrocupon,idrecibo,centro)
            VALUES(treccupon.idvalorescaja, treccupon.autorizacion, treccupon.nrotarjeta,treccupon.monto, 
             treccupon.cuotas, treccupon.nrocupon, treccupon.idrecibo, treccupon.centro);

  
        FETCH regrecibocupon into treccupon;
        END LOOP;
close regrecibocupon;


return true;
END;
$function$
