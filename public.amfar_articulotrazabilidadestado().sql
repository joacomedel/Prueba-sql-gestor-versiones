CREATE OR REPLACE FUNCTION public.amfar_articulotrazabilidadestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_articulotrazabilidadestado(NEW);
        return NEW;
    END;
    $function$
