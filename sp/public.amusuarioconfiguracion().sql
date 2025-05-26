CREATE OR REPLACE FUNCTION public.amusuarioconfiguracion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccusuarioconfiguracion(NEW);
        return NEW;
    END;
    $function$
