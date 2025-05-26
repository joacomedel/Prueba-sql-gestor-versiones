CREATE OR REPLACE FUNCTION public.asientogenerico_crear_4_arreglo(bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
	rejerciciocontable RECORD;
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
	xhaber1 double precision;
	xdebe double precision;
	xdebe1 double precision;
	xiva double precision;
	xdebitos double precision;
	xdh varchar;

-- CS 2018-10-16
-- Este SP se usa para generar los asientosgenericos de Minutas de Pago, solo los que tienen debitos y por esta única vez para corregir
   
BEGIN

idOperacion = $1::integer/100;
cen = $1::integer%100;

-- Solamente tomo las OP que tienen débitos		
		select into regencabezado
		       idordenpagotipo,agfechacontable,concepto,importetotal,case when not nullvalue(o.nrocuentachaber) then o.nrocuentachaber else ot.nrocuentachaber end as nrocuentachaber
		from ordenpago o 
        join ordenpagotipo ot using (idordenpagotipo)
        join (select * from cambioestadoordenpago where nullvalue(ceopfechafin)) e on (o.nroordenpago*100+o.idcentroordenpago=e.nroordenpago*100+e.idcentroordenpago)
      	join (select split_part(idcomprobantesiges,'|',1)::bigint nroordenpago,split_part(idcomprobantesiges,'|',2)::integer idcentroordenpago, agfechacontable 
from asientogenerico natural join (select * from asientogenericoestado where nullvalue(agefechafin) and tipoestadofactura=7) as eag
where idasientogenericocomprobtipo=4) as ag on (o.nroordenpago*100+o.idcentroordenpago=ag.nroordenpago*100+ag.idcentroordenpago)
	join (select distinct nroordenpago,idcentroordenpago from ordenpagoimputacion where haber>0) ss on (o.nroordenpago*100+o.idcentroordenpago=ss.nroordenpago*100+ss.idcentroordenpago)			
		where o.idordenpagotipo=1 and e.idtipoestadoordenpago<>4 and o.nroordenpago= idOperacion and o.idcentroordenpago=cen;

		if found then
                        xdesc = concat('Dev.Minuta ',idOperacion,'-',cen,' | ',regencabezado.concepto);				
--                        xfechaimputa = regencabezado.agfechacontable;
                        xfechaimputa = '2018-12-31';

                        insert into asientogenerico(idasientogenericotipo,idasientogenericocomprobtipo,agfechacontable,agdescripcion,idcomprobantesiges,agtipoasiento,idagquienmigra)
			values(1,4,xfechaimputa,xdesc,concat(idOperacion,'|',cen),'OTP',3);
			
			xidasiento=currval('asientogenerico_idasientocontable_seq');

			OPEN curitem for 
				select *
				from ordenpago o natural join ordenpagoimputacion i
				where nroordenpago= idOperacion and idcentroordenpago=cen; --and debe>0;
			FETCH curitem INTO regitem;


			xdebitos = 0;
			xdebe = 0;
                        xhaber = 0;
                        xiva = 0;
			WHILE FOUND LOOP 
			    --items DEBE
                            if not (regitem.nrocuentac='10386') then
                            --CS 2017-12-18 el IVA que aparece devengado no debe incluirse en el asiento				
				if (regitem.haber>0) then
				        insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
					values(xidasiento,centro(),abs(regitem.haber),regitem.nrocuentac,xdesc,'D');
                                        xdebe = xdebe + abs(regitem.haber);			
					xdebitos = xdebitos + regitem.haber;
					-- Actualizo el tipo de asiento para que soporte Muchos a Muchos (debe y haber)
                                        update asientogenerico set idasientogenericotipo=6,agtipoasiento='AS'
                                        where idasientogenerico=xidasiento and idcentroasientogenerico=centro();
				
				end if;
                            else
                                xiva=regitem.debe;
                            end if;
			    FETCH curitem INTO regitem;
			END LOOP;
			CLOSE curitem;
			
			--Deudas por Prestaciones Medicas (PASIVO)
			if (regencabezado.importetotal>0) then
                                xhaber1 = xdebitos;
				insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				values(xidasiento,centro(),xhaber1,regencabezado.nrocuentachaber,xdesc,'H');
                                xhaber = xhaber + xhaber1;
			end if;

			-- CS 2017-09-06
			-- Esto es para evitar asientos desbalanceados
			if (abs(xdebe-xhaber)>0.01) then
                                update asientogenerico set idasientogenericotipo=6,agtipoasiento='AS'
                                where idasientogenerico=xidasiento and idcentroasientogenerico=centro();
                                if (abs(xdebe-xhaber)>1) then
                                    update asientogenerico set agerror='Advertencia: Diferencia por Redondeo mayor a $1'
                                    where idasientogenerico=xidasiento and idcentroasientogenerico=centro();
                                end if;
    			        
                                if (xdebe>xhaber) then
					xdh = 'H';
				else
					xdh = 'D';
				end if;
				insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				values(xidasiento,centro(),abs(xdebe-xhaber),'50911',xdesc,xdh);
			end if;
			----------------------------------------------
		end if;

perform	cambiarestadoasientogenerico(xidasiento,centro(),1);

        perform	cambiarestadoasientogenerico(xidasiento,centro(),1);
	
        -- CS 2018-06-05 la fechaimputa no siempre es un campo visible en la temp, por lo tanto hay que obtenerlo del asiento registrado
        select into xfechaimputa agfechacontable from asientogenerico where idasientogenerico=xidasiento and idcentroasientogenerico=centro();

/*
        --- VAS 16/04/2018 para guardar a que ejercicio corresponde el asiento
        SELECT INTO rejerciciocontable *
        FROM contabilidad_ejerciciocontable 
        WHERE xfechaimputa>=ecfechadesde and xfechaimputa<=ecfechahasta ;

        UPDATE asientogenerico 
        SET idejerciciocontable = rejerciciocontable.idejerciciocontable 	 
        WHERE idasientogenerico = xidasiento 
               and idcentroasientogenerico = centro() ;

        --- OJOOOO Cuando el ejercicio esta cerrado se debe utilizar como fecha del asiento la configurada
        IF not nullvalue(rejerciciocontable.eccerrado) THEN 
                 UPDATE asientogenerico 
                 SET agfechacontable = rejerciciocontable.ecfechaimpxcierre
                 WHERE idasientogenerico = xidasiento 
                       and idcentroasientogenerico = centro() ;
                
        END IF;
*/


	

RETURN xidasiento;
END;

$function$
