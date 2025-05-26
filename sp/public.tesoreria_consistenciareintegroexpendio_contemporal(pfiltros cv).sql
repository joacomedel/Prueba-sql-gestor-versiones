CREATE OR REPLACE FUNCTION public.tesoreria_consistenciareintegroexpendio_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_tesoreria_consistenciareintegroexpendio_contemporal
AS (
	SELECT DISTINCT opce.idordenpagocontableestadotipo,concat(opc.idordenpagocontable,'-',opc.idcentroordenpagocontable) as nroopc,concat(nroordenpago,'-',idcentroordenpago) as nrominuta,concat(nroorden,'-',orden.centro) as nroordenexpendio,
	  concat(tipofactura,' ',nrosucursal,'-',nrofactura,'-',tipocomprobante) as nrofactura, CASE WHEN nullvalue(anulada) THEN '' ELSE anulada::text END AS anulada, facturaventa.fechaemision as fechaemisionot, concat(p.apellido, ' ', p.nombres) as elafiliado,concat(p.nrodoc, '-',p.barra) as nroafil,crdescripcion,importeefectivo,to_char( case when not nullvalue(bofechapago) then bofechapago else opc.opcfechaingreso end ,'DD/MM/YYYY') as fechaoperacion
,abs(importeorden - rimporte) as diferencia, bonrooperacion::varchar as nrooperacion,case when (opce.idordenpagocontableestadotipo=6) then '' else fpdescripcion end as fpdescripcion,opcetdescripcion	, concat(reintegro.nroreintegro,'-', reintegro.anio,'-', reintegro.idcentroregional) as elreintegro
	  ,'1-Fcha Emision#fechaemisionot@2-Comprobante#nrofactura@3-Cliente#elafiliado@4-Nro.Siges#nroafil@5-CR#crdescripcion@6-Total OT#importeefectivo@7-F. Operacion#fechaoperacion@8-Nro. OP#nroopc@9-Nro. Transf#nrooperacion@10-Forma Pago#fpdescripcion@11-Estado OP#opcetdescripcion@12-Nro.Reintegro#elreintegro@13-Diferencia(Orden/Reintegro)#diferencia'::text as mapeocampocolumna 
	     FROM  orden 
		natural join reintegroorden 
		natural join reintegro  
		NATURAL JOIN ordenpago
		NATURAL JOIN (SELECT nroorden,centro,sum(importe) as importeorden,fechaemision 
			       FROM orden 
				NATURAL JOIN consumo 
				NATURAL JOIN importesorden 
				WHERE not anulado and idformapagotipos <> 6 AND tipo = 55 
				GROUP BY nroorden,centro,fechaemision
				) as infoorden
		LEFT join facturaorden USING(nroorden,centro)
		LEFT JOIN facturaventa USING(nrosucursal,nrofactura,tipocomprobante,tipofactura) LEFT JOIN   persona p ON facturaventa.nrodoc = p.nrodoc
                LEFT JOIN centroregional cr ON facturaventa.centro=cr.idcentroregional 
		LEFT JOIN ordenpagocontableordenpago opcr USING(nroordenpago,idcentroordenpago)                
                LEFT JOIN ordenpagocontable opc using ( idordenpagocontable,idcentroordenpagocontable)                
                LEFT JOIN ordenpagocontableestado opce ON (opc.idcentroordenpagocontable = opce.idcentroordenpagocontable 
                                                           and  opc.idordenpagocontable= opce.idordenpagocontable and nullvalue(opcfechafin)
                                                        )
                LEFT JOIN ordenpagocontableestadotipo USING(idordenpagocontableestadotipo)
                LEFT JOIN pagoordenpagocontable popc  ON (opc.idcentroordenpagocontable = popc.idcentroordenpagocontable 
                                                           and  opc.idordenpagocontable= popc.idordenpagocontable
                                                           )
                LEFT JOIN valorescaja using(idvalorescaja)
                LEFT JOIN formapagotipos using(idformapagotipos)
                LEFT JOIN ordenpagocontablebancatransferencia using (idcentropagoordenpagocontable ,idpagoordenpagocontable)
                LEFT JOIN bancatransferencia using (idbancatransferencia)
                LEFT JOIN bancaoperacion using (idbancaoperacion)
          
         WHERE   orden.fechaemision >=  /*'2018-06-01'*/ rfiltros.fechadesde 
                    and orden.fechaemision <=  /*'2018-06-01'*/ rfiltros.fechahasta AND tipo = 55 
	

);
  

return true;
END;
$function$
