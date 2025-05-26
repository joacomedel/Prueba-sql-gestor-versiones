CREATE OR REPLACE FUNCTION public.generarordenpagocontable_multivac()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       ctempcomprobante refcursor;
       ctempcomprobantedeuda refcursor;
       uncomprobante record;
       uncomprobantedeuda record;
       elidordenpagocontable bigint;
       elidcentroordenpagocontable integer;
       elidpago bigint;	
       elcentroidpago integer;
       numregistro BIGINT;
       elanio integer;
       resp boolean;
       obs varchar;
       laobservacion varchar;
       idcenopc integer;
       nroopc bigint;
       fechaop date;
       vdiferencia double precision;
BEGIN
-- MaLaPi  04/04/2018 Se genera una OPC por cada OP en Multivac.

	OPEN ctempcomprobante FOR  select idcomprobantepago,montoordenpago,nroordenpago,sum(montopagado) as montopagado
					, count(*) as cantidaddeudas,min(observaciones) as tobservaciones,min(montoretenciones) as montoretenciones
					,max(mdp.fechaimputacion) as fechaimputacion,ccp.idprestador,ccp.idprestadorctacte
					from multivac_siges_pagos as mdp
					JOIN reclibrofact as f ON idcomprobantecompras = idcomprobantemultivac
					JOIN prestadorctacte as ccp USING(idprestador)
					JOIN ctactedeudaprestador ccdp ON (idcomprobante = (numeroregistro*10000+anio) 
					AND ccp.idprestadorctacte = ccdp.idprestadorctacte )
					WHERE nullvalue(idordenpagocontable) 
					GROUP BY ccp.idprestador,ccp.idprestadorctacte,idcomprobantepago,montoordenpago,nroordenpago
					--LIMIT 10
					;

        FETCH ctempcomprobante into uncomprobante;
	WHILE FOUND LOOP
	obs = concat('- Pago generedo usando informacion de Multivac -',uncomprobante.tobservaciones);
	fechaop = uncomprobante.fechaimputacion;
           	-- se guardan los datos de la orden pago contable
      	INSERT INTO ordenpagocontable(opcmontototal,opcmontoretencion,idprestador,idordenpagocontabletipo,opcobservacion,opcfechaingreso)
        VALUES(uncomprobante.montoordenpago,0,uncomprobante.idprestador, 2,obs,fechaop);

        elidordenpagocontable= currval('ordenpagocontable_idordenpagocontable_seq');
	elidcentroordenpagocontable = centro();
	SELECT INTO resp  cambiarestadoordenpagocontable(elidordenpagocontable, centro(), 1, obs) ;
	SELECT INTO resp  cambiarestadoordenpagocontable(elidordenpagocontable, centro(), 8, 'Estado generado para desaparecer OPC generadas solo a los efectos de generar pagos que vienen desde OP de Multivac') ;
        
	obs = concat(obs,'Monto de Retenciones: ',uncomprobante.montoretenciones,'- Para ver la informacion de como se pago, mirarlo en Multivac');
	-- MaLapi Genero el Valor Caja 161 -(Para info pago multivac)
	INSERT INTO pagoordenpagocontable(idordenpagocontable, idcentroordenpagocontable, popmonto, popobservacion,idvalorescaja)
            VALUES(elidordenpagocontable,elidcentroordenpagocontable,uncomprobante.montoordenpago ,obs ,161);

	   -- Genero el Pago en la Cta.Cte.
	   INSERT INTO ctactepagoprestador(fechamovimiento,idcomprobantetipos,idprestadorctacte,movconcepto,nrocuentac,importe,idcomprobante, saldo)
           VALUES(fechaop,40,uncomprobante.idprestadorctacte,concat('Generacion OPC:',obs),555,uncomprobante.montoordenpago*-1,(elidordenpagocontable*10)+elidcentroordenpagocontable,0);
           elidpago = currval('ctactepagoprestador_idpago_seq');
	   elcentroidpago = centro();

           OPEN ctempcomprobantedeuda FOR  SELECT * 
						FROM multivac_siges_pagos as mdp  
						JOIN reclibrofact as f ON idcomprobantecompras = idcomprobantemultivac
						JOIN prestadorctacte as ccp USING(idprestador)
						JOIN ctactedeudaprestador ccdp ON (idcomprobante = (numeroregistro*10000+anio) 
							AND ccp.idprestadorctacte = ccdp.idprestadorctacte )
						WHERE idcomprobantepago =uncomprobante.idcomprobantepago;

			FETCH ctempcomprobantedeuda into uncomprobantedeuda;
			WHILE FOUND LOOP
				vdiferencia = round(CASE WHEN (uncomprobantedeuda.saldo < uncomprobantedeuda.montopagado)
						THEN uncomprobantedeuda.saldo ELSE uncomprobantedeuda.montopagado END::numeric,2);
				-- se guarda la relacion entre la ordenpagocontable y el comprobante
				UPDATE multivac_siges_pagos SET idordenpagocontable = elidordenpagocontable ,idcentroordenpagocontable = elidcentroordenpagocontable
				WHERE idcomprobantecompras = uncomprobantedeuda.idcomprobantecompras 
					AND idcomprobantepago = uncomprobantedeuda.idcomprobantepago
					AND fechaimputacion = uncomprobantedeuda.fechaimputacion
					AND montopagado = uncomprobantedeuda.montopagado;
			   -- Genero la imputacion
			   -- vincula la deuda con el pago
			   INSERT INTO ctactedeudapagoprestador(fechamovimientoimputacion,idpago,iddeuda,idcentrodeuda,idcentropago,importeimp,idimputacion)
			   VALUES(fechaop,elidpago,uncomprobantedeuda.iddeuda,uncomprobantedeuda.idcentrodeuda,elcentroidpago,vdiferencia,nextval('ctactedeudapagoprestador_idimputacion_seq'));
			   -- Actualizo el saldo de la deuda
			   UPDATE ctactedeudaprestador SET saldo = round((saldo - vdiferencia)::numeric,2)
			     WHERE iddeuda=uncomprobantedeuda.iddeuda and idcentrodeuda =uncomprobantedeuda.idcentrodeuda;

		FETCH ctempcomprobantedeuda into uncomprobantedeuda;
		END LOOP;
		close ctempcomprobantedeuda;
     	
		
	FETCH ctempcomprobante into uncomprobante;
	END LOOP;
     	close ctempcomprobante;
     	return 'Listo';
END;
$function$
