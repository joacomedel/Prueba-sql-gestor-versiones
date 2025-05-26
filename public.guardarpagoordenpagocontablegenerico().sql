CREATE OR REPLACE FUNCTION public.guardarpagoordenpagocontablegenerico()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
--REGISTRO
       rordenpagocontable record;
--CURSOR
       crordenpagocontable refcursor;
--VARIABLES
       elidpagoopc VARCHAR;
BEGIN
	 CREATE TEMP TABLE tempordenpagocontable( 
		claveordenpagocontable VARCHAR ,  
		opcobservacion VARCHAR , 
		opcmontototal  double precision  ,  
		opcmontoretencion  double precision  ,  
		opcmontocontadootra  double precision  ,  
		opcmontochequeprop  double precision  ,  
		idprestador  bigint  ,  
		opcfechaingreso date ,  
		opcmontochequetercero  double precision   );

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

	CREATE TEMP TABLE tretencionprestador (
				idtiporetencion BIGINT,
				rpfecha TIMESTAMP WITHOUT TIME ZONE DEFAULT ('now'::text)::date, 
				idprestador BIGINT,
				rpmontofijo DOUBLE PRECISION,
				rpmontoporc DOUBLE PRECISION,
				rpmontototal DOUBLE PRECISION,
				rpmontobase DOUBLE PRECISION,
				rpmontoretanteriores DOUBLE PRECISION) WITHOUT OIDS;
