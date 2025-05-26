CREATE OR REPLACE FUNCTION public.ponercomosincronizablepedido()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

  	respuesta boolean;
	
	
BEGIN

     respuesta = FALSE;
    SELECT * FROM agregarsincronizable('far_pedido');
SELECT * FROM agregarsincronizable('far_pedidoitems');
SELECT * FROM agregarsincronizable('far_pedidoestado');

RETURN respuesta;
END;
$function$
