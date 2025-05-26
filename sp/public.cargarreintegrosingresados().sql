CREATE OR REPLACE FUNCTION public.cargarreintegrosingresados()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Ingresa todss los reintegros ingresados por mesa de entrada en las tablas de reintegros para poder
ser auditadas por el modulo de Reintegros. */
DECLARE
    rreintegro RECORD;
    alta refcursor;
    rresultado boolean;

BEGIN
OPEN alta FOR SELECT *
               FROM recepcion
               NATURAL JOIN recreintegro WHERE idrecepcion >=10000;

FETCH alta INTO rreintegro;
WHILE  found LOOP
       SELECT INTO rresultado * FROM insertarreintegro(cast(rreintegro.idrecepcion as INTEGER));
FETCH alta INTO rreintegro;
END LOOP;
CLOSE alta;
RETURN rresultado;
END;
$function$
