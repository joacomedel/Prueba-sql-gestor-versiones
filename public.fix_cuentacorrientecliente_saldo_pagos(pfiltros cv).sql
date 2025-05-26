CREATE OR REPLACE FUNCTION public.fix_cuentacorrientecliente_saldo_pagos(pfiltros character varying)
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
	reg_pagosaldo RECORD;
	cursor_cliente refcursor;
	reg_cliente RECORD;
	
	cursor_pago refcursor;
	reg_pago RECORD;
	eliddeuda bigint;
    	elsaldopago double precision;
	hay_minuta boolean;
	r_minimp record;
	hay_asientogenerico boolean;
	r_asientogenerico record;
    los_pago varchar; 
BEGIN

    /***** 
     El proposito del siguiente script es eliminar las PAGOS de los afiliados a traves de la generacion de deuda
    *****/ 
    EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
    -- La siguiente consulta permite identificar los pagos que deben ser eliminadas
    -- Va a variar dependiendo del tipo de PAGO que se desea cancelar
 	
	 -- 1 busco  de los clientes solicidados
	 ---pero basicamente seria todos los saldos de los pagos de clientes hasta el 31/12/2022
	 
	 -- desactivo el trigger para que no se genere contabilidad
	 ALTER TABLE ctactedeudapagocliente DISABLE TRIGGER tr_asientogenericoimputacioncliente_crear_5; 
	 OPEN cursor_cliente FOR SELECT * 
	 FROM cliente 
	 JOIN clientectacte USING (nrocliente, barra)
	 WHERE  ---idclientectacte=24 AND
	        (denominacion ilike '%OSDE ORGANIZACION DE SERVICIOS DIRECTOS EMPRESARIOS%'
 			OR denominacion ilike '%A.M.U.C.%'
 			OR denominacion ilike '%Asoc. Mutual del Pers.Jerarquico de bancos of Nac.%'
 			OR denominacion ilike '%ASOCIACION NEUQUINA DE EMPLEADOS LEGISLATIVOS%'
 			OR denominacion ilike '%ISSN-INSTITUTO DE SEGURIDAD SOCIAL DEL NEUQUEN%'
 			OR denominacion ilike '%MEDIFE ASOCIACIÓN CIVIL%'
 			OR denominacion ilike '%MUTUAL DEL PERSONAL DE LA POLICIA DEL NEUQUEN%'
 			OR denominacion ilike '%OSDE ORGANIZACION DE SERVICIOS DIRECTOS EMPRESARIOS%'
 			OR denominacion ilike '%SWISS MEDICAL SA%'
			OR denominacion ilike '%D.O.S.U.B.A.: DIRECCION DE OBRA SOCIAL DE LA UNIVERSIDAD DE BUENOS AIRES%'
 			OR denominacion ilike '%A.S.P.U.R.C.: ACCION SOCIAL PERSONAL UNIV. NAC. DE RIO CUARTO%'	
			);

	FETCH cursor_cliente INTO reg_cliente;
	WHILE FOUND LOOP --- por cada uno de los inclientes informados
	 
			SELECT INTO reg_pagosaldo SUM(saldo) saldo, 	nrocuentac	  
			FROM ctactepagocliente 
			WHERE idclientectacte = reg_cliente.idclientectacte
			      AND idcentroclientectacte = reg_cliente.idcentroclientectacte
				  AND abs(saldo) >0 AND fechamovimiento <= '2022-12-31' 
				
				  group by 	nrocuentac	;
			 RAISE NOTICE 'Cliente (%)(%)I',reg_cliente.idclientectacte, reg_cliente.idcentroclientectacte;	  
			IF (abs(reg_pagosaldo.saldo) >0) THEN	  
			        elsaldopago = reg_pagosaldo.saldo;
		            RAISE NOTICE 'Cliente (%)(%)I',reg_cliente.idclientectacte, reg_cliente.idcentroclientectacte;
					INSERT INTO ctactedeudacliente 	(idclientectacte, idcentroclientectacte,	idcomprobantetipos,	idcomprobante,	fechamovimiento,	movconcepto,
							nrocuentac,	importe,	saldo)VALUES(reg_cliente.idclientectacte,reg_cliente.idcentroclientectacte,12,	0,current_date
						   , 'CORRECCION SALDOS AL 31/12/2022: TK 6288 - Ajuste de movimientos que forman parte de balances cerrados '
						   ,reg_pagosaldo.nrocuentac,  abs(elsaldopago),0);
                    eliddeuda = currval('ctactedeudacliente_iddeuda_seq');

                    RAISE NOTICE '>>>>>>>>>>>>>>> ID Pago Cliente (idclientectacte,idcentroclientectacte):(%) (%) (%) saldo = (%) <<<<<<<  ' ,reg_cliente.idclientectacte,reg_cliente.idcentroclientectacte, reg_cliente.denominacion, elsaldopago;
      

                    -- busco cada una de las deudas para vincular 
					OPEN cursor_pago FOR SELECT * 
					FROM ctactepagocliente 
					WHERE idclientectacte = reg_cliente.idclientectacte
			      			AND idcentroclientectacte = reg_cliente.idcentroclientectacte
							AND nrocuentac = reg_pagosaldo.nrocuentac
				  			AND abs(saldo) >0 AND fechamovimiento <= '2022-12-31' ;
					FETCH cursor_pago INTO reg_pago;		
					WHILE FOUND LOOP	
					          --- Vinculo la deuda al pago
							  INSERT INTO ctactedeudapagocliente (idpago,idcentropago ,iddeuda,idcentrodeuda,fechamovimientoimputacion,importeimp)
					          VALUES(reg_pago.idpago, reg_pago.idcentropago, eliddeuda,centro(),now(), abs(reg_pago.saldo));
							  -- Actualizo el saldo de la deuda para que quede en 0$
							  RAISE NOTICE '>>>>>>>>>>>>>>> Se imputo la deuda (%)-(%)  con el pago (%)-(%)' ,reg_pago.idpago, reg_pago.idcentropago,  eliddeuda,centro();
							  
							  
							  UPDATE ctactepagocliente SET saldo = 0
							  WHERE idpago = reg_pago.idpago AND idcentropago= reg_pago.idcentropago;
					          RAISE NOTICE '>>>>>>>>>>>>>>> Se actualizo el saldo del pago  (%)-(%) a 0' ,  reg_pago.idpago ,   reg_pago.idcentropago;
						FETCH cursor_pago INTO reg_pago;						  
				    END LOOP;
					CLOSE cursor_pago;
	 	    	END IF;
			
			
            FETCH cursor_cliente INTO reg_cliente;
    END LOOP;
    CLOSE cursor_cliente;
	   
	
	 -- vuelvo a activar el trigger para que SI se genere contabilidad
	ALTER TABLE ctactedeudapagocliente ENABLE TRIGGER tr_asientogenericoimputacioncliente_crear_5;
    RETURN true;
END;
$function$
