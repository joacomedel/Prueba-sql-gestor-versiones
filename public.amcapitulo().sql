CREATE OR REPLACE FUNCTION public.amcapitulo()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	curtempcapitulo CURSOR FOR SELECT * FROM tempcapitulo WHERE nullvalue(error);
	
		
	capi		 RECORD;
	nomencla	 BOOLEAN;
	capitu		 BOOLEAN;
	resultado 	boolean;

BEGIN
	
	OPEN curtempcapitulo;	
	FETCH curtempcapitulo INTO capi;
	WHILE  found LOOP
		
	SELECT INTO nomencla * 
	FROM verificanomenclador(capi.idnomenclador,'tempcapitulo');

	if nomencla then

		SELECT INTO capitu * 
		FROM verificacapitulo(capi.idnomenclador,capi.idcapitulo,'tempcapitulo');

		if capitu then

		UPDATE capitulo 
		SET 	cdescripcion = capi.cdescripcion
		WHERE 	idnomenclador = capi.idnomenclador AND
			idcapitulo    = capi.idcapitulo;
        DELETE FROM tempcapitulo WHERE 	idnomenclador = capi.idnomenclador AND
                                        idcapitulo    = capi.idcapitulo;
		
		else

		INSERT INTO capitulo (idnomenclador, idcapitulo, cdescripcion )
		VALUES (capi.idnomenclador, capi.idcapitulo, capi.cdescripcion );
		DELETE FROM tempcapitulo WHERE 	idnomenclador = capi.idnomenclador AND
                                        idcapitulo    = capi.idcapitulo;
		end if;
	resultado = resultado and true;

	end if;
		
	

	FETCH curtempcapitulo INTO capi;
	END LOOP;
	CLOSE curtempcapitulo;

    return resultado;

END;
$function$
