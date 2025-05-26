CREATE OR REPLACE FUNCTION public.aesolicitudauditoria()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccsolicitudauditoria(OLD);
        return OLD;
    END;
    $function$
