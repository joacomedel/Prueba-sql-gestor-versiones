CREATE OR REPLACE FUNCTION public.asientogenerico_precarga_crear_7(bigint, integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$-- Este SP se usa para generar los asientosgenericos de Comprobantes de Compras
DECLARE
--CURSORES 
curitem refcursor;
curasiento refcursor;
curasientoitem refcursor;
curasientoformpago refcursor;

--RECORD
regencabezado RECORD;
ritem RECORD;
regasiento RECORD;
rrlffp  RECORD;
ractividad  RECORD;
rprestador RECORD; --BelenA lo agrego para poner el prestador si la FP es de contado
rtempformapago RECORD;

--VARIABLES
xnroregistro varchar;
xanio integer;
xidasiento bigint;
vcuenta_iibb varchar;
xdh varchar;
xd_h varchar;
xIva varchar;
xRetIva varchar;
xRetGan varchar;
xRetIIBB varchar;
xDesc varchar;
xRedondeo varchar;
xRecargo varchar; 
-- <---> BelenA agrego:
xImbDebCred varchar;
xhaber double precision;
xdebe double precision; 

vrlfiva double precision DEFAULT 0.0;   
vrlfretiva double precision DEFAULT 0.0;
vrlfretganancias double precision DEFAULT 0.0;
vrlfrlfpiibbneuquen double precision DEFAULT 0.0;
vrlfrlfpiibbrionegro double precision DEFAULT 0.0;
vrlfrlfpiibbotrajuri double precision DEFAULT 0.0;
vrlfrecargo double precision DEFAULT 0.0;
vrlfdescuento  double precision DEFAULT 0.0;
vtotal double precision DEFAULT 0.0;
-- <---> BelenA agrego:
vrlfimpdebcred double precision DEFAULT 0.0;
vauxtotal double precision DEFAULT 0.0;
vidvalorcaja BIGINT;


    

   
BEGIN
--KR 10-03-23 Creo una temporal para guardar los importes totales x actividad

CREATE TEMP TABLE  tempactividadtotal (idactividad integer, catgasto integer, importe double precision);
 
-- Cuentas contables Default
xIva = '10386';
xRetIva='10389';
xRetGan='50845';
xRetIIBB='50797';
xDesc='40607';
xRedondeo='50911';
xRecargo='50731';
xImbDebCred='10395';

xnroregistro = $1; 
xanio = $2; 

RAISE NOTICE 'asientogenerico_precarga_crear_7 (%,%)',xnroregistro,xanio ;

OPEN curasiento FOR 
                   SELECT * 
                   FROM reclibrofact  
                   WHERE idprestador <> 2608 AND numeroregistro = xnroregistro  and anio = xanio ;  -- los comprobantes de sosunc no  deberian generar contabilidad

FETCH curasiento INTO regasiento;
WHILE FOUND LOOP
     SELECT INTO rrlffp * FROM reclibrofact r NATURAL JOIN reclibrofact_formpago NATURAL JOIN tipofacturatipomovimiento WHERE numeroregistro=xnroregistro  and anio = xanio and tftmsesincroniza;
    
     IF FOUND THEN 
       IF rrlffp.idvalorescaja=3 THEN 

    SELECT INTO regencabezado  tipomovimiento,fechaimputacion, concat(tipofactura,' ',letra,' ',puntodeventa,'-',numero,' - ',pdescripcion,' (',numeroregistro,'-',anio,')') leyenda ,nrocuentacproveedor nrocuentac
        FROM reclibrofact r NATURAL JOIN prestador p NATURAL JOIN tipofacturatipomovimiento join multivac.mapeocatgasto m on(r.catgasto=m.idcategoriagastosiges)
        WHERE numeroregistro=xnroregistro AND anio=xanio and tftmsesincroniza; 

       ELSE 

       -- BelenA agrego esto para obtener la leyenda correcta con los datos del prestador, ticket 6092
        SELECT INTO rprestador  concat(tipofactura,' ',letra,' ',puntodeventa,'-',numero,' - ',pdescripcion,' (',numeroregistro,'-',anio,')') leyenda
        FROM reclibrofact r 
        NATURAL JOIN prestador p 
        NATURAL JOIN tipofacturatipomovimiento 
        WHERE numeroregistro=xnroregistro AND anio=xanio and tftmsesincroniza;

       -- KAR 07-05-23 esto se usa cuando en la carga se llaman las FP de contado
        SELECT   INTO regencabezado   tipomovimiento,fechaimputacion, nombrecuentafondos leyenda ,nrocuentac 
        FROM reclibrofact r NATURAL JOIN reclibrofact_formpago NATURAL JOIN tipofacturatipomovimiento  NATURAL JOIN ordenpagocontablevalorescaja natural join multivac.mapeocuentasfondos
        WHERE numeroregistro=xnroregistro AND anio=xanio and tftmsesincroniza; 

        -- BelenA esto es para poner la leyenda del prestador en el encabezado, asi puedo usar regencabezado en el insert, ticket 6092
        regencabezado.leyenda=rprestador.leyenda;

       END IF; 
      
        RAISE NOTICE 'xnroregistro (%)',xnroregistro;
        INSERT INTO asientogenerico(idasientogenericotipo,idasientogenericocomprobtipo,agfechacontable,agdescripcion,idcomprobantesiges,agtipoasiento,idagquienmigra)
        values(6,7,regencabezado.fechaimputacion,regencabezado.leyenda,concat(xnroregistro,'|',xanio),'AS',3);
            
        xidasiento=currval('asientogenerico_idasientocontable_seq');
        IF regencabezado.tipomovimiento='Deuda' THEN
            xd_h='D';
        ELSE
            xd_h='H';
        END IF;
               --items   
           OPEN curasientoitem FOR 
                  SELECT m.nrocuentac as nrocuentacgasto, (rlfanetoiva105+rlfanetoiva21+rlfanetoiva27+rlfaexento+rlfanogravado+rlfapercepciones ) as subtotalact,monto as total,rlfaretganancias,rlfaretiva,(rlfaiva105+rlfaiva21+rlfaiva27 -rlfaivadescuento27-rlfaivadescuento105-rlfaivadescuento21+rlfaivarecargo27+rlfaivarecargo105+rlfaivarecargo21) as ivaact,(rlfarecargo21+rlfarecargo27+rlfarecargo105+rlfarecargoexento) as rlfarecargo,(rlfadescuento21+rlfadescuento27+rlfadescuento105+rlfadescuentoexento) as rlfadescuento,rlfarlfpiibbneuquen,rlfarlfpiibbrionegro,rlfarlfpiibbotrajuri, rlfa.idactividad, rlfa.catgasto, rlfaimpdebcred
          FROM reclibrofact r JOIN reclibrofact_catgastoactividad rlfa USING(idrecepcion,idcentroregional) JOIN  multivac.mapeocatgasto m on(rlfa.catgasto=m.idcategoriagastosiges) 

          WHERE numeroregistro=xnroregistro AND anio=xanio; 

          FETCH curasientoitem INTO ritem;
              WHILE FOUND LOOP
                 vtotal=0;
                 vrlfretiva = vrlfretiva +ritem.rlfaretiva;
                 vtotal = vtotal + ritem.subtotalact + ritem.ivaact  +ritem.rlfaretiva + ritem.rlfarecargo- ritem.rlfadescuento+ritem.rlfarlfpiibbneuquen +ritem.rlfarlfpiibbrionegro +ritem.rlfarlfpiibbotrajuri+ritem.rlfaimpdebcred;    
                 --Gasto
             IF (ritem.subtotalact>0) THEN
                      INSERT INTO asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
               VALUES(xidasiento,centro(), ritem.subtotalact, ritem.nrocuentacgasto, regencabezado.leyenda, xd_h);              
              IF (xd_h='D') THEN 
                           xdebe = xdebe + (ritem.subtotalact);
                        
              ELSE 
                           xhaber = xhaber + (ritem.subtotalact);
              END IF;
                      vrlfiva = vrlfiva +ritem.ivaact;
                      vrlfretganancias = vrlfretganancias +ritem.rlfaretganancias;
                      vrlfrlfpiibbneuquen = vrlfrlfpiibbneuquen +ritem.rlfarlfpiibbneuquen;
                      vrlfrlfpiibbrionegro = vrlfrlfpiibbrionegro +ritem.rlfarlfpiibbrionegro;
                      vrlfrlfpiibbotrajuri = vrlfrlfpiibbotrajuri +ritem.rlfarlfpiibbotrajuri;
                      vrlfrecargo = vrlfrecargo +ritem.rlfarecargo;
                      vrlfdescuento = vrlfdescuento +ritem.rlfadescuento;
                      -- <---> BelenA agrego: 
                      vrlfimpdebcred= vrlfimpdebcred + ritem.rlfaimpdebcred;
                      
                     
                 END IF;
                    INSERT INTO tempactividadtotal (idactividad, catgasto, importe) VALUES (ritem.idactividad, ritem.catgasto, vtotal);
                  
      
              FETCH curasientoitem INTO ritem;
          END LOOP;
          CLOSE curasientoitem;
          
        --IVA
          IF vrlfiva>0 THEN
              INSERT INTO asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
               VALUES(xidasiento,centro(), vrlfiva, xIva, regencabezado.leyenda, xd_h);             
              IF xd_h='D' THEN  xdebe = xdebe + vrlfiva;
              ELSE      xhaber = xhaber + vrlfiva;
              END IF;
          END IF;

        --Percepcion IVA
          IF vrlfretiva>0 THEN
                INSERT INTO asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
            VALUES(xidasiento,centro(),vrlfretiva, xRetIva, regencabezado.leyenda,xd_h);                
            IF xd_h='D' THEN    xdebe = xdebe + vrlfretiva;
            ELSE            xhaber = xhaber + vrlfretiva;
            END IF;
          END IF;

        --Percepcion GANANCIAS
          IF vrlfretganancias>0 THEN
            INSERT INTO asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
            VALUES(xidasiento,centro(),vrlfretganancias, xRetGan, regencabezado.leyenda,xd_h);              
            IF xd_h='D' THEN    xdebe = xdebe + (vrlfretganancias);
            ELSE            xhaber = xhaber + (vrlfretganancias);
            END IF;
          END IF;

        --Percepcion IIBB   
          IF (vrlfrlfpiibbneuquen>0)  THEN
                    vcuenta_iibb = 10383; --- IIBB Neuquen
                    INSERT INTO asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
            VALUES(xidasiento,centro(),vrlfrlfpiibbneuquen, vcuenta_iibb, regencabezado.leyenda,xd_h);              
          END IF;

          IF (vrlfrlfpiibbrionegro>0)  THEN
                    vcuenta_iibb =  10384;  --- IIBB Rio NNegro
                    INSERT INTO asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
            VALUES(xidasiento,centro(),vrlfrlfpiibbrionegro, vcuenta_iibb, regencabezado.leyenda,xd_h);             
          END IF; 

          IF (vrlfrlfpiibbotrajuri>0)  THEN  
                     vcuenta_iibb=  50797;  --- IIBB OTRA  
                     INSERT INTO asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
            VALUES(xidasiento,centro(),vrlfrlfpiibbotrajuri, vcuenta_iibb, regencabezado.leyenda,xd_h);                               
          END IF; 
                
          IF (regencabezado.tipomovimiento='D') THEN
                     xdebe = xdebe + (vrlfrlfpiibbneuquen+vrlfrlfpiibbrionegro+vrlfrlfpiibbotrajuri);
          ELSE
                     xhaber = xhaber + (vrlfrlfpiibbneuquen+vrlfrlfpiibbrionegro+vrlfrlfpiibbotrajuri);
          END IF;

                 --Recargo
          IF vrlfrecargo>0 then
            INSERT INTO asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                VALUES(xidasiento,centro(), vrlfrecargo, xRecargo, regencabezado.leyenda, xd_h);                
            IF (xd_h='D') THEN      xdebe = xdebe +vrlfrecargo;
            ELSE            xhaber = xhaber + vrlfrecargo;
            END IF;
          END IF;

          -- <---> BelenA agrego: impdebcred  xImbDebCred
          IF vrlfimpdebcred>0 then
            INSERT INTO asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                VALUES(xidasiento,centro(), vrlfimpdebcred, xImbDebCred, regencabezado.leyenda, xd_h);              
            IF (xd_h='D') THEN      xdebe = xdebe +vrlfimpdebcred;
            ELSE            xhaber = xhaber + vrlfimpdebcred;
            END IF;
          END IF;

        --CONTRAPARTIDA
          IF xd_h='D' THEN xd_h='H';
          ELSE xd_h='D';
          END IF;




        --Proveedores
        -- Ya no es proveedores, es Formas de Pago
          IF vtotal>0 THEN
        --  BelenA 03-06-24 Se comenta la reestriccion de que solo para ctacte ponga más de un item, ahora las otras Formas de Pago también
        -- Ahora para los proveedores me va a poner las Formas de Pago, Proveedores si es CtaCte y para las otras FP sus nombres

        OPEN curasientoformpago FOR 
        SELECT * FROM reclibrofact r 
        NATURAL JOIN reclibrofact_formpago 
        /* NATURAL JOIN tipofacturatipomovimiento
        LEFT JOIN ordenpagocontablevalorescaja USING (idvalorescaja)
        LEFT JOIN multivac.mapeocuentasfondos USING (idcuentafondos)*/
        WHERE numeroregistro=xnroregistro  and anio = xanio; --and tftmsesincroniza;

        vauxtotal=0;
    /*
        SELECT tipomovimiento,fechaimputacion, concat(tipofactura,' ',letra,' ',puntodeventa,'-',numero,' - ',pdescripcion,' (',numeroregistro,'-',anio,')') leyenda ,nrocuentacproveedor nrocuentac, t.importe
        FROM reclibrofact r NATURAL JOIN prestador p JOIN reclibrofact_catgastoactividad rlfa USING(idrecepcion,idcentroregional)   
        JOIN ( SELECT SUM(importe) importe, idactividad, catgasto FROM tempactividadtotal GROUP BY idactividad, catgasto) t ON(rlfa.idactividad=t.idactividad and rlfa.catgasto=t.catgasto)
        NATURAL JOIN tipofacturatipomovimiento join multivac.mapeocatgasto m on(rlfa.catgasto=m.idcategoriagastosiges)
        WHERE numeroregistro=xnroregistro AND anio=xanio and tftmsesincroniza
        GROUP BY tipomovimiento,fechaimputacion, tipofactura,letra,puntodeventa,numero,pdescripcion,numeroregistro,anio,nrocuentacproveedor, t.importe;
     */                       
            FETCH curasientoformpago INTO ritem;
            WHILE FOUND LOOP 

            IF (ritem.idvalorescaja=3) THEN     
            -- Si es CtaCte
                /*SELECT INTO rtempformapago * FROM reclibrofact r 
                NATURAL JOIN reclibrofact_formpago 
                NATURAL JOIN tipofacturatipomovimiento
                join multivac.mapeocatgasto m on(r.catgasto=m.idcategoriagastosiges)
                WHERE numeroregistro=xnroregistro  and anio = xanio and tftmsesincroniza;*/
                SELECT INTO rtempformapago tipomovimiento,
                fechaimputacion, 
                concat(tipofactura,' ',letra,' ',puntodeventa,'-',numero,' - ',pdescripcion,' (',numeroregistro,'-',anio,')')::varchar as leyenda ,
                nrocuentacproveedor::varchar as nrocuentac, rlffpmonto as importe
                    FROM reclibrofact r NATURAL JOIN prestador p JOIN reclibrofact_catgastoactividad rlfa USING(idrecepcion,idcentroregional)   
                JOIN ( SELECT SUM(importe) importe, idactividad, catgasto FROM tempactividadtotal GROUP BY idactividad, catgasto) t ON(rlfa.idactividad=t.idactividad and rlfa.catgasto=t.catgasto)
                    NATURAL JOIN tipofacturatipomovimiento join multivac.mapeocatgasto m on(rlfa.catgasto=m.idcategoriagastosiges)
                    NATURAL JOIN reclibrofact_formpago
                    WHERE numeroregistro=xnroregistro AND anio=xanio and tftmsesincroniza 
                GROUP BY tipomovimiento,fechaimputacion, tipofactura,letra,puntodeventa,numero,pdescripcion,numeroregistro,anio,nrocuentacproveedor, reclibrofact_formpago.rlffpmonto;
            
            ELSE
            -- Todas las otras FP
                SELECT INTO rtempformapago *, 
                rlffpmonto as importe, 
                nombrecuentafondos::varchar as leyenda, 
                nrocuentac::varchar as nrocuentac
                FROM reclibrofact r 
                NATURAL JOIN reclibrofact_formpago 
                NATURAL JOIN tipofacturatipomovimiento
                LEFT JOIN ordenpagocontablevalorescaja USING (idvalorescaja)
                LEFT join multivac.mapeocuentasfondos  USING (idcuentafondos)
                WHERE numeroregistro=xnroregistro  and anio = xanio and tftmsesincroniza and idvalorescaja=ritem.idvalorescaja;

                

            END IF;
                vauxtotal=rtempformapago.importe;
                --vtotal=vtotal+vauxtotal;
                RAISE NOTICE 'rtempformapago (%) ',rtempformapago;

                INSERT INTO asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                VALUES(xidasiento,centro(), vauxtotal, rtempformapago.nrocuentac::varchar, rtempformapago.leyenda::varchar, xd_h);                 

                IF xd_h='D' THEN    
                    --xdebe = xdebe + vtotal;
                    xdebe = xdebe + vauxtotal;
                ELSE            
                    --xhaber = xhaber + vtotal;
                    xhaber = xhaber + vauxtotal;
                END IF;

            FETCH curasientoformpago INTO ritem;
        END LOOP;
        CLOSE curasientoformpago;    

/*                  ELSE      
       -- KAR 07-05-23 esto se usa cuando en la carga se llaman las FP de contado, POR ahora no es necesario un cursor 

            INSERT INTO asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                VALUES(xidasiento,centro(), vtotal, regencabezado.nrocuentac, regencabezado.leyenda, xd_h);             
            IF xd_h='D' THEN    xdebe = xdebe + vtotal;
            ELSE            xhaber = xhaber + vtotal;
            END IF;
           
                  END IF;
*/          
            END IF;


 --RAISE EXCEPTION 'AAAAAAAAAAAA ';





            --Descuento
         IF vrlfdescuento>0 THEN
            INSERT INTO asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                VALUES(xidasiento,centro(),vrlfdescuento , xDesc, regencabezado.leyenda, xd_h);             
            IF xd_h='D' THEN    xdebe = xdebe + vrlfdescuento ;
            ELSE            xhaber = xhaber +vrlfdescuento ;
            END IF;
         END IF;

        -- Esto es para evitar asientos desbalanceados
         IF (abs(xdebe-xhaber)>0.01) THEN
            IF (xdebe>xhaber) THEN
                    xdh = 'H';
            ELSE
                    xdh = 'D';
            END IF;
            INSERT INTO asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                VALUES(xidasiento,centro(),abs(xdebe-xhaber),xRedondeo,regencabezado.leyenda,xdh);
         END IF;
              
  END IF; --IF ritem.subtotalact>0 THEN
FETCH curasiento INTO regasiento;
END LOOP;
CLOSE curasiento;

RAISE NOTICE 'asientogenerico_precarga_crear_7 (%) ',xidasiento;

RETURN xidasiento;
END;$function$
