CREATE OR REPLACE FUNCTION public.ammanextra()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccmanextra(NEW);
        return NEW;
    END;
    $function$
