CREATE OR REPLACE FUNCTION public.contabilidad_generarminutaimputacioncliente(character varying)
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
 
BEGIN   
     
	 EXECUTE sys_dar_filtros($1) INTO rfiltros;
	 
	 -- 1 Buesco información de la deuda y del pago que se desea imputar
	 SELECT INTO rimputacion  
	 		case when p.fechamovimiento>=d.fechamovimiento then p.fechamovimiento::date else case when d.fechamovimiento>current_date then p.fechamovimiento::date else d.fechamovimiento::date end end as fechamovimientoimputacion
			,importeimp,idpago,idcentropago,iddeuda,idcentrodeuda
			,p.idcomprobante,CASE WHEN nullvalue(cc.nrocuentacontable) THEN d.nrocuentac::varchar ELSE cc.nrocuentacontable::varchar END nrocuentac,d.movconcepto conceptodeuda
			,p.movconcepto conceptopago,d.idcomprobante idcomprobantedeuda  
	 FROM ctactedeudapagocliente dp
	 JOIN ctactedeudacliente d using (iddeuda,idcentrodeuda)
         JOIN ctactedeudacliente_ext d_e using (iddeuda,idcentrodeuda)
         JOIN comprobantestipos ct on (d.idcomprobantetipos=ct.idcomprobantetipos and ct.ctgeneracontabilidad)
         LEFT JOIN cuentacorrienteconceptotipo cc on (   d_e.idcuentacorrienteconceptotipo = cc.idcuentacorrienteconceptotipo		 
                                                    and d_e.idconcepto=cc.idconcepto)
                          
	 JOIN ctactepagocliente p using (idpago,idcentropago) 
 
         LEFT JOIN informefacturacion if ON ((p.idcomprobante / 100) = if.nroinforme AND p.idcomprobantetipos=21 )
	 WHERE (p.idcomprobantetipos=0                        
             OR (p.idcomprobantetipos=21 and not nullvalue(if.nroinforme))
             OR p.idcomprobantetipos=60  
           ) and dp.idctactedeudapagocliente=rfiltros.idctactedeudapagocliente
		   and dp.idcentroctactedeudapagocliente=rfiltros.idcentroctactedeudapagocliente
           and p.fechamovimiento>'2018-12-31';
							 
	 IF FOUND THEN
                     elconcepto = concat( ' | MINUTA IMPUTACION ',rimputacion.idpago,'-',rimputacion.idcentropago,'-',rimputacion.idcomprobante,': ',rimputacion.conceptopago,' <--> a Deuda ',rimputacion.iddeuda,'-',rimputacion.idcentrodeuda,'-',rimputacion.idcomprobantedeuda,': ',rimputacion.conceptodeuda);
 
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

            -- genero la minuta
            SELECT INTO laordenpago  generarordenpagogenerica() AS comprobante;

            IF (not nullvalue(laordenpago) AND char_length(laordenpago)>0 ) THEN
                
                    lanroordenpago = split_part(laordenpago, '-', 1);
                    elidcentroordenpago =  split_part(laordenpago, '-', 2)   ;
                    INSERT INTO ctactedeudapagoclienteordenpago (idctactedeudapagocliente, idcentroctactedeudapagocliente,nroordenpago, idcentroordenpago) 
                    VALUES( rfiltros.idctactedeudapagocliente, rfiltros.idcentroctactedeudapagocliente, lanroordenpago   ,elidcentroordenpago);         
                 
            END IF;

	  END IF;
      RETURN laordenpago;
     
END;

$function$
