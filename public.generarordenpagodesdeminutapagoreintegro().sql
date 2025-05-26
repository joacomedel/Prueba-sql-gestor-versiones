CREATE OR REPLACE FUNCTION public.generarordenpagodesdeminutapagoreintegro()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD
	rlaminuta RECORD;
        rreintegro RECORD;
        
--VARIABLES 
	laordenpago VARCHAR;
	elidpagocontable VARCHAR;
        elidordenpagocontable  bigint;
        elidcentroordenpagocontable integer;
	idordenpago VARCHAR;
        obs varchar;
        pagoencaja boolean;
	respuesta varchar;
        rtaspestadominuta boolean;
--CURSORES
       creintegros refcursor; 
BEGIN
      SELECT INTO rlaminuta * FROM tempordenpago;

      SELECT INTO rtaspestadominuta * FROM verificarestadoordenpago(rlaminuta.nroordenpago, rlaminuta.idcentroordenpago, 2);
      IF (rtaspestadominuta) THEN 

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
	

	

	CREATE TEMP TABLE tempordenpagocontable(
				claveordenpagocontable VARCHAR ,  
				opcmontototal  double precision  ,
				opcmontoretencion  double precision  , 
				opcmontocontadootra  double precision  ,  
				idprestador bigint   , 
				opcmontochequeprop  double precision  ,
                                opcobservacion varchar,  
				opcfechaingreso date ,
				opcmontochequetercero  double precision );

	CREATE TEMP TABLE tretencionprestador (
				idtiporetencion BIGINT,
				rpfecha TIMESTAMP WITHOUT TIME ZONE DEFAULT ('now'::text)::date, 
				idprestador BIGINT,
				rpmontofijo DOUBLE PRECISION,
				rpmontoporc DOUBLE PRECISION,
				rpmontototal DOUBLE PRECISION,
				rpmontobase DOUBLE PRECISION,
				rpmontoretanteriores DOUBLE PRECISION) WITHOUT OIDS;

	
	  
	   OPEN creintegros FOR SELECT nroordenpago*100+idcentroordenpago as idoperacion, nroreintegro, anio, idcentroregional, rimporte,
			 concat('Reintegro ',lpad(concat(nroreintegro,'-', anio,'-', idcentroregional )::text,16,' '), ' Fecha ', rfechaingreso, ' del afiliado ',p.apellido, ',', p.nombres, ' Doc:', nrodoc, '. Liquidado sin OTP. ', concepto) as xobs, CASE WHEN mfpttfp.idformapagotipos=9 THEN 'CHPROP'  WHEN (mfpttfp.idformapagotipos=8  or mfpttfp.idformapagotipos=2) THEN 'CT/TRANS' END AS tipo,  NULL AS idvalorescaja,fpdescripcion AS descripcion, NULL AS idcuentabancaria, NULL as fechaemision ,rlaminuta.opcobservacion, rlaminuta.opcfechaingreso, idformapagotipos
		FROM reintegro NATURAL JOIN ordenpago  NATURAL JOIN tipoformapago NATURAL JOIN mapeoformapagotipostipoformapago AS mfpttfp NATURAL JOIN formapagotipos  NATURAL JOIN persona as p
		WHERE nroordenpago = rlaminuta.nroordenpago AND  idcentroordenpago = rlaminuta.idcentroordenpago; 
                --WHERE nroordenpago = 104807 AND  idcentroordenpago = 1  order by nroreintegro ; 
		FETCH creintegros into rreintegro;
		WHILE  FOUND LOOP



			INSERT INTO tempcomprobante (nrocomp, idcentrocomp, montopagar, montoretencion,apagarcomprobante, tipocomp, observacion, idprestador) 
		     VALUES(rlaminuta.nroordenpago, rlaminuta.idcentroordenpago, rreintegro.rimporte, 0, 0, 'Minuta ', concat('Pago ', rreintegro.xobs,' - Minuta: ' ,rlaminuta.nroordenpago, '|',rlaminuta.idcentroordenpago ), 2608);
			
			SELECT INTO laordenpago generarordenpagocontable();


			INSERT INTO ordenpagocontablereintegro(idordenpagocontable, idcentroordenpagocontable, nroreintegro, anio, idcentroregional, opcrconotp, opcrobservacion) 
	VALUES(	trim(split_part(laordenpago, '|', 1))::bigint,
                trim(split_part(laordenpago, '|', 2))::integer,
                rreintegro.nroreintegro, 
                rreintegro.anio, 
                rreintegro.idcentroregional,
                false, 
                concat('Insercion realizada en SP generarordenpagodesdeminutapagoreintegro el día ', now()));


	--Comento porque nunca se va  fptseaplica en caja
   /* SELECT INTO pagoencaja CASE WHEN (fptseaplica ilike '%Caja%') THEN true ELSE false end
    FROM valorescaja NATURAL JOIN formapagotipos WHERE idformapagotipos =rreintegro.idformapagotipos;
    IF pagoencaja THEN
        SELECT INTO obs opcobservacion FROM ordenpagocontable WHERE  idordenpagocontable=  trim(split_part(laordenpago, '|', 1))
            AND idcentroordenpagocontable= trim(split_part(laordenpago, '|', 2));
        INSERT INTO tempordenpagocontable (claveordenpagocontable,opcmontototal,idprestador,opcobservacion )
		       VALUES( replace(laordenpago, '|','-') ,rreintegro.rimporte,2608, obs);	

        INSERT INTO temppagoordenpagocontable (idvalorescaja, monto , observacion,tipo,idcuentabancaria,idchequera,fechacobro, fechaemision)
	           VALUES (rreintegro.idvalorescaja, rreintegro.rimporte, rreintegro.descripcion,rreintegro.descripcion,
	                  rreintegro.idcuentabancaria,rreintegro.nrocheque,rreintegro.fechaemision,rreintegro.fechaemision);
        SELECT INTO elidpagocontable * FROM guardarpagoordenpagocontable();
	 DELETE FROM temppagoordenpagocontable;
    END IF;
	     */
          DELETE FROM tempcomprobante;         
          DELETE FROM tempordenpagocontable;
          DELETE FROM tretencionprestador;
          
