CREATE OR REPLACE FUNCTION public.dardatoscuentaproveedor()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

	ctempcuentas refcursor;
--RECORD
	unacuenta RECORD;
	aux RECORD;
	minutareintegro RECORD;
	rcuentanrodoc RECORD;
--VARIABLES
	resultado BOOLEAN;
	
BEGIN
	OPEN ctempcuentas FOR  SELECT * FROM tempcuentaproveedor;
	FETCH ctempcuentas into unacuenta;
	WHILE FOUND LOOP
               
		SELECT INTO minutareintegro * 
		FROM informefacturacionexpendioreintegro AS ifex NATURAL JOIN ordenpagocontableordenpago AS opc
		WHERE idordenpagocontable = unacuenta.idcomprobante;
		IF FOUND THEN
    	-- es una orden de pago contable asociada a un reintegro, entonces busco al beneficiario del reintegro
			SELECT INTO rcuentanrodoc CASE WHEN nullvalue(nrodoctitu) THEN p.nrodoc ELSE bs.nrodoctitu END AS nrodoc, 
			CASE WHEN nullvalue(nrodoctitu) THEN p.tipodoc  ELSE bs.tipodoctitu END::integer  AS tipodoc,
                        CASE WHEN nullvalue(nrodoctitu) THEN concat(p.apellido,' ',p.nombres) ELSE concat(ptitu.apellido,' ',ptitu.nombres) END::text AS p_razonsocial
			FROM reintegrobenef AS rb NATURAL JOIN persona AS p --ON (rb.nrodocbenef = p.nrodoc AND rb.tipodocbenef=p.tipodoc)			
			LEFT JOIN benefsosunc AS bs USING(nrodoc, tipodoc) 
                        LEFT JOIN persona AS ptitu ON(nrodoctitu=ptitu.nrodoc AND tipodoctitu=ptitu.tipodoc) 
			WHERE rb.nroreintegro= minutareintegro.nroreintegro AND rb.anio= minutareintegro.anio AND rb.idcentroregional=minutareintegro.idcentroregional;
		ELSE
                        SELECT INTO rcuentanrodoc unacuenta.nrodoc, 12 AS tipodoc, unacuenta.p_razonsocial;
/*			rcuentanrodoc.nrodoc = unacuenta.nrodoc;
			rcuentanrodoc.tipodoc = 12;*/
			
		END IF;
                
		SELECT INTO aux *  FROM cuentas  WHERE cuentas.nrodoc  = rcuentanrodoc.nrodoc AND cuentas.tipodoc =  rcuentanrodoc.tipodoc;  

		UPDATE tempcuentaproveedor SET tipocuenta= aux.tipocuenta, nrobanco= aux.nrobanco, nrosucursal= aux.nrosucursal,
			nrocuenta= aux.nrocuenta, digitoverificador = aux.digitoverificador, cemail = aux.cemail, nrodoc=rcuentanrodoc.nrodoc, cbuini= aux.cbuini, cbufin= aux.cbufin, p_razonsocial= rcuentanrodoc.p_razonsocial
		WHERE idcomprobante = unacuenta.idcomprobante;
     
		FETCH ctempcuentas into unacuenta;
	END LOOP;
     	CLOSE ctempcuentas;
return 'true';
END;
$function$
