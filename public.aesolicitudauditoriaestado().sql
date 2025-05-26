CREATE OR REPLACE FUNCTION public.aesolicitudauditoriaestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccsolicitudauditoriaestado(OLD);
        return OLD;
    END;
    $function$
