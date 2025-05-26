CREATE OR REPLACE FUNCTION public.insertarnuevoestadobenefreci()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	aux boolean;
BEGIN

--llama a un strore con todo los datos para realizar nueva tubla en cambio de estado y actualizar la vieja
SELECT INTO aux * FROM insertarestadonuevapers(4,NEW.tipodoc,NEW.nrodoc,NEW.idestado);
return NEW;
END;
$function$
