CREATE OR REPLACE FUNCTION public.aefar_articuloagrupador()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_articuloagrupador(OLD);
        return OLD;
    END;
    $function$
