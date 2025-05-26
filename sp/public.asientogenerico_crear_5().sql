CREATE OR REPLACE FUNCTION public.asientogenerico_crear_5()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$-- Este SP se usa para generar los asientosgenericos de Facturas de Venta
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
        xobs varchar;
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
	rasientogenerado RECORD;
	rasientogenerico RECORD;
existe_asiento_comprobante boolean;
resp boolean;
   
BEGIN

/*
Esta es la temporal con los datos de ingreso
CREATE TEMP TABLE tasientogenerico	(
            idoperacion varchar,
            idasientogenericocomprobtipo int DEFAULT 5,				
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

           IF char_length(split_part(regasiento.idoperacion, '|', 4)) >= 1 THEN --MaLaPi 15-06-2018 Verifico puesto que al ingresar un reintegro el trigger se dispara 2 veces no se por que....
		
		xtipofactura = split_part(regasiento.idoperacion, '|', 1);
		xtipocomprobante = trim(split_part(regasiento.idoperacion, '|', 2))::integer;
		xnrosucursal = split_part(regasiento.idoperacion, '|', 3)::integer;
		xnrofactura = split_part(regasiento.idoperacion, '|', 4)::bigint;
                xobs = CASE WHEN nullvalue(regasiento.obs) THEN '' ELSE concat(regasiento.obs,' ') END;
		--MaLaPi 27-02-2019 Verifico que no se trate de una factura GENERADA como anulada, si es este caso, no debe generar contabilidad
		SELECT INTO regencabezado * 
		from facturaventa f 
		NATURAL JOIN itemfacturaventa
		where tipofactura=xtipofactura and tipocomprobante=xtipocomprobante and nrosucursal=xnrosucursal and nrofactura=xnrofactura
		LIMIT 1;
		IF FOUND AND regencabezado.idconcepto = '40718' THEN 
			RAISE NOTICE 'La Factura se genero como anulada, no corresponde el asiento (%)',regencabezado.nrofactura;
		ELSE 
		--MaLaPi 27-02-2019 Primero verifico que no exista un asiento para el mismo comprobante que no este reveritido.
			SELECT INTO rasientogenerico * FROM asientogenerico 
						WHERE idasientogenericotipo = 6 
						AND idasientogenericocomprobtipo = 5 
						AND idcomprobantesiges = regasiento.idoperacion
						AND nullvalue(idasientogenericorevertido) -- No es un asiento que se encuentra revertido
                                                AND agdescripcion not like '%REVERSION%' ;-- no es un asiento de reversion ;
			IF FOUND THEN 
				--Puede tratarse de la necesitdad de anular una factura, em realidad hay que revertir el asiento. 
                         IF not nullvalue(regencabezado.anulada) AND rasientogenerico.agdescripcion NOT ILIKE 'REVERSION%' THEN
                             --Si esta anulada, y el asiento que encuentro es una reversion, no hay nada para hacer
                             -- Tengo que llamar a revertir el asiento, pues la factura esta anulada.
                             perform asientogenerico_revertir(rasientogenerico.idasientogenerico*100+rasientogenerico.idcentroasientogenerico);
                            	RAISE NOTICE 'La Factura esta anulada y se revirtio';
			             END IF;
                           /*  Deberia entrar en el if siguiente
                         IF nullvalue(regencabezado.anulada) AND rasientogenerico.agdescripcion ILIKE 'REVERSION%' THEN
                                      --Si encuentro, un asiento revertido, y la factura no esta anulada, tengo que generar el asiento
                                      -- Resulta que el asiento que existe es una reversión, por lo que hay que generar el original
                                      SELECT INTO xidasiento * FROM asientogenerico_crear_5_emision();
                         END IF;*/
                         IF existecolumtemp('tasientogenerico', 'modificacomprobante') and nullvalue(regencabezado.anulada) THEN
                                         -- Si estoy modificando el comprobante puede ser que requiera generar el asiento con el actual para ver si hay o no            diferencia
                                      

   SELECT INTO xidasiento * FROM asientogenerico_crear_5_emision();

  RAISE NOTICE 'lo que tiene xidasiento antes de es igual  (%)',xidasiento ;
                                
                                         SELECT INTO existe_asiento_comprobante * FROM  asientogenerico_esigual(rasientogenerico.idcomprobantesiges,rasientogenerico.idasientogenericocomprobtipo,xidasiento,centro());

  RAISE NOTICE 'lo que tiene xidasiento despues de es igual  (%)',xidasiento ;
                                
                                        RAISE NOTICE 'existe_asiento_comprobante (%)',existe_asiento_comprobante ;
                                         IF  existe_asiento_comprobante THEN
                                 RAISE NOTICE 'estoy llamando adentro del if del eliminar  existe_asiento_comprobante (%)(%)',xidasiento,centro() ;
                            
                                                    SELECT INTO resp contabilidad_eliminarasiento(xidasiento,centro());
                                                    xidasiento = null;
                                         ELSE
                                                    perform asientogenerico_revertir(rasientogenerico.idasientogenerico*100+rasientogenerico.idcentroasientogenerico);
                                         END IF;
                         END IF;

				
			ELSE 
				--Se va a generar el asiento de la emisiond de una factura
				SELECT INTO xidasiento * FROM asientogenerico_crear_5_emision();
			END IF;
		END IF;
	END IF;

	FETCH curasiento INTO regasiento;
      
END LOOP;
CLOSE curasiento;
RETURN xidasiento;
END;
$function$
