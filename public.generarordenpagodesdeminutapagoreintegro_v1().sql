CREATE OR REPLACE FUNCTION public.generarordenpagodesdeminutapagoreintegro_v1()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD
	rlaminuta RECORD;
        rreintegro RECORD;
        rpagoopc RECORD;
--VARIABLES 
	laordenpago VARCHAR;
	elidpagocontable VARCHAR;
        elidordenpagocontable  bigint;
        elidcentroordenpagocontable integer;
	idordenpago VARCHAR;
        obs varchar;
        respuesta varchar;
        rtaspestadominuta boolean;
       
--CURSORES
        creintegros refcursor; 
	cordenpagoconopc refcursor; 
BEGIN
/*
CREATE TEMP TABLE temppagoordenpagocontable(  idvalorescaja INTEGER ,  monto  double precision  ,  observacion VARCHAR ,  tipo VARCHAR,  idcuentabancaria INTEGER,  idchequera BIGINT ,  fechacobro VARCHAR ,  fechaemision VARCHAR ,  idcheque BIGINT ,  nroordenpago BIGINT ,  idcentroordenpago INTEGER ,  idcentrocheque INTEGER );
 INSERT INTO temppagoordenpagocontable (idvalorescaja, monto , observacion,tipo, nroordenpago,idcentroordenpago ) VALUES (45, 2508.32, 'Contado / OtrasCredicoop (Nqn) 24917/1', 'CT/TRANS', 109743, 1);

 CREATE TEMP TABLE tempordenpagoconopc (idordenpagotipo integer, nrocuentachaber varchar,idvalorescaja integer,idprestador bigint,nroordenpago   bigint,idcentroordenpago integer, fechaingreso date ,beneficiario  character varying,concepto  character varying, importetotal double precision										,opcobservacion varchar,opcfechaingreso date); 
 INSERT INTO tempordenpagoconopc ( nroordenpago,idcentroordenpago, opcobservacion,opcfechaingreso) VALUES(109743,1,NULL,NULL);
*/
	CREATE TEMP TABLE temppagoordenpagocontable(  
			idvalorescaja INTEGER ,  
			monto  double precision,  
			observacion VARCHAR,  
			tipo VARCHAR,  
			idcuentabancaria INTEGER,  
			idchequera BIGINT,  
			fechacobro VARCHAR,  
			fechaemision VARCHAR ,  
			idcheque BIGINT ,  
			nroordenpago BIGINT ,  
			idcentroordenpago INTEGER , 
			idcentrocheque INTEGER );

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

	OPEN cordenpagoconopc FOR SELECT * FROM tempordenpagoconopc;
	FETCH cordenpagoconopc into rlaminuta;
	WHILE  FOUND LOOP
		
		SELECT INTO rtaspestadominuta * FROM verificarestadoordenpago(rlaminuta.nroordenpago, rlaminuta.idcentroordenpago, 2);
		IF (rtaspestadominuta) THEN 
 
			OPEN creintegros FOR SELECT distinct ON(r.nroreintegro) r.nroreintegro ,
