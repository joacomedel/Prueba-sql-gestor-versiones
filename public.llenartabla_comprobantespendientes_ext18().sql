CREATE OR REPLACE FUNCTION public.llenartabla_comprobantespendientes_ext18()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
	    curcomprobante refcursor;	
	    regcomprobante RECORD;
        cont INTEGER;
      /*  rejerciciocontable RECORD;
        rasientodesbalanceado RECORD;
        rasientocondiferencia RECORD;
        ridsiges RECORD;
        rag_r RECORD;
        xfechaimputa DATE;*/

BEGIN
    cont = 0;
  /*    -- 1 cada uno de los comprobantes que se quieren migrar

      OPEN curcomprobante FOR  SELECT  * FROM migrar_multivac_compras_2018;

      FETCH curcomprobante INTO regcomprobante;
      WHILE FOUND LOOP
                  -- 2 ingreso la info en la tabla que se va a leer para luego migrar
                  INSERT INTO com_comprobantespendientes_ext18(tipofactura,registroresumen,anioresumen,numeroregistro,anio,numfactura,clase,idprestador,pdescripcion,pcuit,
obs,monto,ffecharecepcion,descuento,exento,fechaemision,fechaimputacion,catgasto,talonario,condcompra,iva21,iva105,iva27,letra,netoiva21,netoiva105,netoiva27,
nogravado,percepciones,puntodeventa,recargo,retganancias,retiibb,retiva,subtotal,tipocambio,numero,ivatotal,tipoestadofactura,idrecepcion,tipomov,idcomprobantemultivac,actualizado,
estado,montopagado,idtipocomprobante,tipocomprobantedesc,auditable,fechavenc)
(SELECT r.tipofactura,
    res.numeroregistro AS registroresumen,
    res.anio
    AS anioresumen,
    r.numeroregistro,
    r.anio,
    r.numfactura,
    r.clase,
    p.idprestador,
    p.pdescripcion,
    p.pcuit,
    r.obs,
    r.monto,
    rr.fecha AS ffecharecepcion,
    r.descuento,
    r.exento,
    r.fechaemision,
    r.fechaimputacion,
    r.catgasto,
    r.talonario,
    r.condcompra,
    r.iva21,
    r.iva105,
    r.iva27,
    r.letra,
    r.netoiva21,
    r.netoiva105,
    r.netoiva27,
    r.nogravado,
    r.percepciones,
    r.puntodeventa,
    r.recargo,
    r.retganancias,
    r.retiibb,
    r.retiva,
    r.subtotal,
    r.tipocambio,
    r.numero,
    ((r.iva105 + r.iva21) + r.iva27) AS ivatotal,
    3 AS tipoestadofactura,
    r.idrecepcion,
        CASE
            WHEN nullvalue((map.tipomov)::text)
    THEN '1'::character varying
            ELSE
            CASE
    WHEN ((map.tipomov)::text = 'I'::text) THEN '1'::character varying
    ELSE
                CASE
                    WHEN ((map.tipomov)::text =
    'D'::text) THEN '2'::character varying
                    ELSE
    CASE
                        WHEN ((map.tipomov)::text = 'U'::text) THEN
    '3'::character varying
                        ELSE NULL::character
    varying
                    END
                END
            END
    END AS tipomov,
        CASE
            WHEN
    nullvalue((map.idcomprobantemultivac)::text) THEN (0)::bigint
    ELSE map.idcomprobantemultivac
        END AS idcomprobantemultivac,
    CASE
            WHEN nullvalue(map.update) THEN false
            ELSE
    map.update
        END AS actualizado,
    0 AS estado,
    opcr.montopagado,
    tipocomprobante.idtipocomprobante,
    tipocomprobante.tipocomprobantedesc,
    tipocomprobante.auditable,
    r.fechavenc
FROM (((((((reclibrofact r
     LEFT JOIN (
    SELECT ordenpagocontablereclibrofact.idordenpagocontable,
        ordenpagocontablereclibrofact.idcentroordenpagocontable,
        ordenpagocontablereclibrofact.numeroregistro,
        ordenpagocontablereclibrofact.anio,
        ordenpagocontablereclibrofact.montopagado,
        opce.idordenpagocontableestado,
        opce.idcentroordenpagocontableestado,
            opce.opcefechaini,
        opce.opcfechafin,
            opce.idordenpagocontableestadotipo,
        opce.opcdescripcion,
            opce.opceidusuario
    FROM (ordenpagocontablereclibrofact
             JOIN
        ordenpagocontableestado opce USING (idordenpagocontable,
        idcentroordenpagocontable))
    WHERE (nullvalue((opce.opcfechafin)::text) AND
        (opce.idordenpagocontableestadotipo <> 6))
    ) opcr USING (numeroregistro, anio))
     JOIN tipocomprobante USING
        (idtipocomprobante))
     JOIN prestador p USING (idprestador))
        JOIN recepcion rr USING (idrecepcion, idcentroregional))
     LEFT JOIN
        recepcion rrr ON (((r.idrecepcionresumen = rrr.idrecepcion) AND
        (r.idcentroregionalresumen = rrr.idcentroregional))))
     LEFT JOIN
        reclibrofact res ON (((rrr.idrecepcion = res.idrecepcion) AND
        (rrr.idcentroregional = res.idcentroregional))))
     LEFT JOIN
        mapeocompcompras map ON (((r.idrecepcion = map.idrecepcion) AND
        (r.idcentroregional = map.idcentroregional))))
WHERE ((((r.catgasto <> 4) AND (r.idtipocomprobante <> 3)) AND
    (r.numeroregistro >= 12586)) AND (r.anio >= 2010))       AND (r.numeroregistro = regcomprobante.numeroregistro AND r.anio = regcomprobante.anio)
UNION
SELECT r.tipofactura,
    res.numeroregistro AS registroresumen,
    res.anio
    AS anioresumen,
    r.numeroregistro,
    r.anio,
    r.numfactura,
    r.clase,
    p.idprestador,
    p.pdescripcion,
    p.pcuit,
    r.obs,
    r.monto,
    rr.fecha AS ffecharecepcion,
    r.descuento,
    r.exento,
    r.fechaemision,
    r.fechaimputacion,
    r.catgasto,
    r.talonario,
    r.condcompra,
    r.iva21,
    r.iva105,
    r.iva27,
    r.letra,
    r.netoiva21,
    r.netoiva105,
    r.netoiva27,
    r.nogravado,
    r.percepciones,
    r.puntodeventa,
    r.recargo,
    r.retganancias,
    r.retiibb,
    r.retiva,
    r.subtotal,
    r.tipocambio,
    r.numero,
    ((r.iva105 + r.iva21) + r.iva27) AS ivatotal,
    festadosfact.tipoestadofactura,
    r.idrecepcion,
        CASE
    WHEN nullvalue((map.tipomov)::text) THEN '1'::character varying
    ELSE
            CASE
                WHEN ((map.tipomov)::text =
    'I'::text) THEN '1'::character varying
                ELSE
    CASE
                    WHEN ((map.tipomov)::text = 'D'::text) THEN
    '2'::character varying
                    ELSE
                    CASE
    WHEN ((map.tipomov)::text = 'U'::text) THEN '3'::character varying
    ELSE NULL::character varying
                    END
                END
    END
        END AS tipomov,
        CASE
            WHEN
    nullvalue((map.idcomprobantemultivac)::text) THEN (0)::bigint
    ELSE map.idcomprobantemultivac
        END AS idcomprobantemultivac,
    CASE
            WHEN nullvalue(map.update) THEN false
            ELSE
    map.update
        END AS actualizado,
    festadosfact.tipoestadofactura
    AS estado,
    opcr.montopagado,
    tipocomprobante.idtipocomprobante,
    tipocomprobante.tipocomprobantedesc,
    tipocomprobante.auditable,
    r.fechavenc
FROM ((((((((reclibrofact r
     LEFT JOIN (
    SELECT ordenpagocontablereclibrofact.idordenpagocontable,
        ordenpagocontablereclibrofact.idcentroordenpagocontable,
        ordenpagocontablereclibrofact.numeroregistro,
        ordenpagocontablereclibrofact.anio,
        ordenpagocontablereclibrofact.montopagado,
        opce.idordenpagocontableestado,
        opce.idcentroordenpagocontableestado,
            opce.opcefechaini,
        opce.opcfechafin,
            opce.idordenpagocontableestadotipo,
        opce.opcdescripcion,
            opce.opceidusuario
    FROM (ordenpagocontablereclibrofact
             JOIN
        ordenpagocontableestado opce USING (idordenpagocontable,
        idcentroordenpagocontable))
    WHERE (nullvalue((opce.opcfechafin)::text) AND
        (opce.idordenpagocontableestadotipo <> 6))
    ) opcr USING (numeroregistro, anio))
     JOIN tipocomprobante USING
        (idtipocomprobante))
     JOIN prestador p USING (idprestador))
        JOIN recepcion rr USING (idrecepcion, idcentroregional))
     LEFT JOIN (
    SELECT f.tipoestadofactura,
            f.nroregistro,
            f.anio
    FROM festados f
    WHERE nullvalue((f.fefechafin)::text)
    ) festadosfact ON (((r.numeroregistro = festadosfact.nroregistro) AND
        (r.anio = festadosfact.anio))))
     LEFT JOIN recepcion rrr ON
        (((r.idrecepcionresumen = rrr.idrecepcion) AND
        (r.idcentroregionalresumen = rrr.idcentroregional))))
     LEFT JOIN
        reclibrofact res ON (((rrr.idrecepcion = res.idrecepcion) AND
        (rrr.idcentroregional = res.idcentroregional))))
     LEFT JOIN
        mapeocompcompras map ON (((r.idrecepcion = map.idrecepcion) AND
        (r.idcentroregional = map.idcentroregional))))
WHERE (
        ( ((r.catgasto = 4) AND (r.idtipocomprobante <> 3))
         AND (r.numeroregistro >= 12586))
         AND (r.anio >= 2010))
       AND (r.numeroregistro = regcomprobante.numeroregistro AND r.anio = regcomprobante.anio)  

);
     cont = cont + 1;
      FETCH curcomprobante INTO regcomprobante;
      END LOOP;
*/
ALTER TABLE reclibrofact DISABLE TRIGGER reclibrofact_tr;
ALTER TABLE reclibrofact DISABLE TRIGGER tr_asientogenericoreclibrofact_upd;


UPDATE reclibrofact SET obs = concat('EXT18 // ',reclibrofact.obs)
FROM com_comprobantespendientes_ext18
WHERE com_comprobantespendientes_ext18.numeroregistro = reclibrofact.numeroregistro
      and com_comprobantespendientes_ext18.anio = reclibrofact.anio;

ALTER TABLE reclibrofact ENABLE TRIGGER reclibrofact_tr;
ALTER TABLE reclibrofact ENABLE TRIGGER tr_asientogenericoreclibrofact_upd;

RETURN cont::numeric;
END;
$function$
