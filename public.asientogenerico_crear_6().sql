CREATE OR REPLACE FUNCTION public.asientogenerico_crear_6()
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
         elidcentrocosto integer;
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
	borrar boolean;
-- Este SP se usa para generar los asientosgenericos de ASIENTOS MANUALES
   
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

			IF  nullvalue(regasiento.idasientogenerico) AND nullvalue(regasiento.idcentroasientogenerico) 	 THEN 

				INSERT INTO asientogenerico(idasientogenericotipo,idasientogenericocomprobtipo,agfechacontable,agdescripcion,idcomprobantesiges,agtipoasiento,idagquienmigra)
				VALUES(6,regasiento.idasientogenericocomprobtipo,regasiento.fechaimputa,regasiento.agdescripcion,regasiento.idcomprobantesiges,'AS',4);
				
				xidasiento=currval('asientogenerico_idasientocontable_seq');
			ELSE
				UPDATE asientogenerico 
					SET 
						agdescripcion=regasiento.agdescripcion
						,agfechacontable=regasiento.fechaimputa 
				WHERE 
					idasientogenerico=regasiento.idasientogenerico 
					AND idcentroasientogenerico=regasiento.idcentroasientogenerico;

				xidasiento=regasiento.idasientogenerico;

			END IF;


			IF  NOT (nullvalue(regasiento.idasientogenerico) AND nullvalue(regasiento.idcentroasientogenerico)) THEN 

					DELETE FROM asientogenericoitem WHERE idasientogenerico=xidasiento AND idcentroasientogenerico=regasiento.idcentroasientogenerico;

			END IF;
		                    
			
			OPEN curitem for SELECT * FROM tasientogenericoitem;
			FETCH curitem INTO regitem;
					--xdifasiento = regencabezado.importetotal;
					WHILE FOUND LOOP 
							--xdifasiento = xdifasiento - (regitem.debe-regitem.haber);

							
                            RAISE NOTICE 'entro al bucle' ;
		

                            IF (regitem.acimonto>0) THEN
                                elidcentrocosto = 1;
                                IF  existecolumtemp('tasientogenericoitem', 'idcentrocosto') THEN 
                                      	elidcentrocosto  = regitem.idcentrocosto;
                                END IF; 
                                ---  RAISE NOTICE 'el id centrocosto(%) ',elidcentrocosto  ;

                               

								INSERT INTO asientogenericoitem(idasientogenerico,idcentroasientogenerico,acimonto,nrocuentac,acidescripcion,acid_h,acicentrocosto)
								VALUES(xidasiento,centro(),regitem.acimonto,regitem.nrocuentac,regitem.acidescripcion,regitem.acid_h,elidcentrocosto );	
								

							END IF;
						FETCH curitem INTO regitem;
					END LOOP;
			CLOSE curitem;	

		FETCH curasiento INTO regasiento;
	END LOOP;
CLOSE curasiento;

RETURN xidasiento;

END;

$function$
