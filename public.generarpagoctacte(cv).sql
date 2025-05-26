CREATE OR REPLACE FUNCTION public.generarpagoctacte(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	facturas refcursor;
	unafactura RECORD;
	
	laordenpago bigint;
	cfactura refcursor;
	lafacturadeuda  RECORD;
	rlaordenpagocontable  RECORD;
        rctacte RECORD;
	importepagado double precision ;
	nuevosaldodeuda double precision ;
	importetotalopc double precision ;
	elidpago bigint;
	elidordenpagocontable bigint;
	elidcentroordenpagocontable integer;
	elidprestadorctacte bigint;
	resp boolean;
	elidprestador bigint;
rta boolean;
	
BEGIN
elidprestadorctacte = 0;
rta = false;
      --  Por parametro se recibe el N OPC que se esta registrando el pago
      SELECT INTO elidordenpagocontable split_part($1, '-',1);
      SELECT INTO elidcentroordenpagocontable split_part($1, '-',2);


     -- Busco info de la orden de pago contable
     SELECT INTO rlaordenpagocontable * FROM ordenpagocontable WHERE idordenpagocontable = elidordenpagocontable and idcentroordenpagocontable = elidcentroordenpagocontable;
     IF FOUND THEN
        importetotalopc = rlaordenpagocontable.opcmontototal;
     
        -- busco el idctacte del prestador
        elidprestador = rlaordenpagocontable.idprestador;
        SELECT INTO elidprestadorctacte * FROM prestadorctacte_verifica(elidprestador);
        RAISE NOTICE ' elidprestador (%)',elidprestador;
        RAISE NOTICE ' elidprestadorctacte (%)',elidprestadorctacte;
        -- guardo los datos del pago en la cuenta corriente
        --IF NOT nullvalue(elidprestadorctacte) then
          INSERT INTO ctactepagoprestador(idcomprobantetipos ,idprestadorctacte,movconcepto,
                             nrocuentac,importe,
                             idcomprobante, saldo,fechacomprobante)
               VALUES(40,elidprestadorctacte,concat('Generacion OPC:',$1),
                              555,(abs(importetotalopc)*-1),
                              (elidordenpagocontable*10)+elidcentroordenpagocontable,(-1 * abs(importetotalopc)),rlaordenpagocontable.opcfechaingreso);

          elidpago = currval('ctactepagoprestador_idpago_seq');
          
          select into rta * from imputarpagoctacteprestador(concat(elidpago,'-',centro()));

        --END IF;
     END IF;
     
     
     
RETURN rta;
END;
$function$
