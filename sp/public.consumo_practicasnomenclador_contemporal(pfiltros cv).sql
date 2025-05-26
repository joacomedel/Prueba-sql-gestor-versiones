CREATE OR REPLACE FUNCTION public.consumo_practicasnomenclador_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       rfiltros RECORD;
     --  cmayor refcursor;
     --  rmayor RECORD;
BEGIN

     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

     CREATE TEMP TABLE temp_consumo_practicasnomenclador_contemporal
     AS (
        select *
        --,'1-Delegacion#crdescripcion@2-Fecha Emision#fechaemision@3-Orden#nroorden@4-Centro#centro@5-Nro.Doc.#nrodoc@6-Barra#barra@7-TipoDoc#tipodoc@8-Nombres#nombres@9-Apellido#apellido@10-Edad#edad@11-TipoOrden#tipoorden@12-Cod.Tipo#tipo@13-Cantidad#cantidad@14-Fecha Emision#fechaemision@15-ImporteFacturado#facturado@16-Imp.Pagado#apagar@17-TipoDebito#mdfdescripcion@18-ImporteDebitado#debito@19-Motivo#descripciondebito@20-Prestador#pdescripcionfinal@21-Cod.Prestador#idprestadorfinal@22-PrestadorOrden#prestadororden@23-Nro.Registro#nroregistroanio@24-Filtro Fecha#fechadesde@25-Filtro Codigo#codigofiltrado@26-Practica#lapractica@27-Descripcion#pdescripcion'::text as mapeocampocolumna
        -- BelenA 23/07/24 agrego el dato del IMPORTE DE LA ORDEN, ya que quizas la orden no fue utilizada pero igual se quiere saber el importe de la orden
--        ,'1-Delegacion#crdescripcion@2-Fecha Emision#fechaemision@3-Orden#nroorden@4-Centro#centro@5-Nro.Doc.#nrodoc@6-Barra#barra@7-TipoDoc#tipodoc@8-Nombres#nombres@9-Apellido#apellido@10-Edad#edad@11-TipoOrden#tipoorden@12-Cod.Tipo#tipo@13-Cantidad#cantidad@14-Fecha Emision#fechaemision@15-ImporteOrden#importeorden@16-ImporteFacturado#facturado@17-Imp.Pagado#apagar@18-TipoDebito#mdfdescripcion@19-ImporteDebitado#debito@20-Motivo#descripciondebito@21-Prestador#pdescripcionfinal@22-Cod.Prestador#idprestadorfinal@23-PrestadorOrden#prestadororden@24-Nro.Registro#nroregistroanio@25-Filtro Fecha#fechadesde@26-Filtro Codigo#codigofiltrado@27-Practica#lapractica@28-Descripcion#pdescripcion'::text as mapeocampocolumna
        ,'1-Delegacion#crdescripcion@2-Fecha Emision#fechaemision@3-Orden#nroorden@4-Centro#centro@5-Nro.Doc.#nrodoc@6-Barra#barra@7-TipoDoc#tipodoc@8-Nombres#nombres@9-Apellido#apellido@10-Edad#edad@11-TipoOrden#tipoorden@12-Cod.Tipo#tipo@13-Cantidad#cantidad@14-Fecha Emision#fechaemision@15-ImporteOrden#importeorden@16-ImporteFacturado#facturado@17-Imp.Pagado#importepagado@18-TipoDebito#mdfdescripcion@19-ImporteDebitado#debito@20-Motivo#descripciondebito@21-Prestador#pdescripcionfinal@22-Cod.Prestador#idprestadorfinal@23-PrestadorOrden#prestadororden@24-Nro.Registro#nroregistroanio@25-Filtro Fecha#fechadesde@26-Filtro Codigo#codigofiltrado@27-Practica#lapractica@28-Descripcion#pdescripcion'::text as mapeocampocolumna

        from (
            SELECT crdescripcion,fechaemision,nroorden,centro,nrodoc,barra,tipodoc,nombres,apellido,extract('year' from age(fechanac)) as edad,CASE WHEN emitidas.tipo = 55 THEN 'Reintegro' ELSE concat('O.Valorizada_',emitidas.tipo) END as tipoorden,emitidas.tipo,cantidad,importeorden
            --,CASE WHEN emitidas.tipo = 55 THEN importeorden ELSE ordenesutilizadas.importe END as importepagado
                ,CASE WHEN nullvalue(p1.idprestador) THEN p2.idprestador ELSE p1.idprestador END as idprestadorfinal
                ,CASE WHEN nullvalue(p1.pdescripcion) THEN p2.pdescripcion ELSE p1.pdescripcion END as pdescripcionfinal
                ,case WHEN nullvalue(p3.idprestador) THEN '' ELSE concat(p3.idprestador,'-',p3.pdescripcion) END as prestadororden
                ,case WHEN nullvalue(nroregistro) THEN 'No facturada' ELSE concat(nroregistro,'-',anio) END as nroregistroanio
                ,rfiltros.fechadesde::date
                ,rfiltros.codigofiltrado::varchar
                ,concat(emitidas.idnomenclador,'.',emitidas.idcapitulo,'.',emitidas.idsubcapitulo,'.',emitidas.idpractica) as lapractica,emitidas.pdescripcion
                ,fmpaiimportes as facturado,
                --fmpaiimportetotal as apagar,
                fmpaimportedebito as debito,case when nullvalue(fmpadescripciondebito) then '' else
                fmpadescripciondebito end   as descripciondebito
                ,mdfdescripcion,

                -- BelenA 24/07/24  cambio que el importe pagado sea el que se muestre en "Imp.Pagado" en vez de que se muestre "apagar".
                -- Esto es porque así muestro el de los reintegros como lo mostraba ANTES (Lo cambiaron y agregaron lo de fichamedicapreauditada pero no se cuando)
                CASE WHEN emitidas.tipo = 55 THEN importeorden ELSE fmpaiimportetotal END as importepagado
 

 
            FROM (
                    select fechaemision,nrodoc,tipodoc,nroorden,centro,orden.tipo,nromatricula,sum(cantidad) as cantidad,sum(importe*cantidad) as importeorden,
                        idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion
                    from orden 
                    natural join ordvalorizada 
                    natural join itemvalorizada 
                    natural join item 
                    natural join practica 
                    NATURAL JOIN consumo
                    where fechaemision >= rfiltros.fechadesde
                    AND fechaemision <= rfiltros.fechahasta

                    AND (
                      (concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica) = rfiltros.codigofiltrado )
                    OR (concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.','**') = rfiltros.codigofiltrado AND split_part(rfiltros.codigofiltrado,'.',4) = '**'  )
                    OR (concat(idnomenclador,'.',idcapitulo,'.','**','.','**') = rfiltros.codigofiltrado AND split_part(rfiltros.codigofiltrado,'.',3) = '**'  )
                    OR (concat(idnomenclador,'.','**','.','**','.','**') = rfiltros.codigofiltrado AND split_part(rfiltros.codigofiltrado,'.',2) = '**'  )
                    OR (concat('**','.','**','.','**','.','**') = rfiltros.codigofiltrado AND split_part(rfiltros.codigofiltrado,'.',1) = '**'  )
                    or nullvalue(rfiltros.codigofiltrado)
                    ) AND not anulado
                    group by fechaemision,nroorden,centro,nrodoc,tipodoc,tipo,nromatricula,idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion
                    order by fechaemision
                ) as emitidas
            NATURAL JOIN persona
            LEFT JOIN ordenesutilizadas USING(nroorden,centro,tipo)
            LEFT JOIN facturaordenesutilizadas USING(nroorden,centro,tipo)

            LEFT JOIN  
            (  SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada,idplancovertura
                        FROM  fichamedicapreauditadaitemconsulta 
                        NATURAL JOIN ordconsulta
                        UNION
                        SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada,idplancovertura
                        FROM fichamedicapreauditadaitem
                        NATURAL JOIN itemvalorizada
            ) as datoauditoria USING(nroorden,centro)

            -- BelenA 23/07/24 cambio el natural join a un left porque muchas ordenes no me las traia porque no estaban preauditadas 
            --natural JOIN fichamedicapreauditada
            LEFT JOIN  fichamedicapreauditada USING (idfichamedicapreauditada, idcentrofichamedicapreauditada)
             
            LEFT JOIN motivodebitofacturacion using(idmotivodebitofacturacion)

            -- BelenA 23/07/24 cambio el natural join a un left porque la ficha medica me trae datos del codigo de la practica y se rompia
            --NATURAL JOIN practica
            LEFT JOIN practica ON (emitidas.idnomenclador=practica.idnomenclador AND emitidas.idcapitulo=practica.idcapitulo AND 
              emitidas.idsubcapitulo=practica.idsubcapitulo AND emitidas.idpractica=practica.idpractica)

            LEFT JOIN factura USING(nroregistro,anio)
            LEFT JOIN (select nroorden,centro,idprestador
                       FROM catalogoordencomprobante
                       JOIN catalogocomprobante USING(idcatalogocomprobante,idcentrocatalogocomprobante)
                       GROUP BY nroorden,centro,idprestador
            ) as catalogo USING(nroorden,centro)
            LEFT JOIN prestador as p1 ON factura.idprestador = p1.idprestador
            LEFT JOIN prestador as p2 ON catalogo.idprestador = p2.idprestador
            LEFT JOIN prestador as p3 ON emitidas.nromatricula = p3.idprestador 
            LEFT JOIN centroregional ON idcentroregional = centro
            where (facturaordenesutilizadas.nroregistro=rfiltros.nroregistro or nullvalue(rfiltros.nroregistro))
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
