CREATE OR REPLACE FUNCTION public.amfar_pedidoestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_pedidoestado(NEW);
        return NEW;
    END;
    $function$
