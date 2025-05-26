CREATE OR REPLACE FUNCTION public.recibocuponlote_agreganrocomercio_fc(fila recibocuponlote)
 RETURNS recibocuponlote
 LANGUAGE plpgsql
AS $function$
DECLARE
    rcupon RECORD;
BEGIN

    select into rcupon nrocomercio from valorescajacomercio natural join valorescaja natural join recibocupon f
    where idposnet=fila.idposnet and f.idrecibocupon = fila.idrecibocupon AND f.idcentrorecibocupon=fila.idcentrorecibocupon;

	fila.nrocomercio:= rcupon.nrocomercio;
    
	return fila;
END;
$function$
