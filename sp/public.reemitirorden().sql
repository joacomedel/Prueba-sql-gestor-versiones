CREATE OR REPLACE FUNCTION public.reemitirorden()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
valorizada CURSOR FOR
             SELECT *
                    FROM ttvalorizada;
nuevas CURSOR FOR
             SELECT *
                    FROM ttordenesgeneradas;
dato record;
nueva record;
respuesta boolean;

BEGIN
     respuesta=false;
-- Llama a asentarvalorizada()
   PERFORM asentarvalorizada();
   open nuevas;
   fetch nuevas into nueva;

-- Actualiza Orden valorizada
   open valorizada;
   fetch valorizada into dato;	
			--la orden reemitida guarda una referencia a la orden nueva
            UPDATE ordvalorizada
                   SET ordenreemitida = nueva.nroorden,
                       centroreemitida = nueva.centro
                   WHERE centro=dato.centroreemitida AND nroorden=dato.ordenreemitida;
			--la orden nueva guarda una referencia a si misma, para no permitir que sea reemitida
            UPDATE ordvalorizada
                   SET ordenreemitida = nueva.nroorden, 
                       centroreemitida = nueva.centro
                   WHERE nroorden=nueva.nroorden AND centro = nueva.centro;
            -- actualiza el consumo para que quede anulado
	        UPDATE consumo
                   SET anulado = true
                   WHERE nroorden=dato.ordenreemitida AND centro = dato.centroreemitida;
            INSERT into ordenesreemitidas
                   VALUES (nueva.nroorden,nueva.centro,dato.ordenreemitida); 	
   respuesta = true;
   close valorizada;
   close nuevas;
   return respuesta;
END;
$function$
