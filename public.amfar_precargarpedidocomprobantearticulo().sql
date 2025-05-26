CREATE OR REPLACE FUNCTION public.amfar_precargarpedidocomprobantearticulo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_precargarpedidocomprobantearticulo(NEW);
        return NEW;
    END;
    $function$
