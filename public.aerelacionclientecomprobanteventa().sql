CREATE OR REPLACE FUNCTION public.aerelacionclientecomprobanteventa()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrelacionclientecomprobanteventa(OLD);
        return OLD;
    END;
    $function$
