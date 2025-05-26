CREATE OR REPLACE FUNCTION public.asientogenerico_crear_1()
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
    -- Este SP se usa para generar los asientosgenericos de ORDENES DE PAGO CONTABLE
   
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

		idOperacion = regasiento.idoperacion::integer/100;
        cen = regasiento.idoperacion::integer%100;
 

		
		SELECT INTO regencabezado  case when nullvalue(op.nrocuentachaber) or length(op.nrocuentachaber)=0  then p.nrocuentac else op.nrocuentachaber end  as nrocuentachaber,opcobservacion,opcfechaingreso,opcmontototal
        FROM ordenpagocontable opc
		LEFT JOIN prestador p ON  (opc.idprestador=p.idprestador)	       			
		LEFT JOIN  (SELECT idordenpagocontable,idcentroordenpagocontable,nroordenpago,idcentroordenpago,case when nullvalue(o.nrocuentachaber) then ot.nrocuentachaber else o.nrocuentachaber end as nrocuentachaber
                    FROM ordenpago o
                    LEFT JOIN ordenpagotipo ot using(idordenpagotipo)
                    NATURAL JOIN ordenpagocontableordenpago
		) op USING (idordenpagocontable,idcentroordenpagocontable)
        WHERE idordenpagocontable= idOperacion and idcentroordenpagocontable=cen;

		IF FOUND THEN
			xdesc = concat(regasiento.obs,' | ',regencabezado.opcobservacion);
			xquien = 3;	
            
            OPEN curformapago for  SELECT COUNT(*),idvalorescaja
                                   FROM pagoordenpagocontable
                                   NATURAL JOIN valorescaja
                                   WHERE idordenpagocontable*100+idcentroordenpagocontable=regasiento.idoperacion
                                   GROUP BY idvalorescaja;
           FETCH curformapago INTO regformapago;
		   WHILE FOUND LOOP
                       if regformapago.idvalorescaja=2 then -- efectivo
                               xquien=2;
                       end if;
                       FETCH curformapago INTO regformapago;
          END LOOP;
          CLOSE curformapago;

          insert into asientogenerico(idasientogenericotipo,idasientogenericocomprobtipo,agfechacontable,agdescripcion,idcomprobantesiges,agtipoasiento,idagquienmigra)
           values(2,regasiento.idasientogenericocomprobtipo,regencabezado.opcfechaingreso,xdesc,concat(idOperacion,'|',cen),'OTI',xquien);
			
   		  xidasiento=currval('asientogenerico_idasientocontable_seq');

 		  xnrocuentac = regencabezado.nrocuentachaber;
			--if (regencabezado.idprestador=2608) then --Es Sosunc, en el caso de Reintegros pagados
			--	xnrocuentac = '60120';
			--	xdesc = concat('Pago Reintegro: ',xdesc);
			--end if;

          xdebe = 0;
          xhaber = 0;
          xmontototal = regencabezado.opcmontototal;
			--item PROVEEDOR
		  if (xmontototal>0) then			
		        -- VAS 30/03 verifico si es una OPC vinculada a comprobantes de reclibrofact 
				OPEN curitem for SELECT nrocuentacproveedor as nrocuentac ,SUM(montopagado) as importe
								  FROM ordenpagocontable opc    
								  LEFT JOIN ordenpagocontablereclibrofact  USING (idordenpagocontable,idcentroordenpagocontable)
								  LEFT JOIN ordenpagocontableordenpago    USING(idordenpagocontable,idcentroordenpagocontable)
                                                                  LEFT JOIN reclibrofact  as r USING(numeroregistro,anio)
								  JOIN multivac.mapeocatgasto m on(r.catgasto=m.idcategoriagastosiges)
								  WHERE idordenpagocontable= idOperacion AND idcentroordenpagocontable=cen
                                                                         AND nullvalue(nroordenpago) 
								  GROUP BY nrocuentacproveedor; 
				FETCH curitem INTO regitem;
				WHILE FOUND LOOP 
				     INSERT INTO asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				      VALUES(xidasiento,centro(),regitem.importe,regitem.nrocuentac,xdesc,'D');  
				      xdebe = xdebe + regitem.importe;
			    FETCH curitem INTO regitem;
				END LOOP;
				CLOSE curitem;
				if(xdebe =0) THEN ---  VAS 30/03 no es una opc con comprobantes de reclibrofact
				      INSERT INTO asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
				      VALUES(xidasiento,centro(),xmontototal,xnrocuentac,xdesc,'D');
                      xdebe = xdebe + xmontototal;
			    END IF;
		   END IF;
			
		   OPEN curitem for	select * 
				            FROM pagoordenpagocontable 
                            NATURAL JOIN ordenpagocontablevalorescaja  -- VAS 240822 en esta tabla se almacena el mapeo a las cuentas de fondo de los valores caja vinculados a las ordenes de pago contables
                            NATURAL JOIN multivac.mapeocuentasfondos
				            WHERE idordenpagocontable= idOperacion 
                                      AND idcentroordenpagocontable=cen 
                                      AND idcentroordenpagocontablevalorescaja=cen;
			
            xdifasiento = xmontototal;
            FETCH curitem INTO regitem;
		
			WHILE FOUND LOOP 
				--ITEMS PAGO	
				xdifasiento = xdifasiento - regitem.popmonto;
				if (regitem.popmonto>0) then
					              if regitem.idvalorescaja=47 then  --- cheque
					                  -- Analizo si es un cheque de tercero
                                                         SELECT INTO rcheque
                                                         FROM chequetercero
                                                         WHERE idcheque = regitem.idcheque AND idcentrocheque =regitem.idcentrocheque ; -- Es un cheque a tercero
                                                         IF FOUND THEN  regitem.nrocuentac = 10227; --- valores a depositar                                        
                                                       
                                                         END IF;
                                                      --ELSE 
                                                          --- Analizo si es un cheque propio
                                                          SELECT INTO rinfocheque * 
                                                          FROM cheque
                                                          NATURAL JOIN chequera
                                                          WHERE idcheque = regitem.idcheque AND idcentrocheque =regitem.idcentrocheque;
                                                          IF FOUND THEN  regitem.nrocuentac = rinfocheque.chnrocuentac;  END IF; 
                                                      END IF;
                                  insert into asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h)
					              values(xidasiento,centro(),regitem.popmonto,regitem.nrocuentac,xdesc,'H');			
                                  xhaber = xhaber + regitem.popmonto;
				end if;
				FETCH curitem INTO regitem;
			END LOOP;
			CLOSE curitem;
			-- CS 2017-09-06
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
			----------------------------------------------
		end if;
                
-- CS 2018-03-07
-- El cambio de estado se hace solamente si el estado actual es menor a Contabilizada (5)
-- Esto es para evitar que en las regeneraciones de asientos se vuelva el estado hacia atrás, por ej. en casos de OPC ya Asentadas
                select into restado * from ordenpagocontableestado
                where nullvalue(opcfechafin) and idordenpagocontable= idOperacion and idcentroordenpagocontable=cen and idordenpagocontableestadotipo<5;
                if found then
		   perform cambiarestadoordenpagocontable(idOperacion, cen, 5, concat('Al generar asientogenerico ',xidasiento,'|',centro()));	
                end if;
-----------------------------------------------------------------------------------

	FETCH curasiento INTO regasiento;
END LOOP;
CLOSE curasiento;
RETURN xidasiento;
END;
$function$
