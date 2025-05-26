CREATE OR REPLACE FUNCTION public.amadmitemusousuario()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccadmitemusousuario(NEW);
        return NEW;
    END;
    $function$
