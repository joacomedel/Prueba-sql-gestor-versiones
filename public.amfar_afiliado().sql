CREATE OR REPLACE FUNCTION public.amfar_afiliado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_afiliado(NEW);
        return NEW;
    END;
    $function$
