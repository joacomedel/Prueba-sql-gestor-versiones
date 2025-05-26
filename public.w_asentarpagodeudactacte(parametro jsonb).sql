CREATE OR REPLACE FUNCTION public.w_asentarpagodeudactacte(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*{"iddeuda":"08216252","idcentrodeuda":"1","importepago":"1.0","autorizacion":"0","nrotarjeta":"0","nrocupon":"0"}
*/
DECLARE
--VARIABLES 
   vvalorcagamercadopago INTEGER;
--RECORD
      respuestajson jsonb;
      rdeuda RECORD;
      rpago  RECORD;
      rformapagouw RECORD;
      rpagocupon RECORD;
      vimporte float;
      vnrotarjeta VARCHAR;
      vnrocupon VARCHAR;
begin
       vvalorcagamercadopago = 959;
       IF nullvalue(parametro->>'iddeuda') OR nullvalue(parametro->>'idcentrodeuda')
       OR nullvalue(parametro->>'autorizacion') 
      
       OR nullvalue(parametro->>'importepago') 
       
       THEN 
		RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
       END IF;

       IF nullvalue(parametro->>'nrotarjeta') THEN 
		vnrotarjeta  = 'Ticket';
       ELSE
          vnrotarjeta  = parametro->>'nrotarjeta';
       END IF;
       IF nullvalue(parametro->>'nrocupon')      THEN 
		vnrocupon  = 'PF';
       ELSE 
           vnrocupon  = parametro->>'nrocupon';
       END IF;
       IF iftableexists('temppagodeuda') THEN
          DELETE FROM temppagodeuda;
       ELSE 
	 CREATE TEMP TABLE temppagodeuda (iddeuda BIGINT,   idcentrodeuda INTEGER,    nrodoc varchar,   tipodoc integer,       importeapagar DOUBLE PRECISION,   origendeuda varchar DEFAULT 'afiliado');  
       END IF;
       IF iftableexists('tempfacturaventacupon') THEN
          DELETE FROM tempfacturaventacupon;
       ELSE 
	 CREATE TEMP TABLE tempfacturaventacupon (idvalorescaja INTEGER ,  autorizacion VARCHAR ,  nrotarjeta VARCHAR,  monto DOUBLE PRECISION ,  montodto DOUBLE PRECISION ,  cuotas SMALLINT ,  fvcporcentajedto DOUBLE PRECISION ,  nrocupon VARCHAR);
       END IF;
        --sl 14/11 - Agrego union para contemplar a los afiliados
		SELECT INTO rdeuda *
		FROM (
			SELECT iddeuda, idcentrodeuda, nrocliente, barra, saldo, nrocuentac
			FROM ctactedeudacliente
			NATURAL JOIN clientectacte 
			WHERE iddeuda = parametro->>'iddeuda' AND idcentrodeuda = parametro->>'idcentrodeuda' 
				AND nrocliente = parametro->>'nrocliente'
				AND barra = parametro->>'barra'
			
			UNION
			
			SELECT iddeuda, idcentrodeuda, nrocliente, barra, saldo, nrocuentac
			FROM cuentacorrientedeuda
			NATURAL JOIN cliente 
			WHERE iddeuda = parametro->>'iddeuda' AND idcentrodeuda = parametro->>'idcentrodeuda'
				AND nrocliente = parametro->>'nrocliente'
				AND barra = parametro->>'barra'
		) AS rdeuda;
	IF FOUND THEN 
                 vimporte = cast(parametro->>'importepago' as float); 
                 INSERT INTO temppagodeuda(iddeuda,idcentrodeuda,nrodoc,tipodoc,importeapagar) 
		    VALUES(rdeuda.iddeuda,rdeuda.idcentrodeuda,rdeuda.nrocliente,rdeuda.barra,vimporte);
		 INSERT INTO tempfacturaventacupon (idvalorescaja,autorizacion,nrotarjeta ,monto ,cuotas,nrocupon,fvcporcentajedto,montodto) 
		    VALUES (vvalorcagamercadopago,parametro->>'autorizacion',vnrotarjeta,vimporte,'1',vnrocupon,'0','0');
		 IF  rdeuda.saldo > 0 THEN
		   SELECT INTO rpago * FROM asentarpagoctactev2();
		   respuestajson = row_to_json(rpago);
		 ELSE
                    --MaLaPi 02-05-2022 Verifico que el cupon de mercado Pago no este ya registrado.
                    SELECT INTO rpagocupon * from recibocupon where autorizacion = parametro->>'autorizacion' AND idvalorescaja = vvalorcagamercadopago AND monto = vimporte;
                    IF FOUND THEN 
                        RAISE EXCEPTION 'R-002, La deuda no existe o ya esta saldada y el cupon esta registrado!!.  %',parametro;
                    ELSE 

                        SELECT INTO rpago * FROM asentarreciboctacte_sindeuda();
                        respuestajson = row_to_json(rpago);
                    END IF;
               
	         END IF;
      END IF;

       return respuestajson;

end;
$function$
