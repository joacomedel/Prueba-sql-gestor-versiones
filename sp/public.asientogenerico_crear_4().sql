CREATE OR REPLACE FUNCTION public.asientogenerico_crear_4()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
    	rliq RECORD;
	xestado bigint;
	xidasiento bigint;
	idas integer;
elacid_h  varchar;
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
	xdebe1 double precision;
	xhaber1 double precision;
        xgastos double precision;
	xivaD double precision;
	xivaH double precision;
	xdebitos double precision;
	xdh varchar;
        rtipo RECORD;
-- Este SP se usa para generar los asientosgenericos de Minutas de Pago
   
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

SELECT INTO rtipo column_name, data_type, is_nullable 
from information_schema.columns 
where table_name = 'tasientogenerico'
AND column_name = 'idoperacion';

OPEN curasiento FOR SELECT * FROM tasientogenerico;

FETCH curasiento INTO regasiento;
WHILE FOUND LOOP
               
 IF trim(rtipo.data_type) = 'bigint' THEN

                   RAISE NOTICE 'asientogenerico_crear_4:: regasiento.idoperacion -  (%)',regasiento.idoperacion/100;
 		   idOperacion = (regasiento.idoperacion::integer/100)::bigint;
                   cen = regasiento.idoperacion::integer%100;
               ELSE

                  
 		   idOperacion = trim(substring(regasiento.idoperacion,1,LENGTH(regasiento.idoperacion)-2))::bigint;
                   cen = trim(substring(regasiento.idoperacion,length(regasiento.idoperacion)-1,length(regasiento.idoperacion)))::integer;

               END IF;
		
                     RAISE NOTICE 'asientogenerico_crear_4:: regasiento.idoperacion -  (id % cen %)',idOperacion,cen;

		

		select into regencabezado
		       idtipoestadoordenpago,idordenpagotipo,fechaingreso,CONCAT(beneficiario,' ',concepto) as concepto,importetotal,case when not nullvalue(o.nrocuentachaber) then o.nrocuentachaber else ot.nrocuentachaber end as nrocuentachaber
		from ordenpago o 
        join ordenpagotipo ot using (idordenpagotipo)
-- CS 2018-01-11 solo se deben tener en cuenta las minutas No Anuladas
        join (select * from cambioestadoordenpago where nullvalue(ceopfechafin)) e on (o.nroordenpago*100+o.idcentroordenpago=e.nroordenpago*100+e.idcentroordenpago)			
		where --e.idtipoestadoordenpago<>4 and 
                          o.nroordenpago= idOperacion and o.idcentroordenpago=cen

                          AND not( beneficiario ='SERVICIO DE OBRA SOCIAL DE LA UNIVERSIDAD DEL COMAHUE' AND idordenpagotipo =1) 
                          --- 050423 tk=5757 para que no tenga en cuenta a las minutas de farmacia correspondientes  a las liquidaciones
                ;

		if found then

                         RAISE NOTICE 'regencabezado.fechaingreso -  (%)(idordenpagotipo: %)(idtipoestadoordenpago:%)',regencabezado.fechaingreso,regencabezado.idordenpagotipo,regencabezado.idtipoestadoordenpago;
                        xdesc = concat(regasiento.obs,' | ',regencabezado.concepto);				
--                        xdesc = regencabezado.concepto;
                        IF existecolumtemp('tasientogenerico', 'fechaimputa') THEN  -- VAS 13-04-18 si la temporal tiene configurada una fecha esa debe ser utilizada en el asiento
                                IF(not nullvalue(regasiento.fechaimputa)) THEN
                                     xfechaimputa = regasiento.fechaimputa;
                                ELSE 
                                     xfechaimputa = regencabezado.fechaingreso;
                                END IF; 
                        ELSE
                                xfechaimputa = regencabezado.fechaingreso;
                        END IF;
                        if (regencabezado.idordenpagotipo=1) then
                              -- 17/08/2018 En las minutas, la fechaimputa se obtiene desde la fechauso de las ordenes utilizadas
                              SELECT into xfechaimputa concat (extract(year from fechauso),'/',extract(month from fechauso),'/',MAX(extract(day from fechauso)))::date
                              FROM factura 
                              NATURAL JOIN tipocomprobante
                              left join facturaordenesutilizadas using (nroregistro,anio)
                              left join ordenesutilizadas using(nroorden,centro,tipo)
                              WHERE  nroordenpago*100+idcentroordenpago = regasiento.idoperacion and auditable
                              group by extract(year from fechauso),extract(month from fechauso)
                              having not nullvalue(extract(year from fechauso)) and not nullvalue(extract(month from fechauso))
                              order by count(*) desc
                              limit 1 ;                             

                        end if;

