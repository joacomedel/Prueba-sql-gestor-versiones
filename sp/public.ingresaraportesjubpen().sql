CREATE OR REPLACE FUNCTION public.ingresaraportesjubpen()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*Luego de este proceso hay que correo el proceso cambiarestadoconfechafinos() para que el estado se corresponda con la
fechafinos */
DECLARE
	alta CURSOR FOR SELECT * FROM taportejubpen order by nrodoc,tipodoc,fechafinaport desc;
	elem RECORD;
	per RECORD;
	aux RECORD;
	verif RECORD;
	resultado BOOLEAN;
	fechafin DATE;
	
BEGIN

OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP
    SELECT INTO per * FROM afilsosunc where afilsosunc.tipodoc = elem.tipodoc  and afilsosunc.nrodoc = elem.nrodoc;
    IF NOT FOUND THEN
     /*Verifico que exista la persona*/
       UPDATE taportejubpen SET tipoinforme = 'No existe persona' WHERE taportejubpen.nrodoc = elem.nrodoc and taportejubpen.tipodoc = elem.tipodoc;
    ELSE
     /*Verifico que No Exista el aporte para el corriente mes*/
	   SELECT INTO aux * FROM aportejubpen where aportejubpen.nrodoc = elem.nrodoc and aportejubpen.tipodoc = elem.tipodoc and aportejubpen.mes = elem.mes and aportejubpen.anio = elem.anio;
       IF NOT FOUND
 	      THEN
 	   	      INSERT INTO aportejubpen (nrodoc,tipodoc,importe,fechainiaport,fechafinaport,mes,anio)
                            VALUES (elem.nrodoc,elem.tipodoc,elem.importe,elem.fechainiaport,elem.fechafinaport,elem.mes,elem.anio);
        END IF;
    -- La idea que los que no existen quedan en la tabla para ser reportados.
     /*Actualizo la fechafinos en persona, como estan ordenasdas en forma decreciente, la ultima que se inserta es la que tiene la fechafinlab
    que determina la fechadinos y el estado valido*/
    fechafin = elem.fechafinaport + INTEGER '90';
    UPDATE persona SET fechafinos = fechafin WHERE nrodoc = elem.nrodoc and tipodoc = elem.tipodoc;
    DELETE FROM taportejubpen WHERE taportejubpen.nrodoc = elem.nrodoc and taportejubpen.tipodoc = elem.tipodoc;
    END IF;
fetch alta into elem;
END LOOP;
CLOSE alta;
return 'true';
END;
$function$
