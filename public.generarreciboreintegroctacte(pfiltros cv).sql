CREATE OR REPLACE FUNCTION public.generarreciboreintegroctacte(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$ 
DECLARE
rusuario record;

        
       cursormovimientos refcursor;
       --Las formas de pago del recibo, para insertarlos en importes recibos y recibocupon
       cursorpagos CURSOR FOR SELECT * FROM tempfacturaventacupon NATURAL JOIN valorescaja;

       cursorpagosformapago CURSOR FOR SELECT idformapagotipos,sum(monto) as importefpt
                            FROM tempfacturaventacupon
                            NATURAL JOIN valorescaja
                            GROUP BY idformapagotipos;
--registros
       unrecibo RECORD;
respuesta  RECORD;
       unpago RECORD;
       	
--variables
       nrorecibo bigint;
     

BEGIN
      
 OPEN cursormovimientos FOR  SELECT opcmontototal,movconcepto,importe,fechamovimiento,reintegroorden.*,idpago ,idcentropago
FROM public.ordenpagocontablereintegroctacte natural join ordenpagocontablereintegro natural join reintegroorden 
join cuentacorrientepagos  on idcomprobante= reintegroorden.nroorden * 100 + reintegroorden.centro
 where opcfechaingreso >='2019-01-01' and  opcfechaingreso <='2019-12-31' and (idordenpagocontable<>73603 and idordenpagocontable<> 72029 and idordenpagocontable<>72183 and idordenpagocontable<>73701 )
    ;
 FETCH cursormovimientos into unrecibo ;
 WHILE  found LOOP

    

     SELECT INTO nrorecibo * FROM getidrecibocaja();
     INSERT INTO recibo(idrecibo,importerecibo,fecharecibo,imputacionrecibo,centro,importeenletras)
     VALUES (nrorecibo,unrecibo.opcmontototal,unrecibo.fechamovimiento,unrecibo.movconcepto,centro(),convertinumeroalenguajenatural(unrecibo.opcmontototal::numeric));

    INSERT INTO importesrecibo(idrecibo,centro,idformapagotipos , importe )  VALUES (nrorecibo,centro(),3,unrecibo.opcmontototal);
 
    
               
    INSERT INTO reintegrorecibo(idrecibo,centro,nroreintegro  ,anio ,idcentroregional) VALUES (nrorecibo,centro(),unrecibo.nroreintegro,unrecibo.anio,unrecibo.idcentroregional);
    

     update cuentacorrientepagos set idcomprobante=nrorecibo,idcomprobantetipos=0 where idpago = unrecibo.idpago and idcentropago=unrecibo.idcentropago;
 
 
      INSERT INTO recibocupon(idvalorescaja, autorizacion, nrotarjeta, monto, cuotas, nrocupon,idrecibo,centro)
            VALUES(968, 0, 0,unrecibo.opcmontototal,1,0,nrorecibo, centro());
     

      INSERT INTO recibousuario (idrecibo,centro,idusuario) VALUES (nrorecibo,centro(),25);

 FETCH cursormovimientos into unrecibo ;
 END LOOP;
 CLOSE cursormovimientos ;
RETURN 'todo ok';
END;
$function$
