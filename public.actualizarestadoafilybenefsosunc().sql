CREATE OR REPLACE FUNCTION public.actualizarestadoafilybenefsosunc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
	benefprue refcursor;
--        benefprueba1 CURSOR FOR SELECT * FROM benefsosunc WHERE nrodoctitu = NEW.nrodoc AND --tipodoctitu = NEW.tipodoc;
--        benefprueba2 CURSOR FOR SELECT * FROM benefsosunc WHERE nrodoctitu = NEW.nrodoc AND --tipodoctitu = NEW.tipodoc;
	elem RECORD;
	pers RECORD;
	aux boolean;
BEGIN
--ALTER TABLE afilsosunc disable TRIGGER actualizarestafil;
--OPEN benefprueba1;
--OPEN benefprueba2;
--CLOSE benefprueba1;
--CLOSE benefprueba2;
--if NOT (NEW.idestado = OLD.idestado) then
	OPEN benefprue FOR SELECT * FROM benefsosunc WHERE nrodoctitu = NEW.nrodoc AND tipodoctitu = NEW.tipodoc;
	--OPEN benefprue;
		FETCH benefprue INTO elem;
		WHILE  found LOOP
			if NEW.idestado = 4 then
			   IF elem.idestado <> 4 THEN
               --14/04/2010 MaLaPi Modifico, para que si el padre esta en pasivo, se verifique en que estado
			   -- tiene que quedar el beneficiario.
				--	UPDATE benefsosunc SET idestado = NEW.idestado WHERE nrodoc = elem.nrodoc AND tipodoc = elem.tipodoc;
				 SELECT INTO aux * FROM actualizarlafechadefinosbenefsosunc(elem.nrodoc,elem.tipodoc);
				END IF;
                else
				   SELECT INTO aux * FROM actualizarlafechadefinosbenefsosunc(elem.nrodoc,elem.tipodoc);
			end if;
			fetch benefprue into elem;
		END LOOP;
	CLOSE benefprue;

--llama a un strore con todo los datos para realizar nueva tubla en cambio de estado y actualizar la vieja
/*if NOT(OLD.idestado = NEW.idestado) then
		SELECT INTO aux * FROM insertarcambioestado(1,NEW.tipodoc,NEW.nrodoc,OLD.idestado,NEW.idestado);
end if;
*/
	--llama a un strore con todo los datos para realizar nueva tubla en cambio de estado y actualizar la vieja
	--SELECT INTO aux * FROM insertarcambioestado(1,NEW.tipodoc,NEW.nrodoc,OLD.idestado,NEW.idestado);
	--llama a un strore con todo los datos para realizar la actualizacion de los datos de ctacte
	--SELECT INTO aux * FROM actualizarctacte(NEW.nrodoc,NEW.tipodoc);
--end if;
--ALTER TABLE afilsosunc enable TRIGGER actualizarestafil;
return NEW;
END;
$function$
