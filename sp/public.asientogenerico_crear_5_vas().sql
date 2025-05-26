CREATE OR REPLACE FUNCTION public.asientogenerico_crear_5_vas()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
-- Este SP se usa para generar los asientosgenericos de Facturas de Venta
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
	xdh varchar;

	xtipofactura varchar;
	xtipocomprobante integer;
	xnrosucursal integer;
	xnrofactura bigint;
	xcentro  integer;
	xitems double precision;
	xitem double precision;
	xitem1 double precision;
	xitem2 double precision;
	xitem3 double precision;
	xd_h varchar;
	xiva double precision;
	xdesciva1 double precision;
	xdesciva2 double precision;
	xdesciva3 double precision;
	xdesciva1porc double precision;
	xdesciva2porc double precision;
	xdesciva3porc double precision;
        xidcentroasiento integer;

BEGIN

/*
Esta es la temporal con los datos de ingreso */
/*CREATE TEMP TABLE tasientogenerico	(
        idoperacion varchar,
        idasientogenericocomprobtipo int DEFAULT 5,				
  	    idcentroperacion integer DEFAULT centro(),
	    operacion varchar,
	    fechaimputa date,
	    obs varchar,
	    centrocosto int );
*/


OPEN curasiento FOR SELECT idasientogenerico,idcentroasientogenerico,idasientogenericotipo,idasientogenericocomprobtipo
				,agfechacontable as fechaemision, agdescripcion as concepto,idcomprobantesiges as idoperacion
				,agtipoasiento
				,idagquienmigra 
				FROM  asientogenerico
				LEFT JOIN asientogenericoitem USING(idasientogenerico,idcentroasientogenerico)
				WHERE idasientogenericocomprobtipo = 5 AND nullvalue(asientogenericoitem.idasientogenerico)
				AND agfechacontable >= '2018-09-01'
;

FETCH curasiento INTO regasiento;
WHILE FOUND LOOP

           IF char_length(split_part(regasiento.idoperacion, '|', 4)) > 1 THEN --MaLaPi 15-06-2018 Verifico puesto que al ingresar un reintegro el trigger se dispara 2 veces no se por que....

               RAISE NOTICE 'regasiento.idoperacion, tipocomprobante (%)(%)',regasiento.idoperacion,split_part(regasiento.idoperacion, '|', 2);
		xtipofactura = split_part(regasiento.idoperacion, '|', 1);
