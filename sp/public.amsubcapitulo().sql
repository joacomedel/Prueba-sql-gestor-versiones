CREATE OR REPLACE FUNCTION public.amsubcapitulo()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	curtempsubcapitulo CURSOR FOR SELECT * FROM tempsubcapitulo;
	
		
	subcapi RECORD;
	nomencla   VARCHAR;
	capitu	   VARCHAR;
	subcapitu    VARCHAR;
	
BEGIN
	OPEN curtempsubcapitulo;	
	FETCH curtempsubcapitulo INTO subcapi;
	WHILE  found LOOP

	SELECT INTO nomencla * 
	FROM verificanomenclador(subcapi.idnomenclador,'tempsubcapitulo');

	if nomencla then

		SELECT INTO capitu * 
		FROM verificacapitulo(subcapi.idnomenclador,subcapi.idcapitulo,'tempsubcapitulo');

		if capitu then

			SELECT INTO subcapitu * 
			FROM verificasubcapitulo(subcapi.idnomenclador,subcapi.idcapitulo,subcapi.idsubcapitulo,'tempsubcapitulo');
			
			if subcapitu then

				UPDATE subcapitulo 
				SET    scdescripcion  = subcapi.scdescripcion
				WHERE 	idnomenclador = subcapi.idnomenclador AND
					idcapitulo    = subcapi.idcapitulo AND
					idsubcapitulo = subcapi.idsubcapitulo ;
	
	
				else
	
				INSERT INTO subcapitulo (idnomenclador,idcapitulo,idsubcapitulo, scdescripcion)
				VALUES (subcapi.idnomenclador,subcapi.idcapitulo,subcapi.idsubcapitulo, subcapi.scdescripcion);
			
				end if;
	
			DELETE FROM tempsubcapitulo
			WHERE 	idnomenclador = subcapi.idnomenclador AND
				idcapitulo    = subcapi.idcapitulo AND
				idsubcapitulo = subcapi.idsubcapitulo ;
	
			end if;
		end if;

	FETCH curtempsubcapitulo INTO subcapi;
	END LOOP;
	CLOSE curtempsubcapitulo;

    return true;


END;
$function$
