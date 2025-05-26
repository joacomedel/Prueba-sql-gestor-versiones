CREATE OR REPLACE FUNCTION public.aeadmitemusousuariodiario()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccadmitemusousuariodiario(OLD);
        return OLD;
    END;
    $function$
