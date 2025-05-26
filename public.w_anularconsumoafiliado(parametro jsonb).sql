CREATE OR REPLACE FUNCTION public.w_anularconsumoafiliado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*{"NroAfiliado":"28272137","Barra":30,"NroDocumento":null,"TipoDocumento":null,"Track":null
"centro": 1, "idrecibo": 748447, "nroorden": 1014722, "ctdescripcion": "Orden online"}"
*/

DECLARE
      
       respuestajson jsonb;
       jsonafiliado jsonb;
       clasordenes refcursor;
       rlasordenes RECORD;
       rverifica RECORD;	
begin
      SELECT INTO jsonafiliado * FROM w_determinarelegibilidadafiliado(parametro);
      
      OPEN clasordenes FOR  SELECT * FROM ordenrecibo WHERE idrecibo = parametro->>'idrecibo' AND centro=parametro->>'centro';
      FETCH clasordenes  INTO rlasordenes;
      WHILE found LOOP
	 --Verifico que el consumo sea del afiliado ingresado
	 SELECT INTO rverifica * FROM orden NATURAL JOIN consumo WHERE nrodoc = jsonafiliado->>'nrodocumento' AND nroorden = rlasordenes.nroorden AND centro = rlasordenes.centro;
	 IF NOT FOUND THEN
		RAISE EXCEPTION 'A-001, El recibo ingresado no pertenece al afiliado ingresado.(NroDocumento,NroRecibo,%,%)',jsonafiliado->>'nrodocumento',parametro->>'idrecibo';
	 ELSE 
		IF rverifica.anulado THEN 
			RAISE EXCEPTION 'A-002, El consumo ingresado, ya se encuentra anulado.(NroDocumento,NroRecibo,%,%)',jsonafiliado->>'nrodocumento',parametro->>'idrecibo';
		END IF;
	 END IF;
	 
--KR 05-09-19 el estado anulada es 2, idordenestadotipos lo toma de la tabla ordenestadotipos
/*KR 10/02/21 SOlo se anulan ordenes que fueron emitidas por Suap*/
      IF (rverifica.tipo=56) THEN 
         INSERT INTO ordenestados (nroorden,centro, fechacambio,idordenestadotipos) 
                   VALUES (rlasordenes.nroorden,rlasordenes.centro,CURRENT_TIMESTAMP,2);
         PERFORM expendio_cambiarestadoorden (rlasordenes.nroorden, rlasordenes.centro, 2);
	    
       -- PERFORM asentarconsumoctactev2(rlasordenes.idrecibo,rlasordenes.centro,rlasordenes.nroorden);
     END IF;
      FETCH clasordenes  INTO rlasordenes;
      END LOOP;
    CLOSE clasordenes; 
    	
    return parametro;

end;
$function$
