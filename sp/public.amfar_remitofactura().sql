CREATE OR REPLACE FUNCTION public.amfar_remitofactura()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_remitofactura(NEW);
        return NEW;
    END;
    $function$
