CREATE OR REPLACE FUNCTION public.cambioestadoafilsosunc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
		benefprue refcursor;
	elem RECORD;
	pers RECORD;
	aux boolean;
        auxcontrol RECORD;
BEGIN
-- 1=afiliados titulares de sosunc

IF(TG_OP = 'INSERT')  THEN
           -- SELECT INTO aux * FROM insertarestadonuevapers(1,NEW.tipodoc,NEW.nrodoc,NEW.idestado);
              
            select INTO auxcontrol *   from cambioestafil where tipodoc = NEW.tipodoc AND nrodoc = NEW.nrodoc AND fechaini = current_timestamp;
      IF NOT FOUND then
            INSERT INTO cambioestafil (tipodoc,nrodoc,idestado,fechaini,fechafin) VALUES(NEW.tipodoc,NEW.nrodoc,NEW.idestado,current_timestamp,'9999-12-31');
      END if;
END if;

IF(TG_OP = 'UPDATE')  THEN

           if NOT(OLD.idestado = NEW.idestado) then
		UPDATE cambioestafil SET fechafin = current_date WHERE tipodoc = NEW.tipodoc AND nrodoc = NEW.nrodoc AND fechafin = '9999-12-31';
   
         select INTO auxcontrol *   from cambioestafil where tipodoc = NEW.tipodoc AND nrodoc = NEW.nrodoc AND fechaini = current_timestamp;
      IF NOT FOUND then
                INSERT INTO cambioestafil (tipodoc,nrodoc,idestado,fechaini,fechafin)   VALUES(NEW.tipodoc,NEW.nrodoc,NEW.idestado,current_timestamp,'9999-12-31');
      END if;

end if;


--SELECT INTO aux * FROM agregarpersonaplanes(NEW.nrodoc,NEW.tipodoc);
/*
KR comento 06-06, daba error el sp de  agregaraportesjubpen('malapi'), el error es No se han conseguido datos al ejecutar la  siguiente consulta:  ERROR: límite de profundidad , de stack alcanzado.


SELECT INTO aux * FROM actualizarctacte(NEW.nrodoc,NEW.tipodoc);
        		
          */



END if;

OPEN benefprue FOR SELECT * FROM benefsosunc WHERE nrodoctitu = NEW.nrodoc AND tipodoctitu = NEW.tipodoc;
	
		FETCH benefprue INTO elem;
		WHILE  found LOOP
			if NEW.idestado = 4 then
			   IF elem.idestado <> 4 THEN
              			 SELECT INTO aux * FROM actualizarlafechadefinosbenefsosunc(elem.nrodoc,elem.tipodoc);
			   END IF;
                        else
			   SELECT INTO aux * FROM actualizarlafechadefinosbenefsosunc(elem.nrodoc,elem.tipodoc);
			end if;
		fetch benefprue into elem;
		END LOOP;
	CLOSE benefprue;

return new;
END;$function$