RAISE NOTICE 'tipocomprobante (%)',split_part(regasiento.idoperacion, '|', 2);
		xtipocomprobante = trim(split_part(regasiento.idoperacion, '|', 2))::integer;
		xnrosucursal = split_part(regasiento.idoperacion, '|', 3)::integer;
		xnrofactura = split_part(regasiento.idoperacion, '|', 4)::bigint;

		select into regencabezado
			concat(f.tipofactura,' ',desccomprobanteventa,' ',lpad(nrosucursal,4,'0'),'-',lpad(nrofactura,8,'0'),' - ',denominacion) as concepto, case when tt.tipomovimiento='Deuda' then 1 else -1 end *
			importeefectivo+importectacte as importe,fechaemision
		from facturaventa f
			join tipocomprobanteventa t on (f.tipocomprobante=t.idtipo)
			join tipofacturatipomovimiento tt using(tipofactura)			
			join cliente c on (f.nrodoc=c.nrocliente and f.barra=c.barra)
		where tipofactura=xtipofactura and tipocomprobante=xtipocomprobante and nrosucursal=xnrosucursal and nrofactura=xnrofactura;


		if found then

			
			--insert into asientogenerico(idasientogenericotipo,idasientogenericocomprobtipo,agfechacontable,agdescripcion,idcomprobantesiges,agtipoasiento,idagquienmigra)
			--values(6,5,regencabezado.fechaemision,regencabezado.concepto,regasiento.idoperacion,'AS',2);
			
			--xidasiento=currval('asientogenerico_idasientocontable_seq');
			--xidcentroasiento = centro();
			xidasiento = regasiento.idasientogenerico;
			xidcentroasiento = regasiento.idcentroasientogenerico;

			-- PRIMERA PARTE
			--Los Descuentos agrupados por idiva
			select into xdesciva1 case when nullvalue(sum(importe)) then 0 else sum(importe) end as importe
				from itemfacturaventa					
				where idiva=1 and idconcepto='50840' and tipofactura=xtipofactura and tipocomprobante=xtipocomprobante and nrosucursal=xnrosucursal and nrofactura=xnrofactura;
			select into xdesciva2 case when nullvalue(sum(importe)) then 0 else sum(importe) end as importe
				from itemfacturaventa
				where idiva=2 and idconcepto='50840' and tipofactura=xtipofactura and tipocomprobante=xtipocomprobante and nrosucursal=xnrosucursal and nrofactura=xnrofactura;
			select into xdesciva3 case when nullvalue(sum(importe)) then 0 else sum(importe) end as importe
				from itemfacturaventa
				where idiva=3 and idconcepto='50840' and tipofactura=xtipofactura and tipocomprobante=xtipocomprobante and nrosucursal=xnrosucursal and nrofactura=xnrofactura;

			
			--Calculo el porcentaje de descuento a prorratear
			select into xitem1 case when nullvalue(sum(importe*(1+porcentaje))) then 0 else sum(importe*(1+porcentaje)) end as importe
				from itemfacturaventa
					join tipoiva using (idiva)
				where idconcepto not in ('50840','20821') and tipofactura=xtipofactura and tipocomprobante=xtipocomprobante and nrosucursal=xnrosucursal and nrofactura=xnrofactura and idiva=1;
			xdesciva1porc = 1;
			if (xitem1<>0) then xdesciva1porc = 1 - xdesciva1*(-1)/xitem1; end if;

			select into xitem2 case when nullvalue(sum(importe*(1+porcentaje))) then 0 else sum(importe*(1+porcentaje)) end as importe
				from itemfacturaventa
					join tipoiva using (idiva)
				where idconcepto not in ('50840','20821') and tipofactura=xtipofactura and tipocomprobante=xtipocomprobante and nrosucursal=xnrosucursal and nrofactura=xnrofactura and idiva=2;
			xdesciva2porc = 1;			
			if (xitem2<>0) then xdesciva2porc = 1 - xdesciva2*(-1)/xitem2; end if;

			select into xitem3 case when nullvalue(sum(importe*(1+porcentaje))) then 0 else sum(importe*(1+porcentaje)) end as importe
				from itemfacturaventa
					join tipoiva using (idiva)
				where idconcepto not in ('50840','20821') and tipofactura=xtipofactura and tipocomprobante=xtipocomprobante and nrosucursal=xnrosucursal and nrofactura=xnrofactura and idiva=3;
			xdesciva3porc = 1;
			if (xitem3<>0) then xdesciva3porc = 1 - xdesciva3*(-1)/xitem3; end if;
		
			-- los items
			OPEN curitem for
				select sum(importe) as importe,idiva,idconcepto,porcentaje
					from itemfacturaventa
					join tipoiva using (idiva)
				where idconcepto not in ('50840','20821') and tipofactura=xtipofactura and tipocomprobante=xtipocomprobante and nrosucursal=xnrosucursal and nrofactura=xnrofactura
				group by idconcepto,idiva,porcentaje;

			FETCH curitem INTO regitem;

			xitems = 0;
			xitem = 0;
			xiva = 0;
			WHILE FOUND LOOP
 				if (regencabezado.importe<0) then
					xd_h='D';
				else
					xd_h='H';
				end if;

				-- Prorrateamos el descuento global en cada uno de los items
				if (regitem.idiva=1) then xitem = regitem.importe*xdesciva1porc; end if;
				if (regitem.idiva=2) then xitem = regitem.importe*xdesciva2porc; end if;
				if (regitem.idiva=3) then xitem = regitem.importe*xdesciva3porc; end if;
								
				insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				values(xidasiento,xidcentroasiento,xitem,regitem.idconcepto,regencabezado.concepto,xd_h);						
				xitems = xitems + xitem;
				xiva = xiva + (xitem*regitem.porcentaje);
				xitem = 0;
				FETCH curitem INTO regitem;
			END LOOP;
			CLOSE curitem;
			if (abs(xiva)>0) then
				insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				values(xidasiento,xidcentroasiento,xiva,'20821',regencabezado.concepto,xd_h);				
			end if;
			xhaber = xitems + xiva;
			-- SEGUNDA PARTE:
				-- los valores
			xdebe=0;
			OPEN curitem for
				select sum(monto) as monto,nrocuentac
					from facturaventacupon f
					join multivac.formapagotiposcuentafondos t on(f.nrosucursal=t.nrosucursal and f.idvalorescaja=t.idvalorescaja)
					join multivac.mapeocuentasfondos m using(idcuentafondos)					
				where f.tipofactura=xtipofactura and f.tipocomprobante=xtipocomprobante and f.nrosucursal=xnrosucursal and f.nrofactura=xnrofactura
				group by nrocuentac;

			FETCH curitem INTO regitem;
			
			WHILE FOUND LOOP
 				if (regencabezado.importe>0) then
					xd_h='D';
				else
					xd_h='H';
				end if;

				insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				values(xidasiento,xidcentroasiento,regitem.monto,regitem.nrocuentac,regencabezado.concepto,xd_h);						
				xdebe = xdebe + (regitem.monto);
				FETCH curitem INTO regitem;
			END LOOP;
			CLOSE curitem;

			-- Esto es para evitar asientos desbalanceados
			if (abs(xdebe-xhaber)>0.01) then
				if (xdebe>xhaber) then
					xdh = 'H';
				else
					xdh = 'D';
				end if;
				insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				values(xidasiento,xidcentroasiento,abs(xdebe-xhaber),'50911',xdesc,xdh);
			end if;
			----------------------------------------------
		end if;	

        END IF;

	FETCH curasiento INTO regasiento;

END LOOP;
CLOSE curasiento;
RETURN xidasiento;
END;
$function$
