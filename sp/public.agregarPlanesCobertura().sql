CREATE OR REPLACE FUNCTION public."agregarPlanesCobertura"()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Agrega Todos los datos de los Planes de Cobertura en las tablas temporales */
DECLARE
       resultado  BOOLEAN;
       verifica record;

BEGIN
resultado = TRUE;
SELECT INTO verifica * FROM temptipoplancob WHERE nullvalue(temptipoplancob.error);
IF FOUND THEN /*Si hay datos en la tabla temporal lo llamo a cargar*/
   SELECT INTO resultado * FROM amtipoplancob();
END IF;
IF resultado THEN
   SELECT INTO verifica * FROM tempplancobertura WHERE nullvalue(tempplancobertura.error);
          IF FOUND THEN /*Si hay datos en la tabla temporal lo llamo a cargar*/
             SELECT INTO resultado * FROM amplancobertura();
          END IF;
END IF;
IF resultado THEN
   SELECT INTO verifica * FROM temppracticaplan WHERE nullvalue(temppracticaplan.error);
          IF FOUND THEN /*Si hay datos en la tabla temporal lo llamo a cargar*/
             SELECT INTO resultado * FROM ampracticaplan();
          END IF;
END IF;
IF resultado THEN
   SELECT INTO verifica * FROM tempplancobpersona WHERE nullvalue(tempplancobpersona.error);
          IF FOUND THEN /*Si hay datos en la tabla temporal lo llamo a cargar*/
             SELECT INTO resultado * FROM amplancobpersona();
          END IF;
END IF;
IF resultado THEN
   SELECT INTO verifica * FROM tempconvenioplancob WHERE nullvalue(tempconvenioplancob.error);
          IF FOUND THEN /*Si hay datos en la tabla temporal lo llamo a cargar*/
             SELECT INTO resultado * FROM amconvenioplancob();
          END IF;
END IF;
RETURN resultado;
END;
$function$
