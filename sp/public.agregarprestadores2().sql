CREATE OR REPLACE FUNCTION public.agregarprestadores2()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
*/
DECLARE
    rpres RECORD;
    idprest bigint;
    rprestador CURSOR FOR SELECT
    apellido,nombre,
    matprov,localidad,especialidad
    FROM temporalprestador;

BEGIN

OPEN rprestador;

FETCH rprestador INTO rpres;

WHILE  found LOOP

 SELECT INTO idprest max(idprestador)+1 FROM prestador;

 INSERT INTO prestador(idprestador,pdescripcion)
 VALUES (concat ( idprest,rpres.apellido,',',rpres.nombre));

 INSERT INTO profesional(idprestador,pnombres,papellido)
 VALUES(idprest,rpres.nombre,rpres.apellido);

 INSERT INTO matricula(nromatricula,malcance,idprestador,
 mespecialidad)
 VALUES(rpres.matprov,rpres.localidad,
 idprest,rpres.especialidad);

FETCH rprestador INTO rpres;
END LOOP;
CLOSE rprestador;
RETURN TRUE;
END;
$function$
