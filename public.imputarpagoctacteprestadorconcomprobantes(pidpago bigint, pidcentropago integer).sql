CREATE OR REPLACE FUNCTION public.imputarpagoctacteprestadorconcomprobantes(pidpago bigint, pidcentropago integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       ctempcomprobante refcursor;
       uncomprobante record;
       resp boolean;
       obs varchar;
       diferencia double precision;
       
BEGIN
        obs =' ';
	OPEN ctempcomprobante FOR  SELECT 
				ccdpp.importeimp
				,op.nroordenpago,op.idcentroordenpago,op.importetotal
				,rlf.clase,rlf.puntodeventa,rlf.numero,tc.tipocomprobantedesc
                                ,rlf.numeroregistro as nroregistro,rlf.anio,opc.idordenpagocontable,opc.idcentroordenpagocontable
				,CASE WHEN nullvalue(opcop.idordenpagocontable) THEN false ELSE true END as conrel_opcop 
				,CASE WHEN nullvalue(op.nroordenpago) THEN false ELSE true END as conrel_minuta
				,CASE WHEN nullvalue(opcrlf.idordenpagocontable) AND not nullvalue(rlf.numeroregistro) THEN false ELSE true END as conrel_opcrlf
				FROM ctactedeudaprestador as ccdp
				JOIN ctactedeudapagoprestador as ccdpp USING(iddeuda,idcentrodeuda)
				JOIN ctactepagoprestador  as pago USING(idpago,idcentropago)
				JOIN ordenpagocontable as opc on (pago.idcomprobante=opc.idordenpagocontable*10+opc.idcentroordenpagocontable and pago.idcomprobantetipos=40)
				LEFT JOIN ordenpagocontablereclibrofact as opcrlf using (idordenpagocontable,idcentroordenpagocontable)
				LEFT JOIN factura as f ON (f.nroregistro*10000+f.anio=ccdp.idcomprobante)
				LEFT JOIN reclibrofact as rlf ON (rlf.numeroregistro*10000+rlf.anio=ccdp.idcomprobante)
				LEFT JOIN tipocomprobante tc ON (rlf.idtipocomprobante = tc.idtipocomprobante)
				LEFT JOIN ordenpago as op ON (f.nroordenpago=op.nroordenpago AND f.idcentroordenpago = op.idcentroordenpago)
				LEFT JOIN ordenpagocontableordenpago as opcop using (idordenpagocontable,idcentroordenpagocontable)

				WHERE idpago = pidpago and idcentropago = pidcentropago
				GROUP BY 
				importeimp,rlf.clase,rlf.puntodeventa,rlf.numero,tipocomprobantedesc,op.importetotal,rlf.numeroregistro,rlf.anio,idordenpagocontable,idcentroordenpagocontable,op.nroordenpago,op.idcentroordenpago,conrel_opcop,conrel_minuta,conrel_opcrlf,pago.idpago,pago.idcentropago;

	FETCH ctempcomprobante into uncomprobante;
	WHILE FOUND LOOP
		SELECT INTO obs concat(
			CASE WHEN nullvalue(uncomprobante.nroordenpago) THEN '' 
			ELSE concat(' Al Imputar un Pago a Cuenta: MP:',uncomprobante.nroordenpago::text,uncomprobante.idcentroordenpago)  END
                              ,' // Pago de ',uncomprobante.tipocomprobantedesc,' ',uncomprobante.clase,' ',uncomprobante.puntodeventa::text,'-',uncomprobante.numero::text );
		IF NOT uncomprobante.conrel_opcop AND uncomprobante.conrel_minuta THEN 
			UPDATE ordenpagocontableordenpago SET nroordenpago =  uncomprobante.nroordenpago 
				WHERE nroordenpago = uncomprobante.nroordenpago 
					AND idcentroordenpago = uncomprobante.idcentroordenpago
					AND idordenpagocontable = uncomprobante.idordenpagocontable 
					AND idcentroordenpagocontable = uncomprobante.idcentroordenpagocontable;
			IF NOT FOUND THEN 
				INSERT INTO ordenpagocontableordenpago (idordenpagocontable,idcentroordenpagocontable,nroordenpago,idcentroordenpago)
				VALUES(uncomprobante.idordenpagocontable,uncomprobante.idcentroordenpagocontable,uncomprobante.nroordenpago,uncomprobante.idcentroordenpago);
				UPDATE ordenpago SET concepto = concat(concepto , obs)
					WHERE nroordenpago = uncomprobante.nroordenpago 
					AND idcentroordenpago = uncomprobante.idcentroordenpago;
			END IF;
			

		    SELECT INTO diferencia  (MIN(importetotal) - SUM(popmonto))
                    FROM ordenpagocontableordenpago
                    JOIN pagoordenpagocontable using(idordenpagocontable,idcentroordenpagocontable)
                    JOIN ordenpago using (nroordenpago,idcentroordenpago)
                    JOIN ordenpagocontableestado using (idordenpagocontable,idcentroordenpagocontable)
                    WHERE nullvalue(opcfechafin) AND idordenpagocontableestadotipo <> 7
                          AND nroordenpago = uncomprobante.nroordenpago  AND idcentroordenpago = uncomprobante.idcentroordenpago
                    GROUP BY nroordenpago,idcentroordenpago;
			IF diferencia < 1 THEN
                	       SELECT INTO resp  cambiarestadoordenpago(uncomprobante.nroordenpago,uncomprobante.idcentroordenpago,3,'Generado automaticamente al imputar un pago desde la cta.cte ');
			END IF;    

		END IF;

		IF NOT uncomprobante.conrel_opcrlf THEN 
		     UPDATE ordenpagocontablereclibrofact SET montopagado = abs(uncomprobante.importeimp)
				WHERE idordenpagocontable = uncomprobante.idordenpagocontable
					AND idcentroordenpagocontable = uncomprobante.idcentroordenpagocontable
					AND numeroregistro = uncomprobante.nroregistro
					AND anio = uncomprobante.anio;
		     IF NOT FOUND THEN 
			INSERT INTO ordenpagocontablereclibrofact(idordenpagocontable,idcentroordenpagocontable,numeroregistro,anio,montopagado)
			VALUES (uncomprobante.idordenpagocontable,uncomprobante.idcentroordenpagocontable,uncomprobante.nroregistro,uncomprobante.anio,uncomprobante.importeimp);
		     END IF;
		END IF;
                     
		    UPDATE ordenpagocontable SET opcobservacion = concat(opcobservacion , obs)
                    WHERE idordenpagocontable = uncomprobante.idordenpagocontable 
			AND idcentroordenpagocontable = uncomprobante.idcentroordenpagocontable;
	FETCH ctempcomprobante into uncomprobante;
	END LOOP;
     	close ctempcomprobante;
     	return true;
END;
$function$
