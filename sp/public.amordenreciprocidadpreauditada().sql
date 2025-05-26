CREATE OR REPLACE FUNCTION public.amordenreciprocidadpreauditada()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccordenreciprocidadpreauditada(NEW);
        return NEW;
    END;
    $function$
