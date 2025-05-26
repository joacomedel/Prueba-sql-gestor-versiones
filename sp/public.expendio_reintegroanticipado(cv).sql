CREATE OR REPLACE FUNCTION public.expendio_reintegroanticipado(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
    
--registros
	rlaordenp RECORD;
	ritems RECORD;
        rformapago RECORD;
        rlaorden RECORD;
--variables
	elconcepto  VARCHAR;
	laordenpago VARCHAR; 
        laordenpagoc VARCHAR;
        obs VARCHAR; 
        elidpagocontable VARCHAR; 
        elanticipo BIGINT;
        elidordenpago BIGINT;
        elidcentroordenpago INTEGER;
BEGIN
  IF existecolumtemp('temporden', 'anticiporeintegro') THEN
   SELECT INTO rlaorden *,(EXTRACT (YEAR FROM now())) as anioa FROM temporden JOIN persona p USING(nrodoc) ;
 --  RAISE NOTICE '(rlaorden,%)',rlaorden;

   IF (rlaorden.anticiporeintegro is not null and rlaorden.anticiporeintegro and rlaorden.tipo=20) THEN 

      SELECT INTO rlaordenp * FROM ttordenesgeneradas NATURAL JOIN temporden WHERE NOT autogestion;  
      SELECT INTO ritems elanticipo,rlaorden.anioa,tipoprestacion,text_concatenar(obsprestacion) obsprestacion, sum(tempitems.afiliado)as importe, sum(tempitems.cantidad) as cantidad,centro()
      FROM tempitems  
      GROUP BY tipoprestacion;

      INSERT INTO anticipo(anio,idcentroregional,nrodoc,tipodoc,aimporte, anroorden, acentro) VALUES (rlaorden.anioa, centro(), rlaorden.nrodoc, rlaorden.tipodoc::smallint,ritems.importe,rlaordenp.nroorden, rlaordenp.centro);
     elanticipo =  currval('anticipo_nroanticipo_seq'); 
      INSERT INTO anticipobenef(nroanticipo, anio, nrodoc, barra,idcentroregional) VALUES (elanticipo,rlaorden.anioa ,rlaorden.nrodoc,rlaorden.barra, centro());

 
    
    
    INSERT INTO anticipoprestacion(nroanticipo,anio,tipoprestacion,observacion,importe,cantidad,idcentroregional) VALUES(elanticipo,ritems.anioa,ritems.tipoprestacion,ritems.obsprestacion,ritems.importe,ritems.cantidad,centro());

 
	-- Creo la MP de imputacion 
 
     elconcepto = concat( ' | MINUTA Anticipado Reintegro: ',elanticipo,'-',rlaorden.anioa,'-',centro(),' -> Orden Pres. ',rlaordenp.nroorden,'-',rlaordenp.centro);

     /* Creo las temporales para generar la minuta */
     IF (iftableexists('tempordenpago') ) THEN
            DELETE FROM tempordenpago;
     ELSE 	  
	   -- 2 - Genero la minuta de la imputación
	    CREATE TEMP TABLE tempordenpago  (  
				idordenpagotipo integer, 
				nrocuentachaber varchar,
				idvalorescaja integer,
				idprestador bigint,
				nroordenpago   bigint,
				fechaingreso date ,
				beneficiario  character varying,
				concepto  character varying, 
				importetotal double precision,
                                requiereopc BOOLEAN DEFAULT true); 
        END IF;
  
     

        -- La cuenta es la cuenta de la deuda que se encuentra configurada en la tabla cuentacorrienteconceptotipo para laa deuda
	INSERT INTO tempordenpago (idordenpagotipo, nrocuentachaber,idvalorescaja,idprestador,fechaingreso,beneficiario,concepto,importetotal) 
			 VALUES(12,60151,0,0,now(),concat(rlaorden.apellido, ' ', rlaorden.nombres) ,elconcepto,ritems.importe);

         RAISE NOTICE '(ritems.importe,%)',ritems.importe;
 RAISE NOTICE '(ritems,%)',ritems;
        IF (iftableexists('tempordenpagoimputacion') ) THEN
            DELETE FROM tempordenpagoimputacion;
        ELSE 
	    CREATE TEMP TABLE tempordenpagoimputacion (codigo integer ,nrocuentac character varying, debe double precision, haber double precision, nroordenpago  bigint);
	END IF;  
       
        INSERT INTO tempordenpagoimputacion (codigo, nrocuentac,debe ,haber) VALUES (10829  ,'10829' , ritems.importe,'0');
    
           -- genero la minuta
        SELECT INTO laordenpago  generarordenpagogenerica() AS comprobante;

        SELECT INTO elidordenpago split_part(laordenpago, '-',1);
        SELECT INTO elidcentroordenpago  split_part(laordenpago, '-',2);
     
        UPDATE anticipo SET nroordenpago = elidordenpago, idcentroordenpago = elidcentroordenpago 
        WHERE nroanticipo= elanticipo AND anio= ritems.anioa AND idcentroregional=centro();

    END IF;
  END IF;
return laordenpago::text;
END;$function$
