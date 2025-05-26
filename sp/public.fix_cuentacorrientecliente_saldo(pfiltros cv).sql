CREATE OR REPLACE FUNCTION public.fix_cuentacorrientecliente_saldo(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       /*
	   este SP se utiliza para volver a 0 
	   
	   */
    arr varchar[];
    array_len integer;
    rfiltros record;
        vquery varchar;
	reg_deudasaldo RECORD;
	cursor_cliente refcursor;
	reg_cliente RECORD;
	
	cursor_deuda refcursor;
	reg_deuda RECORD;
	elidpago bigint;
    	elsaldodeuda double precision;
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
 	
	 -- 1 busco las deudas de los clientes solicidados
	 ---pero basicamente seria toda la deuda de clientes hasta el 31/12/2022
	 
	 -- desactivo el trigger para que no se genere contabilidad
	 ALTER TABLE ctactedeudapagocliente DISABLE TRIGGER tr_asientogenericoimputacioncliente_crear_5; 
	 OPEN cursor_cliente FOR SELECT * 
	 FROM cliente 
	 JOIN clientectacte USING (nrocliente, barra)
	 WHERE denominacion ilike '%OSDE ORGANIZACION DE SERVICIOS DIRECTOS EMPRESARIOS%'
 			OR denominacion ilike '%A.M.U.C.%'
 			--OR denominacion ilike '%Asoc. Mutual del Pers.Jerarquico de bancos of Nac.%'
 			--OR denominacion ilike '%ASOCIACION NEUQUINA DE EMPLEADOS LEGISLATIVOS%'
 			--OR denominacion ilike '%ISSN-INSTITUTO DE SEGURIDAD SOCIAL DEL NEUQUEN%'
 			--OR denominacion ilike '%MEDIFE ASOCIACIÓN CIVIL%'
 			--OR denominacion ilike '%MUTUAL DEL PERSONAL DE LA POLICIA DEL NEUQUEN%'
 			OR denominacion ilike '%OSDE ORGANIZACION DE SERVICIOS DIRECTOS EMPRESARIOS%'
 			OR denominacion ilike '%SWISS MEDICAL SA%'
			--OR denominacion ilike '%D.O.S.U.B.A.: DIRECCION DE OBRA SOCIAL DE LA UNIVERSIDAD DE BUENOS AIRES%'
 			--OR denominacion ilike '%A.S.P.U.R.C.: ACCION SOCIAL PERSONAL UNIV. NAC. DE RIO CUARTO%'	
			;

	FETCH cursor_cliente INTO reg_cliente;
	WHILE FOUND LOOP --- por cada uno de los inclientes informados
			SELECT INTO reg_deudasaldo SUM(saldo) saldo, 	nrocuentac	  
			FROM ctactedeudacliente 
			WHERE idclientectacte = reg_cliente.idclientectacte
			      AND idcentroclientectacte = reg_cliente.idcentroclientectacte
				  AND abs(saldo) >0 AND fechamovimiento <= '2022-12-31' 
				  group by 	nrocuentac	;
			IF (reg_deudasaldo.saldo >0) THEN	  
			        elsaldodeuda = reg_deudasaldo.saldo;
		           
					INSERT INTO ctactepagocliente  (idclientectacte,	idcomprobantetipos,	idcomprobante,	fechamovimiento,	movconcepto,	nrocuentac,	importe,	saldo,	idcentroclientectacte)
					VALUES(reg_cliente.idclientectacte,12,	0,current_date, 'CORRECCION SALDOS AL 31/12/2022: TK 6288 - Ajuste de movimientos que forman parte de balances cerrados ',reg_deudasaldo.nrocuentac,(-1)* abs(elsaldodeuda),0,reg_cliente.idcentroclientectacte);
                    elidpago = currval('ctactepagocliente_idpago_seq');

                    RAISE NOTICE '>>>>>>>>>>>>>>> ID Pago Cliente (idclientectacte,idcentroclientectacte):(%) (%) (%) saldo = (%) <<<<<<<  ' ,reg_cliente.idclientectacte,reg_cliente.idcentroclientectacte, reg_cliente.denominacion, elsaldodeuda;
      

                    -- busco cada una de las deudas para vincular 
					OPEN cursor_deuda FOR SELECT * 
					FROM ctactedeudacliente 
					WHERE idclientectacte = reg_cliente.idclientectacte
			      			AND idcentroclientectacte = reg_cliente.idcentroclientectacte
							AND nrocuentac = reg_deudasaldo.nrocuentac
				  			AND abs(saldo) >0 AND fechamovimiento <= '2022-12-31' ;
					FETCH cursor_deuda INTO reg_deuda;		
					WHILE FOUND LOOP	
					          --- Vinculo la deuda al pago
							  INSERT INTO ctactedeudapagocliente (idpago,idcentropago ,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp)
					          VALUES(elidpago,centro(),reg_deuda.iddeuda, reg_deuda.idcentrodeuda,now(), reg_deuda.saldo);
							  -- Actualizo el saldo de la deuda para que quede en 0$
							  RAISE NOTICE '>>>>>>>>>>>>>>> Se imputo la deuda (%)-(%)  con el pago (%)-(%)' ,reg_deuda.iddeuda, reg_deuda.idcentrodeuda,  elidpago,centro();
							  
							  
							  UPDATE ctactedeudacliente SET saldo = 0
							  WHERE iddeuda = reg_deuda.iddeuda AND idcentrodeuda= reg_deuda.idcentrodeuda;
					          RAISE NOTICE '>>>>>>>>>>>>>>> Se actualizo el saldo de la deuda  (%)-(%) a 0' ,  reg_deuda.iddeuda ,  reg_deuda.idcentrodeuda;
						FETCH cursor_deuda INTO reg_deuda;			  
				    END LOOP;
					CLOSE cursor_deuda;
	 	    	END IF;
			
			
            FETCH cursor_cliente INTO reg_cliente;
    END LOOP;
    CLOSE cursor_cliente;
	   
	
	 -- vuelvo a activar el trigger para que SI se genere contabilidad
	ALTER TABLE ctactedeudapagocliente ENABLE TRIGGER tr_asientogenericoimputacioncliente_crear_5;
    RETURN true;
END;
$function$