nroordenpago*100+idcentroordenpago as idoperacion, r.nroreintegro, r.anio, r.idcentroregional, rimporte, concat('Reintegro ',lpad(concat(r.nroreintegro,'-', r.anio,'-', r.idcentroregional )::text,16,' '), ' Fecha ', rfechaingreso, ' del afiliado ',p.apellido, ',', p.nombres, ' Doc:', p.nrodoc, 
	(CASE WHEN nullvalue (fv.nrofactura) THEN  concat('. Liquidado sin OTP. ', concepto) 
	ELSE concat('. Liquidado con la OTP ', tipocomprobante,'|',tipofactura,'|',nrosucursal,'|',nrofactura, '. Emitada el ', fechaemision ) 	END) ) as xobs, CASE WHEN mfpttfp.idformapagotipos=9 THEN 'CHPROP'  WHEN (mfpttfp.idformapagotipos=8  or mfpttfp.idformapagotipos=2) THEN 'CT/TRANS' END AS tipo,  NULL AS idvalorescaja,fpdescripcion AS descripcion, NULL AS idcuentabancaria, NULL as fechaemision ,rlaminuta.opcobservacion, rlaminuta.opcfechaingreso, fpt.idformapagotipos, opcr.idordenpagocontable,opcr.idcentroordenpagocontable
		FROM reintegro AS r NATURAL JOIN ordenpago  NATURAL JOIN tipoformapago NATURAL JOIN mapeoformapagotipostipoformapago AS mfpttfp NATURAL JOIN formapagotipos AS fpt NATURAL JOIN persona as p
		LEFT JOIN informefacturacionexpendioreintegro USING ( nroreintegro,anio,idcentroregional) 
		LEFT JOIN informefacturacion AS if USING(nroinforme, idcentroinformefacturacion) 
		LEFT JOIN facturaventa AS fv  USING (nrofactura, tipocomprobante, nrosucursal, tipofactura)
		LEFT JOIN ordenpagocontablereintegro AS opcr ON(r.nroreintegro=opcr.nroreintegro AND r.anio=opcr.anio AND r.idcentroregional=opcr.idcentroregional)
		LEFT JOIN ordenpagocontableestado USING(idordenpagocontable,idcentroordenpagocontable) 
		WHERE nroordenpago = rlaminuta.nroordenpago AND  idcentroordenpago = rlaminuta.idcentroordenpago
                --WHERE nroordenpago = 106603 AND  idcentroordenpago = 1  
                AND  nullvalue(anulada) AND nullvalue(opcfechafin) AND (idordenpagocontableestadotipo=6 OR nullvalue(idordenpagocontableestadotipo))
		order by nroreintegro ; 





		FETCH creintegros into rreintegro;
		WHILE  FOUND LOOP
			INSERT INTO tempcomprobante (nrocomp, idcentrocomp, montopagar, montoretencion,apagarcomprobante, tipocomp, observacion, idprestador) 
		     VALUES(rlaminuta.nroordenpago, rlaminuta.idcentroordenpago, rreintegro.rimporte, 0, 0, 'Minuta ', concat('Pago ', rreintegro.xobs,' - Minuta: ' ,rlaminuta.nroordenpago, '|',rlaminuta.idcentroordenpago ), 2608);
			
			SELECT INTO laordenpago generarordenpagocontable();

			IF (nullvalue(rreintegro.idordenpagocontable)) THEN 
				INSERT INTO ordenpagocontablereintegro(idordenpagocontable, idcentroordenpagocontable, nroreintegro, anio, idcentroregional, opcrconotp, opcrobservacion) 
				VALUES(	trim(split_part(laordenpago, '|', 1))::bigint,
					trim(split_part(laordenpago, '|', 2))::integer,
					rreintegro.nroreintegro, 
					rreintegro.anio, 
					rreintegro.idcentroregional,
					false, 
					concat('Insercion realizada en SP generarordenpagodesdeminutapagoreintegro el día ', now()));
			ELSE 
				UPDATE ordenpagocontablereintegro SET idordenpagocontable = trim(split_part(laordenpago, '|', 1))::bigint, idcentroordenpagocontable= trim(split_part(laordenpago, '|', 2))::integer
				WHERE nroreintegro= rreintegro.nroreintegro AND anio=rreintegro.anio AND idcentroregional=rreintegro.idcentroregional AND idordenpagocontable=rreintegro.idordenpagocontable AND idcentroordenpagocontable=rreintegro.idcentroordenpagocontable; 
			END IF; 


          DELETE FROM tempcomprobante;         
          DELETE FROM tempordenpagocontable;
          DELETE FROM tretencionprestador;
 
          /*guardo los datos del pago*/        
        IF (iftableexistsparasp('temppagompopc_contrasf') ) THEN /*Hay datos del pago y los guardo*/      
		SELECT INTO rpagoopc * FROM temppagompopc_contrasf 	
		WHERE nroordenpago = rlaminuta.nroordenpago AND  idcentroordenpago = rlaminuta.idcentroordenpago; 
		IF FOUND THEN -- para esa MP tengo un pago ingresado 
			SELECT INTO obs opcobservacion FROM ordenpagocontable 
				WHERE  idordenpagocontable=  trim(split_part(laordenpago, '|', 1)) AND idcentroordenpagocontable= trim(split_part(laordenpago, '|', 2));
			INSERT INTO temppagoordenpagocontable (idvalorescaja, monto , observacion,tipo) 			VALUES (rpagoopc.idvalorescaja
				,rreintegro.rimporte
				,rpagoopc.observacion
				,rpagoopc.tipo
				);
			INSERT INTO tempordenpagocontable (idprestador, claveordenpagocontable,opcmontototal ,opcmontoretencion  , opcmontocontadootra , opcmontochequeprop , opcmontochequetercero ,opcobservacion,opcfechaingreso) 
			VALUES( 2608,replace(laordenpago, '|','-'),rpagoopc.monto,0,rreintegro.rimporte,0,0,obs,rreintegro.opcfechaingreso);

			SELECT INTO respuesta guardarpagoordenpagocontable() as comprobante;

                        DELETE FROM temppagoordenpagocontable; 
                        DELETE FROM tempordenpagocontable; 
		END IF;
	END IF;  
       
	FETCH creintegros into rreintegro;
	END LOOP;
	CLOSE creintegros;
	END IF;
	FETCH cordenpagoconopc into rlaminuta;
	END LOOP;
        CLOSE cordenpagoconopc;
  	 
	
     
return true;   

END;
$function$
