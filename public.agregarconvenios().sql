CREATE OR REPLACE FUNCTION public.agregarconvenios()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Agrega Todos los datos de Convenios que se encuentren en las tablas temporales */
DECLARE
       resultado  BOOLEAN;

BEGIN
     SELECT INTO resultado * FROM amconvenio();
     IF resultado THEN
          SELECT INTO resultado * FROM amtipounidad();
     END IF;
     IF resultado THEN
          SELECT INTO resultado * FROM amtipovalor();
     END IF;
     IF resultado THEN
          SELECT INTO resultado * FROM amtablavalores();
     END IF;
     IF resultado THEN
          SELECT INTO resultado * FROM amasocconvenio();
     END IF;
     IF resultado THEN
          SELECT INTO resultado * FROM ampractconvval();
     END IF;
     IF resultado THEN
          SELECT INTO resultado * FROM amconvenioprestador();
     END IF;
     IF resultado THEN
          SELECT INTO resultado * FROM amconvenioplancob();
     END IF;
     
RETURN resultado;
END;
$function$
