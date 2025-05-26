CREATE OR REPLACE FUNCTION public.aefar_validacionitemsestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_validacionitemsestado(OLD);
        return OLD;
    END;
    $function$
