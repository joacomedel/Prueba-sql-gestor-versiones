CREATE OR REPLACE FUNCTION public.far_darcantidadarticulospedidos(particulo bigint)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$DECLARE

       particulo alias for $1;
       pcantidad INTEGER;


BEGIN

SELECT INTO pcantidad sum(picantidad) as picantidad
FROM far_pedidoitems fpi
JOIN  far_pedidoestado fpe ON fpi.idpedido = fpe.idpedido and nullvalue(pefechafin)
WHERE idestadotipo <> 3 AND idestadotipo <> 5 AND idarticulo = particulo
GROUP BY idarticulo;

IF nullvalue(pcantidad) THEN
pcantidad = 0;
END IF;

RETURN pcantidad;
END;

$function$
