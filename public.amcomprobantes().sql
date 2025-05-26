CREATE OR REPLACE FUNCTION public.amcomprobantes()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccomprobantes(NEW);
        return NEW;
    END;
    $function$
