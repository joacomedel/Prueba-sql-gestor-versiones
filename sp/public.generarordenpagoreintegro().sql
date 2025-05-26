CREATE OR REPLACE FUNCTION public.generarordenpagoreintegro()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Genera una orden para pagar un conjunto de reintegros, realizando el cambio de estados para los
mismos.*/

DECLARE
	reintegros refcursor;
	unreintegro RECORD;
	resultado boolean;
	elregistro RECORD;
        temporegistro RECORD;
BEGIN
/*Llamo para que se inserte la Orden de Pago*/

IF not existecolumtemp('tempordenpago', 'idordenpagotipo') THEN 
        ALTER TABLE tempordenpago ADD COLUMN idordenpagotipo integer DEFAULT 2;
END IF;

IF not iftableexistsparasp('tasientogenerico') THEN
 
      CREATE TEMP TABLE tasientogenerico(
				idoperacion bigint,
				idcentroperacion integer DEFAULT centro(),
				operacion varchar,
				
				obs varchar,
				idasientogenericocomprobtipo integer,
				centrocosto int	)WITHOUT OIDS;

ELSE
      DROP TABLE tasientogenerico;
      CREATE TEMP TABLE tasientogenerico(
				idoperacion bigint,
				idcentroperacion integer DEFAULT centro(),
				operacion varchar,
				
				obs varchar,
				idasientogenericocomprobtipo integer,
				centrocosto int	)WITHOUT OIDS;

END IF;







SELECT INTO resultado * FROM generarordenpago();

SELECT INTO temporegistro * FROM tempreintegro;


if resultado THEN


	SELECT INTO elregistro  rfechaingreso , tempreintegro.nroordenpago*100+ centro() as idoperacion, concat(tempreintegro.nroordenpago,'-', centro()) as monitaobs, concat('Reintegro ',lpad(concat(r.nroreintegro,'-', r.anio,'-', r.idcentroregional )::text,16,' '), ' Fecha ', rfechaingreso, ' del afiliado ',p.apellido, ',', p.nombres, ' Doc:', p.nrodoc, 
	(CASE WHEN nullvalue (fv.nrofactura) THEN  concat('. Liquidado sin OTP. ', concepto) 
	ELSE concat('. Liquidado con la OTP ', tipocomprobante,'|',tipofactura,'|',nrosucursal,'|',nrofactura, '. Emitada el ', fechaemision ) 	END) ) as xobs, fv.fechaemision,  tempreintegro.nroordenpago, centro() as idcentroordenpago

		FROM reintegro AS r NATURAL JOIN persona as p
                JOIN tempreintegro ON (r.nroreintegro= tempreintegro.nroreintegro AND r.anio=tempreintegro.anio AND r.idcentroregional=tempreintegro.centroregional ) 
JOIN ordenpago ON (tempreintegro.nroordenpago= ordenpago.nroordenpago AND centro()= ordenpago.idcentroordenpago)
	        LEFT JOIN informefacturacionexpendioreintegro AS ifer ON  (r.nroreintegro= ifer.nroreintegro AND r.anio=ifer.anio AND r.idcentroregional=ifer.idcentroregional)                 
		LEFT JOIN informefacturacion AS if USING(nroinforme, idcentroinformefacturacion) 
		LEFT JOIN facturaventa AS fv  USING (nrofactura, tipocomprobante, nrosucursal, tipofactura);
	-- hasta 16/08/18 fechaimputa = elregistro.rfechaingreso a partir de ahora el asiento tomara la fecha de la minuta

	INSERT INTO tasientogenerico(idoperacion,obs,idasientogenericocomprobtipo,centrocosto) 
	VALUES(	elregistro.idoperacion,		 
		
		concat('Devengamiento ', ' | MP: ',elregistro.monitaobs,'|',elregistro.xobs),
		4,
		centro());

        PERFORM asientogenerico_crear();
      
        DROP TABLE tasientogenerico;

       --cambio el estado de la MP a Liquidable (se envio a pagar)
        SELECT INTO resultado cambiarestadoordenpago(temporegistro.nroordenpago::bigint,elregistro.idcentroordenpago ,2,'Generado automaticamente generarordenpagoreintegro ');




   /*Modifico el estado de los reintegros y su vinculacion a la Orden de pago*/

   OPEN reintegros FOR SELECT * FROM tempreintegro;
   FETCH reintegros INTO unreintegro;
	

   WHILE  found LOOP
   UPDATE reintegro  SET nroordenpago = unreintegro.nroordenpago
                      ,tipoformapago =unreintegro.tipoformapago
                      ,idcentroordenpago = centro()
                    
                      WHERE reintegro.nroreintegro = unreintegro.nroreintegro AND reintegro.anio =  unreintegro.anio and  idcentroregional = unreintegro.centroregional;
    /*El Reintegro se coloca en estado 3 - Liquidado*/
   INSERT INTO restados (fechacambio,nroreintegro,anio,tipoestadoreintegro,observacion,idcentroregional)
   VALUES (CURRENT_DATE,unreintegro.nroreintegro,unreintegro.anio,3,concat('Al ser generada La Minuta de Pago ',unreintegro.nroordenpago,'-',centro()),unreintegro.centroregional);
   FETCH reintegros INTO unreintegro;
   END LOOP;
   CLOSE reintegros;
   resultado = 'true';
END IF;

 
         
RETURN resultado;
END;$function$
