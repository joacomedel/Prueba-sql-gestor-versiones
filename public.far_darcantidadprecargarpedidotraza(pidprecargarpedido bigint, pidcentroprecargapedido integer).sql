CREATE OR REPLACE FUNCTION public.far_darcantidadprecargarpedidotraza(pidprecargarpedido bigint, pidcentroprecargapedido integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$DECLARE

       pcantidad INTEGER;


BEGIN


SELECT INTO pcantidad count(*) as  cant 
	 	FROM far_precargarpedidotraza 
		WHERE idprecargarpedido = pidprecargarpedido 
	              AND idcentroprecargapedido = pidcentroprecargapedido
                      AND not pptborrado
group by  idprecargarpedido,idcentroprecargapedido;



IF nullvalue(pcantidad) THEN
pcantidad = 0;
END IF;

RETURN pcantidad;
END;
$function$
