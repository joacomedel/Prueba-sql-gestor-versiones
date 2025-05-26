CREATE OR REPLACE FUNCTION public.cambioestadoafilreci()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
		benefprue refcursor;
	elem RECORD;
	pers RECORD;
	aux RECORD;
BEGIN
-- 3 = afiliados titulares de reciprocidad
/*Dani 25092019 ver si se debe reemplazar por cambioestafilreci*/ 
SELECT INTO aux * FROM  cambioestbenefreci WHERE tipodoc = NEW.tipodoc AND nrodoc = NEW.nrodoc AND idestado = NEW.idestado AND fechaini = current_timestamp;
IF FOUND THEN 
    IF(TG_OP = 'INSERT')  THEN
           INSERT INTO cambioestafilreci (tipodoc,nrodoc,idestado,fechaini,fechafin) VALUES(NEW.tipodoc,NEW.nrodoc,NEW.idestado,current_timestamp,'9999-12-31');
    END if;
    IF(TG_OP = 'UPDATE')  THEN
          if NOT(OLD.idestado = NEW.idestado) then
          	UPDATE cambioestafilreci SET fechafin = current_date WHERE tipodoc = NEW.tipodoc AND nrodoc = NEW.nrodoc AND fechafin = '9999-12-31';
		   INSERT INTO cambioestafilreci (tipodoc,nrodoc,idestado,fechaini,fechafin) VALUES(NEW.tipodoc,NEW.nrodoc,NEW.idestado,current_timestamp,'9999-12-31');
         
          end if;
    END if;
END if;

OPEN benefprue FOR SELECT * FROM benefreci WHERE nrodoctitu = NEW.nrodoc AND tipodoctitu = NEW.tipodoc;
	
		FETCH benefprue INTO elem;
		WHILE  found LOOP
                        SELECT INTO aux * FROM  cambioestbenefreci WHERE tipodoc = NEW.tipodoc AND nrodoc = NEW.nrodoc AND idestado = NEW.idestado AND fechaini = current_timestamp;
                        IF FOUND THEN 
			IF(TG_OP = 'INSERT')  THEN
                             -- SELECT INTO aux * FROM insertarestadonuevapers(1,NEW.tipodoc,NEW.nrodoc,NEW.idestado);
                            INSERT INTO cambioestbenefreci(tipodoc,nrodoc,idestado,fechaini) VALUES(elem.tipodoc,elem.nrodoc,NEW.idestado,current_timestamp);
                       END if;

                        IF(TG_OP = 'UPDATE')  THEN

                              if NOT(OLD.idestado = NEW.idestado) then

		                 UPDATE cambioestbenefreci SET fechafin = current_date WHERE tipodoc = elem.tipodoc AND nrodoc = elem.nrodoc  AND fechafin = '9999-12-31';
		                INSERT INTO cambioestbenefreci(tipodoc,nrodoc,idestado,fechaini) VALUES(elem.tipodoc,elem.nrodoc,NEW.idestado,current_timestamp);
                              end if;

                        END if;
                       END if;
			fetch benefprue into elem;
		END LOOP;
	CLOSE benefprue;
return new;
END;$function$
