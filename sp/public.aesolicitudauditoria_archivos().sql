CREATE OR REPLACE FUNCTION public.aesolicitudauditoria_archivos()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccsolicitudauditoria_archivos(OLD);
        return OLD;
    END;
    $function$