/*
 INSERT INTO tempordenpagocontabletodas (idprestador , claveordenpagocontable,opcmontototal ,opcmontoretencion  , opcmontocontadootra , opcmontochequeprop , opcmontochequetercero ,opcobservacion,opcfechaingreso, idordenpagocontable, idcentroordenpagocontable, idordenpagocontableestadotipo, idvalorescaja, monto , observacion,tipo ) VALUES( 2608,'3516-1',721.0,0.0,721.0,0,0,'MP: 105501|1 Pago Reintegro 33373-2017-1 del afiliado 27646206 con la OTP 4|OT|1|683. Emitada el 2017-10-19 - Minuta: 105501|1 . Pago Masivo. ','2017-10-19',3516,1,1,45, 721.0, 'Contado / OtrasCredicoop (Nqn) 24917/1', 'CT/TRANS');INSERT INTO tempordenpagocontabletodas (idprestador , claveordenpagocontable,opcmontototal ,opcmontoretencion  , opcmontocontadootra , opcmontochequeprop , opcmontochequetercero ,opcobservacion,opcfechaingreso, idordenpagocontable, idcentroordenpagocontable, idordenpagocontableestadotipo, idvalorescaja, monto , observacion,tipo ) VALUES( 2608,'3515-1',1895.54,0.0,1895.54,0,0,'MP: 105500|1 Pago Reintegro 33314-2017-1 del afiliado 05169291 con la OTP 4|OT|1|682. Emitada el 2017-10-19 - Minuta: 105500|1 . Pago Masivo. ','2017-10-19',3515,1,1,45, 1895.54, 'Contado / OtrasCredicoop (Nqn) 24917/1', 'CT/TRANS');INSERT INTO tempordenpagocontabletodas (idprestador , claveordenpagocontable,opcmontototal ,opcmontoretencion  , opcmontocontadootra , opcmontochequeprop , opcmontochequetercero ,opcobservacion,opcfechaingreso, idordenpagocontable, idcentroordenpagocontable, idordenpagocontableestadotipo, idvalorescaja, monto , observacion,tipo ) VALUES( 2608,'3514-1',164.25,0.0,164.25,0,0,'MP: 105499|1 Pago Reintegro 33365-2017-1 del afiliado 05128383 con la OTP 4|OT|1|681. Emitada el 2017-10-19 - Minuta: 105499|1 . Pago Masivo. ','2017-10-19',3514,1,1,45, 164.25, 'Contado / OtrasCredicoop (Nqn) 24917/1', 'CT/TRANS');INSERT INTO tempordenpagocontabletodas (idprestador , claveordenpagocontable,opcmontototal ,opcmontoretencion  , opcmontocontadootra , opcmontochequeprop , opcmontochequetercero ,opcobservacion,opcfechaingreso, idordenpagocontable, idcentroordenpagocontable, idordenpagocontableestadotipo, idvalorescaja, monto , observacion,tipo ) VALUES( 2608,'3513-1',1061.36,0.0,1061.36,0,0,'MP: 105498|1 Pago Reintegro 30080-2017-4 del afiliado 25640418 con la OTP 4|OT|1|680. Emitada el 2017-10-19 - Minuta: 105498|1 . Pago Masivo. ','2017-10-19',3513,1,1,45, 1061.36, 'Contado / OtrasCredicoop (Nqn) 24917/1', 'CT/TRANS');INSERT INTO tempordenpagocontabletodas (idprestador , claveordenpagocontable,opcmontototal ,opcmontoretencion  , opcmontocontadootra , opcmontochequeprop , opcmontochequetercero ,opcobservacion,opcfechaingreso, idordenpagocontable, idcentroordenpagocontable, idordenpagocontableestadotipo, idvalorescaja, monto , observacion,tipo ) VALUES( 2608,'3512-1',812.0,0.0,812.0,0,0,'MP: 105497|1 Pago Reintegro 32773-2017-3 del afiliado 25929191 con la OTP 4|OT|1|679. Emitada el 2017-10-19 - Minuta: 105497|1 . Pago Masivo. ','2017-10-19',3512,1,1,45, 812.0, 'Contado / OtrasCredicoop (Nqn) 24917/1', 'CT/TRANS');

SELECT *
	FROM tempordenpagocontabletodas JOIN ordenpagocontable USING(idordenpagocontable, idcentroordenpagocontable) 
	JOIN ordenpagocontableordenpago USING(idordenpagocontable, idcentroordenpagocontable) 
	JOIN ordenpago  USING(nroordenpago, idcentroordenpago) LEFT JOIN reintegro USING(nroordenpago, idcentroordenpago) ;
	 		*/

	-- Recupero informacion de la orden de pago contable
	OPEN crordenpagocontable FOR SELECT *
	FROM tempordenpagocontabletodas JOIN ordenpagocontable USING(idordenpagocontable, idcentroordenpagocontable) 
	JOIN ordenpagocontableordenpago USING(idordenpagocontable, idcentroordenpagocontable) 
	JOIN ordenpago  USING(nroordenpago, idcentroordenpago) LEFT JOIN reintegro USING(nroordenpago, idcentroordenpago) ;
	 		
	FETCH crordenpagocontable into rordenpagocontable;
	WHILE  FOUND LOOP

	 IF (rordenpagocontable.idordenpagocontableestadotipo = 1 AND rordenpagocontable.tipoformapago=2) THEN 
	 
		INSERT INTO tempordenpagocontable (idprestador , claveordenpagocontable,opcmontototal ,opcmontoretencion  ,			opcmontocontadootra , opcmontochequeprop , opcmontochequetercero ,opcobservacion, opcfechaingreso) 
		VALUES( rordenpagocontable.idprestador,
			rordenpagocontable.claveordenpagocontable,
			rordenpagocontable.opcmontototal,
			rordenpagocontable.opcmontoretencion,
			rordenpagocontable.opcmontocontadootra,
			rordenpagocontable.opcmontochequeprop,
			rordenpagocontable.opcmontochequetercero,
			rordenpagocontable.opcobservacion,
			rordenpagocontable.opcfechaingreso);

		 INSERT INTO temppagoordenpagocontable (idvalorescaja, monto , observacion,tipo) 
		VALUES( rordenpagocontable.idvalorescaja,
			rordenpagocontable.monto,
			rordenpagocontable.observacion,
			rordenpagocontable.tipo);

		 
		PERFORM guardarpagoordenpagocontable();

		
		DELETE FROM tempordenpagocontable;
		DELETE FROM temppagoordenpagocontable;
	 ELSE 
		UPDATE tempordenpagocontabletodas SET 
			error = TRUE, 
			observacionerror = CASE WHEN rordenpagocontable.idordenpagocontableestadotipo<>1 THEN CONCAT('El Estado actual de la OP: ', rordenpagocontable.claveordenpagocontable, ' NO permite que sea Pagada') 
					WHEN (rordenpagocontable.tipoformapago<>2 or nullvalue(rordenpagocontable.tipoformapago)) THEN 'La forma de pago del reintegro NO es transferencia' END 
			WHERE idordenpagocontable=rordenpagocontable.idordenpagocontable 
				AND idcentroordenpagocontable= rordenpagocontable.idcentroordenpagocontable; 
	 END IF; 
	  FETCH crordenpagocontable into rordenpagocontable;
        END LOOP;
	CLOSE crordenpagocontable;

	
return true;
END;$function$
