CREATE OR REPLACE FUNCTION public.amordconsulta()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccordconsulta(NEW);
        return NEW;
    END;
    $function$
