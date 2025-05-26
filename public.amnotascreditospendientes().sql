CREATE OR REPLACE FUNCTION public.amnotascreditospendientes()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccnotascreditospendientes(NEW);
        return NEW;
    END;
    $function$
