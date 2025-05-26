CREATE OR REPLACE FUNCTION public.generarordenpagogenerica()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/*Genera una orden para pagar un conjunto de prestaciones.*/

DECLARE

	elprestador RECORD;
	unaordenpago RECORD;
	laorden bigint;
	resp2 bigint;
	resultado boolean;
        imptotal DOUBLE PRECISION;
        xidorigen varchar;
        rcomprobante_fac record;
rcomprobante record; 
        cursor_comp refcursor;
        r_comp record;

BEGIN

     SELECT INTO unaordenpago * FROM tempordenpago JOIN ordenpagotipo  USING(idordenpagotipo) ;
     IF nullvalue(unaordenpago.nroordenpago) THEN
        SELECT INTO laorden nextval('ordenpago_seq')  ;
        UPDATE tempordenpagoimputacion SET nroordenpago = laorden;
        UPDATE tempordenpago SET nroordenpago = laorden;
     ELSE
           laorden = unaordenpago.nroordenpago;
     END IF;

     --- genero la minuta de pago
    SELECT INTO resultado  public.generarordenpago();

    -- Si el idprestador es <> null guardo la relacion entre la minuta y el idprestador
      IF (existecolumtemp('tempordenpago', 'idprestador') AND unaordenpago.idprestador<>0) THEN
             INSERT INTO ordenpagoprestador( nroordenpago, idcentroordenpago,	idprestador )
             VALUES (laorden ,centro(),unaordenpago.idprestador) ;
      END IF;

       IF (iftableexists('temp_comprobante')) THEN  -- Si hay comprobantes de compra a vincular a la minuta Actualizo
                OPEN cursor_comp  FOR SELECT * FROM  temp_comprobante;
                FETCH cursor_comp INTO r_comp;
                WHILE FOUND LOOP
                         SELECT INTO rcomprobante * FROM  temp_comprobante;
                         -- Verifico si es un comprobante de factura o SOLO de reclibrofact
                         SELECT INTO rcomprobante_fac * 
                         FROM  reclibrofact r
                         JOIN temp_comprobante USING( idrecepcion, idcentroregional)
                         JOIN factura f ON (r.numeroregistro = f.nroregistro  and r.anio = f.anio)
                         WHERE idrecepcion = r_comp.idrecepcion and idcentroregional = r_comp.idcentroregional;
                         IF FOUND THEN 
                               UPDATE factura 
                               SET nroordenpago = laorden  , idcentroordenpago = centro()
                               WHERE nroregistro = rcomprobante_fac.nroregistro  and anio = rcomprobante_fac.anio;
                         ELSE -- es un comprobante de reclibrofact
                                 INSERT INTO reclibrofactordenpago( idrecepcion, idcentroregional,nroordenpago,idcentroordenpago 	 )
                                 VALUES (r_comp.idrecepcion,r_comp.idcentroregional,laorden ,centro()) ;
                         END IF;
               FETCH cursor_comp INTO r_comp;
               END LOOP;
      END IF;



     -- dejo la OP lista para pagar      2 	Liquidable

       SELECT INTO  resultado public.cambiarestadoordenpago(laorden,centro(),2,'Generado automaticamente generarordenpagogenerica ');

      -- Si la minuta no requiere opc debe quedar en el estado siguiente
      IF existecolumtemp('tempordenpago', 'requiereopc') THEN
         IF NOT(unaordenpago.requiereopc) THEN 
          SELECT INTO  resultado public.cambiarestadoordenpago(laorden,centro(),3,'Generado automaticamente generarordenpagogenerica ');
         END IF;
      END IF;
  
-----------------------------------------------------------------
-- CS 2017-04-26 Agrega Asiento Generico
-- genero los asientos genericos

-- CS 2018-07-30 Queda Deshabilitago, porque el asiento generico se crea con un Trigger en la tabla ordenpago
   IF (unaordenpago.optgeneracontabilidad) THEN
          IF (not iftableexistsparasp('tasientogenerico')) THEN

                CREATE TEMP TABLE tasientogenerico (
	                  idoperacion varchar,
	                  idcentroperacion integer DEFAULT centro(),
	                  operacion varchar,
	                  fechaimputa date,
		          obs varchar,
		          centrocosto int,
                          idasientogenericocomprobtipo integer DEFAULT 4,
                          idasientogenerico bigint,
                          idcentroasientogenerico integer,
                          idmultivac varchar
                )WITHOUT OIDS;
          
          
          END IF;
          INSERT INTO tasientogenerico(idoperacion,operacion,fechaimputa,obs,centrocosto)
          VALUES(	laorden*100+centro(),'otp',unaordenpago.fechaingreso, concat('Orden Pago Generica:',laorden ,'-',centro()), centro());

          SELECT INTO resp2 public.asientogenerico_crear();
   END IF;

     RETURN concat(laorden ,'-',centro());
END;
$function$
