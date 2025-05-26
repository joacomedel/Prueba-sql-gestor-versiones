CREATE OR REPLACE FUNCTION public.generarotrospagos()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* Este SP recibe una temporal con cuentas debe/ haber y sus respectivos importes
 * 1- genera la minuta de pago correspondiente y la deja lista para que se realice el pago en tesoreria
*/

DECLARE

	elprestador RECORD;
	unaordenpago RECORD;
	laorden bigint;
	resultado boolean;
resp2  bigint;
    resp boolean;
    laOPC varchar;
    elidopc bigint;
    elidcentroopc integer;
    elidvalorescaja integer;
    fechaop date;
BEGIN

     SELECT INTO unaordenpago * FROM tempordenpago;
     IF nullvalue(unaordenpago.nroordenpago) THEN
        SELECT INTO laorden nextval('ordenpago_seq')  ;
        UPDATE tempordenpagoimputacion SET nroordenpago = laorden;
        UPDATE tempordenpago SET nroordenpago = laorden;
        fechaop = unaordenpago.fechaingreso;

     END IF;

     --- genero la minuta de pago
    SELECT INTO resultado  generarordenpago();

    -- dejamos lista la minuta para ser pagada
    UPDATE cambioestadoordenpago SET ceopfechafin = CURRENT_DATE WHERE nroordenpago= laorden and idcentroordenpago =centro() ;
    INSERT INTO cambioestadoordenpago (fechacambio,nroordenpago,idcentroordenpago,idtipoestadoordenpago,motivo, idusuario)
            VALUES(CURRENT_DATE,laorden,centro(),3,'desde generarotrospagos',25);
            
    -- creo la temporal que se requiere para generar la opc
    CREATE TEMP TABLE tempcomprobante (  idcomprobante bigint,  idcomprobantetipos integer,  nrocomp varchar ,
               idcentrocomp INTEGER , montopagar double precision , montoretencion double precision,
               apagarcomprobante double precision, tipocomp varchar, observacion varchar, iddeuda bigint, idcentrodeuda integer,
               idpago bigint, idcentropago integer, idprestador bigint, fechaoperacion date  );
    INSERT INTO tempcomprobante(idcomprobante,idcomprobantetipos,nrocomp, idcentrocomp ,montopagar,montoretencion,apagarcomprobante,tipocomp,iddeuda,idcentrodeuda,idpago,idcentropago,idprestador,fechaoperacion)
           VALUES( NULL,NULL,laorden,centro(),unaordenpago.importetotal,'0',NULL,'OP',NULL,NULL,NULL,NULL,NULL,fechaop);
  	SELECT INTO laOPC  generarordenpagocontable();
    elidopc = split_part(laOPC, '|', 1)::bigint;
    elidcentroopc = split_part(laOPC, '|', 2)::INTEGER;
	SELECT INTO resp  cambiarestadoordenpagocontable(elidopc,elidcentroopc, 5, 'Desde generarotrospagos') ;

    -- Ingresa informacion del pago que va a depender de la cuenta del haber seleccionada al realizar los otros pagos
    SELECT INTO elidvalorescaja idvalorescaja
    FROM ordenpagocontablevalorescaja
    NATURAL JOIN multivac.mapeocuentasfondos
    NATURAL JOIN cuentascontables
    NATURAL JOIN  (SELECT nrocuentachaber as nrocuentac FROM ordenpago WHERE nroordenpago = laorden and idcentroordenpago = centro() )as t;
    
    INSERT INTO pagoordenpagocontable
            (idordenpagocontable, idcentroordenpagocontable, popmonto, popobservacion,idvalorescaja)
    VALUES(elidopc,elidcentroopc,unaordenpago.importetotal, concat(' O/P MP:',laorden,'-',centro()),elidvalorescaja );

    
    
    --  Se actualiza el tipo de la ordenpagocontable =2 Otros Pagos
    UPDATE ordenpagocontable SET idordenpagocontabletipo = 2 WHERE idordenpagocontable =elidopc AND idcentroordenpagocontable=elidcentroopc;
   
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
            VALUES(	laorden*100+centro(),'otp',unaordenpago.fechaingreso, concat('O/POP:',elidopc ,'-',elidcentroopc), centro());
    
     SELECT INTO resp2 asientogenerico_crear();
    

     
     RETURN concat(laorden ,'-',centro());
END;
$function$
