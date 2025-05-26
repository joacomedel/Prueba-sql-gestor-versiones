CREATE OR REPLACE FUNCTION public.generarordenpagocontable_multivac_limpiar()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       ctempcomprobante refcursor;
       uncomprobante record;
       
BEGIN
        OPEN ctempcomprobante FOR  SELECT * 
					FROM multivac_siges_pagos 
					WHERE not nullvalue(idordenpagocontable)
					--LIMIT 100
					;
	FETCH ctempcomprobante into uncomprobante;
	WHILE FOUND LOOP

		DELETE FROM ctactedeudapagoprestador WHERE (idpago,idcentropago) 
				IN (SELECT idpago,idcentropago 
					FROM ctactepagoprestador 
					WHERE idcomprobante = (uncomprobante.idordenpagocontable*10)+uncomprobante.idcentroordenpagocontable
					AND idcomprobantetipos = 40
					AND fechamovimiento = uncomprobante.fechaimputacion);
		
		DELETE FROM ctactepagoprestador 
				WHERE idcomprobante = (uncomprobante.idordenpagocontable*10)+uncomprobante.idcentroordenpagocontable
				AND idcomprobantetipos = 40
				AND fechamovimiento = uncomprobante.fechaimputacion;


		DELETE FROM pagoordenpagocontable 
				WHERE idordenpagocontable = uncomprobante.idordenpagocontable 
				AND idcentroordenpagocontable = uncomprobante.idcentroordenpagocontable ;

		DELETE FROM ordenpagocontableestado 
				WHERE idordenpagocontable = uncomprobante.idordenpagocontable 
					AND idcentroordenpagocontable = uncomprobante.idcentroordenpagocontable ; 
		DELETE FROM ordenpagocontable 
				WHERE idordenpagocontable = uncomprobante.idordenpagocontable 
				AND idcentroordenpagocontable = uncomprobante.idcentroordenpagocontable ;
        
			     
		UPDATE multivac_siges_pagos SET idordenpagocontable = null,idcentroordenpagocontable = null
 		WHERE idcomprobantecompras =uncomprobante.idcomprobantecompras 
			AND idcomprobantepago = uncomprobante.idcomprobantepago
			AND  fechaimputacion = uncomprobante.fechaimputacion
			AND montopagado = uncomprobante.montopagado;
			
	FETCH ctempcomprobante into uncomprobante;
	END LOOP;
     	close ctempcomprobante;
     	
	/*UPDATE ctactedeudaprestador SET saldo = t.saldo
			FROM ctactedeudaprestador_bk as t
			WHERE t.iddeuda=ctactedeudaprestador.iddeuda 
	and t.idcentrodeuda=ctactedeudaprestador.idcentrodeuda;*/
     	
     	return 'Listo';
END;
$function$
