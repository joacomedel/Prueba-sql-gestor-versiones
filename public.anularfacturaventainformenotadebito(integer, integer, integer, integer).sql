CREATE OR REPLACE FUNCTION public.anularfacturaventainformenotadebito(integer, integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
-- $1: nroinforme anulado
-- $2: idcentroinformefacturacion anulado
-- $3: nroinforme creado en pendiente de facturacion
-- $4: idcentroinformefacturacion creado en pendiente de facturacion

--cursor con los datos que se deben cargar en la tabla del nuevo informe
sitemsinfonotadebito CURSOR FOR SELECT * FROM informefacturacionnotadebito NATURAL JOIN informefacturacion  
                                 WHERE nroinforme= $1 and idcentroinformefacturacion=$2;
--cursor con los datos que se deben cargar en la tabla temporal de nc a mapear
--itemsmapeo CURSOR FOR SELECT * FROM tempmapeoNDNC;

--RECORD
	regsitemsinfonotadebito RECORD;
	rctacteprestador RECORD;
	rusuario record;
	datomapeo record;
        rncprestador RECORD;
        rctactenc  RECORD;
--variables 
        valor boolean;
        vidprestadorctacte  bigint;
BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
        rusuario.idusuario = 25;
END IF;

--


OPEN sitemsinfonotadebito;
fetch sitemsinfonotadebito INTO  regsitemsinfonotadebito; 

WHILE FOUND LOOP

--KR 30-07-21 modifico SP para que entre otras cosas la NC tome el lugar de la DI en la cta cte del prestador 

   SELECT INTO valor nogenerapendiente from tempfacturaaanular WHERE nrosucursal=regsitemsinfonotadebito.nrosucursal and tipocomprobante=regsitemsinfonotadebito.tipocomprobante and tipofactura=regsitemsinfonotadebito.tipofactura and nrofactura=regsitemsinfonotadebito.nrofactura;

   IF (not valor ) THEN 
     	INSERT INTO informefacturacionnotadebito(idcentroinformefacturacion,nroinforme,idcentrodebitofacturaprestador,iddebitofacturaprestador)
	VALUES($4,$3,regsitemsinfonotadebito.idcentrodebitofacturaprestador,regsitemsinfonotadebito.iddebitofacturaprestador);
   END IF;

  --Busco el numero de registro vinculado a la ND para luego buscar la deuda en caso de que exista
   SELECT INTO rctacteprestador *
   FROM ctactepagoprestador AS ccpp LEFT JOIN ctactedeudapagoprestador USING (idpago, idcentropago)
   LEFT JOIN ctactedeudaprestador USING (iddeuda, idcentrodeuda)
   WHERE ccpp.idcomprobante=$1 * 10 + $2 AND ccpp.idcomprobantetipos= 54;

   IF FOUND THEN 
       
	UPDATE  ctactepagoprestador SET saldo = 0, importe=0,
				movconcepto = CONCAT(movconcepto,' - Pago cancelado al anularse la ND vinculada al mismo.'),
				anulado = now()
        WHERE idpago = rctacteprestador.idpago AND idcentropago = rctacteprestador.idcentropago; 

     --sumo al importe del saldo el pago que ya no existe 
	UPDATE ctactedeudaprestador as tf SET saldo = saldo + T.importeimp		        
	FROM (SELECT SUM(importeimp) AS importeimp, iddeuda, idcentrodeuda 
                     FROM ctactedeudapagoprestador 
	             WHERE idpago = rctacteprestador.idpago AND idcentropago = rctacteprestador.idcentropago
              GROUP BY iddeuda, idcentrodeuda) AS T
	WHERE tf.iddeuda = T.iddeuda AND tf.idcentrodeuda = T.idcentrodeuda; 
     
     --pongo el pago en 0
       UPDATE  ctactedeudapagoprestador SET importeimp = 0 
		WHERE idpago = rctacteprestador.idpago AND idcentropago = rctacteprestador.idcentropago;
     IF iftableexists('tempmapeondnc') THEN
       SELECT INTO rncprestador * FROM tempmapeondnc 
        WHERE nrosucursal=regsitemsinfonotadebito.nrosucursal and tipocomprobante=regsitemsinfonotadebito.tipocomprobante and tipofactura=regsitemsinfonotadebito.tipofactura and nrofactura=regsitemsinfonotadebito.nrofactura;
       IF FOUND THEN 
          INSERT INTO mapeondnc(tipocomprobante,nrosucursal,tipofactura,nrofactura,idrecepcion,idcentroregional,idusuario) VALUES
            (rncprestador.tipocomprobante,rncprestador.nrosucursal,rncprestador.tipofactura,rncprestador.nrofactura,rncprestador.idrecepcion,rncprestador.idcentroregional,rusuario.idusuario);
      
      -- LA NC ocupa el lugar de la DI 
         SELECT INTO rctactenc * FROM reclibrofact rlf join ctactepagoprestador on (rlf.numeroregistro*10000)+rlf.anio = idcomprobante 
                 WHERE idrecepcion =rncprestador.idrecepcion and idcentroregional=rncprestador.idcentroregional;
--SE supone existe pq se encontro de esta forma pero por las dudas....
         IF FOUND THEN 
              SELECT  INTO vidprestadorctacte CASE WHEN not nullvalue(pccr.idprestadorctacte) THEN pccr.idprestadorctacte end idprestadorctacte 
               FROM informefacturacionnotadebito   NATURAL JOIN debitofacturaprestador comp   
               JOIN reclibrofact ON (comp.nroregistro =reclibrofact.numeroregistro  and comp.anio = reclibrofact.anio) JOIN prestadorctacte USING(idprestador)
               LEFT JOIN reclibrofact rlfr ON (reclibrofact.idcentroregionalresumen= rlfr.idcentroregional and reclibrofact.idrecepcionresumen= rlfr.idrecepcion) 
               LEFT JOIN prestadorctacte pccr on rlfr.idprestador =pccr.idprestador 
               WHERE  nroinforme = $1 and idcentroinformefacturacion=$2;
--si el DI corresponde a un agrupador, pongo la NC en la cta cte del agrupador
             IF NOT nullvalue(vidprestadorctacte) THEN 
               UPDATE ctactepagoprestador SET 	idprestadorctacte = vidprestadorctacte 
               WHERE  idpago = rctactenc.idpago AND idcentropago = rctactenc.idcentropago;
             END IF; 
         END IF;
      END IF; 
   END IF; 
  END IF; 

	
fetch sitemsinfonotadebito into regsitemsinfonotadebito; 
END LOOP;
close sitemsinfonotadebito;
/*KR 16-06-21
IF (  valor ) THEN
raise notice 'Inicia... % ', CURRENT_TIMESTAMP;
open itemsmapeo;
fetch itemsmapeo into datomapeo; 
WHILE FOUND LOOP

    insert into  mapeondnc(tipocomprobante,nrosucursal,tipofactura,nrofactura,idrecepcion,idcentroregional,idusuario)
    values (datomapeo.tipocomprobante,datomapeo.nrosucursal,datomapeo.tipofactura,datomapeo.nrofactura,datomapeo.idrecepcion,datomapeo.idcentroregional,rusuario.idusuario);

fetch itemsmapeo into datomapeo; 
 END LOOP;
close itemsmapeo;

end if;
*/
return true;
END;$function$
