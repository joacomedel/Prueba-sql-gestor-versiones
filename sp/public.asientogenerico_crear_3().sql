CREATE OR REPLACE FUNCTION public.asientogenerico_crear_3()
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
-- Este SP se usa para generar los asientosgenericos de Bonificaciones otorgadas en Aportes
   
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
		*
		from aporte
		where idaporte= idOperacion and idcentroregionaluso=cen;

		if found then
			xdesc = regasiento.obs;				

			insert into asientogenerico(idasientogenericotipo,idasientogenericocomprobtipo,agfechacontable,agdescripcion,idcomprobantesiges,agtipoasiento,idagquienmigra)
			values(2,regasiento.idasientogenericocomprobtipo,regasiento.fechaimputa,xdesc,concat(idOperacion,'|',cen),'OTI',4);

			xidasiento=currval('asientogenerico_idasientocontable_seq');

			--item BONIFICACION
			if (regencabezado.importe-(regencabezado.importe/1.105)>0) then			
				insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				values(xidasiento,centro(),regencabezado.importe-(regencabezado.importe/1.105),'50842',xdesc,'D');			
			--item APORTE
				insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				values(xidasiento,centro(),regencabezado.importe-(regencabezado.importe/1.105),regencabezado.nrocuentac,xdesc,'H');			
			end if;
		end if;	


	FETCH curasiento INTO regasiento;
END LOOP;
CLOSE curasiento;
RETURN xidasiento;
END;

$function$
