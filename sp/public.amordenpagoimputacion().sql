CREATE OR REPLACE FUNCTION public.amordenpagoimputacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccordenpagoimputacion(NEW);
        return NEW;
    END;
    $function$
