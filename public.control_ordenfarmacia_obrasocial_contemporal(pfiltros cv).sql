CREATE OR REPLACE FUNCTION public.control_ordenfarmacia_obrasocial_contemporal(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       
	rfiltros record; 
	
BEGIN

-- Darle permiso a Daiana y a Marcela
-- Agregarle ventas sin coberturas de Obra Social
-- Agregar cantidad de articulos por orden Listo
-- Agregar Monto x Cobertura por orden  Se saca desde la opcionde Reportes el check es Excel Ordenes Farmacia

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_control_ordenfarmacia_obrasocial_contemporal
AS (
	  SELECT 
		concat(idordenventa,'-',idcentroordenventa) as nroorden,
		ovfechaemision,
		vnombre as vendedor,
		case when nullvalue(fovv.vale) THEN 'NO' ELSE 'SI' END as tienevale,
		concat(tipofactura,' ',nrosucursal,'-',nrofactura) as numerofactura,
		numeronotacredito,
		cob,
		ovetdescripcion,
		cantarticulodiferentes,
		totalarticulos,
		monto
		,'1-Fecha Emision#ovfechaemision@2-Vendedor#vendedor@3-Factura#numerofactura@4-Nro NC#numeronotacredito@5-Nro Orden#nroorden@6-Cantidad Artirculos Diferentesc#cantarticulodiferentes@7-Total articulos#totalarticulos@8-Tiene vale#tienevale@9-Cobertura#cob@10-Monto Cobertura#monto@11-Estado#ovetdescripcion'::text as mapeocampocolumna 
	
	FROM far_ordenventa 
	NATURAL JOIN far_ordenventatipo 
	NATURAL JOIN far_ordenventaestado 
	NATURAL JOIN far_ordenventaestadotipo 
	NATURAL JOIN far_vendedor
	NATURAL JOIN (
		SELECT 
			idordenventa,
			idcentroordenventa,
			CASE WHEN t.idvalorescaja=0 THEN text_concatenar(concat(idvalorescaja,'- Sin Obra Social','|')) ELSE text_concatenar(concat(idvalorescaja,'-',lfdescripcion,'|')) END as cob,
			cantarticulodiferentes,
			totalarticulos,
			monto
		FROM  (
			SELECT DISTINCT idordenventa,idcentroordenventa,idvalorescaja,	count(*) as cantarticulodiferentes ,sum(ovicantidad) as totalarticulos,sum(oviimonto) as monto 
			FROM  far_ordenventaitem 
			NATURAL JOIN far_ordenventaitemimportes 
			--WHERE idvalorescaja  > 0
			GROUP BY idordenventa,idcentroordenventa,idvalorescaja
			ORDER BY idvalorescaja) as t
		LEFT JOIN liquidadorfiscalvalorescaja USING (idvalorescaja)
		WHERE (lfrequiereliquidar OR idvalorescaja =0)
			--AND( idvalorescaja = null or nullvalue(null))
			GROUP BY idordenventa,idcentroordenventa,cantarticulodiferentes,totalarticulos,monto,t.idvalorescaja
	) as coberturas
	
	LEFT JOIN facturaorden ON idordenventa = nroorden AND idcentroordenventa = centro AND tipofactura = 'FA'
	LEFT JOIN (
		SELECT DISTINCT idordenventa,idcentroordenventa,true as vale
		FROM  far_ordenventaitem as fovi 
		JOIN far_ordenventaitemvale as fovv ON fovv.idordenventaitemoriginal = fovi.idordenventaitem 
								AND fovv.idcentroordenventaitemoriginal = fovi.idcentroordenventaitem
	) as fovv USING(idordenventa,idcentroordenventa)
	
	LEFT JOIN (
		SELECT idordenventa,idcentroordenventa,text_concatenar(numerofactura||' | ') as numeronotacredito 
		FROM (
				SELECT idordenventa,idcentroordenventa,concat(tipofactura,' ',nrosucursal,'-',nrofactura) as numerofactura
				FROM far_ordenventa 
				NATURAL JOIN far_ordenventaitem 
				NATURAL JOIN  far_ordenventaitemitemfacturaventa
				WHERE tipofactura = 'NC'
				GROUP BY idordenventa,idcentroordenventa,tipofactura,nrofactura,nrosucursal
				ORDER BY idordenventa,idcentroordenventa
			) as t
		GROUP BY idordenventa,idcentroordenventa
	) as tieneNC USING(idordenventa,idcentroordenventa)
	
	WHERE 
		nullvalue(ovefechafin) 
		AND  ovtfacturable 
		AND ovfechaemision >= rfiltros.fechadesde
		and ovfechaemision <= rfiltros.fechahasta  
		AND (idvendedor= rfiltros.idvendedor OR nullvalue(rfiltros.idvendedor))

) 
ORDER BY ovfechaemision;
  

return 'true';
END;
$function$
