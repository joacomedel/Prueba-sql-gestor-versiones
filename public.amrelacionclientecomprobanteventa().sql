CREATE OR REPLACE FUNCTION public.amrelacionclientecomprobanteventa()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrelacionclientecomprobanteventa(NEW);
        return NEW;
    END;
    $function$
