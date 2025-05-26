CREATE OR REPLACE FUNCTION public.centro_costo_comp_compra(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;

  respuesta varchar;
BEGIN
/**
 PARAMETROS fechahasta   fechadesde

*/
     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;

     CREATE TEMP TABLE temp_centro_costo_comp_compra AS (

          SELECT *,
                '1-El Comprobante#elcomprobante@2-Comprobante#comprobante@3-Tipo factura#tipofactura@4-Letra#letra@5-Fecha emision#fechaemision@6-Fecha imputacion#fechaimputacion@7-Monto Centro#montocentro@8-NombreCentroCosto#nombrecentrocosto@9-Categoria de gasto#descripcionsiges@10-Numero registro#numregistro@11-CUIT#cuit@12-Razon Social#razonsocial@13-Iva Proveedor#ivaproveedor@14-Importe Total#importetotal@15-Imp Gravado#impgravado@16-Imp No Gravado#impnogravado@17-Descuento#descuento@18-Recargo#recargo@19-Imp IVA21#impiva21@20-Imp IVA105#impiva105@21-Imp IVA27#impiva27@22-Neto IVA105#netoiva105@23-Neto IVA21#netoiva21@24-Neto IVA27#netoiva27@25-No gravado#nogravado@26-Retiibb#retiibb@27-Ret iva#retiva@28-Percepciones IVA#percepcionesiva@29-Imp otros impuestos#impotrosimpuestos@30-Tipo gasto#tipogasto@31-Actividad#actividad@32-Id Actividad#idactividad@33-ID periodo fiscal#idperiodofiscal@34-Prestador gasto directo#procedenciagastodirecto@35-Nro Asientos#nroasientos@36-Gastos Indirectos SOSUNC#gasto_indirectososunc@37-Gastos Indirectos FARMACIA#gasto_indirectofarma@38-Otros imp#otros_imp@39-Impuestos Cred Deb#impuesto_debito_credito'::text as mapeocampocolumna
               FROM (
                  ---- Dejo por aqui la consulta 
		 SELECT     
 				concat(rf.tipofactura,':',letra,' ' ,puntodeventa,'-',numero) as elcomprobante
				,concat(puntodeventa,'-',numero) as comprobante
				, rf.tipofactura
				, letra
				, rf.fechaemision as fechaemision
				, rf.fechaimputacion AS fechaimputacion
			
				, ((CASE WHEN (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) ELSE 1 END) * (CASE WHEN nullvalue(montocentro) THEN monto ELSE montocentro END)) as montocentro
				, CASE WHEN (mcg.descripcionsiges ILIKE '%Bienes de cambio%') THEN 'Farmacia' ELSE (CASE WHEN (mcg.descripcionsiges = 'Facturacion a controlar' or ((rf.tipofactura='NCR' or rf.tipofactura='NCL') and (mcg.descripcionsiges = 'Deducciones a Prestadores' or mcg.descripcionsiges in (select descripcionsiges from multivac.mapeocatgasto natural join mapeocatgastoprestador)))) THEN 'OSocial' ELSE (CASE WHEN nullvalue(nombrecentrocosto) THEN 'Sin Definir' ELSE nombrecentrocosto END) END) END as nombrecentrocosto
                                , mcg.descripcionsiges as descripcionsiges
				, concat(numeroregistro,'-',anio) as numregistro
				, p.pcuit AS cuit
				, concat(rf.idprestador,' - ',p.pdescripcion) AS razonsocial
				, t.descripcioniva AS ivaproveedor  
				, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * monto as importetotal

				, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * 
                       (case when nullvalue(rf.netoiva21)  then 0 else (  rf.netoiva21 -rlfdescuento21 + rlfrecargo21) end 
                        + case when nullvalue(rf.netoiva105) then 0 else ( rf.netoiva105 - rlfdescuento105 +rlfrecargo105)end 
                        + case when nullvalue(rf.netoiva27)  then 0  else ( rf.netoiva27- rlfdescuento27 + rlfrecargo27) end) 

				AS impgravado 

				,  (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * ( case when nullvalue(rf.nogravado) then 0 else rf.nogravado end  + case when nullvalue(rf.exento) then 0 else rf.exento end )
				AS impnogravado  
				, (-1) * rf.descuento as descuento
				, rf.recargo as recargo
  				,(case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * case when nullvalue(iva21) then 0 else (iva21 -rlfivadescuento21 + rlfivarecargo21) end as impiva21
				, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * case when nullvalue(iva105) then 0 else (iva105- rflivadescuento105 + rlfivarecargo105) end as impiva105
				, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * case when nullvalue(iva27) then 0 else (iva27 - rlfivadescuento27 + rlfivarecargo27) end  as impiva27
				, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * case when nullvalue(netoiva105) then 0 else (netoiva105 - rlfdescuento105 +rlfrecargo105 )  end  as netoiva105	
				, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * case when nullvalue(netoiva21 ) then 0 else ( netoiva21 - rlfdescuento21 + rlfrecargo21) end as netoiva21 
				, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * case when nullvalue(netoiva27) then 0 else (netoiva27- rlfdescuento27 + rlfrecargo27) end  as netoiva27
				, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * case when nullvalue(nogravado) then 0 else nogravado end  as nogravado
				, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) * case when nullvalue(retiibb) then 0 else retiibb end  as retiibb

				, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) 
           			* (case when  rf.idprestador=6297 THEN 1 else 0 end) 
           			* retiva as retiva

				, (case when  (rf.tipofactura='NCR' or rf.tipofactura='NCL') THEN (-1) else 1 end) 
          			* (case when  rf.idprestador=6297 THEN 0 else 1 end)
          			* (case when nullvalue(rf.retiva) then 0 else rf.retiva end)  as percepcionesiva 

				, 0 as impotrosimpuestos 	
				, case when mcg.nrocuentac ilike '107%' then 2 else 1 end tipoGasto

				, case when nullvalue(rf.idactividad) then 'Obra Social' else actividad.acdescripcion end as actividad
				, case when nullvalue(rf.idactividad) then '1' else rf.idactividad end as idactividad

				,idperiodofiscal
				,CASE WHEN pcgastodirfarm THEN 'Farmacia' ELSE 'OSU' END as procedenciagastodirecto
				, asientogenerico_daridasientogenerico (concat(rf.numeroregistro,'|',rf.anio)) as nroasientos
 

				,case when (nullvalue(rf.idactividad) or rf.idactividad=1) 
           				and (not pcgastodirosu or nullvalue(pcgastodirosu) ) 
          				and (not pcgastodirfarm or nullvalue(pcgastodirfarm) )then 'Si'
 					else 'No' end as gasto_indirectososunc  
				,case when (rf.idactividad=2) 
            			and (not pcgastodirosu or nullvalue(pcgastodirosu) ) 
            			and  (not pcgastodirfarm or nullvalue(pcgastodirfarm) ) then 'Si'
 					else 'No' end as gasto_indirectofarma   -- cuando la actividad es FARMA pero no esta clasificado el prestador como gasto directo entonces es INDIRECTO

				,percepciones as otros_imp   --VAS 15-11-22

				,impdebcred as impuesto_debito_credito

		FROM  reclibrofact AS rf
		JOIN prestador p on (rf.idprestador=p.idprestador)
		LEFT JOIN prestadorconfig pc on (p.idprestador = pc.idprestador)
		JOIN condicioniva t on (p.idcondicioniva=t.idcondicioniva)
		JOIN contabilidad_periodofiscalreclibrofact using (idrecepcion,idcentroregional)
		natural join contabilidad_periodofiscal cpf
		LEFT JOIN multivac.mapeocatgasto mcg on (rf.catgasto=mcg.idcategoriagastosiges)
		LEFT JOIN (
	  			SELECT  idrecepcion,idcentroregional ,monto montocentro,nombrecentrocosto  ---replace(text_concatenar(idcentrocosto),' ','') id, text_concatenar(nombrecentrocosto) nombrecentrocosto,idrecepcion,idcentroregional
          		FROM reclibrofactitemscentroscosto
          		NATURAL JOIN centrocosto
        
		) as act USING (idrecepcion,idcentroregional)
		LEFT JOIN actividad USING(idactividad)
		WHERE fechaemision<=rparam.fechahasta
      			AND fechaemision>=rparam.fechadesde) as centrosvinculados
 

       );
 
   
    --por ahora ponemos esto. 
     respuesta = 'todook';
     
    
    
return respuesta;
END;$function$
