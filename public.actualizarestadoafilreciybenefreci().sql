CREATE OR REPLACE FUNCTION public.actualizarestadoafilreciybenefreci()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	benef CURSOR FOR SELECT * FROM benefreci WHERE nrodoctitu = NEW.nrodoc AND tipodoctitu = NEW.tipodoc;
	elem RECORD;
	aux boolean;
BEGIN
if NOT (NEW.idestado = OLD.idestado) then
OPEN benef;
FETCH benef INTO elem;
WHILE  found LOOP

if NEW.idestado = 4
	then
		UPDATE benefreci SET idestado = NEW.idestado WHERE nrodoc = elem.nrodoc AND tipodoc = elem.tipodoc;
	else
		if elem.idestado = OLD.idestado
			then
				UPDATE benefreci SET idestado = NEW.idestado WHERE nrodoc = elem.nrodoc AND tipodoc = elem.tipodoc;
			--no tengo else porque si tiene un estado distinto es por algo.
		end if;
end if;
fetch benef into elem;
END LOOP;
CLOSE benef;

--llama a un strore con todo los datos para realizar nueva tubla en cambio de estado y actualizar la vieja
SELECT INTO aux * FROM insertarcambioestado(3,NEW.tipodoc,NEW.nrodoc,OLD.idestado,NEW.idestado);
end if;
return NEW;
END;
$function$
