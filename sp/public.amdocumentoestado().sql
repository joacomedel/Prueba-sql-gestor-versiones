CREATE OR REPLACE FUNCTION public.amdocumentoestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccdocumentoestado(NEW);
        return NEW;
    END;
    $function$