/*guardo los datos del pago*/

         SELECT INTO obs opcobservacion FROM ordenpagocontable WHERE  idordenpagocontable=  trim(split_part(laordenpago, '|', 1))
            AND idcentroordenpagocontable= trim(split_part(laordenpago, '|', 2));
        
        IF (iftableexistsparasp('temppagoordenpagocontable') ) THEN /*Hay datos del pago y los guardo*/
      
        	INSERT INTO tempordenpagocontable (idprestador , claveordenpagocontable,opcmontototal ,opcmontoretencion  , opcmontocontadootra , opcmontochequeprop , opcmontochequetercero ,opcobservacion,opcfechaingreso) VALUES( 2608,replace(laordenpago, '|','-'),
	rreintegro.rimporte,0,rreintegro.rimporte,0,0,obs,rreintegro.opcfechaingreso);


	       UPDATE temppagoordenpagocontable SET monto = rreintegro.rimporte;

	       SELECT INTO respuesta guardarpagoordenpagocontable() as comprobante;

	END IF;  
       
	FETCH creintegros into rreintegro;
          END LOOP;
          CLOSE creintegros;
  	 /*  KR 07-03-18 COmento porque ahora el asiento de devengamiento se genera cuando se crea la MP 

SELECT INTO obs  text_concatenar(concat('MP: ',rlaminuta.nroordenpago,'|', rlaminuta.idcentroordenpago,' Reintegro ', nroreintegro,'-', anio,'-', idcentroregional))
		FROM reintegro NATURAL JOIN ordenpago 
		WHERE nroordenpago = rlaminuta.nroordenpago  AND  idcentroordenpago = rlaminuta.idcentroordenpago; 

	  IF NOT  iftableexistsparasp('tasientogenerico') THEN 
		CREATE TEMP TABLE tasientogenerico(
				idoperacion bigint,
				idcentroperacion integer DEFAULT centro(),
				operacion varchar,
				fechaimputa date,
				obs varchar,
				idasientogenericocomprobtipo integer,
				centrocosto int	)WITHOUT OIDS;				
	ELSE 
		DELETE FROM tasientogenerico; 
	END IF;
          
          INSERT INTO tasientogenerico(idoperacion,fechaimputa,obs,idasientogenericocomprobtipo,centrocosto) 
			VALUES(	rlaminuta.nroordenpago*100+rlaminuta.idcentroordenpago, now(),concat('Devengamiento ',obs), 4,centro());

	  PERFORM asientogenerico_crear();
	  DELETE FROM tasientogenerico;
	*/
      END IF;
return true;   

END;
$function$
