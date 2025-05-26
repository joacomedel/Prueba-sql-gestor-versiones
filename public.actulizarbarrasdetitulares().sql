CREATE OR REPLACE FUNCTION public.actulizarbarrasdetitulares()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
    aux RECORD; 
    regreci RECORD; 
BEGIN
if (NEW.barra < 100)
	then
		if (NEW.barra > 29)
			then
				UPDATE afilsosunc SET barra = NEW.barra  WHERE nrodoc = NEW.nrodoc AND tipodoc = NEW.tipodoc ;
				SELECT INTO aux * FROM actualizarbarrabenefsosunc(NEW.tipodoc,NEW.nrodoc,NEW.barra);
			else
				SELECT INTO aux * FROM actualizarbarrabenefsosunc(NEW.tipodoc,NEW.nrodoc,NEW.barra);
		end if;
	else
		if (NEW.barra > 129)
			then
                                SELECT INTO regreci * FROM osreci WHERE barra = NEW.barra;
				--RAISE NOTICE 'actulizarbarrasdetitulares (%)',NEW.barra;

                                UPDATE afilreci SET barra = NEW.barra, idosreci=regreci.idosreci  WHERE nrodoc = NEW.nrodoc AND tipodoc = NEW.tipodoc ;
				SELECT INTO aux * FROM actualizarbarrabenefreci(NEW.tipodoc,NEW.nrodoc,NEW.barra);
			else
				SELECT INTO aux * FROM actualizarbarrabenefreci(NEW.tipodoc,NEW.nrodoc,NEW.barra);
		end if;
end if;
return NEW;
END;
$function$
