CREATE OR REPLACE FUNCTION public.conciliacionbancaria_generaropc(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/*Genera una orden de pago contable correspondiente al comprobante de gasto generado */

DECLARE

	regfactcompgasto RECORD;
        rfiltros RECORD;
        rconc RECORD;
        elnroregistro integer;
        elanio integer;
	laopc varchar;
	resp varchar;
        resp2 boolean;
        datoaux record;

BEGIN
       ---- 1 - Generar la Orden Pago contable
       EXECUTE sys_dar_filtros($1) INTO rfiltros;
       elnroregistro = rfiltros.elnroregistro;
       elanio =rfiltros.elanio;
/*Dani comento el 07092021 porq estos comprobantes no se insertan en factura*/
       /*SELECT INTO regfactcompgasto *
       FROM factura as f
       JOIN reclibrofact as r ON(r.numeroregistro=f.nroregistro  and r.anio=f.anio)
       WHERE f.nroregistro = elnroregistro and f.anio = elanio;
        */
SELECT INTO regfactcompgasto *
       FROM   reclibrofact as r 
       WHERE  numeroregistro = elnroregistro and  anio = elanio;
      
       IF (iftableexists('tempcomprobante')) THEN DROP TABLE tempcomprobante;  END IF;
       CREATE TEMP TABLE tempcomprobante (  idcomprobante bigint,  idcomprobantetipos integer,  nrocomp varchar ,  idcentrocomp INTEGER , montopagar double precision , montoretencion double precision, apagarcomprobante double precision, tipocomp varchar, observacion varchar, iddeuda bigint, idcentrodeuda integer, idpago bigint, idcentropago integer, idprestador bigint , fechaoperacion date);

       INSERT INTO tempcomprobante(idcomprobante,idcomprobantetipos,nrocomp,idcentrocomp ,montopagar,montoretencion,apagarcomprobante,tipocomp,iddeuda,idcentrodeuda,idpago,idcentropago,idprestador,fechaoperacion )
       VALUES(  concat(elnroregistro::varchar,elanio::varchar)::bigint,49,concat(elnroregistro::varchar,'-',elanio::varchar),regfactcompgasto.idcentroregional,regfactcompgasto.monto,'0',regfactcompgasto.monto,'FAC',NULL,NULL,NULL,NULL,regfactcompgasto.idprestador,regfactcompgasto.fechaemision);

       SELECT INTO laopc    generarordenpagocontable() ;

       ---- 2 - Informacion del pago  de la OPC
       IF (iftableexists('tempordenpagocontable')) THEN DROP TABLE tempordenpagocontable;  END IF;
       CREATE TEMP TABLE tempordenpagocontable(  claveordenpagocontable VARCHAR ,  opcobservacion VARCHAR ,  idordenpagocontable BIGINT,  idcentroordenpagocontable INTEGER ,  opcmontototal  double precision  ,  opcmontoretencion  double precision  ,  opcmontocontadootra  double precision  ,  opcmontochequeprop  double precision  ,  idprestador  bigint  ,  opcfechaingreso date ,  opcmontochequetercero  double precision   );

       INSERT INTO tempordenpagocontable (idprestador , claveordenpagocontable,opcmontototal ,opcmontoretencion  , opcmontocontadootra , opcmontochequeprop , opcmontochequetercero ,opcobservacion,opcfechaingreso)
       VALUES( regfactcompgasto.idprestador,replace(laopc, '|', '-'),regfactcompgasto.monto,0,regfactcompgasto.monto,0,0,concat('Pago de Comp. Gasto Registro Num:',$1),regfactcompgasto.fechaemision);

       IF (iftableexists('temppagoordenpagocontable')) THEN DROP TABLE temppagoordenpagocontable;  END IF;
       CREATE TEMP TABLE temppagoordenpagocontable(   idvalorescaja INTEGER ,  monto  double precision  ,  observacion VARCHAR ,  tipo VARCHAR,  idcuentabancaria INTEGER,  idchequera BIGINT ,  fechacobro VARCHAR ,  fechaemision VARCHAR ,  idcheque BIGINT ,  idcentrocheque INTEGER );
       
       IF (iftableexists('tretencionprestador')) THEN DROP TABLE tretencionprestador;  END IF;
       CREATE TEMP TABLE tretencionprestador ( 			idtiporetencion BIGINT,			idprestador BIGINT,			rpmontofijo DOUBLE PRECISION,			rpmontoporc DOUBLE PRECISION,			rpmontototal DOUBLE PRECISION,			idretencionprestador SERIAL,			rpmontobase DOUBLE PRECISION,			rpmontoretanteriores DOUBLE PRECISION);

       SELECT INTO rconc * 
       FROM conciliacionbancaria 
       JOIN cuentabancariasosunc using(idcuentabancaria)
       WHERE idconciliacionbancaria = rfiltros.idconciliacionbancaria 
                AND idcentroconciliacionbancaria = rfiltros.idcentroconciliacionbancaria ;


       INSERT INTO temppagoordenpagocontable (idvalorescaja, monto , observacion,tipo) VALUES (rconc.idvalorescajacuentab, regfactcompgasto.monto, 'Contado / Otras Credicoop (Nqn) 24917/1', 'CT/TRANS');
select into datoaux * from tempordenpagocontable;
RAISE NOTICE '>>>>>>>>Llamada al datoaux.opcfechaingreso %',datoaux;
        SELECT INTO resp  guardarpagoordenpagocontable();

       SELECT INTO resp2  cambiarestadoordenpagocontable(split_part(laopc, '|', 1)::bigint,split_part(laopc, '|', 2)::integer, 2, 'Generado desde SP conciliacionbancaria_generaropc') ; -- La OPC queda pagada ya que es un movimiento del banco


       RETURN resp;
END;
$function$
