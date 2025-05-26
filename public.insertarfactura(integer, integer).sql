CREATE OR REPLACE FUNCTION public.insertarfactura(integer, integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* Inserta los datos de factura cada ves que en mesa de entrada se ingresa una nueva recepcion
de tipo facturacion*/
DECLARE
    rfactura RECORD;
    idrec ALIAS FOR $1;
    idcentrorecept ALIAS FOR $2;
    alta refcursor;
    cant Integer;
    nroreg integer;
    aniores integer;
    imptotal double precision;
    regfactura RECORD;
    resumen_old RECORD;
    resumen_new RECORD;


BEGIN

aniores = null;
OPEN alta FOR SELECT auditable,
          recepcion.fecha as ffecharecepcion,
          recepcion.idrecepcion,
          reclibrofact.numeroregistro as nroregistro,
          reclibrofact.anio,
--          date_part('year' ,now()) as anio,
          prestador.idprestador,
          localidad.idlocalidad,
          reclibrofact.catgasto,
          reclibrofact.numfactura as nrofactura,
          reclibrofact.monto as fimportepagar,
          reclibrofact.monto as fimportetotal,
          reclibrofact.descuento as descuento,
          reclibrofact.montosiniva as fimportesiniva,
          reclibrofact.idtipocomprobante as idtipocomprobante,
          reclibrofact.idrecepcionresumen,
          reclibrofact.idcentroregionalresumen,
          reclibrofact.clase,
          idtiporecepcion,
          CASE WHEN recepcion.idtiporecepcion = 3 THEN fechasfact.fechafin ELSE reclibrofact.fechaemision END as fechafin,
          reclibrofact.idcomprobantemultivac,
          CASE WHEN recepcion.idtiporecepcion = 3 THEN fechasfact.fechainicio ELSE reclibrofact.fechaemision END as fechainicio,
          FALSE as prefacturacion
          FROM recepcion NATURAL JOIN reclibrofact natural join tipocomprobante
 --NATURAL JOIN fechasfact
-- NATURAL JOIN localidad
 NATURAL JOIN prestador
 LEFT JOIN localidad on reclibrofact.idlocalidad=localidad.idlocalidad
 LEFT JOIN fechasfact USING(idrecepcion,idcentroregional)
      WHERE idrecepcion = idrec and idcentroregional =idcentrorecept;

FETCH alta INTO rfactura;

      --Recupera el nroRegistro del Resumen
    select numeroregistro,anio into resumen_new from reclibrofact where idrecepcion=rfactura.idrecepcionresumen and idcentroregional=rfactura.idcentroregionalresumen;

--    if not nullvalue(nroreg) THEN
--       select anio into aniores from reclibrofact where idrecepcion=rfactura.idrecepcionresumen and idcentroregional=rfactura.idcentroregionalresumen;
--       aniores = rfactura.anio;
--    end if;

    /* Corroboro si se requiere una insercion o una actualizacion*/
    SELECT INTO regfactura  * FROM factura  WHERE nroregistro= rfactura.nroregistro and anio=rfactura.anio;
    IF FOUND THEN


-- CS 2016-11-18 Apara actualizar el monto del resumen luego de una modificacion en la factura
SELECT INTO resumen_old idresumen, anioresumen 
                          FROM factura 
                          WHERE nroregistro= rfactura.nroregistro and anio=rfactura.anio; 



     

       UPDATE factura set
       idprestador = rfactura.idprestador,
       ffecharecepcion = rfactura.ffecharecepcion,
       nrofactura = rfactura.nrofactura,
       fimportesiniva = rfactura.fimportesiniva,

---------------------
      fimportetotal = rfactura.fimportetotal+rfactura.descuento,

--- VAS  280224 auditoria de facturacion debe ver el importe a auditar
  --- VAS lo vuelvo para atras 22-03-24     fimportetotal = rfactura.fimportetotal ,
--------------------

       fimportepagar = rfactura.fimportepagar,
       prefacturacion = rfactura.prefacturacion,
       idlocalidad = rfactura.idlocalidad,
       idtipocomprobante = rfactura.idtipocomprobante,
       idresumen = resumen_new.numeroregistro,
       anioresumen = resumen_new.anio,
       clase = rfactura.clase
       WHERE nroregistro= rfactura.nroregistro and anio=rfactura.anio;

       RAISE NOTICE 'va a actualizar (%)', rfactura.fimportetotal+rfactura.descuento; 

       if not ((rfactura.catgasto=4 OR rfactura.catgasto=6)) then --OR rfactura.auditable) THEN
            if nullvalue(resumen_new.numeroregistro) then
               -- cambiar estado de la factura a Rechazada
               perform cambioestadofactura(rfactura.nroregistro::integer,rfactura.anio,5);
            else
               -- cambiar estado a Pendiente
               perform cambioestadofactura(rfactura.nroregistro::integer,rfactura.anio,1);
            end if;
       end if;

