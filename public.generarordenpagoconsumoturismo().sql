CREATE OR REPLACE FUNCTION public.generarordenpagoconsumoturismo()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	consumoturismoOP refcursor;
	rordenpago record;
	unconsumot RECORD;
	 
	resultado boolean;
	imptotalconsumo double precision;
	importeabonado double precision;
	elidprestador bigint;
	unidconsumoturismo  bigint;
	unidcentroconsumoturismo bigint;
	resp2 bigint;
	cuentaprestador character varying;
BEGIN

/*Llamo para que se inserte la Orden de Pago*/
ALTER TABLE tempordenpago ADD COLUMN idordenpagotipo integer DEFAULT 6;

SELECT INTO resultado * FROM generarordenpago();

/* Actualizo el motivo del cambio de estado generado por defecto*/
SELECT INTO rordenpago * FROM tempordenpago;

/* VAS 02/03/2018 dejo la minuta lista para ingresar el pago desde tesoreria*/
perform cambiarestadoordenpago(rordenpago.nroordenpago,centro(),2,'Estado generado desde generarordenpagoconsumoturismo');

if resultado THEN
   
   
   /*Modifico el estado de los consumos y su vinculacion a la Orden de pago*/
   OPEN consumoturismoOP FOR SELECT * FROM tempconsumoordenpago;
   FETCH consumoturismoOP INTO unconsumot;
   WHILE  found LOOP
          --vinculo el consumo a la orden de pago
       INSERT INTO consumoturismoordenpago (idconsumoturismo,idcentroconsumoturismo,nroordenpago,idcentroordenpago,ctopimportepagado)
           VALUES(unconsumot.idconsumoturismo, unconsumot.idcentroconsumoturismo, unconsumot.nroordenpago,centro(),unconsumot.ctopimportepagado) ;
      -- Si se cancela la deuda del consumo turismo este debe cambiar a estado pagado
      -- 1 - Recuperar el importe total adeudado
      -- 2 - Recuperar el importe total pagado
      -- 3 - Comparar SI adeudado= pagado => cambiar de estado al consumo turismo 5-PAGADO

      --- 1 ---
      SELECT INTO imptotalconsumo (imptotaldelconsumo - ctdescuento)
      FROM (
           SELECT SUM(tuvimportesosunc*ctvcantdias) as imptotaldelconsumo
           FROM consumoturismovalores
           NATURAL JOIN turismounidadvalor
           NATURAL JOIN turismounidad
           NATURAL JOIN turismoadmin
           WHERE   idconsumoturismo = unconsumot.idconsumoturismo and idcentroconsumoturismo=unconsumot.idcentroconsumoturismo
           GROUP BY idconsumoturismo ,idcentroconsumoturismo
       ) as T
       NATURAL JOIN consumoturismo
       WHERE idconsumoturismo =  unconsumot.idconsumoturismo and idcentroconsumoturismo=unconsumot.idcentroconsumoturismo;

      --- 2 ---
      SELECT INTO importeabonado SUM (ctopimportepagado)
            FROM consumoturismoordenpago
            WHERE idconsumoturismo =unconsumot.idconsumoturismo
                 and idcentroconsumoturismo=unconsumot.idcentroconsumoturismo
            group by idconsumoturismo ,idcentroconsumoturismo;
      --- 3 ---
            IF (importeabonado >=imptotalconsumo ) THEN
                    UPDATE consumoturismoestado
                           SET ctefechafin =now()
                           WHERE nullvalue(ctefechafin)  and  idconsumoturismo =unconsumot.idconsumoturismo and idcentroconsumoturismo=unconsumot.idcentroconsumoturismo;
                     INSERT INTO consumoturismoestado (idconsumoturismo,idcentroconsumoturismo,idconsumoturismoestadotipos)
                            VALUES (unconsumot.idconsumoturismo,unconsumot.idcentroconsumoturismo,5 ) ;
            END IF;
            unidconsumoturismo = unconsumot.idconsumoturismo; -- vas 01-09-2017
            unidcentroconsumoturismo = unconsumot.idcentroconsumoturismo ; -- vas 01-09-2017
            
            FETCH consumoturismoOP INTO unconsumot;
   END LOOP;
   CLOSE consumoturismoOP;
   
   -- vas 01-09-2017 Busco el idPrestador del consumo turismo y Guardo el vinculo entre la minuta y el prestador de la minuta
   SELECT into elidprestador idprestador
           FROM consumoturismovalores
           NATURAL JOIN turismounidadvalor
           NATURAL JOIN turismounidad
           NATURAL JOIN turismoadmin
           WHERE idconsumoturismo = unidconsumoturismo and idcentroconsumoturismo = unidcentroconsumoturismo ;
   INSERT INTO ordenpagoprestador(nroordenpago,idcentroordenpago,idprestador)VALUES( rordenpago.nroordenpago, centro(),elidprestador);
   --- vas 01-09-2017
   ----------------------------------------------------------------------------
   /** Cambio VAS 13-03-2018 la cuenta del haber es la cuenta definida al prestador */
   /* comenta vas 03/05/2023 tk=5771  SELECT INTO cuentaprestador nrocuentac FROM prestador WHERE idprestador = elidprestador;
   UPDATE ordenpagoimputacion SET nrocuentac = cuentaprestador
   WHERE (nrocuentac = 40450 or nrocuentac = 50398) and nroordenpago = rordenpago.nroordenpago and idcentroordenpago = centro() ;
   */
   --- la cuenta debe ser 20301
   UPDATE ordenpagoimputacion SET nrocuentac = 20301
   WHERE (nrocuentac = 40450 or nrocuentac = 50398) 
          and nroordenpago = rordenpago.nroordenpago 
          and idcentroordenpago = centro() ;
   
   
   -----------------------------------------------------------------
  
   
   -- genero los asientos genericos
   IF (not iftableexistsparasp('tasientogenerico') ) THEN

      CREATE TEMP TABLE tasientogenerico (
	        idoperacion bigint,
	        idcentroperacion integer DEFAULT centro(),
	        operacion varchar,
	        fechaimputa date,
		    obs varchar,
		centrocosto int,
                idasientogenericocomprobtipo integer DEFAULT 4
      )WITHOUT OIDS;
     END IF;
           INSERT INTO tasientogenerico(idoperacion,operacion,fechaimputa,obs,centrocosto)
            VALUES(	rordenpago.nroordenpago*100+centro(),'otp',now(), concat('MP - Turismo :',rordenpago.nroordenpago ,'-',centro()), centro());

     SELECT INTO resp2 public.asientogenerico_crear();
   -----------------------------------------------------------------------------------
   
   resultado = 'true';
END IF;
RETURN resultado;
END;
$function$
