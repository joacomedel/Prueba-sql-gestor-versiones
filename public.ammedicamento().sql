CREATE OR REPLACE FUNCTION public.ammedicamento()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccmedicamento(NEW);
        return NEW;
    END;
    $function$
