CREATE OR REPLACE FUNCTION public.arreglo_darvalorclave(elarreglo text[], laclave character varying, delimitador character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
    salida boolean;
    elemento text[];
    i integer;
    result varchar;
    claveelem  varchar;
    valorelem varchar;
BEGIN
/*
* se recorre un arreglo donde en cada posicion del arreglo se encuentra un elemento de la siguiente forma:
* clave@valorclave.
* retorna el valorclave para la clave recibida por parametro
*/

         i= array_lower(elarreglo,1);
         result = '';
         WHILE ((i <=  array_upper(elarreglo,1) )
            and length(result)=0)  LOOP

                 elemento = string_to_array(elarreglo[i], delimitador);
                 claveelem = trim(both ' ' from elemento[1] );
                 valorelem = trim(both ' ' from elemento[2] );
                 if (laclave ilike claveelem) THEN
                        result = valorelem;
                 END IF;

                 i= i+1;
         END LOOP;

RETURN 	result;
END;
$function$
