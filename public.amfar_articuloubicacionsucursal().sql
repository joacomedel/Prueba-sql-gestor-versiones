CREATE OR REPLACE FUNCTION public.amfar_articuloubicacionsucursal()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_articuloubicacionsucursal(NEW);
        return NEW;
    END;
    $function$
