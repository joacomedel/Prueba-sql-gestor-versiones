CREATE OR REPLACE FUNCTION public.recibocuponlote_agreganrocomercio_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW:= recibocuponlote_agreganrocomercio_fc(NEW);
    return NEW;
END;
$function$
