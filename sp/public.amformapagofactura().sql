CREATE OR REPLACE FUNCTION public.amformapagofactura()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccformapagofactura(NEW);
        return NEW;
    END;
    $function$
