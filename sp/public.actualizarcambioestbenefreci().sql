CREATE OR REPLACE FUNCTION public.actualizarcambioestbenefreci()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	aux boolean;
BEGIN

--llama a un strore con todo los datos para realizar nueva tubla en cambio de estado y actualizar la vieja
if NOT(OLD.idestado = NEW.idestado)
	then
		SELECT INTO aux * FROM insertarcambioestado(4,NEW.tipodoc,NEW.nrodoc,OLD.idestado,NEW.idestado);
end if;
return NEW;
END;
$function$
