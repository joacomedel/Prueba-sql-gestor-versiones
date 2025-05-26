CREATE OR REPLACE FUNCTION public.cambiarestadoinformefacturacion(integer, integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

    
/* Se cierra un informe
 * Se pasan por parametro el nro  de informe y el centro del mismo  y el nuevo estado al cual va a estar el informe
*/

BEGIN

   -- Cambio el estado del informe de facturacion al que pasa por parametro $3

             UPDATE informefacturacionestado
             SET fechafin=NOW()
             WHERE nroinforme=$1 and idcentroinformefacturacion=$2 and nullvalue(fechafin);

             INSERT INTO informefacturacionestado (nroinforme,idcentroinformefacturacion,idinformefacturacionestadotipo,fechaini,descripcion)
             VALUES($1,$2,$3,NOW(),$4);

return true;
END;

$function$
