CREATE OR REPLACE FUNCTION public.contabilidad_info10333(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       rfiltros record;
       info varchar;
       rinfo   record;
       rinfoaux   record;
       xnumeroregistro bigint;
       rreversion  record;
       xanio integer;
	
BEGIN
       /** Este mayor se utiliza para controlar el iva ventas: lo que va a retornar es el id de la declaracion de iva en el que fue liquidado */
      info ='Sin vincular';
    --  RAISE NOTICE 'En el sp 10386(%)',$1;
      EXECUTE sys_dar_filtros($1) INTO rfiltros;

      SELECT INTO rinfo *
      FROM asientogenericoitem
      NATURAL JOIN asientogenerico
      WHERE nrocuentac = rfiltros.nrocuentac
             and idasientogenericoitem = rfiltros.idasientogenericoitem
             and idcentroasientogenericoitem = rfiltros.idcentroasientogenericoitem
             and acid_h = rfiltros.acid_h
           --  and idasientogenericocomprobtipo = 5
             ;
 
      IF (FOUND)THEN
           --- Si es una reversion entonces devuelvo el idasientogenerico
           SELECT INTO rreversion *
           FROM asientogenerico 
           NATURAL JOIN asientogenericoitem 
           WHERE idasientogenericorevertido = rinfo.idasientogenerico AND idcentroasientogenericorevertido=rinfo.idcentroasientogenerico ;
           IF (FOUND) THEN
                    info = concat(rinfo.idasientogenerico,'-',rinfo.idcentroasientogenerico);
           END IF;  
           --- Si esta revertido devuelvo el idasientorevertido
           IF(not nullvalue(rinfo.idasientogenericorevertido))THEN
                    info = concat(rinfo.idasientogenericorevertido,'-',rinfo.idcentroasientogenericorevertido);
                   
           END IF;
           IF ( info ='Sin vincular' AND rinfo.idasientogenericocomprobtipo = 5 ) THEN
          /* Se trata de una facturaventa no vinculada a facturaorden */
           SELECT into rinfoaux concat(idprestamo,'-',idcentroprestamo) as cturismo ,
                  CASE WHEN nullvalue(p.nrodoc) THEN cli.nrocliente ELSE p.nrodoc END nrodoc,
                  CASE WHEN nullvalue(p.nrodoc) THEN cli.barra ELSE p.barra END barra,
                  CASE WHEN nullvalue(p.nrodoc) THEN concat( cli.denominacion  ) 
                       ELSE concat( p.apellido,' ',p.nombres) 
                  END denominacion
                  , *
           FROM facturaventa fv
           LEFT JOIN informefacturacion USING (nrofactura,tipofactura,tipocomprobante,nrosucursal)
           LEFT JOIN informefacturacionturismo USING (nroinforme,idcentroinformefacturacion)
           LEFT JOIN consumoturismo USING (idconsumoturismo,idcentroconsumoturismo	)

           LEFT JOIN  persona as p USING(nrodoc)
           LEFT JOIN cliente cli ON (fv.nrodoc= cli.nrocliente AND fv.tipodoc =  cli.barra) 
           WHERE  nrofactura=split_part(rinfo.idcomprobantesiges, '|', 4)::bigint
	 		AND tipofactura=split_part(rinfo.idcomprobantesiges, '|', 1)
	 		AND tipocomprobante=split_part(rinfo.idcomprobantesiges, '|', 2)::bigint
			AND nrosucursal=split_part(rinfo.idcomprobantesiges, '|', 3)::bigint
                        AND idinformefacturaciontipo = 3;
     
          IF (FOUND)THEN   -- si el comprobante es una factura
                 info = concat(rinfoaux.nrodoc,'-',rinfoaux.barra,' @ ',rinfoaux.denominacion,' @ ',rinfoaux.cturismo);
          
          END IF;
       END IF;


        IF ( info ='Sin vincular' AND rinfo.idasientogenericocomprobtipo = 5 ) THEN     
                SELECT into rinfoaux  
                  CASE WHEN nullvalue(p.nrodoc) THEN cli.nrocliente ELSE p.nrodoc END nrodoc,
                  CASE WHEN nullvalue(p.nrodoc) THEN cli.barra ELSE p.barra END barra,
                  CASE WHEN nullvalue(p.nrodoc) THEN concat( cli.denominacion  ) ELSE concat( p.apellido,' ',p.nombres) END denominacion, *

                FROM facturaventa fv
                LEFT JOIN informefacturacion USING (nrofactura,tipofactura,tipocomprobante,nrosucursal)
                LEFT JOIN cuentacorrientepagos ON (idcomprobante = ( nroinforme * 100) + idcentroinformefacturacion	) 
                LEFT JOIN persona as p ON(cuentacorrientepagos.nrodoc = p.nrodoc AND cuentacorrientepagos.tipodoc = p.tipodoc)
                LEFT JOIN cliente cli ON (fv.nrodoc= cli.nrocliente AND fv.tipodoc =  cli.barra) 
                WHERE  nrofactura=split_part(rinfo.idcomprobantesiges, '|', 4)::bigint
                       AND tipofactura=split_part(rinfo.idcomprobantesiges, '|', 1)
                       AND tipocomprobante=split_part(rinfo.idcomprobantesiges, '|', 2)::bigint
                       AND nrosucursal=split_part(rinfo.idcomprobantesiges, '|', 3)::bigint  ;
                IF (FOUND) THEN
                       info = concat(rinfoaux.nrodoc,'-',rinfoaux.barra,' @ ',rinfoaux.apellido,' ',rinfoaux.nombres);
                END IF;

       END IF;

     IF (rinfo.idasientogenericocomprobtipo = 9) THEN /*Es una Imputacion de Recibo*/
         SELECT into rinfoaux   concat(idprestamo,'-',idcentroprestamo) as cturismo ,*
         FROM cuentacorrientedeuda as d
         JOIN prestamocuotas ON(idcomprobante = (idprestamocuotas * 10) +idcentroprestamocuota)
         JOIN consumoturismo USING(idprestamo,idcentroprestamo)
         JOIN persona USING (nrodoc,tipodoc)
         WHERE iddeuda=split_part(rinfo.idcomprobantesiges, '|', 1)::bigint
                AND idcentrodeuda=split_part(rinfo.idcomprobantesiges, '|', 2)::bigint
                AND d.idcomprobantetipos = 7; -- es     cuota  prestamoturismo  ;                

         IF (FOUND)THEN   -- si el comprobante es un Recibo
                 info =concat(rinfoaux.nrodoc,'-',rinfoaux.barra,' @ ',rinfoaux.apellido,' ',rinfoaux.nombres,' @ ',rinfoaux.cturismo);
            END IF;
      END IF;


      IF (info ='Sin vincular' AND rinfo.idasientogenericocomprobtipo = 9) THEN 

        SELECT into rinfoaux nrodoc  ,cli.barra as barra,apellido,nombres ,concat(idprestamo,'-',idcentroprestamo) as cturismo
        FROM ctactedeudacliente 
        LEFT JOIN prestamocuotas ON(idcomprobante = (idprestamocuotas * 10) +idcentroprestamocuota)
        LEFT JOIN clientectacte USING (idclientectacte ,idcentroclientectacte)
        LEFT JOIN persona as cli ON (nrodoc = nrocliente  AND tipodoc = clientectacte.barra)
        WHERE  iddeuda= split_part(rinfo.idcomprobantesiges, '|', 1)::bigint     
               and idcentrodeuda=  split_part(rinfo.idcomprobantesiges, '|', 2)::bigint;    
       
         IF (FOUND)THEN   -- si el comprobante es un Recibo
                 info =concat(rinfoaux.nrodoc,'-',rinfoaux.barra,' @ ',rinfoaux.apellido,' ',rinfoaux.nombres,' @ ',rinfoaux.cturismo);
         END IF;

     END IF;
 



       IF (rinfo.idasientogenericocomprobtipo =4 ) THEN /* Puede ser una minuta de imputacion */
          SELECT into rinfoaux CASE WHEN nullvalue(dpop_afil.nroordenpago) THEN  'es cliente' ELSE 'es afil' END as datos, 
                 CASE WHEN nullvalue(dpop_afil.nroordenpago) THEN  cli.nrodoc ELSE afil.nrodoc END as nrodoc, 
                 CASE WHEN nullvalue(dpop_afil.nroordenpago) THEN  cli.barra ELSE afil.barra END as barra, 
                 CASE WHEN nullvalue(dpop_afil.nroordenpago) THEN  cli.apellido ELSE afil.apellido END as apellido, 
                 CASE WHEN nullvalue(dpop_afil.nroordenpago) THEN  cli.nombres ELSE afil.nombres END as nombres,

                 CASE WHEN nullvalue(pca.idprestamocuotas) THEN concat(pcc.idprestamo,'-',pcc.idcentroprestamo)  ELSE concat(pca.idprestamo,'-',pca.idcentroprestamo)  END as cturismo 
      
 

          FROM ordenpago 
          LEFT JOIN cuentacorrientedeudapagoordenpago as dpop_afil USING(nroordenpago,idcentroordenpago)
          LEFT JOIN cuentacorrientedeuda as ctaafil USING(iddeuda,idcentrodeuda)
          LEFT JOIN prestamocuotas as pca ON(ctaafil.idcomprobante = (pca.idprestamocuotas * 10) +pca.idcentroprestamocuota)

          LEFT JOIN persona as afil ON (afil.nrodoc =ctaafil.nrodoc  AND afil.tipodoc = ctaafil.tipodoc)
          LEFT JOIN ctactedeudapagoclienteordenpago as dpop_cli USING(nroordenpago,idcentroordenpago)
          LEFT JOIN ctactedeudapagocliente as dp_cli USING (idctactedeudapagocliente, idcentroctactedeudapagocliente)
          LEFT JOIN ctactedeudacliente as ctad_cli  ON(ctad_cli.iddeuda  = dp_cli.iddeuda AND ctad_cli.idcentrodeuda = dp_cli.idcentrodeuda) 
         
          LEFT JOIN prestamocuotas as pcc ON(ctad_cli.idcomprobante = (pcc.idprestamocuotas * 10) +pcc.idcentroprestamocuota)

 LEFT JOIN clientectacte as cta_cli ON (cta_cli.idclientectacte = ctad_cli.idclientectacte  AND cta_cli.idcentroclientectacte = ctad_cli.idcentroclientectacte)
          LEFT JOIN persona as cli ON (cli.nrodoc = cta_cli.nrocliente  AND cli.tipodoc = cta_cli.barra)
          WHERE nroordenpago = split_part(rinfo.idcomprobantesiges, '|', 1)::bigint
                AND idcentroordenpago = split_part(rinfo.idcomprobantesiges, '|', 2)::bigint;
          IF (FOUND)THEN   -- si el comprobante es un Recibo
                 info = concat(rinfoaux.nrodoc,'-',rinfoaux.barra,' @ ',rinfoaux.apellido,' ',rinfoaux.nombres,' @ ',rinfoaux.cturismo);
          END IF;
       END IF;

   

   IF (rinfo.idasientogenericocomprobtipo = 8 ) THEN /* Se trata de una cobranza*/
        SELECT   into rinfoaux
        CASE WHEN nullvalue(pa.nrodoc)THEN pc.apellido ELSE pa.apellido END as apellido,
        CASE WHEN nullvalue(pa.nrodoc)THEN pc.nombres ELSE pa.nombres END as nombres,
        CASE WHEN nullvalue(pa.nrodoc)THEN pc.nrodoc ELSE pa.nrodoc END as nrodoc,
        CASE WHEN nullvalue(pa.barra)THEN pc.barra ELSE pa.barra END as barra    
        FROM recibo
        left join cuentacorrientepagos as p on(p.idcomprobante = idrecibo  and centro=p.idcentropago)
        left join persona as pa ON (pa.nrodoc=p.nrodoc AND pa.tipodoc = p.tipodoc) 
        left join ctactepagocliente on(ctactepagocliente.idcomprobante = idrecibo  and centro=ctactepagocliente.idcentropago)
        left join clientectacte USING(idclientectacte, idcentroclientectacte)
        left join cliente ON (cliente.nrocliente = clientectacte.nrocliente  AND cliente.barra = clientectacte.barra)
        left join persona as pc ON (pc.nrodoc=cliente.nrocliente AND pc.tipodoc = cliente.barra) 
        WHERE  idrecibo = split_part(rinfo.idcomprobantesiges, '|', 1) 
               and centro = split_part(rinfo.idcomprobantesiges, '|', 2)  ;
        IF (FOUND)THEN   -- si el comprobante es recibo
                 info = concat(rinfoaux.nrodoc,'-',rinfoaux.barra,' @ ',rinfoaux.apellido,' ',rinfoaux.nombres,' @ ',rinfo.idcomprobantesiges);
        END IF;
   END IF;
 IF (rinfo.idasientogenericocomprobtipo = 1 ) THEN /* Se trata de una ordenpago contable */
        SELECT into rinfoaux * 
        FROM ordenpagocontable 
        NATURAL JOIN ordenpagocontablereintegro
        NATURAL JOIN reintegro
        NATURAL JOIN persona
        WHERE idordenpagocontable = split_part(rinfo.idcomprobantesiges, '|', 1)  
                 AND idcentroordenpagocontable = split_part(rinfo.idcomprobantesiges, '|', 2); 
        IF (FOUND)THEN   -- si el comprobante es recibo
                 info = concat(rinfoaux.nrodoc,'-',rinfoaux.barra,' @ ',rinfoaux.apellido,' ',rinfoaux.nombres,' @ ',rinfoaux.nroreintegro,'-', rinfoaux.idcentroregional );
        END IF;

    END IF;


 END IF;
RETURN info;
END;
$function$
