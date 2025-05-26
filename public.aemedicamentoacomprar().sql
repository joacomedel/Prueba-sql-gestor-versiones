CREATE OR REPLACE FUNCTION public.aemedicamentoacomprar()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccmedicamentoacomprar(OLD);
        return OLD;
    END;
    $function$
