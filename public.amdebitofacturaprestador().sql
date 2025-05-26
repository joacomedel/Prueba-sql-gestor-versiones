CREATE OR REPLACE FUNCTION public.amdebitofacturaprestador()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccdebitofacturaprestador(NEW);
        return NEW;
    END;
    $function$
