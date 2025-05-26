CREATE OR REPLACE FUNCTION public.aemanextra()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccmanextra(OLD);
        return OLD;
    END;
    $function$
