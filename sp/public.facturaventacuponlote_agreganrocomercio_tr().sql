CREATE OR REPLACE FUNCTION public.facturaventacuponlote_agreganrocomercio_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW:= facturaventacuponlote_agreganrocomercio_fc(NEW);
    return NEW;
END;
$function$
