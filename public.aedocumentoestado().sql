CREATE OR REPLACE FUNCTION public.aedocumentoestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccdocumentoestado(OLD);
        return OLD;
    END;
    $function$
