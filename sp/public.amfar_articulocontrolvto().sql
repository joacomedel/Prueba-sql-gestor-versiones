CREATE OR REPLACE FUNCTION public.amfar_articulocontrolvto()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_articulocontrolvto(NEW);
        return NEW;
    END;
    $function$
