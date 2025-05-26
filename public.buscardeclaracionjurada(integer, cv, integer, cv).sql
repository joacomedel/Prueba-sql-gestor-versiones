CREATE OR REPLACE FUNCTION public.buscardeclaracionjurada(integer, character varying, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	pers RECORD;
	resultado boolean;
	usuario alias for $4;
	benef CURSOR FOR SELECT * FROM declarasubs WHERE nrodoctitu = $2 AND tipodoctitu = $1;
	dec RECORD;
	tipodocbenef varchar;
BEGIN
DELETE FROM rdeclarasubs WHERE idusuario = usuario;
select into pers persona.nombres, persona.apellido, tiposdoc.descrip as tipodoc from persona, tiposdoc where persona.tipodoc = $1 and persona.nrodoc =$2 and persona.barra= $3 and persona.tipodoc = tiposdoc.tipodoc;
if FOUND
  then--existe el titutal con lo que deberÃ­a tener una declaraciÃ³n jurada
	OPEN benef;
	FETCH benef INTO dec;
	resultado ='false';	
	WHILE  found LOOP
	      SELECT INTO tipodocbenef tiposdoc.descrip from tiposdoc WHERE tipodoc = dec.tipodoc;
	          INSERT INTO rdeclarasubs VALUES ($2,dec.nrodoc,dec.nro,dec.apellido,dec.nombres,dec.vinculo,dec.porcent,pers.tipodoc,usuario,tipodocbenef);
	      fetch benef into dec;
	      resultado ='true';	
	END LOOP;
	CLOSE benef;
  else --no hay una persona con los datos especificados como parÃ¡metros
  	resultado = 'false';
end if;

return resultado;
END;
$function$
