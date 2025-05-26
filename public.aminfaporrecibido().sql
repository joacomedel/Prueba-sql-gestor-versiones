CREATE OR REPLACE FUNCTION public.aminfaporrecibido()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccinfaporrecibido(NEW);
        return NEW;
    END;
    $function$
