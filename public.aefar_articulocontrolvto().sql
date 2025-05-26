CREATE OR REPLACE FUNCTION public.aefar_articulocontrolvto()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_articulocontrolvto(OLD);
        return OLD;
    END;
    $function$
