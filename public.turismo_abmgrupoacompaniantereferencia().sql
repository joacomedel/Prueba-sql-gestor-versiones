CREATE OR REPLACE FUNCTION public.turismo_abmgrupoacompaniantereferencia()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	
	resultado RECORD;
	rusuario RECORD;
	elcursor refcursor;
	elem RECORD;
        esinvitado boolean;
BEGIN

esinvitado = true;

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

SELECT INTO elem * FROM grupoacompaniantereferencia_temp WHERE not (nrodoctitular is null) LIMIT 1;
IF FOUND THEN 

	INSERT INTO grupoacompaniantereferencia(nrodoctitular,tipodoctitular,nrodoc,tipodoc, garcorreo,gartelefonocontacto,garnombres,garapellido
	,garfechacnac,idvinculo,garinvitado,garactivo)(
	SELECT bf.nrodoctitu,bf.tipodoctitu,bf.nrodoc,bf.tipodoc, null as garcorreo,null as gartelefonocontacto,pe.nombres,pe.apellido
	,pe.fechanac,0 as idvinculo,false as garinvitado,true as garactivo
	FROM benefsosunc as bf
	NATURAL JOIN persona as pe
	LEFT JOIN grupoacompaniantereferencia as gar ON gar.nrodoctitular =bf.nrodoctitu 
						AND gar.tipodoctitular = bf.tipodoctitu 
						AND gar.nrodoc = bf.nrodoc AND gar.tipodoc = bf.tipodoc
	WHERE nullvalue(gar.nrodoc) AND nrodoctitu = elem.nrodoctitular AND tipodoctitu = elem.tipodoctitular
	UNION 
	SELECT pe.nrodoc,pe.tipodoc,pe.nrodoc,pe.tipodoc, null as garcorreo,null as gartelefonocontacto,pe.nombres,pe.apellido
	,pe.fechanac,0 as idvinculo,false as garinvitado,true as garactivo
	FROM persona as pe
	LEFT JOIN grupoacompaniantereferencia as gar ON gar.nrodoctitular =pe.nrodoc 
						AND gar.tipodoctitular = pe.tipodoc
						AND gar.nrodoc = pe.nrodoc AND gar.tipodoc = pe.tipodoc
	WHERE nullvalue(gar.nrodoc) AND pe.nrodoc = elem.nrodoctitular AND pe.tipodoc = elem.tipodoctitular
	);

END IF; 
OPEN elcursor FOR SELECT *
		FROM grupoacompaniantereferencia_temp WHERE not nullvalue(garnombres);
		
FETCH elcursor into elem;
WHILE  found LOOP

	SELECT INTO resultado * FROM persona WHERE nrodoc = elem.nrodoc AND tipodoc = elem.tipodoc;
	IF FOUND THEN 
	  esinvitado = false;
	END IF;

	SELECT INTO resultado * FROM grupoacompaniantereferencia 
				WHERE nrodoc = elem.nrodoc AND tipodoc = elem.tipodoc
					AND nrodoctitular = elem.nrodoctitular 
					AND tipodoctitular = elem.tipodoctitular;
        IF FOUND THEN 
		UPDATE grupoacompaniantereferencia SET 
			 garcorreo = elem.garcorreo,
			 gartelefonocontacto= elem.gartelefonocontacto,
			 garnombres = elem.garnombres ,
			 garapellido = elem.garapellido ,
			 garfechacnac = elem.garfechacnac,
			 idvinculo = 0,
			 garinvitado = esinvitado,
			 garactivo =  elem.garactivo
		WHERE nrodoc = elem.nrodoc AND tipodoc = elem.tipodoc
					AND nrodoctitular = elem.nrodoctitular 
					AND tipodoctitular = elem.tipodoctitular;
        ELSE 
		INSERT INTO grupoacompaniantereferencia(nrodoctitular,tipodoctitular,nrodoc,tipodoc, garcorreo,gartelefonocontacto,garnombres,garapellido,garfechacnac,idvinculo,garinvitado,garactivo) 
		VALUES(elem.nrodoctitular,elem.tipodoctitular,elem.nrodoc,elem.tipodoc,elem.garcorreo,elem.gartelefonocontacto,elem.garnombres,elem.garapellido,elem.garfechacnac,0,esinvitado,true);
        
        END IF;
	
fetch elcursor into elem;
END LOOP;
close elcursor;		




return 'true';
END;
$function$
