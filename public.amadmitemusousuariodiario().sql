CREATE OR REPLACE FUNCTION public.amadmitemusousuariodiario()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccadmitemusousuariodiario(NEW);
        return NEW;
    END;
    $function$
