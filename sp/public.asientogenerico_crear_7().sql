CREATE OR REPLACE FUNCTION public.asientogenerico_crear_7()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$-- Este SP se usa para generar los asientosgenericos de Comprobantes de Compras
DECLARE
        rliq RECORD;
    xestado bigint;
    xidasiento bigint;
    idas integer;

    curasiento refcursor;
    curitem refcursor;
    curitemdesc refcursor;
    curencabezado refcursor;
        curformapago refcursor;
        regformapago RECORD;
    regencabezado RECORD;
    regitems RECORD;
    regasiento RECORD;
    regitem RECORD;
    regitemdesc RECORD;
        idOperacion bigint;
        cen integer;

        vtipocomprobante integer;
        vtipofactura varchar;
    vnrosucursal integer;
    vnrofactura bigint;

        regrenglones refcursor;
        regrenglon record;

        regformaspago refcursor;
        regfp record;
        xnrocuentac varchar;
        xquien integer;
        xfechaimputa date;
    xmontototal double precision;
    xdifasiento double precision;
    xhaber double precision;
    xdebe double precision; 
    xdh varchar;

    xnroregistro varchar;
    xanio integer;
    xcentro  integer;

    xd_h varchar;

    xIva varchar;
    xRetIva varchar;
    xRetGan varchar;
    xRetIIBB varchar;
    xDesc varchar;
    xRedondeo varchar;
        xRecargo varchar;
        lacuenta_iibb  varchar;
  -- <---> BelenA agrego:
    xImbDebCred varchar;
   
BEGIN

/*
Esta es la temporal con los datos de ingreso
TABLE tasientogenerico  (
            idoperacion bigint,             
        idcentroperacion integer DEFAULT centro(),
        operacion varchar,
        fechaimputa date,
        obs varchar,
        centrocosto int
                        );

*/
-- Cuentas contables Default
xIva = '10386';
xRetIva='10389';
xRetGan='50845';
xRetIIBB='50797';
xDesc='40607';
xRedondeo='50911';
xRecargo='50731';
xImbDebCred='10395';

OPEN curasiento FOR 
                   SELECT * 
                   FROM tasientogenerico 
                   JOIN reclibrofact ON (numeroregistro = tasientogenerico.idoperacion/10000 and anio = tasientogenerico.idoperacion%10000 ) 
                   WHERE idprestador <> 2608 ;  -- los comprobantes de sosunc no  deberian generar contabilidad

FETCH curasiento INTO regasiento;
WHILE FOUND LOOP

        xnroregistro = regasiento.idoperacion/10000;
--      xnroregistro = split_part(regasiento.idoperacion, '|', 1);
        xanio = regasiento.idoperacion%10000;
--      xanio = split_part(regasiento.idoperacion, '|', 2);
        
        select into regencabezado
            tipomovimiento,fechaimputacion,nrocuentacproveedor,m.nrocuentac as nrocuentacgasto, netoiva105+netoiva21+netoiva27+exento+nogravado as subtotal,monto as total,retganancias,retiibb,retiva,iva105+iva21+iva27 as iva,recargo,descuento,
