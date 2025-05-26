CREATE OR REPLACE FUNCTION public.asientogenerico_crear_2()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
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
-- Este SP se usa para generar los asientosgenericos de Liquidaciones de Tarjetas
   
BEGIN

/*
Esta es la temporal con los datos de ingreso
TABLE tasientogenerico	(
            idoperacion bigint,				
  	    idcentroperacion integer DEFAULT centro(),
	    operacion varchar,
	    fechaimputa date,
	    obs varchar,
	    centrocosto int
                        );

*/


OPEN curasiento FOR SELECT * FROM tasientogenerico;

FETCH curasiento INTO regasiento;
WHILE FOUND LOOP

		idOperacion = regasiento.idoperacion/100;
                cen = regasiento.idoperacion%100;

		select into regencabezado 
			lttotalcupones as totalcupones,monto as totalgasto,
			lttotalcupones - case when nullvalue(monto) then 0 else monto end as totalliquidacion, 
			idliquidaciontarjeta,
			idcuentabancaria,case when cc.nrocuentac='10253' then '10377'  else '10374' end   as nrocuentahaber,*
		from liquidaciontarjeta as l natural join cuentabancariasosunc as cbs
			join cuentascontables as cc on (cbs.nrocuentac=cc.nrocuentac)			
                        left join (
                             select idliquidaciontarjeta,idcentroliquidaciontarjeta,sum(r.monto) monto from reclibrofact r 
                                    join liquidaciontarjetacomprobantegasto g on (r.numeroregistro=g.nroregistro and r.anio=g.anio) 
                                    group by idliquidaciontarjeta,idcentroliquidaciontarjeta
                                  ) gasto using (idliquidaciontarjeta,idcentroliquidaciontarjeta)
		where idliquidaciontarjeta=idOperacion and idcentroliquidaciontarjeta=cen;		
		
		if found then
			xdesc = regasiento.obs;				

			insert into asientogenerico(idasientogenericotipo,idasientogenericocomprobtipo,agfechacontable,agdescripcion,idcomprobantesiges,agtipoasiento)
			values(2,regasiento.idasientogenericocomprobtipo,regasiento.fechaimputa,xdesc,concat(idOperacion,'|',cen),'OTI');
			
			xidasiento=currval('asientogenerico_idasientocontable_seq');

			--item BANCO			
			if (regencabezado.totalliquidacion>0) then
				insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				values(xidasiento,centro(),regencabezado.totalliquidacion,regencabezado.nrocuentac,xdesc,'D');
			end if;
			--item PROVEEDOR
			if (regencabezado.totalgasto>0) then
				insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				values(xidasiento,centro(),regencabezado.totalgasto,'20301',xdesc,'D');
			end if;

			--item CUPONES A COBRAR
			if (regencabezado.totalcupones>0) then
				insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				values(xidasiento,centro(),regencabezado.totalcupones,regencabezado.nrocuentahaber,xdesc,'H');
			end if;
		end if;


	FETCH curasiento INTO regasiento;
END LOOP;
CLOSE curasiento;
RETURN xidasiento;
END;

$function$
