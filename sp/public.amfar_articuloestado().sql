CREATE OR REPLACE FUNCTION public.amfar_articuloestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_articuloestado(NEW);
        return NEW;
    END;
    $function$
