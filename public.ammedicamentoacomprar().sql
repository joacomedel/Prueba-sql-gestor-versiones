CREATE OR REPLACE FUNCTION public.ammedicamentoacomprar()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccmedicamentoacomprar(NEW);
        return NEW;
    END;
    $function$
