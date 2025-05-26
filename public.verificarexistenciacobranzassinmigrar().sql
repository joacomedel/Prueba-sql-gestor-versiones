CREATE OR REPLACE FUNCTION public.verificarexistenciacobranzassinmigrar()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSORES
	 clascobranzas CURSOR FOR  SELECT T.* FROM ( 

                         SELECT r.*, ccp.idpago, ccp.idcentropago, 
			CASE 
                         WHEN ccd.idcomprobantetipos=21 and ccd.nrocuentac=10333 THEN 'Turismo' 
                         WHEN ccp.tipodoc=600 THEN 'Cliente'  
			 WHEN ccd.idcomprobantetipos=7 THEN 'Turismo'  
			 WHEN ccd.idcomprobantetipos=18 OR ccd.idcomprobantetipos=17 THEN 'Prestamo'    
			 WHEN ccd.idconcepto=387 OR not nullvalue(ra.idorigenrecibo) THEN 'Asistencial'  
			
			END AS tipocobranza
			FROM cuentacorrientepagos as ccp 
-- CS 2017-02-24 agrego left
                             left JOIN cuentacorrientedeudapago AS ccdp USING (idpago, idcentropago)
			     left JOIN cuentacorrientedeuda AS ccd USING (iddeuda, idcentrodeuda)
----------------------------
			LEFT JOIN informefacturacioncobranza as ifc USING(idpago,idcentropago) 	
			JOIN recibo as r ON (ccp.idcentropago = r.centro AND ccp.idcomprobante = r.idrecibo) 
			LEFT JOIN  reciboautomatico AS ra USING(idrecibo, centro)
                        LEFT JOIN   temp_cobranzassinmigrar AS tcsm  ON(nullvalue(tcsm.filtrocentro) OR ccp.idcentropago =tcsm.filtrocentro )

			WHERE nullvalue(ifc.idpago) 
                            AND (ccp.idcentropago = tcsm.filtrocentro OR nullvalue(tcsm.filtrocentro))
                            AND (ccp.fechamovimiento::date>= tcsm.filtrofechadesde )
                            AND (ccp.fechamovimiento::date<= tcsm.filtrofechahasta )
                            AND ccp.idcomprobantetipos =0
                          
			UNION 
			SELECT r.*, ccpna.idpago, ccpna.idcentropago, 
			CASE WHEN nullvalue(ra.idrecibo) THEN 'Institucion'  ELSE 'Descuentos UNCo' END AS tipocobranza
		--FROM ctactepagonoafil  as ccpna 
                FROM ctactepagocliente  as ccpna     
                   
                        JOIN recibo as r ON (ccpna.idcentropago = r.centro AND ccpna.idcomprobante = r.idrecibo) 
                        LEFT JOIN informefacturacioncobranza as ifc USING(idpago,idcentropago) 				
			LEFT JOIN  reciboautomatico AS ra USING(idrecibo, centro)
                        LEFT JOIN   temp_cobranzassinmigrar AS tcsm  ON(nullvalue(tcsm.filtrocentro) OR ccpna.idcentropago =tcsm.filtrocentro )
			WHERE nullvalue(ifc.idpago) 
                            AND (ccpna.idcentropago = tcsm.filtrocentro OR nullvalue(tcsm.filtrocentro))
                            AND (ccpna.fechamovimiento::date>= tcsm.filtrofechadesde )     
                            AND (ccpna.fechamovimiento::date<= tcsm.filtrofechahasta )
                            AND ccpna.idcomprobantetipos =0
                            and ccpna.idpago*100+ccpna.idcentropago not in (select ccpc_idpago*100+ccpc_idcentropago from ccpc_ccpna)
			ORDER BY tipocobranza, idcentropago
                            ) AS T 
                      JOIN   temp_cobranzassinmigrar AS tcsm ON(nullvalue(tcsm.filtrotipocobranza) OR T.tipocobranza =filtrotipocobranza );

--RECORD
	elem RECORD;

BEGIN


OPEN clascobranzas;
FETCH clascobranzas INTO elem;
WHILE  found LOOP
     INSERT INTO temp_cobranzassinmigrar(importerecibo,	fecharecibo,	imputacionrecibo,	idrecibo,	centro,	idpago,	idcentropago,	tipocobranza)
     VALUES (elem.importerecibo,elem.fecharecibo,elem.imputacionrecibo,	elem.idrecibo,elem.centro,elem.idpago,elem.idcentropago,elem.tipocobranza);

    FETCH clascobranzas INTO elem;   
END LOOP;
CLOSE clascobranzas;

DELETE FROM temp_cobranzassinmigrar WHERE nullvalue(tipocobranza);
return 'true';
END;$function$
