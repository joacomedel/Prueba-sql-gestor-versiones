CREATE OR REPLACE FUNCTION public.ammutualpadronestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccmutualpadronestado(NEW);
        return NEW;
    END;
    $function$
