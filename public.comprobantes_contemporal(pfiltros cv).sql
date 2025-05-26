CREATE OR REPLACE FUNCTION public.comprobantes_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
    
    rfiltros record;
        vfechadesde varchar;
        vfechahasta varchar; 
        vquery text;
        vselectasiento  text;
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
--(rfiltros.idconac= 1) con asientos contables
vselectasiento  = case when rfiltros.idconac= 1 then 'concat(ag.idasientogenerico,''|'',ag.idcentroasientogenerico)' else 'null' end ;

--MaLaPi 06/12/2021 Saco el filtro del estado anulada de las OPC, pues como esta en la subqueri y es un Left JOIN, lo unico que se logra es no mostrar la descripcion del estado, hable con Andrea P y me dijo que las muestre pero anuladas, pues puede servir como control cuando sea necesario encontrar una OPC

 SELECT INTO vquery concat('CREATE TEMP TABLE temp_comprobantes_contemporal
AS (

SELECT   
nrofactura, t.razonsocial, t.tcgdescripcion, t.fechaemision, t.ffecharecepcion, t.numeroregistro, t.anio,t.pdescripcion,t.pcuit, t.ctacble
, t.netoiva, t.iva, t.exento, t.monto, t.descuento, t.retiibb, t.retiva, t.nogravado, t.fechaoperacion , t.laopc, 
t.bonrooperacion, 
--t.tipoformapagodesc , 
text_concatenar(concat('''',t.tipoformapagodesc))as tipoformapagodesc,
t.opcetdescripcion, 
t.idasientocontable, 
t.saldo,
t.tipofactura,
t.nrocuentac, t.desccuenta, t.fechavenc, 
t.agfechacontable,
t.mapeocampocolumna

FROM(
        SELECT pdescripcion as razonsocial, tcgdescripcion, fechaemision,rr.fecha AS ffecharecepcion,concat(puntodeventa,''-'',numero) as nrofactura,numeroregistro,anio,pdescripcion,pcuit, descripcionsiges as ctacble
        , CASE WHEN tipofactura ILIKE ''NCR'' AND netoiva21<>0 THEN netoiva21*-1 
               WHEN tipofactura ILIKE ''NCR'' AND netoiva105<>0 THEN netoiva105*-1 
               WHEN tipofactura ILIKE ''NCR'' AND netoiva27<>0 THEN netoiva27*-1 
               WHEN tipofactura NOT ILIKE ''NCR'' AND netoiva21<>0 THEN netoiva21 
               WHEN tipofactura NOT ILIKE ''NCR'' AND netoiva105<>0 THEN netoiva105 
               WHEN tipofactura NOT ILIKE ''NCR'' AND netoiva27<>0 THEN netoiva27 
          END AS netoiva
        , CASE WHEN tipofactura ILIKE ''NCR'' AND iva21<>0 THEN iva21*-1 
               WHEN tipofactura ILIKE ''NCR'' AND iva105<>0 THEN iva105*-1 
               WHEN tipofactura ILIKE ''NCR'' AND iva27<>0 THEN iva27*-1 
               WHEN tipofactura NOT ILIKE ''NCR'' AND iva21<>0 THEN iva21 
               WHEN tipofactura NOT ILIKE ''NCR'' AND iva105<>0 THEN iva105 
               WHEN tipofactura NOT ILIKE ''NCR'' AND iva27<>0 THEN iva27 
          END AS iva
        , CASE WHEN tipofactura ILIKE ''NCR'' THEN exento*-1 ELSE exento END AS exento
        , CASE WHEN tipofactura ILIKE ''NCR'' THEN monto*-1 ELSE monto END AS monto
        , cuentascontables.nrocuentac, desccuenta,fechavenc,(descuento*-1) as descuento
        , CASE WHEN tipofactura ILIKE ''NCR'' THEN retiibb*-1 ELSE retiibb END AS retiibb
        , CASE WHEN tipofactura ILIKE ''NCR'' THEN retiva*-1 ELSE retiva END AS retiva
        , CASE WHEN tipofactura ILIKE ''NCR'' THEN nogravado*-1 ELSE nogravado END AS nogravado
        , CASE WHEN not nullvalue(bofechapago) THEN bofechapago ELSE opc.opcfechaingreso END as fechaoperacion , 
         CONCAT(opc.idordenpagocontable,''-'',opc.idcentroordenpagocontable) as laopc, bonrooperacion, 
         --case when nullvalue(idcheque) then descripcion else ''CHEQUE'' end as tipoformapagodesc , 

         CASE WHEN not nullvalue(idcheque) THEN ''CHEQUE'' ELSE
            CASE WHEN nullvalue(descripcion) THEN '' '' ELSE descripcion END
            END AS tipoformapagodesc,

         opcetdescripcion
        , case when nullvalue( ',vselectasiento,') then '''' else ', vselectasiento    ,' end as idasientocontable, 
          round(CAST((ccp.saldo) AS numeric),2)  saldo,
        tipofactura
        , ag.agfechacontable as agfechacontable

        , ''1-Nro.Registro#numeroregistro@2-Anio#anio@3-Razon Social#razonsocial@4-Tipo Factura#tipofactura@5-Nro.Factura#nrofactura@6-Estado FA#estadofacturadesc@7-Fecha Recepcion#ffecharecepcion@8-Fecha E.#fechaemision@9-Fecha Vto.#fechavenc@10-Cta.Cble#nrocuentac@11-Desc.Cta.Cble.#desccuenta@12-CUIT#pcuit@13-Exento#exento@14-Iva.#iva@15-Neto Iva#netoiva@16-Descuento#descuento@17-Per.IIBB#retiibb@18-Per. Iva#retiva@19-No Gravado#nogravado@20-Total#monto@21-Descripcion#tcgdescripcion@22-Prestador#pdescripcion@23-F. Operacion#fechaoperacion@24-Nro. OP#laopc@25-Nro. Op.#bonrooperacion@26-Forma Pago#tipoformapagodesc@27-Estado OP#opcetdescripcion@28-ID Asiento Contable#idasientocontable@29-Saldo Cta.Cte#saldo@30-Fecha_Contable_Registro#agfechacontable''::text as mapeocampocolumna 

        FROM recepcion rr  NATURAL JOIN reclibrofact rlf  JOIN prestador p ON (rlf.idprestador=p.idprestador) JOIN multivac.mapeocatgasto as mcg ON(rlf.catgasto=mcg.idcategoriagastosiges) NATURAL JOIN tipocatgasto tcg JOIN cuentascontables ON(mcg.nrocuentac=cuentascontables.nrocuentac)
         /*KR 15-11-21 TKT 4547*/
        LEFT JOIN ctactepagoprestador ccp ON ccp.idcomprobante=((rlf .numeroregistro*10000)+rlf .anio)

        LEFT JOIN ordenpagocontablereclibrofact USING(numeroregistro, anio) 
        LEFT JOIN ordenpagocontable opc USING (idcentroordenpagocontable, idordenpagocontable)

        LEFT JOIN pagoordenpagocontable USING(idordenpagocontable,idcentroordenpagocontable) 
        LEFT JOIN valorescaja USING(idvalorescaja) LEFT JOIN formapagotipos USING(idformapagotipos)
         LEFT JOIN 
        (SELECT DISTINCT idbancatransferencia,idpagoordenpagocontable, idcentropagoordenpagocontable,idbancaoperacion
           FROM ordenpagocontablebancatransferencia  JOIN bancatransferencia USING (idbancatransferencia) ) AS opct
         USING (idcentropagoordenpagocontable ,idpagoordenpagocontable)
        LEFT JOIN bancaoperacion USING (idbancaoperacion)
        LEFT JOIN ordenpagocontableestado opce ON (opc.idcentroordenpagocontable=opce.idcentroordenpagocontable AND opc.idordenpagocontable=opce.idordenpagocontable AND  nullvalue(opcfechafin) /*AND  idordenpagocontableestadotipo<>6 */ )
        LEFT JOIN ordenpagocontableestadotipo USING(idordenpagocontableestadotipo)
        ', case when (rfiltros.idconac= 1) then 'LEFT JOIN asientogenerico ag ON ( idcomprobantesiges = concat(rlf.numeroregistro,''|'',rlf.anio)) ' end ,

        'WHERE ',(case when not nullvalue(rfiltros.numeroregistro) then concat(' numeroregistro = ',rfiltros.numeroregistro,' AND  ')  end ) ,
        case when not nullvalue(rfiltros.fechadesde) then concat('rr.fecha>= ''',rfiltros.fechadesde,''' AND  ')   end ,
        case when not nullvalue(rfiltros.fechahasta) then concat(' rr.fecha<= ''',rfiltros.fechahasta,''' AND  ') end ,
        case when not nullvalue(rfiltros.pcuit) then concat(' pcuit = ',rfiltros.pcuit ,' AND  ')  end ,
        case when not nullvalue(rfiltros.numfactura ) then concat(' numfactura = ',rfiltros.numfactura ,' AND  ') end ,
        case when not nullvalue(rfiltros.nrocuentac) then concat(' cuentascontables.nrocuentac= ',rfiltros.nrocuentac,' AND  ' )   end ,'
        ((idvalorescaja <>67  AND idvalorescaja <>65) OR nullvalue(pagoordenpagocontable.idvalorescaja)) 
        -- BelenA Le agrego que me filtre los que trae formapago tiene nulos (Deben ser los creados desde precarga)
        --AND not nullvalue(opc.idordenpagocontable)



        UNION




        SELECT pdescripcion as razonsocial, tcgdescripcion, fechaemision,rr.fecha AS ffecharecepcion,concat(puntodeventa,''-'',numero) as nrofactura,numeroregistro,anio,pdescripcion,pcuit, descripcionsiges as ctacble
        , CASE WHEN tipofactura ILIKE ''NCR'' AND netoiva21<>0 THEN netoiva21*-1 
               WHEN tipofactura ILIKE ''NCR'' AND netoiva105<>0 THEN netoiva105*-1 
               WHEN tipofactura ILIKE ''NCR'' AND netoiva27<>0 THEN netoiva27*-1 
               WHEN tipofactura NOT ILIKE ''NCR'' AND netoiva21<>0 THEN netoiva21 
               WHEN tipofactura NOT ILIKE ''NCR'' AND netoiva105<>0 THEN netoiva105 
               WHEN tipofactura NOT ILIKE ''NCR'' AND netoiva27<>0 THEN netoiva27 
          END AS netoiva
        , CASE WHEN tipofactura ILIKE ''NCR'' AND iva21<>0 THEN iva21*-1 
               WHEN tipofactura ILIKE ''NCR'' AND iva105<>0 THEN iva105*-1 
               WHEN tipofactura ILIKE ''NCR'' AND iva27<>0 THEN iva27*-1 
               WHEN tipofactura NOT ILIKE ''NCR'' AND iva21<>0 THEN iva21 
               WHEN tipofactura NOT ILIKE ''NCR'' AND iva105<>0 THEN iva105 
               WHEN tipofactura NOT ILIKE ''NCR'' AND iva27<>0 THEN iva27 
          END AS iva
        , CASE WHEN tipofactura ILIKE ''NCR'' THEN exento*-1 ELSE exento END AS exento
        , CASE WHEN tipofactura ILIKE ''NCR'' THEN monto*-1 ELSE monto END AS monto
        , cuentascontables.nrocuentac, desccuenta,fechavenc,(descuento*-1) as descuento
        , CASE WHEN tipofactura ILIKE ''NCR'' THEN retiibb*-1 ELSE retiibb END AS retiibb
        , CASE WHEN tipofactura ILIKE ''NCR'' THEN retiva*-1 ELSE retiva END AS retiva
        , CASE WHEN tipofactura ILIKE ''NCR'' THEN nogravado*-1 ELSE nogravado END AS nogravado
        , NULL as fechaoperacion , 
         CONCAT(opc.idordenpagocontable,''-'',opc.idcentroordenpagocontable) as laopc, 
         NULL as bonrooperacion, 
         valorescaja.descripcion as tipoformapagodesc , 
         NULL as opcetdescripcion
        , case when nullvalue( ',vselectasiento,') then '''' else ', vselectasiento    ,' end as idasientocontable, 
          round(CAST((ccp.saldo) AS numeric),2)  saldo,
        tipofactura
        , ag.agfechacontable as agfechacontable

        , ''1-Nro.Registro#numeroregistro@2-Anio#anio@3-Razon Social#razonsocial@4-Tipo Factura#tipofactura@5-Nro.Factura#nrofactura@6-Estado FA#estadofacturadesc@7-Fecha Recepcion#ffecharecepcion@8-Fecha E.#fechaemision@9-Fecha Vto.#fechavenc@10-Cta.Cble#nrocuentac@11-Desc.Cta.Cble.#desccuenta@12-CUIT#pcuit@13-Exento#exento@14-Iva.#iva@15-Neto Iva#netoiva@16-Descuento#descuento@17-Per.IIBB#retiibb@18-Per. Iva#retiva@19-No Gravado#nogravado@20-Total#monto@21-Descripcion#tcgdescripcion@22-Prestador#pdescripcion@23-F. Operacion#fechaoperacion@24-Nro. OP#laopc@25-Nro. Op.#bonrooperacion@26-Forma Pago#tipoformapagodesc@27-Estado OP#opcetdescripcion@28-ID Asiento Contable#idasientocontable@29-Saldo Cta.Cte#saldo@30-Fecha_Contable_Registro#agfechacontable''::text as mapeocampocolumna 

        FROM recepcion rr  NATURAL JOIN reclibrofact rlf  JOIN prestador p ON (rlf.idprestador=p.idprestador) JOIN multivac.mapeocatgasto as mcg ON(rlf.catgasto=mcg.idcategoriagastosiges) NATURAL JOIN tipocatgasto tcg JOIN cuentascontables ON(mcg.nrocuentac=cuentascontables.nrocuentac)
         /*KR 15-11-21 TKT 4547*/
        LEFT JOIN ctactepagoprestador ccp ON ccp.idcomprobante=((rlf .numeroregistro*10000)+rlf .anio)

        LEFT JOIN ordenpagocontablereclibrofact USING(numeroregistro, anio) 
        LEFT JOIN ordenpagocontable opc USING (idcentroordenpagocontable, idordenpagocontable)

        NATURAL JOIN reclibrofact_formpago 
        LEFT JOIN valorescaja USING (idvalorescaja)
        ', case when (rfiltros.idconac= 1) then 'LEFT JOIN asientogenerico ag ON ( idcomprobantesiges = concat(rlf.numeroregistro,''|'',rlf.anio)) ' end ,

        'WHERE ',(case when not nullvalue(rfiltros.numeroregistro) then concat(' numeroregistro = ',rfiltros.numeroregistro,' AND  ')  end ) ,
        case when not nullvalue(rfiltros.fechadesde) then concat('rr.fecha>= ''',rfiltros.fechadesde,''' AND  ')   end ,
        case when not nullvalue(rfiltros.fechahasta) then concat(' rr.fecha<= ''',rfiltros.fechahasta,''' AND  ') end ,
        case when not nullvalue(rfiltros.pcuit) then concat(' pcuit = ',rfiltros.pcuit ,' AND  ')  end ,
        case when not nullvalue(rfiltros.numfactura ) then concat(' numfactura = ',rfiltros.numfactura ,' AND  ') end ,
        case when not nullvalue(rfiltros.nrocuentac) then concat(' cuentascontables.nrocuentac= ',rfiltros.nrocuentac,' AND  ' )   end ,'
        /*((idvalorescaja <>67  AND idvalorescaja <>65) --OR nullvalue(pagoordenpagocontable.idvalorescaja)
        ) 
        -- BelenA Le agrego que me filtre los que trae formapago tiene nulos (Deben ser los creados desde precarga)
        AND */
        nullvalue(opc.idordenpagocontable) --AND idvalorescaja<>3
) AS T
--WHERE not nullvalue(tipoformapagodesc)

GROUP BY nrofactura, t.razonsocial, t.tcgdescripcion, t.fechaemision, t.ffecharecepcion, t.numeroregistro, t.anio,t.pdescripcion,t.pcuit, t.ctacble
, t.netoiva, t.iva, t.exento, t.monto, t.descuento, t.retiibb, t.retiva, t.nogravado, t.fechaoperacion , t.laopc, 
t.bonrooperacion, 
--t.tipoformapagodesc , 
t.opcetdescripcion, 
t.idasientocontable, 
t.saldo,
t.tipofactura,
t.nrocuentac, t.desccuenta, t.fechavenc, 
t.agfechacontable,
t.mapeocampocolumna


ORDER BY nrofactura

)

'

); 

EXECUTE vquery; 

RAISE NOTICE  'La consulta : % at %: ', vquery, now(); 

return true;
END;
$function$
