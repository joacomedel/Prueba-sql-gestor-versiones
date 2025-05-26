CREATE OR REPLACE FUNCTION public.aefar_articuloestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_articuloestado(OLD);
        return OLD;
    END;
    $function$
