CREATE OR REPLACE FUNCTION public.far_cancelarliquidacion(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
--REGISTRO
rovliquidacion RECORD; 
rlaliquidacion RECORD;
rexistedeuda RECORD; 
rfiltros RECORD; 
--CURSOR
covliqitem refcursor;

BEGIN

 EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

 PERFORM far_cambiarestadoliquidacion(rfiltros.idliquidacion, rfiltros.idcentroliquidacion, rfiltros.idestadotipo);


 SELECT INTO rlaliquidacion * FROM far_liquidacion  WHERE idliquidacion=rfiltros.idliquidacion AND  idcentroliquidacion=rfiltros.idcentroliquidacion;

 IF rlaliquidacion.coseguro THEN   
	OPEN covliqitem FOR SELECT * FROM far_liquidacionitems NATURAL JOIN far_liquidacionitemovii 
			WHERE idliquidacion=rfiltros.idliquidacion AND idcentroliquidacion=rfiltros.idcentroliquidacion;
	FETCH covliqitem into rovliquidacion;
	WHILE FOUND LOOP
                                 
		PERFORM  far_cambiarestadoordenventaitemimporte(rovliquidacion.idordenventaitemimporte
                                         ,rovliquidacion.idcentroordenventaitemimporte,13,concat('Al cancelar liquidacion ',rfiltros.idliquidacion, '-',rfiltros.idcentroliquidacion));
		FETCH covliqitem into rovliquidacion;
	END LOOP;
	CLOSE covliqitem;
/*BORRO LOS ITEMS PARA QUE PUEDAN ESTAR EN OTRA LIQUIDACION*/
	DELETE FROM far_liquidacionitemovii WHERE (idordenventaitem, idcentroordenventaitem, idordenventaitemimporte, idcentroordenventaitemimporte) 
            IN  ( SELECT idordenventaitem, idcentroordenventaitem, idordenventaitemimporte, idcentroordenventaitemimporte
                  FROM far_liquidacionitemovii NATURAL join far_liquidacionitems 
                  WHERE  idliquidacion=rfiltros.idliquidacion AND idcentroliquidacion=rfiltros.idcentroliquidacion);

ELSE 
        open covliqitem FOR SELECT * FROM far_liquidacionitems NATURAL JOIN far_liquidacionitemfvc 
               WHERE idliquidacion=rfiltros.idliquidacion AND idcentroliquidacion=rfiltros.idcentroliquidacion;
	FETCH covliqitem into rovliquidacion;
	WHILE FOUND LOOP 
		PERFORM  far_cambiarestadofacturaventacupon(rovliquidacion.idfacturacupon,rovliquidacion.centro,rovliquidacion.nrofactura,
                           rovliquidacion.tipocomprobante,rovliquidacion.nrosucursal,rovliquidacion.tipofactura,13,concat('Al cancelar liquidacion ',rfiltros.idliquidacion, '-',rfiltros.idcentroliquidacion));
                FETCH covliqitem into rovliquidacion;
	END LOOP;
	CLOSE covliqitem;
END IF;

  return true;
end;
$function$
