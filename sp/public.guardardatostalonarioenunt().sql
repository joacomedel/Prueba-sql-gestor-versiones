CREATE OR REPLACE FUNCTION public.guardardatostalonarioenunt()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$/*
*/
DECLARE
     
BEGIN

	INSERT INTO unidadnegociotalonario(centro, nrosucursal, tipocomprobante, tipofactura, idunidadnegocio)
	VALUES (NEW.centro, NEW.nrosucursal,NEW.tipocomprobante, NEW.tipofactura, CASE WHEN NEW.centro=99 THEN 2 ELSE 1 END);

return NEW;
END;

$function$
