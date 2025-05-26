CREATE OR REPLACE FUNCTION public.expendio_darinformacioncuenta_pagostransferencia(character varying, integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

        pnrodoc alias for $1;
        ptipodoc alias for $2;
        tienecuenta boolean;
        rcuentas RECORD;
        rpersona RECORD;
        respuesta varchar;
	
BEGIN
		tienecuenta = true;
		respuesta = concat('{ nrocuenta=','0',', tipocuenta=','0',',digitoverificador = ','0'
							,',nrobanco=','0',',nrosucursal = ','0',',cbuini = ','0',',cbufin = ','0',',cemail= ','Sin cuenta');

               SELECT  INTO rpersona * FROM persona WHERE nrodoc=pnrodoc and tipodoc = ptipodoc;
		IF FOUND THEN
			IF (rpersona.barra>=1 and rpersona.barra<30) THEN
                              --Es un Beneficiario, voy a buscar la cuenta de su titular
				SELECT INTO rcuentas * FROM cuentas  
				JOIN benefsosunc ON benefsosunc.nrodoctitu = cuentas.nrodoc AND benefsosunc.tipodoctitu =cuentas.tipodoc
				WHERE benefsosunc.nrodoc = pnrodoc AND benefsosunc.tipodoc = ptipodoc; 
				IF not  FOUND then    -- si no tiene insertada nro de cuenta 
					tienecuenta = false;
				END IF;
			ELSE  -- Es titular
				SELECT INTO rcuentas * FROM cuentas  WHERE cuentas.nrodoc = pnrodoc AND cuentas.tipodoc = ptipodoc; 
				IF not  FOUND then    -- si no tiene insertada nro de cuenta 
					tienecuenta = false;
				END IF;

			END IF;
			IF tienecuenta THEN
				respuesta = concat('{ nrocuenta=',rcuentas.nrocuenta,', tipocuenta=',rcuentas.tipocuenta,',digitoverificador = ',rcuentas.digitoverificador
							,',nrobanco=',rcuentas.nrobanco,',nrosucursal = ',rcuentas.nrosucursal,',cbuini = ',rcuentas.cbuini,',cbufin = ',rcuentas.cbufin,',cemail= ',rcuentas.cemail);
			END IF;
           
           END IF;
       
return respuesta;
END;$function$
