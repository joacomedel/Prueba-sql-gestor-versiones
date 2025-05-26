CREATE OR REPLACE FUNCTION public.insertarfactura(integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Inserta los datos de factura cada ves que en mesa de entrada se ingresa una nueva recepcion
de tipo facturacion*/
DECLARE
    rfactura RECORD;
    idrec ALIAS FOR $1;
    alta refcursor;
    cant Integer;
    nroreg integer;
    aniores integer;
    imptotal double precision;

BEGIN
aniores = null;
OPEN alta FOR SELECT
          recepcion.fecha as ffecharecepcion,
          recepcion.idrecepcion,
          reclibrofact.numeroregistro as nroregistro,
          reclibrofact.anio,
/*--          date_part('year' ,now()) as anio,*/
          prestador.idprestador,
          localidad.idlocalidad,
          reclibrofact.numfactura as nrofactura,
          reclibrofact.monto as fimportepagar,
          reclibrofact.monto as fimportetotal,
          reclibrofact.idtipocomprobante as idtipocomprobante,
          reclibrofact.idrecepcionresumen,
          reclibrofact.idcentroregionalresumen,
           reclibrofact.clase,
          fechasfact.fechafin,
          reclibrofact.idcomprobantemultivac,
          fechasfact.fechainicio,
          FALSE as prefacturacion
          FROM recepcion NATURAL JOIN reclibrofact
 NATURAL JOIN fechasfact
-- NATURAL JOIN localidad
 LEFT JOIN localidad on reclibrofact.idlocalidad=localidad.idlocalidad
 NATURAL JOIN prestador
      WHERE idrecepcion = idrec;

FETCH alta INTO rfactura;
      --Recupera el nroRegistro del Resumen
    select numeroregistro into nroreg from reclibrofact where idrecepcion=rfactura.idrecepcionresumen and anio=rfactura.anio;
    if not nullvalue(nroreg) THEN
       aniores = rfactura.anio;
    end if;
      --Inserta la Factura
    INSERT INTO factura(nroregistro,anio,idprestador,ffecharecepcion,nrofactura,fimportetotal,fimportepagar,prefacturacion,idlocalidad,idtipocomprobante,
    idresumen,anioresumen,idcomprobantemultivac,clase)
    VALUES (rfactura.nroregistro,rfactura.anio,rfactura.idprestador,rfactura.ffecharecepcion,rfactura.nrofactura,rfactura.fimportetotal,rfactura.fimportepagar,rfactura.prefacturacion,rfactura.idlocalidad,rfactura.idtipocomprobante,
    nroreg,aniores,rfactura.idcomprobantemultivac,rfactura.clase);
    
    /*
    Si la factura cargada pertenece a un Resumen, entonces actualiza el importe Total del Resumen = suma de los importes
    de todas sus facturas
    */
    if not nullvalue(rfactura.idrecepcionresumen) then
       select sum(fimportetotal) into imptotal
       from factura
            where anio=rfactura.anio and idresumen=nroreg;
       update factura
            set fimportetotal=imptotal
            where nroregistro=nroreg and anio=rfactura.anio;
    end if;
    --Inserta en FEstados
    INSERT INTO festados (fechacambio,nroregistro,anio,tipoestadofactura,observacion)
    VALUES (CURRENT_DATE,rfactura.nroregistro,rfactura.anio,0,'Desde mesa de Entrada');

WHILE  found LOOP
    INSERT INTO facturacionfechas (nroregistro,anio,ffechaini,ffechafin)
    VALUES(rfactura.nroregistro,rfactura.anio,rfactura.fechainicio,rfactura.fechafin);
FETCH alta INTO rfactura;
END LOOP;
CLOSE alta;
RETURN TRUE;
END;
$function$
