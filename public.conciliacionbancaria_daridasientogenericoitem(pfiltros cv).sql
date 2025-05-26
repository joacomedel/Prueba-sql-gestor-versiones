CREATE OR REPLACE FUNCTION public.conciliacionbancaria_daridasientogenericoitem(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

	rfiltros RECORD;
    rinfocomp RECORD;
	rasiento RECORD;
	rconcitem RECORD;
        salida varchar;
BEGIN

   salida = '';
   EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   SELECT INTO rconcitem *
   FROM conciliacionbancaria
   JOIN cuentabancariasosunc using (idcuentabancaria)
   NATURAL JOIN conciliacionbancariaitem
   WHERE idconciliacionbancariaitem = rfiltros.idconciliacionbancariaitem
         and idcentroconciliacionbancaria = rfiltros.idcentroconciliacionbancaria;
/*     WHERE idconciliacionbancariaitem = 3188
       and idcentroconciliacionbancaria = 1;
*/
   IF FOUND THEN

            IF rconcitem.cbitablacomp = 'pagoordenpagocontable' THEN
                      SELECT INTO rinfocomp concat(idordenpagocontable,'|',idcentroordenpagocontable)as elidcomprobantesiges,1 as idasientogenericocomprobtipo
                      FROM pagoordenpagocontable
                      NATURAL JOIN ordenpagocontable
                      WHERE idpagoordenpagocontable = split_part( split_part(rconcitem.cbiclavecompsiges, '|',1),'=',2)
                            AND idcentropagoordenpagocontable =split_part( split_part(rconcitem.cbiclavecompsiges, '|',2),'=',2);
            END IF;

            IF rconcitem.cbitablacomp = 'ordenpago' THEN
                      SELECT INTO rinfocomp concat(nroordenpago,'|',idcentroordenpago) as elidcomprobantesiges , 4 as idasientogenericocomprobtipo
                      FROM ordenpago
                      WHERE nroordenpago = split_part( split_part(rconcitem.cbiclavecompsiges, '|',1),'=',2)
                            AND idcentroordenpago =split_part( split_part(rconcitem.cbiclavecompsiges, '|',2),'=',2);

            END IF;

            IF rconcitem.cbitablacomp = 'liquidaciontarjeta' THEN
                      SELECT INTO rinfocomp concat(nroordenpago,'|',idcentroordenpago) as elidcomprobantesiges , 4 as idasientogenericocomprobtipo
                      FROM liquidaciontarjeta
                      JOIN ordenpago on (concat ('Liq Tarjeta ',idliquidaciontarjeta,' (',ltobservacion,')') = concepto )
                      NATURAL JOIN cambioestadoordenpago
                      WHERE idliquidaciontarjeta = split_part( split_part(rconcitem.cbiclavecompsiges, '|',1),'=',2)
                            and idcentroliquidaciontarjeta =  split_part( split_part(rconcitem.cbiclavecompsiges, '|',2),'=',2)
                             AND ( nullvalue(ceopfechafin)and idtipoestadoordenpago <>4	)  ;




            END IF;
            IF rconcitem.cbitablacomp = 'facturaventacupon' THEN

                     SELECT INTO rinfocomp concat(tipofactura,'|',tipocomprobante,'|',nrosucursal,'|',nrofactura) as elidcomprobantesiges , 5 as idasientogenericocomprobtipo
                     FROM facturaventa
                     NATURAL JOIN facturaventacupon
                     WHERE  idfacturacupon = split_part( split_part(rconcitem.cbiclavecompsiges, '|',1),'=',2)
                            AND centro = split_part( split_part(rconcitem.cbiclavecompsiges, '|',2),'=',2)
                            AND nrofactura =  split_part( split_part(rconcitem.cbiclavecompsiges, '|',3),'=',2)
                            AND tipocomprobante =  split_part( split_part(rconcitem.cbiclavecompsiges, '|',4),'=',2)
                            AND nrosucursal =  split_part( split_part(rconcitem.cbiclavecompsiges, '|',5),'=',2)
                            AND tipofactura =  split_part( split_part(rconcitem.cbiclavecompsiges, '|',6),'=',2) ;

             END IF;

            IF rconcitem.cbitablacomp = 'recibocupon' THEN

                     SELECT  *
                     FROM recibocupon
                     NATURAL JOIN recibo
                     WHERE  idrecibocupon = split_part( split_part(rconcitem.cbiclavecompsiges, '|',1),'=',2)
                            AND idcentrorecibocupon = split_part( split_part(rconcitem.cbiclavecompsiges, '|',2),'=',2) ;
                           

             END IF;
             -- Si encontre el comp de siges, busco el asiento contable
             IF(not nullvalue(rinfocomp.elidcomprobantesiges) ) THEN
                          SELECT INTO rasiento *
                          FROM asientogenerico
                          NATURAL JOIN asientogenericoitem
                          NATURAL JOIN cuentascontables
                          NATURAL JOIN asientogenericoestado
                          WHERE nrocuentac=rconcitem.nrocuentac::varchar
                              AND idasientogenericocomprobtipo = rinfocomp.idasientogenericocomprobtipo::integer
                                AND idcomprobantesiges = rinfocomp.elidcomprobantesiges::varchar
                                AND nullvalue(agefechafin)
                                AND tipoestadofactura <> 5 ;
                          IF FOUND THEN
                                 UPDATE conciliacionbancariaitem
                                 SET idcentroasientogenericoitem = rasiento.idcentroasientogenericoitem
                                      , idasientogenericoitem = rasiento.idasientogenericoitem
                                 WHERE idconciliacionbancariaitem = rconcitem.idconciliacionbancariaitem
                                        AND idcentroconciliacionbancariaitem = rconcitem.idcentroconciliacionbancariaitem;
                                 salida =concat( rasiento.idasientogenericoitem,'|',  rasiento.idcentroasientogenericoitem);
                                     
                          END IF;
              END IF;
   END IF;







return salida;
END;
$function$
