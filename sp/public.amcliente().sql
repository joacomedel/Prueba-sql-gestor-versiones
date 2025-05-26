CREATE OR REPLACE FUNCTION public.amcliente()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccliente(NEW);
        return NEW;
    END;
    $function$
