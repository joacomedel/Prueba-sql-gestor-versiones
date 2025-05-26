CREATE OR REPLACE FUNCTION public.aenotascreditospendientes()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccnotascreditospendientes(OLD);
        return OLD;
    END;
    $function$
