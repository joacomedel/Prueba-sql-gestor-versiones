CREATE OR REPLACE FUNCTION public.contabilidad_generarminutaimputacion(character varying)
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
     /*
	 Esta funcion comienza a ejecutarse XX-XX-2022, reemplaza a la función que desencadenaba el trigger de 
	 la base cuentacorrientedeudapago asientogenericoimputacion_crear_tr ()
     En esta nueva modalidad los asientos se van a generar a partir de minutas de imputacin y no directamente.
	 comentar el asientogenerico_crear_9
	*/
	 --SELECT contabilidad_generarminutaimputacion ('{iddeuda=353789 ,idcentrodeuda=1,idpago=207149 , idcentropago=1}')
	 
	 --asientogenerico_crear_9 rfiltros NEW.iddeuda,'|',NEW.idcentrodeuda,'|',NEW.idpago,'|',NEW.idcentropago
	 EXECUTE sys_dar_filtros($1) INTO rfiltros;
	 
	 -- 1 Bueso información de la deuda y del pago que se desea imputar
	 SELECT INTO rimputacion  
	 		case when p.fechamovimiento>=d.fechamovimiento then p.fechamovimiento::date else case when d.fechamovimiento>current_date then p.fechamovimiento::date else d.fechamovimiento::date end end as fechamovimientoimputacion
			,importeimp,idpago,idcentropago,iddeuda,idcentrodeuda
			,p.idcomprobante,cc.nrocuentacontable::varchar nrocuentac,d.movconcepto conceptodeuda
			,p.movconcepto conceptopago,d.idcomprobante idcomprobantedeuda
	 FROM cuentacorrientedeudapago dp
	 JOIN cuentacorrientedeuda d using (iddeuda,idcentrodeuda)
         JOIN cuentacorrientedeuda_ext d_e using (iddeuda,idcentrodeuda)
         JOIN comprobantestipos ct on (d.idcomprobantetipos=ct.idcomprobantetipos and ct.ctgeneracontabilidad)
         JOIN cuentacorrienteconceptotipo cc on (   d_e.idcuentacorrienteconceptotipo = cc.idcuentacorrienteconceptotipo		 
                                                    and d.idconcepto=cc.idconcepto)
	 JOIN cuentacorrientepagos p using (idpago,idcentropago)
-- CS 2019-03-26 Solo debe generar imputaciones de Recibos O 55 --Orden Reintegro
/*KR 24-01-22 ME fijo si el informe asociado al pago es de un reintegro, si lo es entonces genera contabilidad*/
     LEFT JOIN informefacturacion if ON ((p.idcomprobante / 100) = if.nroinforme AND p.idcomprobantetipos=21 )
	 WHERE (p.idcomprobantetipos=0 
                            /*KR 24-01-22 comento ya que ahora el movimiento se realiza desde el informe. TKT #4829   OR p.idcomprobantetipos=55 --MaLaPi Orden Reintegro 04-06-2019 */
             OR (p.idcomprobantetipos=21 and not nullvalue(if.nroinforme))
             OR p.idcomprobantetipos=60 -- MaLaPi Minuta de Pago 04-06-2019
           ) and dp.idpago=rfiltros.idpago
		   and dp.idcentropago=rfiltros.idcentropago
		   and dp.iddeuda=rfiltros.iddeuda
		   and dp.idcentrodeuda=rfiltros.idcentrodeuda
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
	             VALUES (10201  ,'10201' , rimputacion.importeimp,'0');

            -- Busco si se debe generar registro de devengamiento
            -- Busco la cofiguracion de la deuda
            SELECT INTO rconf_cont *
            FROM cuentacorrientedeuda
            NATURAL JOIN cuentacorrientedeuda_ext
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
                    INSERT INTO cuentacorrientedeudapagoordenpago (idpago, iddeuda, idcentrodeuda, idcentropago, nroordenpago, idcentroordenpago) 
                    VALUES( rfiltros.idpago, rfiltros.iddeuda,  rfiltros.idcentrodeuda, rfiltros.idcentropago   ,lanroordenpago   ,elidcentroordenpago);         
                 
            END IF;

	  END IF;
      RETURN laordenpago;
     
END;$function$
