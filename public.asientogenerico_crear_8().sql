CREATE OR REPLACE FUNCTION public.asientogenerico_crear_8()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
rliq RECORD;
	xestado bigint;
	xidasiento bigint;
	idas integer;

	curasiento refcursor;
	curitem refcursor;
	curencabezado refcursor;
        curformapago refcursor;
        regformapago RECORD;
	regencabezado RECORD;
	restado RECORD;
	regitems RECORD;
	regasiento RECORD;
	regitem RECORD;
	xdesc varchar;
        idOperacion bigint;
        cen integer;

        vtipocomprobante integer;
        vtipofactura varchar;
	vnrosucursal integer;
	vnrofactura bigint;

        regrenglones refcursor;
        regrenglon record;
        rinfocheque record;
        regformaspago refcursor;
        regfp record;
        xnrocuentac varchar;
        xquien integer;
        xfechaimputa date;
	xmontototal double precision;
	xdifasiento double precision;
	xhaber double precision;
	xdebe double precision;
	xdebitos double precision;
        xdh varchar;
        rcheque record;

	-- Este SP se usa para generar los asientosgenericos de RECIBOS de COBRANZAS

BEGIN

OPEN curasiento FOR SELECT * FROM tasientogenerico;

FETCH curasiento INTO regasiento;
WHILE FOUND LOOP

     -- RAISE NOTICE 'regasiento.idoperacion, tipocomprobante (%)(%)',regasiento.idoperacion,split_part(regasiento.idoperacion, '|', 2);

	idOperacion = split_part(regasiento.idoperacion, '|', 1)::bigint;
        cen = split_part(regasiento.idoperacion, '|', 2)::integer;
-- Busca el movimiento en la cuentacorrientepago o en ctactepagocliente

--KR 24-08-22 PARA clientes adherentes se hardcodea la cta contable 10201 desde la interface (Recibo cobro a cuenta)
--KR 06-09-22 PARA clientes adherentes va a la cuenta contable 10202 Caja - puente cobranzas cliente, para los otros usa la de la cta cte pago
		select into regencabezado * from
			(select CASE WHEN nullvalue(p.nrodoc) THEN nrocuentac ELSE '10202' END nrocuentac,fechamovimiento,importe*-1 as importe,movconcepto,idcomprobante,idcentropago,denominacion, concat(cuitini,cuitmedio,cuitfin) as cuit
        ,concat(nrocliente,'-',c.barra) as id
        from ctactepagocliente 
        JOIN clientectacte  USING(idclientectacte, idcentroclientectacte)   
        NATURAL JOIN cliente c LEFT JOIN persona p ON (c.nrocliente = p.nrodoc AND c.barra = p.tipodoc)
        where idcomprobantetipos=0 
               AND idcomprobante = idOperacion AND idcentropago=cen  -- VAS 160823 
-- CS 2019-02-27 
-- Para los clientes, el nrocuentac viene de la ctactepagocliente
-- Para los afiliados, el nrocuentac se pone 10201 - cliente puente cobranzas y luego en la imputacion se define la correcta
	union 
	select '10201' as nrocuentac,fechamovimiento,importe*-1 as importe,movconcepto,idcomprobante,idcentropago,apellido ||', '||nombres as denominacion,
'' as cuit, concat(nrodoc,'-',barra) as id
            from cuentacorrientepagos 
            JOIN persona USING (nrodoc)
            -- NATURAL JOIN persona 
            -- BelenA TK 6346 -- comento esto porque por algun motivo algunos pagos en la ctacte se generan con el tipo <> 1 entonces al hacer el natural join con persona se rompia.
            where idcomprobantetipos=0 
                    AND idcomprobante = idOperacion AND idcentropago=cen -- VAS 160823 
    ) as t
    where t.idcomprobante=idOperacion and idcentropago=cen;
		if found then
			xdesc = concat('REC ',regasiento.idoperacion,'  ', regasiento.obs,' | ',regencabezado.id,'- Cuit:',regencabezado.cuit,' ',regencabezado.denominacion,' | ',regencabezado.movconcepto);
			insert into asientogenerico(idasientogenericotipo,idasientogenericocomprobtipo,agfechacontable,agdescripcion,idcomprobantesiges,agtipoasiento,idagquienmigra)
           values(2,8,regencabezado.fechamovimiento,xdesc,concat(idOperacion,'|',cen),'OTI',3);			
   		  	xidasiento=currval('asientogenerico_idasientocontable_seq');
			xdebe = 0;
		  	xhaber = 0;
			--ITEM Cobranza Puente
			insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
			values(xidasiento,centro(),regencabezado.importe,regencabezado.nrocuentac,xdesc,'H');			
		        xhaber = xhaber + regencabezado.importe;

			OPEN curitem for
					select * 
					from recibocupon r natural join valorescaja v
						natural join
						(select min(nrosucursal) nrosucursal,centro from talonario where centro<>99 group by centro union select 19,99 UNION select 99, 98) as suc 
					left join multivac.formapagotiposcuentafondos m on (v.idvalorescaja=m.idvalorescaja and suc.nrosucursal=m.nrosucursal)
					left join multivac.mapeocuentasfondos mm using (idcuentafondos)
					where r.idrecibo= idOperacion and idcentrorecibocupon=cen;		
			
			FETCH curitem INTO regitem;
			WHILE FOUND LOOP 
				--ITEMS VALORES
				insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				values(xidasiento,centro(),regitem.monto,regitem.nrocuentac,xdesc,'D');			
		                xdebe = xdebe + regitem.monto;	

				FETCH curitem INTO regitem;
			END LOOP;
			CLOSE curitem;
			-- Esto es para evitar asientos desbalanceados
			if (abs(xdebe-xhaber)>0.01) then
		                if (abs(xdebe-xhaber)>1) then
		                    update asientogenerico set agerror='Advertencia: Diferencia por Redondeo mayor a $1'
		                    where idasientogenerico=xidasiento and idcentroasientogenerico=centro();
		                end if;
				if (xdebe>xhaber) then
					xdh = 'H';
		                        update asientogenerico set idasientogenericotipo=6,agtipoasiento='AS'
		                        where idasientogenerico=xidasiento and idcentroasientogenerico=centro();
				else
					xdh = 'D';
				end if;
				insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				values(xidasiento,centro(),abs(xdebe-xhaber),'50911',xdesc,xdh);
			end if;
		end if;	

	FETCH curasiento INTO regasiento;
END LOOP;
CLOSE curasiento;
RETURN xidasiento;

END;

$function$
