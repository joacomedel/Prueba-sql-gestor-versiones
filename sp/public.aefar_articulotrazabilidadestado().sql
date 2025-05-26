CREATE OR REPLACE FUNCTION public.aefar_articulotrazabilidadestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_articulotrazabilidadestado(OLD);
        return OLD;
    END;
    $function$
