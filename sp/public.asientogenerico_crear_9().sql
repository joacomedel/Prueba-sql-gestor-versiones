CREATE OR REPLACE FUNCTION public.asientogenerico_crear_9()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$-- Parámetros
-- $1 idcomprobante ej: 'iddeuda|idcentrodeuda|idpago|idcentropago'
-- $2 idasientogenericocomprobtipo, ej. 9 equivale a IMPUTACION

DECLARE
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
	xiddeuda bigint;
        xidcd integer;
        xidpago bigint;
        xidcp integer;

	-- Este SP se usa para generar los asientosgenericos de IMPUTACIONES en la cuenta corriente de Clientes y Afiliados

BEGIN

OPEN curasiento FOR SELECT * FROM tasientogenerico;

FETCH curasiento INTO regasiento;
WHILE FOUND LOOP

                xiddeuda = split_part(regasiento.idoperacion, '|', 1);
                xidcd = split_part(regasiento.idoperacion, '|', 2);
                xidpago = split_part(regasiento.idoperacion, '|', 3);
                xidcp = split_part(regasiento.idoperacion, '|', 4);
		
		-- Busca el movimiento en la cuentacorrientedeudapago o en ctactedeudapagocliente
		select into regencabezado  
-- CS 2019-03-28 la fecha debe ser la del PAGO

--
/* CS 2019-04-01 Solamente los recibos de afiliados deben generar asiento de imputacion, ya que los recibos de cliente generan la imputacion directamente en el recibo*/
--KR 26-08-22 Ahora la imputacion tambien genera contabilidad
--			d.fechamovimiento::date as fechamovimientoimputacion
			p.fechamovimiento::date as fechamovimientoimputacion
,importeimp,idpago,idcentropago,iddeuda,idcentrodeuda,p.idcomprobante,d.nrocuentac,d.movconcepto conceptodeuda,p.movconcepto conceptopago,d.idcomprobante idcomprobantedeuda
			from ctactedeudapagocliente dp
			join ctactedeudacliente d using (iddeuda,idcentrodeuda)                        
                        join comprobantestipos ct on (d.idcomprobantetipos=ct.idcomprobantetipos and ct.ctgeneracontabilidad)
			join ctactepagocliente p using (idpago,idcentropago)
			where (p.idcomprobantetipos=0 )
                              AND dp.idctactedeudapagocliente= split_part(regasiento.idoperacion, '|', 5)
                              AND dp.idcentroctactedeudapagocliente = split_part(regasiento.idoperacion, '|', 6)
--dp.idpago=xidpago and dp.idcentropago=xidcp and dp.iddeuda=xiddeuda and dp.idcentrodeuda=xidcd
-- CS 2019-02-25 la fecha del recibo tiene que ser mayor a 2018
                              and p.fechamovimiento>'2018-12-31'
                        union 
                        select
/* -- -----------------------------------------------------------------------*/

-- CS 2019-03-28 la fecha debe ser la del PAGO
--			d.fechamovimiento::date as fechamovimientoimputacion
--                        p.fechamovimiento as fechamovimientoimputacion
-- CS 2019-05-07 la fecha debe ser la del pago o la de la deuda, la mayor de ambas 
-- CS 2019-05-22 siempre que la fecha de la deuda no sea mayor a hoy
 case when p.fechamovimiento>=d.fechamovimiento then p.fechamovimiento::date else case when d.fechamovimiento>current_date then p.fechamovimiento::date else d.fechamovimiento::date end end as fechamovimientoimputacion
,importeimp,idpago,idcentropago,iddeuda,idcentrodeuda,p.idcomprobante,cc.nrocuentacontable::varchar nrocuentac,d.movconcepto conceptodeuda,p.movconcepto conceptopago,d.idcomprobante idcomprobantedeuda
			from cuentacorrientedeudapago dp
			join cuentacorrientedeuda d using (iddeuda,idcentrodeuda)
                        join comprobantestipos ct on (d.idcomprobantetipos=ct.idcomprobantetipos and ct.ctgeneracontabilidad)
                        join cuentacorrienteconceptotipo cc on (d.idconcepto=cc.idconcepto)
			join cuentacorrientepagos p using (idpago,idcentropago)
-- CS 2019-03-26 Solo debe generar imputaciones de Recibos O 55 --Orden Reintegro
/*KR 24-01-22 ME fijo si el informe asociado al pago es de un reintegro, si lo es entonces genera contabilidad*/
                        LEFT JOIN informefacturacion if ON ((p.idcomprobante / 100) = if.nroinforme AND p.idcomprobantetipos=21 )
			where (p.idcomprobantetipos=0 
                            /*KR 24-01-22 comento ya que ahora el movimiento se realiza desde el informe. TKT #4829   OR p.idcomprobantetipos=55 --MaLaPi Orden Reintegro 04-06-2019 */
                               OR (p.idcomprobantetipos=21 and not nullvalue(if.nroinforme))
                               OR p.idcomprobantetipos=60 -- MaLaPi Minuta de Pago 04-06-2019
                               ) and dp.idpago=xidpago and dp.idcentropago=xidcp and dp.iddeuda=xiddeuda and dp.idcentrodeuda=xidcd
                             and p.fechamovimiento>'2018-12-31';		

		if found then
			xdesc = concat(regasiento.obs,' | IMPUTACION ',regencabezado.idcentropago,'-',regencabezado.idcomprobante,': ',regencabezado.conceptopago,' <--> a Deuda ',regencabezado.idcentrodeuda,'-',regencabezado.idcomprobantedeuda,': ',regencabezado.conceptodeuda);
			insert into asientogenerico(idasientogenericotipo,idasientogenericocomprobtipo,agfechacontable,agdescripcion,idcomprobantesiges,agtipoasiento,idagquienmigra)
           values(2,9,regencabezado.fechamovimientoimputacion,xdesc,regasiento.idoperacion,'OTI',3);			
   		  	xidasiento=currval('asientogenerico_idasientocontable_seq');
			xdebe = 0;
		  	xhaber = 0;
			--ITEM Cobranza Puente
			insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
			values(xidasiento,centro(),regencabezado.importeimp,'10201',xdesc,'D');			
		        xhaber = xhaber + regencabezado.importeimp;
			--ITEM Imputacion
			insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
			values(xidasiento,centro(),regencabezado.importeimp,regencabezado.nrocuentac,xdesc,'H');			
		        xdebe = xdebe + regencabezado.importeimp;

			
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

END;$function$
