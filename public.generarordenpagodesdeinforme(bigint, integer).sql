CREATE OR REPLACE FUNCTION public.generarordenpagodesdeinforme(bigint, integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD
	elregistro RECORD;
--VARIABLES 
	laordenpago VARCHAR;
	elidpagocontable VARCHAR;
        elnroinforme alias for $1;
        elcentroinforme alias for $2;
	idordenpago VARCHAR;
        obs varchar;
        pagoencaja boolean;
        resp BOOLEAN;
        diferencia double precision;
BEGIN

	
	SELECT INTO elregistro nroordenpago*100+idcentroordenpago as idoperacion,concat(nroordenpago,'-',idcentroordenpago) as monitaobs,
/* concat(tipocomprobante, tipofactura, lpad(nrosucursal, 4, '0') , lpad(nrofactura, 8, '0')) as idoperacion,*/  case when vc.idformapagotipos=9 then nrocupon end::bigint as nrocheque, CASE WHEN vc.idformapagotipos=9 THEN 'CHPROP'  WHEN (vc.idformapagotipos=8  or vc.idformapagotipos=2) THEN 'CT/TRANS' END AS tipo, concat('Reintegro ',nroreintegro,'-', anio,'-', idcentroregional, ' del afiliado ', c.denominacion, ' Doc:',
 nrodoc, '. Liquidado con la OTP ', tipocomprobante,'|',tipofactura,'|',nrosucursal,'|',nrofactura, '. Emitada el ', fechaemision ) as xobs, SUM(monto) as monto, fvc.nrocupon, nroordenpago, idcentroordenpago, vc.idvalorescaja, vc.descripcion, idcuentabancaria, fechaemision, nroreintegro, anio, idcentroregional
	FROM facturaventa as fv NATURAL JOIN informefacturacion as if NATURAL JOIN facturaventacupon AS fvc 
        JOIN cliente as c ON (fv.nrodoc= c.nrocliente AND fv.tipodoc= c.barra)
        JOIN informefacturacionexpendioreintegro AS ifex ON(if.nroinforme=ifex.nroinforme AND 
        if.idcentroinformefacturacion=ifex.idcentroinformefacturacion) NATURAL JOIN reintegro NATURAL JOIN ordenpago
        JOIN valorescaja AS vc USING (idvalorescaja) LEFT JOIN banco ON (autorizacion=idbanco) 
        
        LEFT JOIN cuentabancaria USING(idbanco)
	WHERE if.nroinforme = elnroinforme AND if.idcentroinformefacturacion=elcentroinforme 
	GROUP BY tipocomprobante, tipofactura, nrosucursal, nrofactura,vc.idformapagotipos, nroreintegro, anio, idcentroregional, fvc.nrocupon, nroordenpago, idcentroordenpago, vc.idvalorescaja, vc.descripcion, idcuentabancaria, fechaemision, c.denominacion, reintegro.nrodoc;
/*     EL asiento del devengamiento se hace cuando se genera la MP NO la OPC

         CREATE TEMP TABLE tasientogenerico(
				idoperacion bigint,
				idcentroperacion integer DEFAULT centro(),
				operacion varchar,
				fechaimputa date,
				obs varchar,
				idasientogenericocomprobtipo integer,
				centrocosto int	)WITHOUT OIDS;


	
	*/


        CREATE TEMP TABLE tempcomprobante (  
                      idcomprobante bigint, 
                      idcomprobantetipos integer,   
                      nrocomp varchar ,    
                      idcentrocomp INTEGER ,  
                      montopagar double precision ,  
                      montoretencion double precision,  
                      apagarcomprobante double precision,                       
                      tipocomp varchar,   
                      observacion varchar,   
                      iddeuda bigint,   
                      idcentrodeuda integer,   
                      idpago bigint,   
                      idcentropago integer,                       
                      idprestador bigint   
                       );    
	
	
	INSERT INTO tempcomprobante (nrocomp, idcentrocomp, montopagar, montoretencion,apagarcomprobante, tipocomp, observacion, idprestador) 
		     VALUES(elregistro.nroordenpago, elregistro.idcentroordenpago, elregistro.monto, 0, 0, 'Minuta ', concat('Pago ', elregistro.xobs,' - Minuta: ' ,elregistro.nroordenpago, '|',elregistro.idcentroordenpago ), 2608);

	SELECT INTO laordenpago generarordenpagocontable();
	
	CREATE TEMP TABLE temppagoordenpagocontable( 
				 idvalorescaja INTEGER ,
				  monto  double precision  ,
				  observacion VARCHAR ,
				  tipo VARCHAR,
				  idcuentabancaria INTEGER,
				  idchequera BIGINT ,
				  fechacobro VARCHAR ,
				  fechaemision VARCHAR ,
				  idcheque BIGINT ,
				  idcentrocheque INTEGER );

	CREATE TEMP TABLE tempordenpagocontable(
				claveordenpagocontable VARCHAR ,  
				opcmontototal  double precision  ,
				opcmontoretencion  double precision  , 
				opcmontocontadootra  double precision  ,  
				idprestador bigint   , 
				opcmontochequeprop  double precision  ,
                                opcobservacion varchar,  
				opcmontochequetercero  double precision   );

        CREATE TEMP TABLE tretencionprestador (
				idtiporetencion BIGINT,
				rpfecha TIMESTAMP WITHOUT TIME ZONE DEFAULT ('now'::text)::date, 
				idprestador BIGINT,
				rpmontofijo DOUBLE PRECISION,
				rpmontoporc DOUBLE PRECISION,
				rpmontototal DOUBLE PRECISION,
				rpmontobase DOUBLE PRECISION,
				rpmontoretanteriores DOUBLE PRECISION) WITHOUT OIDS;

	

	INSERT INTO ordenpagocontablereintegro(idordenpagocontable, idcentroordenpagocontable, nroreintegro, anio, idcentroregional, opcrconotp, opcrobservacion) 
	VALUES(	trim(split_part(laordenpago, '|', 1))::bigint,
                trim(split_part(laordenpago, '|', 2))::integer,
		elregistro.nroreintegro, 
                elregistro.anio, 
                elregistro.idcentroregional,
                true, 
                concat('Insercion realizada en SP generarordenpagodesdeinforme el día ', now()));
/* EL asiento del devengamiento se hace cuando se genera la MP NO la OPC

	INSERT INTO tasientogenerico(idoperacion,fechaimputa,obs,idasientogenericocomprobtipo,centrocosto) 
	VALUES(	elregistro.idoperacion,
		 
		elregistro.fechaemision,
		concat('Devengamiento ', ' | MP: ',elregistro.monitaobs,'|',elregistro.xobs),
		4,
		centro());

        PERFORM asientogenerico_crear();
      
        DROP TABLE tasientogenerico;
*/
    -- VAS 14-09-17 Si el pago se realizo por caja cargo los datos del pago cargo los datos del pagoordenpagocontable

    SELECT INTO pagoencaja CASE WHEN (fptseaplica ilike '%Caja%') THEN true ELSE false end
    FROM valorescaja NATURAL JOIN formapagotipos WHERE idvalorescaja = elregistro.idvalorescaja;
    IF pagoencaja THEN
        SELECT INTO obs opcobservacion FROM ordenpagocontable WHERE  idordenpagocontable=  trim(split_part(laordenpago, '|', 1))
            AND idcentroordenpagocontable= trim(split_part(laordenpago, '|', 2));
        INSERT INTO tempordenpagocontable (claveordenpagocontable,opcmontototal,idprestador,opcobservacion )
		       VALUES( replace(laordenpago, '|','-') ,elregistro.monto,2608, obs);	
        INSERT INTO temppagoordenpagocontable (idvalorescaja, monto , observacion,tipo,idcuentabancaria,idchequera,fechacobro, fechaemision)
	           VALUES (elregistro.idvalorescaja, elregistro.monto, elregistro.descripcion,elregistro.descripcion,
	                  elregistro.idcuentabancaria,elregistro.nrocheque,elregistro.fechaemision,elregistro.fechaemision);
        SELECT INTO elidpagocontable * FROM guardarpagoordenpagocontable();

        --KR 05-03-18 Cambio el estado pq en el sp de generarordenpagocontable no se cambia el estado ya que el pago aun no se guardo en la tabla  pagoordenpagocontable. Cambio el estado a la orden 3 liquidado si la suma de todos los pagos de la minuta coindice con el  importe total de la minuta
	            SELECT INTO diferencia  (MIN(importetotal) - SUM(popmonto))
                    FROM ordenpagocontableordenpago
                    JOIN pagoordenpagocontable using(idordenpagocontable,idcentroordenpagocontable)
                    JOIN ordenpago using (nroordenpago,idcentroordenpago)
                    JOIN ordenpagocontableestado using (idordenpagocontable,idcentroordenpagocontable)
                    WHERE nullvalue(opcfechafin) AND idordenpagocontableestadotipo <> 7
                          AND nroordenpago = elregistro.nroordenpago  AND idcentroordenpago = elregistro.idcentroordenpago
                    GROUP BY nroordenpago,idcentroordenpago;
                    IF diferencia <1 THEN
                	       SELECT INTO resp  cambiarestadoordenpago(elregistro.nroordenpago::bigint,elregistro.idcentroordenpago ,3,'Generado automaticamente generarordenpagodesdeinforme ');
                    END IF;    
    --KR 26-03-18 el estado de la OPC se cambia a ASENTADA, LAS OPC pagadas en efectivo tienen ese estado final
      SELECT INTO resp  cambiarestadoordenpagocontable(trim(split_part(laordenpago, '|', 1))::bigint,
                                    trim(split_part(laordenpago, '|', 2))::integer, 7, 'Generado desde SP generarordenpagodesdeinforme') ;



    END IF;
	
return elidpagocontable;   

END;
$function$
