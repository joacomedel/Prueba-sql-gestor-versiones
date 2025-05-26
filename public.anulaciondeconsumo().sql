CREATE OR REPLACE FUNCTION public.anulaciondeconsumo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
       --unConsumo RECORD;
       recrecibo RECORD;
       respuesta bool;
       rusuario RECORD;
BEGIN
  /* New function body */
IF nullvalue(NEW.oeidusuario) THEN 
     SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
     IF NOT FOUND THEN 
              rusuario.idusuario = 25;
     END IF;
     UPDATE ordenestados SET oeidusuario = rusuario.idusuario 
             WHERE  ordenestados.nroorden = NEW.nroorden AND ordenestados.centro = NEW.centro AND idordenestadotipos = NEW.idordenestadotipos;
END IF;

  --SELECT INTO unConsumo * FROM consumo WHERE consumo.nroorden = new.nrooden;
  --DELETE FROM consumo WHERE consumo.nroorden = new.nroorden AND consumo.centro = NEW.centro;
IF (NEW.idordenestadotipos=2) THEN 
  UPDATE consumo SET anulado = TRUE WHERE consumo.nroorden = new.nroorden AND consumo.centro = NEW.centro;
--KR 26-09-19 Solo genero movimiento en la cta cte del afiliado si la orden no fue facturada, ej. ordenes de afiliados de reci con barra <>149 y <>131. Si la orden fue facturada el movimiento se genera con la NC de la FA.
 /* SELECT INTO recrecibo * FROM ordenrecibo WHERE ordenrecibo.nroorden = new.nroorden
                                                 AND ordenrecibo.centro = NEW.centro;
*/
--KR 25-06-20 modifique para que tbn se anule el consumo si corresponde ya sea pq la orden no se facturo o si se facturo se genero se anulo.  

SELECT INTO recrecibo * FROM orden NATURAL JOIN ordenrecibo LEFT JOIN facturaorden USING(nroorden, centro)  LEFT JOIN facturaventa USING(nrofactura, tipocomprobante, nrosucursal, tipofactura)
         WHERE ordenrecibo.nroorden = new.nroorden AND ordenrecibo.centro = NEW.centro  AND (nullvalue(nrofactura)  OR not nullvalue(anulada));
--KR 01-04-22 LO llamo si la orden no es de suap
  IF FOUND AND recrecibo.tipo <>56 THEN
       SELECT INTO respuesta * FROM asentarconsumoctactev2(recrecibo.idrecibo,recrecibo.centro,recrecibo.nroorden);
  END IF;

SELECT INTO respuesta * FROM alta_modifica_ficha_medica_orden_expendio(new.nroorden,new.centro);
END IF;

  RETURN NULL;
END;
$function$
