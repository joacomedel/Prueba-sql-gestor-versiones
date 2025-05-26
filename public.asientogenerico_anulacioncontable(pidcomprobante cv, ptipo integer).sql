CREATE OR REPLACE FUNCTION public.asientogenerico_anulacioncontable(pidcomprobante character varying, ptipo integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
-- CS 2019-02-19
-- Sirve para Anular contablemente un comprobante de SIGES. Esto es más que una reversion, ya que computa todos los asientos contables que pudieran haberse registrado y genera un asiento que los compensa y anula en forma global.

-- ptipo son los tipo de asiento, por ej. 5: asientos de venta
-- pidcomprobante es el id del comprobante, por ej. 'ND|1|1|7409'

DECLARE       
        xidasiento bigint;
	curasiento refcursor;
	xasiento record;
	xconcepto varchar;
	regasiento RECORD;
	xd_h varchar;
	xdebe double precision;
	xhaber double precision;
BEGIN

OPEN curasiento FOR 
	select sum(acimonto) monto,acid_h,nrocuentac 
	from asientogenericoitem i
		natural join asientogenerico a
		natural join (select * from asientogenericoestado where nullvalue(agefechafin) and tipoestadofactura<>5) as e
	where a.idasientogenericocomprobtipo=ptipo and idcomprobantesiges=pidcomprobante
	group by acid_h,nrocuentac;

if found then
	select into xasiento *
	from asientogenerico a
		natural join (select * from asientogenericoestado where nullvalue(agefechafin) and tipoestadofactura<>5) as e 
        where agdescripcion not ilike 'REVERSION%' and a.idasientogenericocomprobtipo=ptipo and idcomprobantesiges=pidcomprobante;

	xconcepto = concat('<ANU>',xasiento.agdescripcion);

	insert into asientogenerico	(idasientogenericotipo,idasientogenericocomprobtipo,agfechacontable,agdescripcion,idcomprobantesiges,agtipoasiento,idagquienmigra)
	values(6,ptipo,xfecha,xasiento.agfechacontable,xconcepto,xasiento.idcomprobantesiges,'AS',2);

	xidasiento=currval('asientogenerico_idasientocontable_seq');

	FETCH curasiento INTO regasiento;
	WHILE FOUND LOOP

		if (regasiento.acid_h='D') then
			xd_h='H';
		else
			xd_h='D';
		end if;
		
		if (regasiento.monto>0) then
			insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
			values(xidasiento,centro(),regasiento.monto,regasiento.nrocuentac,xconcepto,xd_h);
		
			if (xd_h='D') then
				xdebe = xdebe + regasiento.monto;
			else
				xhaber = xhaber + regasiento.monto;
			end if;
		end if;

	FETCH curasiento INTO regasiento;
	END LOOP;
	CLOSE curasiento;

	-- Esto es para evitar asientos desbalanceados
	if (abs(xdebe-xhaber)>0.05) then
		if (xdebe>xhaber) then
			xd_h = 'H';
		else
			xd_h = 'D';
		end if;
		insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
		values(xidasiento,centro(),abs(xdebe-xhaber),'50911',xconcepto,xd_h);
	end if;

	perform cambiarestadoasientogenerico(xidasiento,centro(),1);

end if;

return xidasiento;
END;

$function$
