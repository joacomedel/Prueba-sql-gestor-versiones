CREATE OR REPLACE FUNCTION public.contabilidad_generarminutaimputacion_corredtic(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       c_pagorechazado refcursor;
       rpago record;
       asientodescripcion varchar;
       rcuentadebe record;
       rfiltros  record;
       rimputacion  record;
       rconf_cont record;
       laordenpago  varchar;

       elconcepto varchar;
       elbeneficiario varchar;
       lanroordenpago bigint;
       elidcentroordenpago integer;
cursorrecibos   refcursor;
       cant integer;
 
BEGIN   
     
/** 
Esta funcion se implemento para generar automaticamente la minuta de imputacion de recibos que fueron generados y contabilizados pero no asi su imputacion (SOLO 2022)

*/
	 EXECUTE sys_dar_filtros($1) INTO rfiltros;
	 
	 -- 1 Buesco información de la deuda y del pago que se desea imputar
	OPEN cursorrecibos  FOR  SELECT  case when p.fechamovimiento>=d.fechamovimiento then p.fechamovimiento::date else case when d.fechamovimiento>current_date then p.fechamovimiento::date else d.fechamovimiento::date end end as fechamovimientoimputacion
			,importeimp,idpago,idcentropago,iddeuda,idcentrodeuda
			,p.idcomprobante,CASE WHEN nullvalue(cc.nrocuentacontable) THEN d.nrocuentac::varchar ELSE cc.nrocuentacontable::varchar END nrocuentac,d.movconcepto conceptodeuda
			,p.movconcepto conceptopago,d.idcomprobante idcomprobantedeuda
                        ,dp.idctactedeudapagocliente,dp.idcentroctactedeudapagocliente
	 FROM asientogenericoitem as i
	 NATURAL JOIN asientogenerico 
	 JOIN ctactepagocliente p ON (concat(idcomprobante,'|',idcentropago)=idcomprobantesiges)
	 JOIN ctactedeudapagocliente as dp USING(idpago,idcentropago)
	 LEFT JOIN ctactedeudapagoclienteordenpago as vmin USING(idctactedeudapagocliente,idcentroctactedeudapagocliente	)
	 JOIN ctactedeudacliente as d USING(iddeuda,idcentrodeuda)
         JOIN ctactedeudacliente_ext d_e using (iddeuda,idcentrodeuda)
         JOIN comprobantestipos ct on (d.idcomprobantetipos=ct.idcomprobantetipos and ct.ctgeneracontabilidad)
         LEFT JOIN cuentacorrienteconceptotipo cc on (   d_e.idcuentacorrienteconceptotipo = cc.idcuentacorrienteconceptotipo		 
                                                    and d_e.idconcepto=cc.idconcepto)
	 WHERE  i.nrocuentac = 10202 --- and idasientogenerico =561384
       	 	 AND idasientogenericocomprobtipo = 8
       	 	 AND nullvalue(nroordenpago)  ---- no genero minuta de imputacion 
       	 	 AND acid_h = 'H'
       	 	 AND agfechacontable >= '2022-01-01'
       	 	 AND nullvalue(idasientogenericorevertido)
       	 	 AND agdescripcion not ilike '%REVERSION%'
                 LIMIT 100
;

		
	FETCH cursorrecibos  INTO rimputacion ;
	WHILE  found LOOP
                     elconcepto = concat( ' | MINUTA IMPUTACION GA30112022  ',rimputacion.idpago,'-',rimputacion.idcentropago,'-',rimputacion.idcomprobante,': ',rimputacion.conceptopago,' <--> a Deuda ',rimputacion.iddeuda,'-',rimputacion.idcentrodeuda,'-',rimputacion.idcomprobantedeuda,': ',rimputacion.conceptodeuda);
 
           	 	 /* Creo las temporales para generar la minuta */
		     IF (iftableexists('tempordenpago') ) THEN
                          	 DELETE FROM tempordenpago  ;
                     ELSE 
	  
		   	 	 -- 2 - Genero la minuta de la imputación
	  		    CREATE TEMP TABLE tempordenpago  (
			        requiereopc boolean, 
				idordenpagotipo integer, 
				nrocuentachaber varchar,
				idvalorescaja integer,
				idprestador bigint,
				nroordenpago   bigint,
				fechaingreso date ,
				beneficiario  character varying,
				concepto  character varying, 
				importetotal double precision); 
                      END IF;
			---idordenpagotipo= 12 genera contabilidad	Imputacion
			elbeneficiario = '';

            -- La cuenta es la cuenta de la deuda que se encuentra configurada en la tabla cuentacorrienteconceptotipo para laa deuda
			INSERT INTO tempordenpago (idordenpagotipo,requiereopc, nrocuentachaber,idvalorescaja,idprestador,fechaingreso,beneficiario,concepto,importetotal) 
			  			VALUES(12,false,rimputacion.nrocuentac::integer,0,0,rimputacion.fechamovimientoimputacion,elbeneficiario,elconcepto,rimputacion.importeimp  );
                         IF (iftableexists('tempordenpagoimputacion') ) THEN
                               DELETE FROM tempordenpagoimputacion;
                         ELSE 
			       CREATE TEMP TABLE tempordenpagoimputacion (codigo integer ,nrocuentac 	character varying , debe  	double precision , haber  	double precision , nroordenpago  bigint);
		         END IF;  
	 	     -- Cuando se realiza un pago el importe afecta a caja puente cobranza por lo que en la
		     -- imputacion es la cuenta contable que debemos afectar 
	 	     INSERT INTO tempordenpagoimputacion (codigo, nrocuentac,debe ,haber) 
	             VALUES (10202  ,'10202' , rimputacion.importeimp,'0');
/*
            -- Busco si se debe generar registro de devengamiento
            -- Busco la cofiguracion de la deuda
            SELECT INTO rconf_cont *
            FROM ctactedeudacliente
            NATURAL JOIN ctactedeudacliente_ext
            JOIN cuentacorrienteconceptotipo  USING (idcuentacorrienteconceptotipo)
            WHERE iddeuda = rfiltros.iddeuda AND  idcentrodeuda = rfiltros.idcentrodeuda  
                   AND NOT nullvalue(nrocuentacontable_debe) AND NOT nullvalue(nrocuentacontable_haber);
            IF FOUND THEN
                     INSERT INTO tempordenpagoimputacion (codigo, nrocuentac,debe ,haber) 
	             VALUES (rconf_cont.nrocuentacontable_debe  ,rconf_cont.nrocuentacontable_debe::varchar , rimputacion.importeimp,'0');
                     INSERT INTO tempordenpagoimputacion (codigo, nrocuentac,debe ,haber) 
	             VALUES (rconf_cont.nrocuentacontable_haber  ,rconf_cont.nrocuentacontable_haber::varchar , 0 , rimputacion.importeimp);
            END IF;
*/

            -- genero la minuta
            SELECT INTO laordenpago  generarordenpagogenerica() AS comprobante;

            IF (not nullvalue(laordenpago) AND char_length(laordenpago)>0 ) THEN
                
                    lanroordenpago = split_part(laordenpago, '-', 1);
                    elidcentroordenpago =  split_part(laordenpago, '-', 2)   ;
                    INSERT INTO ctactedeudapagoclienteordenpago (idctactedeudapagocliente, idcentroctactedeudapagocliente,nroordenpago, idcentroordenpago) 
                    VALUES( rimputacion.idctactedeudapagocliente, rimputacion.idcentroctactedeudapagocliente, lanroordenpago   ,elidcentroordenpago);         
                 
            END IF;
           cant = cant + 1;
           FETCH cursorrecibos  INTO rimputacion ;
	  END LOOP;
          CLOSE cursorrecibos;
      RETURN laordenpago;
     
END;

$function$