-- CS 2019-05-31 la fecha de imputacion en el caso de las minutas de liquidaciones de tarjeta debe venir de la fecha de imputacion de los comprobantes de gastos
                        if (regencabezado.idordenpagotipo=7) then --Liquidaciones de tarjeta
                             -- select into xfechaimputa max(fechaimputacion) fechaimputacion from reclibrofact r
                             --      join liquidaciontarjetacomprobantegasto l on (r.numeroregistro=l.nroregistro and r.anio=l.anio)
                             --     join mapeoliquidaciontarjeta m using (idliquidaciontarjeta,idcentroliquidaciontarjeta)
                             --where m.idcomprobantemultivac=regasiento.idoperacion;
                        --MaLaPi 05-06-2019 Modifico para tomar la fecha de ingreso de la minuta. cambie el proceso de cerrarliquidacion para que coloque en la fecha ingreso de la minuta el max fechaimputacion de los comprobantes de gastos.
                        --     SELECT INTO xfechaimputa fechaingreso FROM ordenpago WHERE nroordenpago= idOperacion and idcentroordenpago=cen;

                               xfechaimputa = regencabezado.fechaingreso;
                                RAISE NOTICE 'Liq. Tarjeta  (%)',xfechaimputa;
                        end if;
-- ---------------------------------------------------------------------------------------------------------------------------------------

-- CS 2019-05-14 la fecha imputacion algunas veces no puede venir de las ordenes utilizadas, por ej. ALFA BETA
                        if nullvalue(xfechaimputa) then
                           select into xfechaimputa max(fechaimputacion) from factura f join reclibrofact r on (f.nroregistro=r.numeroregistro and f.anio=r.anio) where f.nroordenpago*100+f.idcentroordenpago = regasiento.idoperacion;
                        end if;
-- -----------------------------------------------------------------------------------------------------------
                        insert into asientogenerico(idasientogenericotipo,idasientogenericocomprobtipo,agfechacontable,agdescripcion,idcomprobantesiges,agtipoasiento,idagquienmigra)
			values(1,regasiento.idasientogenericocomprobtipo,xfechaimputa,xdesc,concat(idOperacion,'|',cen),'OTP',3);
			
			xidasiento=currval('asientogenerico_idasientocontable_seq');

			OPEN curitem for 
				select *
				from ordenpago o natural join ordenpagoimputacion i
				where nroordenpago= idOperacion and idcentroordenpago=cen; --and debe>0;
			FETCH curitem INTO regitem;

                        xgastos = 0;
			xdebitos = 0;
			xdebe = 0;
                        xhaber = 0;
                        xivaD = 0;
                        xivaH = 0;
			WHILE FOUND LOOP 
			    --items DEBE
				 RAISE NOTICE 'Entre al lopp de los item ';
                            if not (regitem.nrocuentac='10386') then --IVA Credito Fiscal
                            --CS 2017-12-18 el IVA que aparece devengado no debe incluirse en el asiento
