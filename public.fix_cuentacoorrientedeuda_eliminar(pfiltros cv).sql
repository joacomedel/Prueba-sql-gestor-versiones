CREATE OR REPLACE FUNCTION public.fix_cuentacoorrientedeuda_eliminar(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
    arr varchar[];
    array_len integer;
    rfiltros record;
        vquery varchar;
	
	cursor_ctactedeuda refcursor;
    reg_ctactedeuda RECORD;
     hay_minuta boolean;
r_minimp record;
hay_asientogenerico boolean;
r_asientogenerico record;
     los_pago varchar; 
BEGIN

    /***** 
     El proposito del siguiente script es eliminar las deudas de afiliados generadas y que no correspondia
    *****/ 
    EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
    -- La siguiente consulta permite identificar las deudas que deben ser eliminadas
    -- Va a variar dependiendo del tipo de deuda que se desea eliminar
 	
     -- 1 busco las deudas
	 OPEN cursor_ctactedeuda FOR  SELECT  cd.*  FROM facturaventa
 							 NATURAL JOIN facturaventacupon  
      						 JOIN informefacturacion USING (nrofactura,nrosucursal,tipocomprobante, tipofactura) 
      						 JOIN cuentacorrientedeuda as cd ON (cd.idcomprobante= nroinforme*100+idcentroinformefacturacion  ) 
     						 WHERE  idvalorescaja= 97    
           						   AND  nullvalue(fechaenvio)
								  --- AND iddeuda = 371287 AND idcentrodeuda=1
      						 ORDER BY iddeuda;
	 -- elimia de la cuenta corriente las facturas vinculadas a los intereses de los prestamos


	FETCH cursor_ctactedeuda INTO reg_ctactedeuda;
	WHILE FOUND LOOP
                   											   
      		 --- 2 Se recupera el saldo del pago
			 UPDATE cuentacorrientepagos SET saldo = saldo + T.importeimp
			 FROM (
			      SELECT idpago,idcentropago, importeimp
				  FROM cuentacorrientedeudapago 
				  JOIN cuentacorrientepagos USING (idpago,idcentropago)
				  WHERE iddeuda = reg_ctactedeuda.iddeuda 
					    AND idcentrodeuda = reg_ctactedeuda.idcentrodeuda
			
			  )as T
			  WHERE T.idpago = cuentacorrientepagos.idpago
			        AND T.idcentropago = cuentacorrientepagos.idcentropago;
			
			
			  -- 3 Actualizo el saldo de la imputacion a 0
			   hay_minuta = true;
                          UPDATE cuentacorrientedeudapago SET importeimp = 0
			  WHERE cuentacorrientedeudapago.iddeuda = reg_ctactedeuda.iddeuda 
				    AND cuentacorrientedeudapago.idcentrodeuda = reg_ctactedeuda.idcentrodeuda;
 			 
			 
                          -- corroboro la contabilidad generada por la imputacion
                          SELECT INTO r_minimp  * FROM  cuentacorrientedeudapagoordenpago  
                          WHERE cuentacorrientedeudapagoordenpago.iddeuda = reg_ctactedeuda.iddeuda 
				    AND cuentacorrientedeudapagoordenpago.idcentrodeuda = reg_ctactedeuda.idcentrodeuda;
                         
                          IF NOT FOUND THEN
                                 hay_minuta =false;
                          END IF;  
 
                         hay_asientogenerico = true;
                         SELECT INTO r_asientogenerico * 
                         FROM  cuentacorrientedeudapago
                         JOIN  asientogenerico ON ( idcomprobantesiges = concat(iddeuda,'|',idcentrodeuda,'|',idpago,'|',idcentropago)
                                              -- AND idasientogenericocomprobtipo=9 
                                                 )
                         WHERE iddeuda = reg_ctactedeuda.iddeuda 
                               AND idcentrodeuda = reg_ctactedeuda.idcentrodeuda;
                         
                         IF NOT FOUND THEN
                                 hay_asientogenerico =false;
                         END IF;  
                         IF (NOT hay_minuta AND NOT hay_asientogenerico) THEN
                                SELECT INTO los_pago  text_concatenar(concat('<',idpago::varchar,'-',idcentropago::varchar,'>'))
                                FROM  cuentacorrientedeudapago
                                WHERE  iddeuda = reg_ctactedeuda.iddeuda 
                                       AND idcentrodeuda = reg_ctactedeuda.idcentrodeuda
                                GROUP BY iddeuda,idcentrodeuda ;  


                                --- elimino la imputacion 
                                DELETE FROM  cuentacorrientedeudapago
                                WHERE  iddeuda = reg_ctactedeuda.iddeuda 
                                       AND idcentrodeuda = reg_ctactedeuda.idcentrodeuda;
                               RAISE NOTICE '>>>>(SI) Elimino la imputacion de la siguiente deuda (iddeuda,idcentrodeuda) (%)(%) con los siguientes pagos (%) >> ',reg_ctactedeuda.iddeuda,reg_ctactedeuda.idcentrodeuda, los_pago;  
                               
                                --Elimino la deuda
                                DELETE FROM cuentacorrientedeuda 
                                WHERE  iddeuda = reg_ctactedeuda.iddeuda 
                                       AND idcentrodeuda = reg_ctactedeuda.idcentrodeuda;  
                                RAISE NOTICE '>>>>(SI) Elimino la deuda (iddeuda,idcentrodeuda) (%)(%)',reg_ctactedeuda.iddeuda,reg_ctactedeuda.idcentrodeuda;  

                         ELSE 
                                RAISE NOTICE '>>>>(((NO))) Elimino la imputacion de la siguiente deuda (iddeuda,idcentrodeuda) (%)(%)',reg_ctactedeuda.iddeuda,reg_ctactedeuda.idcentrodeuda;
                                 

                         END IF;

			 RAISE NOTICE '>>>>>>>>>>>>>>> Se proceso la deuda (iddeuda,idcentrodeuda) (%)(%) 
 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  ' ,reg_ctactedeuda.iddeuda,reg_ctactedeuda.idcentrodeuda;


              FETCH cursor_ctactedeuda INTO reg_ctactedeuda;
    END LOOP;
    CLOSE cursor_ctactedeuda;
    RETURN true;
END;
$function$
