CREATE OR REPLACE FUNCTION public.aefar_articuloubicacionsucursal()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_articuloubicacionsucursal(OLD);
        return OLD;
    END;
    $function$
