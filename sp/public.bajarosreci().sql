CREATE OR REPLACE FUNCTION public.bajarosreci()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursorosre CURSOR FOR SELECT * FROM temposreci;
	osre RECORD;
	barra integer;
BEGIN

    OPEN cursorosre;
    FETCH cursorosre into osre;
    WHILE  found LOOP
    	barra = osre.idosreci + 129;
        INSERT INTO osreci VALUES(osre.descrip,osre.tipo,osre.idosreci,osre.iddireccion,barra,osre.abreviatura,osre.tel);

    fetch cursorosre into osre;
    END LOOP;
    close cursorosre;

return 'true';
END;
$function$
