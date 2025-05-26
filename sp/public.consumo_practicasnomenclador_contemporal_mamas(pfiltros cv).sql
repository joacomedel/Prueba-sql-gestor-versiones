CREATE OR REPLACE FUNCTION public.consumo_practicasnomenclador_contemporal_mamas(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       rfiltros RECORD;
     --  cmayor refcursor;
     --  rmayor RECORD;
BEGIN

     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

     CREATE TABLE temp_consumo_practicasnomenclador_contemporal_mamas
     AS (
        select *
        --,'1-Delegacion#crdescripcion@2-Fecha Emision#fechaemision@3-Orden#nroorden@4-Centro#centro@5-Nro.Doc.#nrodoc@6-TipoDoc#tipodoc@7-Nombres#nombres@8-Apellido#apellido@9-Edad#edad@10-TipoOrden#tipoorden@11-Cod.Tipo#tipo@12-Cantidad#cantidad@13-Fecha Emision#fechaemision@14-Importe#importeorden@15-Imp.Pagado#importepagado@16-Cod.Prestador#idprestadorfinal@17-Prestador#pdescripcionfinal@18-Filtro Fecha#fechadesde@19-Filtro Codigo#codigofiltrado'::text as mapeocampocolumna
        from (
             SELECT crdescripcion,fechaemision,nroorden,centro,nrodoc,tipodoc,nombres,apellido,extract('year' from age(fechanac)) as edad,CASE WHEN tipo = 55 THEN 'Reintegro' ELSE concat('O.Valorizada_',emitidas.tipo) END as tipoorden,emitidas.tipo,codigopractica,cantidad,importeorden,CASE WHEN tipo = 55 THEN importeorden ELSE ordenesutilizadas.importe END as importepagado
,CASE WHEN nullvalue(p1.idprestador) THEN p2.idprestador ELSE p1.idprestador END as idprestadorfinal
,CASE WHEN nullvalue(p1.pdescripcion) THEN p2.pdescripcion ELSE p1.pdescripcion END as pdescripcionfinal
,rfiltros.fechadesde::date
,rfiltros.codigofiltrado::varchar
--,p1.idprestador as idprestadorfactura,p1.pdescripcion as prestadorfactura
--,p2.idprestador as idprestadororden,p2.pdescripcion as prestadororden
 FROM (
select fechaemision,nrodoc,tipodoc,nroorden,centro,tipo,concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica) as codigopractica,sum(cantidad) as cantidad,sum(importe*cantidad) as importeorden
from orden natural join ordvalorizada natural join itemvalorizada natural join item NATURAL JOIN consumo
where fechaemision >= rfiltros.fechadesde
AND (
  (concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica) = '12.34.06.01' )
OR (concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica) = '12.34.06.10'  )
OR (concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica) = '12.34.06.02'  )

) AND not anulado
group by fechaemision,nroorden,centro,nrodoc,tipodoc,tipo,concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica),nromatricula
order by fechaemision
) as emitidas
NATURAL JOIN persona
LEFT JOIN ordenesutilizadas USING(nroorden,centro,tipo)
LEFT JOIN facturaordenesutilizadas USING(nroorden,centro,tipo)
LEFT JOIN factura USING(nroregistro,anio)
LEFT JOIN (select nroorden,centro,idprestador
           FROM catalogoordencomprobante
           JOIN catalogocomprobante USING(idcatalogocomprobante,idcentrocatalogocomprobante)
           GROUP BY nroorden,centro,idprestador
) as catalogo USING(nroorden,centro)
LEFT JOIN prestador as p1 ON factura.idprestador = p1.idprestador
LEFT JOIN prestador as p2 ON catalogo.idprestador = p2.idprestador
LEFT JOIN centroregional ON idcentroregional = centro

order by crdescripcion,fechaemision
       ) as x
--LIMIT 100
    );

--  OPEN  cmayor FOR
--          SELECT * FROM temp_asientogenerico_mayordecuenta_contemporal;
--    FETCH cmayor INTO rmayor;
--    WHILE FOUND LOOP
--          UPDATE temp_asientogenerico_mayordecuenta_contemporal as t
--          SET Leyenda = --contabilidad_info(concat('{idasientogenericoitem=',rmayor.idasientogenericoitem,',idcentroasientogenericoitem=',rmayor.idcentroasientogenericoitem,',nrocuentac=',rmayor.idCuenta,',acid_h=',rmayor.D_H,'}'))
--          WHERE t.idasientogenericoitem = rmayor.idasientogenericoitem
--                and t.idcentroasientogenericoitem = rmayor.idcentroasientogenericoitem
--                AND idasientogenericoitem <>0;
--          FETCH cmayor INTO rmayor;
--    END LOOP;
--

RETURN true;
END;
$function$
