CREATE OR REPLACE FUNCTION public.amfar_validacionitemsestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_validacionitemsestado(NEW);
        return NEW;
    END;
    $function$
