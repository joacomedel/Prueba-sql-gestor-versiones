CREATE OR REPLACE FUNCTION public.aeplancobpersona()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccplancobpersona(OLD);
        return OLD;
    END;
    $function$
