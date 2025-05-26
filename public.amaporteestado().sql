CREATE OR REPLACE FUNCTION public.amaporteestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccaporteestado(NEW);
        return NEW;
    END;
    $function$
