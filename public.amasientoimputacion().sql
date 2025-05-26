CREATE OR REPLACE FUNCTION public.amasientoimputacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccasientoimputacion(NEW);
        return NEW;
    END;
    $function$
