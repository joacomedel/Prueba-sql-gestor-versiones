CREATE OR REPLACE FUNCTION public.cambioestadobenefreci()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
		benefprue refcursor;
	elem RECORD;
	pers RECORD;
	aux boolean;
BEGIN
-- 4 = beneficiarios de reciprocidad

IF(TG_OP = 'INSERT')  THEN
           -- SELECT INTO aux * FROM insertarestadonuevapers(1,NEW.tipodoc,NEW.nrodoc,NEW.idestado);
            INSERT INTO cambioestbenefreci(tipodoc,nrodoc,idestado,fechaini,fechafin) VALUES(NEW.tipodoc,NEW.nrodoc,NEW.idestado,current_timestamp,'9999-12-31');
END if;

IF(TG_OP = 'UPDATE')  THEN

           if NOT(OLD.idestado = NEW.idestado) then
		UPDATE cambioestbenefreci SET fechafin = current_date WHERE tipodoc = NEW.tipodoc AND nrodoc = NEW.nrodoc  AND fechafin = '9999-12-31';
		        INSERT INTO cambioestbenefreci(tipodoc,nrodoc,idestado,fechaini,fechafin) VALUES(NEW.tipodoc,NEW.nrodoc,NEW.idestado,current_timestamp,'9999-12-31');
          end if;

       
        		
          



END if;

return new;
END;$function$
