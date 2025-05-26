CREATE OR REPLACE FUNCTION public.ctactepagonoafilgeneraminuta()
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
BEGIN

     SELECT INTO unaordenpago * FROM tempordenpago;
     IF nullvalue(unaordenpago.nroordenpago) THEN
        SELECT INTO laorden nextval('ordenpago_seq')  ;
        UPDATE tempordenpagoimputacion SET nroordenpago = laorden;
        UPDATE tempordenpago SET nroordenpago = laorden;
     ELSE 
           laorden = unaordenpago.nroordenpago;
     END IF;
     
     --- genero la minuta de pago
    SELECT INTO resultado  public.generarordenpago();
    
 
     -- dejo la OP lista para pagar      2 	Liquidable
     
       SELECT INTO  resultado public.cambiarestadoordenpago(laorden,centro(),2,'Generado automaticamente ctactepagonoafilgeneraminuta ');
     
     -- busco info de la cta cte

     SELECT INTO elprestador * FROM public.prestadorctacte WHERE idprestador =unaordenpago.idprestador;
     
    -- Guardo el vinculo entre la minuta y el prestador
    INSERT INTO public.ordenpagoprestador (nroordenpago,idcentroordenpago,idprestador) VALUES(laorden,centro(),unaordenpago.idprestador);

    -- se registra el movimiento como una deuda en la cuenta corriente del prestador
    IF (unaordenpago.importetotal >0) THEN

              INSERT INTO public.ctactedeudaprestador(idcomprobantetipos, idprestadorctacte,
                      movconcepto,nrocuentac,importe, idcomprobante, saldo)
               VALUES(40,elprestador.idprestadorctacte,concat(unaordenpago.beneficiario,'MP:',laorden,'-',centro())
                   ,unaordenpago.nrocuentachaber
                   ,unaordenpago.importetotal, (laorden*10)+centro(),unaordenpago.importetotal);
       END IF;

   -----------------------------------------------------------------
   -- NO SE GENERA ASIENTOS YA QUE SE GENERARON CON LA LIQ DE SUELDOS 
   -- CS 2017-04-26 Agrega Asiento Generico

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
   VALUES(	laorden*100+centro(),'otp',unaordenpago.mpfechacontable , concat('MP:',laorden ,'-',centro()), centro());
     
   SELECT INTO resp2 public.asientogenerico_crear();
-----------------------------------------------------------------------------------
   DELETE FROM tasientogenerico; -- Agrega VAS 07/06/2018 ya que se estaban generando asientos duplicados


   RETURN concat(laorden ,'-',centro());
END;
$function$
