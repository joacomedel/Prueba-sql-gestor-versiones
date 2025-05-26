CREATE OR REPLACE FUNCTION public.asientogenerico_auditar_duplicados(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
	cursor_asiento refcursor;
	rfiltros RECORD;
  	rasiento RECORD;
informado  RECORD;
  	salida character varying;
	cant_sinrevertir INTEGER;
	cant_revertidos INTEGER;
registrar boolean;
BEGIN
	salida = '';
    
	-- busco aquellos asientos correspondientes a un mismo comprobante que sea mayor a 1
	 OPEN cursor_asiento FOR   SELECT idcomprobantesiges,idasientogenericocomprobtipo, count(*) as cant 
				   FROM asientogenerico
				   WHERE  agfechacontable >='2021-01-01' and agfechacontable <='2021-12-31'
				   GROUP BY (idcomprobantesiges, idasientogenericocomprobtipo)
				   HAVING count(*)>1;

	FETCH cursor_asiento INTO rasiento;
	-- La cantidad de asientos y la cantidad de asientos revertidos puede variar de la siguiente manera:
	-- La cant de Asientos de un comprobante puede coincidir con la cantidad de asientos revertidos de ese comprobante
	-- O
	-- La cant de Asientos de un comprobante puede coincidir con la cantidad de asientos revertidos + 1 de ese comprobante
        WHILE FOUND LOOP
                        registrar = false;
			SELECT INTO cant_sinrevertir CASE WHEN nullvalue(count(*)) THEN 0 ELSE   count(*) END  
		        FROM asientogenerico
			WHERE  idcomprobantesiges =rasiento.idcomprobantesiges 
                             	AND idasientogenericocomprobtipo 	 =rasiento.idasientogenericocomprobtipo 
			       AND nullvalue(idasientogenericorevertido)  
			GROUP BY (idcomprobantesiges);

                        SELECT INTO cant_revertidos CASE WHEN nullvalue(count(*)) THEN 0 ELSE   count(*) END  
		        FROM asientogenerico
			WHERE  idcomprobantesiges =rasiento.idcomprobantesiges 
                                AND idasientogenericocomprobtipo 	 =rasiento.idasientogenericocomprobtipo 
			       AND not nullvalue(idasientogenericorevertido)  
			GROUP BY (idcomprobantesiges);
---cant_revertidos=1 cant_sinrevertir= 2
			IF not (cant_sinrevertir=1 ) THEN -- solo debe existir un solo asiento sin revertir por comprobante
                               IF not (cant_sinrevertir =2 ) THEN
                                      IF(cant_revertidos>0)  AND (cant_revertidos <> cant_sinrevertir ) AND not (cant_revertidos  +1 = cant_sinrevertir ) THEN
					registrar = true;
                                      END IF; 
                               END IF;
                               
			END IF;


                      /* 2 CONTROL  */
                     -- La cantidad de asientos y la cantidad de asientos revertidos puede variar de la siguiente manera:
	             -- La cant de Asientos de un comprobante puede coincidir con la cantidad de asientos revertidos de ese comprobante
	             -- O
	             -- La cant de Asientos de un comprobante puede coincidir con la cantidad de asientos revertidos + 1 de ese comprobante
                       IF not ( ( cant_sinrevertir = cant_revertidos ) OR (cant_sinrevertir = cant_revertidos + 1 ) ) THEN  
			       
                              registrar = true;
                                  
                               
		       END IF;
                       IF (registrar) THEN 
                                        --- corroboro que no este el comprobante registrado en la tabla 
                                        SELECT INTO informado * FROM asientogenerico_auditoria
                                        WHERE idcomprobantesiges = rasiento.idcomprobantesiges   ; 
                                        IF NOT FOUND  THEN 
                                                INSERT INTO asientogenerico_auditoria(idcomprobantesiges,idasientogenericocomprobtipo,descripcion)
                                                VALUES(rasiento.idcomprobantesiges,rasiento.idasientogenericocomprobtipo,concat('cant_revertidos=',cant_revertidos,' cant_sinrevertir= ',cant_sinrevertir));
                                        END IF;
                       END IF;    

        FETCH cursor_asiento INTO rasiento;
	END LOOP;

	 

	RETURN salida;
END;
$function$
