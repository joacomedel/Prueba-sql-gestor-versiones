CREATE OR REPLACE FUNCTION public.amfar_liquidacionestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_liquidacionestado(NEW);
        return NEW;
    END;
    $function$
