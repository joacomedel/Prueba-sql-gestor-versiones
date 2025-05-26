CREATE OR REPLACE FUNCTION public.insertarboletin(date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	alta CURSOR FOR SELECT * FROM actividades_dos;
		
	elem RECORD;
	boletin RECORD;
	
	act_real	RECORD;
	actividad RECORD;
	idbol   INTEGER;
	idact	INTEGER;
	resultado boolean;

BEGIN

SELECT INTO boletin MAX(idboletin) FROM boletines ;
if NOT FOUND
  then
      return 'false';
  else
	idbol = boletin.max + 1;
        INSERT INTO boletines (idboletin,fechaboletin) VALUES (idbol,$1);

	SELECT INTO actividad MAX(idactividad) FROM actividades ;
	idact = actividad.max;
	
	OPEN alta;
	FETCH alta INTO elem;
	WHILE  found LOOP
	idact = idact + elem.idactividad;		




	INSERT INTO actividades (idactividad,idboletin,descripcion,horainicio, horafin)
		VALUES (idact, idbol, elem.descripcion, elem.horainicio, elem.horafin);

	select into resultado * from insertar_ar(elem.idactividad, idact);

	fetch alta into elem;
	END LOOP;
	CLOSE alta;

    return resultado;
end if;

END;
$function$