--				if (abs(regitem.debe+regitem.haber)>0) then
--                                        xdebe1 = abs(regitem.debe+regitem.haber);				
-- CS 2019-01-21 No se registraba correctamente
				                 IF (abs(regitem.debe+regitem.haber)>0) 
								     -- VAS 12042022
									  -- Siempre se insertaba H por las minutas de prestaciones medicas
                                       	
								      AND NOT ( regencabezado.idordenpagotipo = 12 AND regitem.haber>0 )
											   -- VAS 12042022 END	
								 THEN
                                        xdebe1 = abs(regitem.debe+regitem.haber);
                                        xgastos = xgastos + abs(regitem.debe+regitem.haber);
                                         
                	                   insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
					                   values(xidasiento,centro(),xdebe1,regitem.nrocuentac,xdesc,'D'  );
                                      --RAISE NOTICE '1   asientogenericoitem (%) imp= (%) ','D',  xdebe1;
									   
									   xdebe = xdebe + xdebe1;

				                  END IF;
				                  IF (regitem.haber>0) THEN
		                                 insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
					                     values(xidasiento,centro(),abs(regitem.haber),regitem.nrocuentac,xdesc,'H');
                                         
										-- RAISE NOTICE '2   asientogenericoitem (%) imp= (%) ','H', abs(regitem.haber);
										 xhaber = xhaber + abs(regitem.haber);			
					                     xdebitos = xdebitos + regitem.haber;
					-- Actualizo el tipo de asiento para que soporte Muchos a Muchos (debe y haber)
                                         update asientogenerico set idasientogenericotipo=6,agtipoasiento='AS'
                                         where idasientogenerico=xidasiento and idcentroasientogenerico=centro();
				
				                 end if;
                            else
                               -- la cuenta es la 10386
							  
                                  xivaD=regitem.debe;
                                  xivaH=regitem.haber;
                                  -- Debería generar si se trata de una minuta tipo = 4 el item del asiento   regencabezado.idordenpagotipo =4
                                  IF (regencabezado.idordenpagotipo =4)    THEN  ---  VAS 140623
								        RAISE NOTICE 'El item tiene la cuenta 10386 (%)', regitem.debe;
                                        RAISE NOTICE 'xivaD (%)', xivaD;
                                        RAISE NOTICE 'xivaH (%)', xivaH;
										insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				        values(xidasiento,centro(),regitem.debe,regitem.nrocuentac,xdesc,'D');
						                  xivaD = xivaD + regitem.debe;
										  RAISE NOTICE 'xivaD (%)', xivaD;
                                        RAISE NOTICE 'xivaH (%)', xivaH;
                                  END IF; ---  VAS 140623
--                                xhaber = xhaber + regitem.haber;
                                -- xdebitos = xdebitos + regitem.haber;
                            end if;
			    FETCH curitem INTO regitem;
			END LOOP;
			CLOSE curitem;
            --VAS 12042022
			if (regencabezado.idordenpagotipo<>12) then    
						--Gastos por Prestaciones Medicas (GASTOS) Estos son los debitos
				   IF (xdebitos>0) then
				      insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				      values(xidasiento,centro(),xdebitos,'40716',xdesc,'D');
                                      xdebe = xdebe + xdebitos;
					  -- RAISE NOTICE '3   asientogenericoitem (%) imp= (%) ','D', xdebitos;
								   
			       end if;			
			      --item HABER
			      --Deudas por Prestaciones Medicas (PASIVO)
			      IF ((regencabezado.importetotal + xdebitos - xivaD)>0) then
                                -- CS 2019-04-17 comento esto y lo reemplazo por la variable acuculadora xgastos 
                                --xhaber1 = regencabezado.importetotal + xdebitos - xivaD;                                                                             
                                xhaber1 = xgastos;                                                                             
				                insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				                values(xidasiento,centro(),xhaber1,regencabezado.nrocuentachaber,xdesc,'H');
                             --   RAISE NOTICE '4  asientogenericoitem (%) imp= (%) ','H', xhaber1;
			                    xhaber = xhaber + xhaber1;
			      END IF;
             ELSE -- el tipo es  12 = imputacion VAS 12042022
                                   
				      insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				      values(xidasiento,centro(),regencabezado.importetotal,regencabezado.nrocuentachaber,xdesc,'H');
                      xhaber = xhaber + regencabezado.importetotal;
					--  RAISE NOTICE '5  asientogenericoitem (%) imp= (%) ','H', regencabezado.importetotal;             
			       
 
             END IF;
             if (regencabezado.importetotal=0) then
                        -- CS 2018-01-11 los comprobantes fueron totalmente debitados
				--update asientogenericoitem set nrocuentac='50391'
                                --where idasientogenerico*100+idcentroasientogenerico=xidasiento*100+centro() and acid_h='H';
			end if;
			

			-- CS 2017-09-06
			-- Esto es para evitar asientos desbalanceados
			if (abs(xdebe-xhaber)>0.009) then
			RAISE NOTICE 'xdebe (%)', xdebe; 
			RAISE NOTICE 'xhaber (%)', xhaber; 
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
		--	RAISE NOTICE '6 asientogenericoitem (%) imp= (%) ',xdh, abs(xdebe-xhaber);             
			
			
			end if;
			----------------------------------------------
		
         ELSE --No encontre la orden de pago
              RAISE NOTICE 'No encontre la orden de pago -  (%)',regasiento.idoperacion;
         end if;	

-- RAISE NOTICE '7  el idasiento: (%) ' , xidasiento;
	FETCH curasiento INTO regasiento;
END LOOP;
CLOSE curasiento;
RETURN xidasiento;
END;
$function$
