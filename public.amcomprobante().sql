CREATE OR REPLACE FUNCTION public.amcomprobante()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccomprobante(NEW);
        return NEW;
    END;
    $function$
