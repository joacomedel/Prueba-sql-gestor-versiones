CREATE OR REPLACE FUNCTION public.amtarjeta()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcctarjeta(NEW);
        return NEW;
    END;
    $function$
