CREATE OR REPLACE FUNCTION public.amasientogenericoestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccasientogenericoestado(NEW);
        return NEW;
    END;
    $function$
