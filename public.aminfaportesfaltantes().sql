CREATE OR REPLACE FUNCTION public.aminfaportesfaltantes()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccinfaportesfaltantes(NEW);
        return NEW;
    END;
    $function$
