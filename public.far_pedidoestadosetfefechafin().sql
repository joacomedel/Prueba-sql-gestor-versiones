CREATE OR REPLACE FUNCTION public.far_pedidoestadosetfefechafin()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE

  rpedidoestado RECORD;
  rregistro RECORD;
BEGIN
   
   SELECT INTO rpedidoestado count(*), idpedido, idcentropedido,min(idestadotipo) AS idestadotipo
                                  FROM far_pedidoestado 
                                  WHERE nullvalue(pefechafin) AND idpedido = NEW.idpedido AND 
                                  far_pedidoestado.idcentropedido =  NEW.idcentropedido
                                  GROUP BY idpedido, idcentropedido
                                  HAVING count(*)>1
                                  ORDER BY idpedido;
   IF found THEN
           SELECT INTO rregistro * FROM far_pedidoestado
           WHERE far_pedidoestado.idpedido =  NEW.idpedido AND 
           far_pedidoestado.idcentropedido =  NEW.idcentropedido
           AND nullvalue(far_pedidoestado.pefechafin)  AND idestadotipo=rpedidoestado.idestadotipo 
           limit 1; 

           UPDATE far_pedidoestado SET pefechafin = now()
           WHERE far_pedidoestado.idpedido = NEW.idpedido AND 
           far_pedidoestado.idcentropedido =  NEW.idcentropedido
           AND nullvalue(far_pedidoestado.pefechafin)  AND idestadotipo=rpedidoestado.idestadotipo 
           AND idpedidoestado=rregistro.idpedidoestado;

   END IF;

 RETURN NEW;
END;
$function$
