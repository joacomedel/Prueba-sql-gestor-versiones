CREATE OR REPLACE FUNCTION public.amfar_estado_validador()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_estado_validador(NEW);
        return NEW;
    END;
    $function$
