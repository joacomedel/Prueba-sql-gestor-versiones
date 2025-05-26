CREATE OR REPLACE FUNCTION public.aeadmitemusousuario()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccadmitemusousuario(OLD);
        return OLD;
    END;
    $function$
