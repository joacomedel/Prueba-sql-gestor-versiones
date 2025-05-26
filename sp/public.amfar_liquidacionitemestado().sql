CREATE OR REPLACE FUNCTION public.amfar_liquidacionitemestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_liquidacionitemestado(NEW);
        return NEW;
    END;
    $function$
