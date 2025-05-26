CREATE OR REPLACE FUNCTION public.amfar_pedidoreclibrofact()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_pedidoreclibrofact(NEW);
        return NEW;
    END;
    $function$