concat(tipofactura,' ',letra,' ',puntodeventa,'-',numero,' - ',pdescripcion,' (',numeroregistro,'-',anio,')') leyenda
,rlfpiibbneuquen,rlfpiibbrionegro,rlfpiibbotrajuri, impdebcred
from reclibrofact r natural join prestador p
join multivac.mapeocatgasto m on(r.catgasto=m.idcategoriagastosiges)
natural join tipofacturatipomovimiento
        where numeroregistro=xnroregistro and anio=xanio
                       and tftmsesincroniza  ; -- genera contabilidad

        if found then

                        --RAISE NOTICE 'xnroregistro (%)',xnroregistro;
            insert into asientogenerico(idasientogenericotipo,idasientogenericocomprobtipo,agfechacontable,agdescripcion,idcomprobantesiges,agtipoasiento,idagquienmigra)
            values(6,7,regencabezado.fechaimputacion,regencabezado.leyenda,concat(xnroregistro,'|',xanio),'AS',3);
            
            xidasiento=currval('asientogenerico_idasientocontable_seq');
        
        if regencabezado.tipomovimiento='Deuda' then
            xd_h='D';
        else
            xd_h='H';
        end if;

        --Renglones
            --Gasto
            if regencabezado.subtotal>0 then
                insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                    values(xidasiento,centro(), regencabezado.subtotal, regencabezado.nrocuentacgasto, regencabezado.leyenda, xd_h);                
                    if xd_h='D' then    xdebe = xdebe + (regencabezado.subtotal);
                    else            xhaber = xhaber + (regencabezado.subtotal);
                    end if;
            end if;

            --IVA
            if regencabezado.iva>0 then
                insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                    values(xidasiento,centro(), regencabezado.iva, xIva, regencabezado.leyenda, xd_h);              
                    if xd_h='D' then    xdebe = xdebe + (regencabezado.iva);
                    else            xhaber = xhaber + (regencabezado.iva);
                    end if;
            end if;

            --Percepcion IVA
            if regencabezado.retiva>0 then
                insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                    values(xidasiento,centro(), regencabezado.retiva, xRetIva, regencabezado.leyenda, xd_h);                
                    if xd_h='D' then    xdebe = xdebe + (regencabezado.retiva);
                    else            xhaber = xhaber + (regencabezado.retiva);
                    end if;
            end if;---------

            --Percepcion GANANCIAS
            if regencabezado.retganancias>0 then
                insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                    values(xidasiento,centro(), regencabezado.retganancias, xRetGan, regencabezado.leyenda, xd_h);              
                    if xd_h='D' then    xdebe = xdebe + (regencabezado.retganancias);
                    else            xhaber = xhaber + (regencabezado.retganancias);
                    end if;
            end if;---------------

            --Percepcion IIBB modf 23/10/2019
            if regencabezado.retiibb>0 then
                                 
                                if(  not nullvalue(regasiento.rlfpiibbneuquen)  AND (regasiento.rlfpiibbneuquen>0) ) THEN
                                      lacuenta_iibb = 10383; --- IIBB Neuquen
                                      insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                    values(xidasiento,centro(), regencabezado.rlfpiibbneuquen, lacuenta_iibb, regencabezado.leyenda, xd_h);             
                                END IF;
                                if(  not nullvalue(regasiento.rlfpiibbrionegro) AND (regasiento.rlfpiibbrionegro>0)) THEN
                                       lacuenta_iibb =  10384;  --- IIBB Rio NNegro
                                      insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                    values(xidasiento,centro(), regencabezado.rlfpiibbrionegro, lacuenta_iibb, regencabezado.leyenda, xd_h);                
                                     
                                END IF; 
                                if(  not nullvalue(regasiento.rlfpiibbotrajuri)AND (regasiento.rlfpiibbotrajuri>0) ) THEN
                                      lacuenta_iibb =  50797;  --- IIBB OTRA  
                                      insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                    values(xidasiento,centro(), regencabezado.rlfpiibbotrajuri, lacuenta_iibb, regencabezado.leyenda, xd_h);                
                                     
                                END IF; 
                
                if xd_h='D' then    
                                                     xdebe = xdebe + (regencabezado.retiibb);
                else            
                                                     xhaber = xhaber + (regencabezado.retiibb);
                end if;
            end if;----------

                        --Recargo
            if regencabezado.recargo>0 then
                insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                    values(xidasiento,centro(), regencabezado.recargo, xRecargo, regencabezado.leyenda, xd_h);              
                    if xd_h='D' then    xdebe = xdebe + (regencabezado.recargo);
                    else            xhaber = xhaber + (regencabezado.recargo);
                    end if;
            end if;----------



            -- <---> BelenA agrego: impdebcred  xImbDebCred
          IF regencabezado.impdebcred>0 then
            INSERT INTO asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                VALUES(xidasiento,centro(), regencabezado.impdebcred, xImbDebCred, regencabezado.leyenda, xd_h);                
            IF (xd_h='D') THEN      xdebe = xdebe +regencabezado.impdebcred;
            ELSE            xhaber = xhaber + regencabezado.impdebcred;
            END IF;
          END IF;



            --CONTRAPARTIDA
            if xd_h='D' then xd_h='H';
            else xd_h='D';
            end if;--------

            --Proveedores
            if regencabezado.total>0 then
                insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                    values(xidasiento,centro(), regencabezado.total, regencabezado.nrocuentacproveedor, regencabezado.leyenda, xd_h);               
                    if xd_h='D' then    xdebe = xdebe + (regencabezado.total);
                    else            xhaber = xhaber + (regencabezado.total);
                    end if;
            end if;------

            --Descuento
            if regencabezado.descuento>0 then
                insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                    values(xidasiento,centro(), regencabezado.descuento, xDesc, regencabezado.leyenda, xd_h);               
                    if xd_h='D' then    xdebe = xdebe + (regencabezado.descuento);
                    else            xhaber = xhaber + (regencabezado.descuento);
                    end if;
            end if;----

            -- Esto es para evitar asientos desbalanceados
            --  04/10/2019 Lo comento ya que el control de asientos des balanceados se realiza en el procedimiento ppal
                        --  23/06/2020 MaLaPi lo vuelvo a descomentar, pues no se hace en el ppal.
                        if (abs(xdebe-xhaber)>0.01) then
                if (xdebe>xhaber) then
                    xdh = 'H';
                else
                    xdh = 'D';
                end if;
                insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
                values(xidasiento,centro(),abs(xdebe-xhaber),xRedondeo,regencabezado.leyenda,xdh);
            end if;
            ----------------------------------------------
        end if; 

    FETCH curasiento INTO regasiento;
END LOOP;
CLOSE curasiento;
RETURN xidasiento;
END;

$function$
