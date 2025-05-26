CREATE OR REPLACE FUNCTION public.generarordenpagocontable()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       ctempcomprobante refcursor;
       uncomprobante record;
       crearordenpagocontable integer;
       elidordenpagocontable bigint;
       numregistro BIGINT;
       elanio integer;
       resp boolean;
       eltipoopc integer;
       obs varchar;
       laobservacion varchar;
       idcenopc integer;
       nroopc bigint;
       fechaop date;
      -- diferencia double precision;
BEGIN
        obs =' ';
	crearordenpagocontable = 1;
	OPEN ctempcomprobante FOR  SELECT * FROM tempcomprobante;
	FETCH ctempcomprobante into uncomprobante;
	WHILE FOUND LOOP
		IF (uncomprobante.tipocomp = 'FAC') THEN
			if not nullvalue(uncomprobante.nrocomp) then
				SELECT INTO numregistro split_part(uncomprobante.nrocomp, '-',1);
        	      		SELECT INTO elanio split_part(uncomprobante.nrocomp, '-',2);
        	      		eltipoopc = 1; -- Factura
	                    SELECT INTO obs concat(CASE WHEN nullvalue( nroordenpago) THEN '' ELSE concat(' MP:',nroordenpago::text,idcentroordenpago )  END,' // Pago de ',tipocomprobante.tipocomprobantedesc,' ',reclibrofact.clase,' ',reclibrofact.puntodeventa::text,'-',reclibrofact.numero::text )
				        FROM reclibrofact
                        JOIN tipocomprobante using (idtipocomprobante)
                        LEFT JOIN factura ON(factura.anio = reclibrofact.anio AND factura.nroregistro = reclibrofact.numeroregistro )
				        WHERE reclibrofact.numeroregistro=numregistro and reclibrofact.anio=elanio;
                                
            else
				obs = '- PAGO A CUENTA -';
			end if;
  	     ELSE
              if (uncomprobante.tipocomp = 'aCuenta') THEN
                     obs = ' - PAGO A CUENTA - ';
              ELSE
                     eltipoopc = 0;   -- Minuta
               		 select into obs concat (concat('MP: ',concat( concat( nroordenpago,'-'),idcentroordenpago),concepto))
                     from ordenpago where nroordenpago=uncomprobante.nrocomp and idcentroordenpago=uncomprobante.idcentrocomp;
                            --  VAS 16/08/ 2017
                     if not nullvalue(uncomprobante.observacion) then
                           select into obs concat('MP: ', uncomprobante.nrocomp,'|',uncomprobante.idcentrocomp,' ', uncomprobante.observacion);
                     end if;
        
               END IF;
       	END IF;

                
           	-- se guardan los datos de la orden pago contable
      	IF crearordenpagocontable =1 THEN
      	            IF existecolumtemp('tempcomprobante', 'fechaoperacion') THEN
      	                  fechaop = uncomprobante.fechaoperacion;
      	            ELSE
      	                  fechaop =now();
      	            END IF;
                    INSERT INTO ordenpagocontable(opcmontototal,opcmontoretencion,idprestador,idordenpagocontabletipo,opcobservacion,opcfechaingreso)
                   	       VALUES(uncomprobante.montopagar,uncomprobante.montoretencion,uncomprobante.idprestador, eltipoopc,obs,fechaop);
                   	crearordenpagocontable = 0;
                   	elidordenpagocontable= currval('ordenpagocontable_idordenpagocontable_seq');
			        SELECT INTO resp  cambiarestadoordenpagocontable(elidordenpagocontable, centro(), 1, obs) ;
         ELSE
                    UPDATE ordenpagocontable SET opcobservacion = concat( opcobservacion , obs)
                    WHERE idordenpagocontable = elidordenpagocontable AND idcentroordenpagocontable = centro();
		END IF;

            -- se guarda la relacion entre la ordenpagocontable y el comprobante
-- 		if not nullvalue(uncomprobante.nrocomp) then
 		if uncomprobante.nrocomp<>1 then
       		IF (uncomprobante.tipocomp = 'FAC')THEN
				IF not (uncomprobante.idcomprobantetipos=40) then
					-- ES FACTURA O NCREDITO
                    INSERT INTO ordenpagocontablereclibrofact(idordenpagocontable,idcentroordenpagocontable,numeroregistro,anio,montopagado)
                           VALUES (elidordenpagocontable,centro(),numregistro ,elanio,uncomprobante.apagarcomprobante);
				ELSE
					-- ES OPAGO
					nroopc = uncomprobante.idcomprobante/10;
					idcenopc =   uncomprobante.idcomprobante%10;                    			
					INSERT INTO ordenpagocontableacuenta(idordenpagocontable,idcentroordenpagocontable,idordenpagocontableacuenta,idcentroordenpagocontableacuenta,montopagado)
                  			VALUES (elidordenpagocontable,centro(),nrocomp,idcen,uncomprobante.apagarcomprobante);
				END IF;
			ELSE
				-- ES MINUTA
	                INSERT INTO ordenpagocontableordenpago (idordenpagocontable,idcentroordenpagocontable,nroordenpago,idcentroordenpago)
                		VALUES(elidordenpagocontable,centro(),uncomprobante.nrocomp::bigint,uncomprobante.idcentrocomp );
                	-- 15/11/17 cambio el estado a la orden 3 liquidado si la suma de todos los pagos de la minuta coindice con el  importe total de la minuta
	             /* KR 09-03-18 el control se hace en el guardarpagoordenpagocontable ya que en esta instancia la tabla pagoordenpagocontable no tiene datos
                    SELECT INTO diferencia  (MIN(importetotal) - SUM(popmonto))
                    FROM ordenpagocontableordenpago
                    JOIN pagoordenpagocontable using(idordenpagocontable,idcentroordenpagocontable)
                    JOIN ordenpago using (nroordenpago,idcentroordenpago)
                    JOIN ordenpagocontableestado using (idordenpagocontable,idcentroordenpagocontable)
                    WHERE nullvalue(opcfechafin) AND idordenpagocontableestadotipo <> 7
                          AND nroordenpago = uncomprobante.nrocomp::bigint  AND idcentroordenpago = uncomprobante.idcentrocomp
                    GROUP BY nroordenpago,idcentroordenpago;
                    IF diferencia <1 THEN
                	       SELECT INTO resp  cambiarestadoordenpago(uncomprobante.nrocomp::bigint,uncomprobante.idcentrocomp ,3,'Generado automaticamente generarordenpagocontable ');
                    END IF;                	
                    	*/
			END IF;
		end if;   
		FETCH ctempcomprobante into uncomprobante;
	END LOOP;
     	close ctempcomprobante;
     	return concat(elidordenpagocontable,'|',centro());
END;
$function$
