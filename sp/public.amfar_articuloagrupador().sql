CREATE OR REPLACE FUNCTION public.amfar_articuloagrupador()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_articuloagrupador(NEW);
        return NEW;
    END;
    $function$
