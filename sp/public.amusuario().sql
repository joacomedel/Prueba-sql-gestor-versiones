CREATE OR REPLACE FUNCTION public.amusuario()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccusuario(NEW);
        return NEW;
    END;
    $function$
