CREATE OR REPLACE FUNCTION public.aeordenreciprocidadpreauditada()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccordenreciprocidadpreauditada(OLD);
        return OLD;
    END;
    $function$
