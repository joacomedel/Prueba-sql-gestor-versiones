CREATE OR REPLACE FUNCTION public.despuesmodificarbenefsosunc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
aux boolean;
BEGIN
--ALTER TABLE benefsosunc disable TRIGGER disparadordespuesmodificarbenefsosunc;

-- llama a un strore con todo los datos para realizar la actualizacion de los datos de ctacte
--SELECT INTO aux * FROM actualizarctacte(NEW.nrodoc,NEW.tipodoc);
--llama a un store con todos los datos para agregar a la persona a los planes
-- de cobertura que corresponden
SELECT INTO aux * FROM agregarpersonaplanes(NEW.nrodoc,NEW.tipodoc);

--ALTER TABLE benefsosunc enable TRIGGER disparadordespuesmodificarbenefsosunc;

return NEW;
END;
$function$
