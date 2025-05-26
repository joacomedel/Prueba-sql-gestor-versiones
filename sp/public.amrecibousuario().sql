CREATE OR REPLACE FUNCTION public.amrecibousuario()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrecibousuario(NEW);
        return NEW;
    END;
    $function$
