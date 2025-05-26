CREATE OR REPLACE FUNCTION public.actulizarbarradepersona()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
    aux RECORD; 
    barrita RECORD;
    resultado boolean;
BEGIN
SELECT INTO barrita * FROM barras WHERE nrodoc = NEW.nrodoc AND tipodoc = NEW.tipodoc
                  AND prioridad = (SELECT min(prioridad) FROM barras WHERE nrodoc = NEW.nrodoc AND tipodoc = NEW.tipodoc)
ORDER BY barras.barrascc DESC  limit 1;
SELECT INTO aux * FROM persona WHERE nrodoc = NEW.nrodoc AND tipodoc = NEW.tipodoc 
                  AND barra = barrita.barra;
if NOT FOUND
	then
		UPDATE persona SET barra = barrita.barra  WHERE nrodoc = NEW.nrodoc AND tipodoc = NEW.tipodoc ;
		UPDATE cliente SET barra =  NEW.tipodoc  WHERE nrocliente = NEW.nrodoc;
	else
		UPDATE persona SET barra = NEW.barra  WHERE nrodoc = NEW.nrodoc AND tipodoc = NEW.tipodoc ;
		UPDATE cliente SET barra =  NEW.tipodoc  WHERE nrocliente = NEW.nrodoc;
		--si tengo la mayor prioridad
end if;

SELECT INTO aux * FROM cliente WHERE nrocliente = NEW.nrodoc AND barra = barrita.barra;
if NOT FOUND then
           UPDATE cliente SET barra =  NEW.tipodoc  WHERE nrocliente = NEW.nrodoc;
end if;

   
SELECT INTO aux * FROM persona WHERE nrodoc = NEW.nrodoc AND tipodoc = NEW.tipodoc ;
SELECT INTO barrita * FROM histobarras WHERE nrodoc = NEW.nrodoc AND tipodoc = NEW.tipodoc AND fechafin = '9999-12-31';
if FOUND
	then --ya tiene al menos una barra
		if aux.barra = barrita.barra
			then 
				resultado = 'true';
			else
				UPDATE histobarras SET fechafin = current_date WHERE  nrodoc = NEW.nrodoc AND tipodoc = NEW.tipodoc AND fechafin = '9999-12-31';
		INSERT INTO histobarras (barra,prioridad,tipodoc,nrodoc,fechaini) VALUES(NEW.barra,NEW.prioridad,NEW.tipodoc,NEW.nrodoc,current_timestamp);
		end if;
	else --es la primera barra
		INSERT INTO histobarras (barra,prioridad,tipodoc,nrodoc,fechaini) VALUES(NEW.barra,NEW.prioridad,NEW.tipodoc,NEW.nrodoc,current_timestamp);
end if;
return NEW;
END;
$function$