-- CS 2016-11-18
-- Actualizo el Resumen_old

               UPDATE factura SET 
                              fimportetotal = (SELECT sum(fimportetotal+descuento) as fimportetotal
                                  FROM factura JOIN reclibrofact ON nroregistro=numeroregistro and factura.anio=reclibrofact.anio
                                  WHERE idresumen=resumen_old.idresumen AND anioresumen= resumen_old.anioresumen),

                              fimportepagar = (SELECT sum(fimportepagar+descuento) as fimportepagar
                                  FROM factura JOIN reclibrofact ON nroregistro=numeroregistro and factura.anio=reclibrofact.anio
                                  WHERE idresumen=resumen_old.idresumen AND anioresumen= resumen_old.anioresumen)

 
               WHERE nroregistro = resumen_old.idresumen AND factura.anio= resumen_old.anioresumen;

               UPDATE reclibrofact set fechavenc =(
                                select max(fechavenc) as fechavenc
                                from factura as f
                                     join reclibrofact r on f.nroregistro=r.numeroregistro and f.anio=r.anio
                                WHERE f.idresumen=resumen_old.idresumen AND f.anioresumen= resumen_old.anioresumen
                                )
               WHERE numeroregistro = resumen_old.idresumen AND anio = resumen_old.anioresumen;

    ELSE

         if ((rfactura.catgasto=4 OR rfactura.catgasto=6 OR rfactura.catgasto=7 
              OR rfactura.idtiporecepcion = 3  -- Para que cargue un resumen
               ) or not nullvalue(resumen_new.numeroregistro)) then  --OR rfactura.auditable) THEN
           begin          
       
         --Inserta la Factura
           INSERT INTO factura(nroregistro,anio,idprestador,ffecharecepcion,nrofactura,fimportesiniva,fimportetotal,fimportepagar,prefacturacion,idlocalidad,idtipocomprobante,
           idresumen,anioresumen,idcomprobantemultivac,clase)
           VALUES



 ------ VUELVO ATRAS 

(rfactura.nroregistro,rfactura.anio,rfactura.idprestador,rfactura.ffecharecepcion,rfactura.nrofactura,rfactura.fimportesiniva,rfactura.fimportetotal+rfactura.descuento,rfactura.fimportepagar,rfactura.prefacturacion,rfactura.idlocalidad,rfactura.idtipocomprobante,
           resumen_new.numeroregistro,resumen_new.anio,rfactura.idcomprobantemultivac,rfactura.clase);
/*
--- VAS rfactura.fimportetotal-rfactura.descuento : ahora RESTO EL DESCUENTO 280224

(rfactura.nroregistro,rfactura.anio,rfactura.idprestador,rfactura.ffecharecepcion,rfactura.nrofactura,rfactura.fimportesiniva,
rfactura.fimportetotal ,rfactura.fimportepagar,rfactura.prefacturacion,rfactura.idlocalidad,rfactura.idtipocomprobante,
           resumen_new.numeroregistro,resumen_new.anio,rfactura.idcomprobantemultivac,rfactura.clase);
*/



           --Inserta en FEstados
           INSERT INTO festados (fechacambio,nroregistro,anio,tipoestadofactura,observacion)
           VALUES (CURRENT_DATE,rfactura.nroregistro,rfactura.anio,0,'Desde mesa de Entrada');

           --Inserta en facturacionfechas
           INSERT INTO facturacionfechas (nroregistro,anio,ffechaini,ffechafin)
           VALUES(rfactura.nroregistro,rfactura.anio,rfactura.fechainicio,rfactura.fechafin);
           end;
        end if;
    END IF;


-- Actualizo el Resumen_new

               UPDATE factura SET 
                                 fimportetotal = (SELECT sum(fimportetotal+descuento) as fimportetotal
                                                          FROM factura JOIN reclibrofact ON nroregistro=numeroregistro and factura.anio=reclibrofact.anio
                                                          WHERE idresumen=resumen_new.numeroregistro AND anioresumen= resumen_new.anio),
                                 fimportepagar = (SELECT sum(fimportepagar+descuento) as fimportepagar
                                  FROM factura JOIN reclibrofact ON nroregistro=numeroregistro and factura.anio=reclibrofact.anio
                                  WHERE idresumen=resumen_new.numeroregistro AND anioresumen= resumen_new.anio)

 
               WHERE nroregistro = resumen_new.numeroregistro AND factura.anio = resumen_new.anio;

               UPDATE reclibrofact set fechavenc =(
                                select max(fechavenc) as fechavenc
                                from factura as f
                                     join reclibrofact r on f.nroregistro=r.numeroregistro and f.anio=r.anio
                                WHERE f.idresumen=resumen_new.numeroregistro AND f.anioresumen= resumen_new.anio
                                )
               WHERE numeroregistro = resumen_new.numeroregistro AND anio = resumen_new.anio;


CLOSE alta;
RETURN '';
END;
$function$
