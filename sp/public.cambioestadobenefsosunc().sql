CREATE OR REPLACE FUNCTION public.cambioestadobenefsosunc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
		benefprue refcursor;
	elem RECORD;
	pers RECORD;
	aux boolean;
BEGIN
-- 2 = beneficiarios de sosunc

IF(TG_OP = 'INSERT')  THEN
           
           INSERT INTO cambioestbenef (tipodoc,nrodoc,idestado,fechaini,fechafin) VALUES(NEW.tipodoc,NEW.nrodoc,NEW.idestado,current_timestamp,'9999-12-31');

END if;

IF(TG_OP = 'UPDATE')  THEN

           if NOT(OLD.idestado = NEW.idestado) then
		UPDATE cambioestbenef SET fechafin = current_date WHERE tipodoc = NEW.tipodoc AND nrodoc = NEW.nrodoc AND fechafin = '9999-12-31';
                INSERT INTO cambioestbenef (tipodoc,nrodoc,idestado,fechaini,fechafin)   VALUES(NEW.tipodoc,NEW.nrodoc,NEW.idestado,current_timestamp,'9999-12-31');
          end if;

       
        		
          



END if;

return new;
END;$function$
