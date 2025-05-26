CREATE OR REPLACE FUNCTION public.amrestados()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrestados(NEW);
        return NEW;
    END;
    $function$
