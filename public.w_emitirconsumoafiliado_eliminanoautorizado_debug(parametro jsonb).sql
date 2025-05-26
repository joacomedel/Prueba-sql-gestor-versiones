CREATE OR REPLACE FUNCTION public.w_emitirconsumoafiliado_eliminanoautorizado_debug(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$DECLARE
       respuestajson jsonb;
       jsonconsumo jsonb;
      
--RECORD
       ritems RECORD; 

begin
--1056009
RAISE NOTICE 'Inicio.(parametro,%)',parametro;

	SELECT INTO ritems nroorden,centro, cobertura, item.iditem
	FROM itemvalorizada NATURAL JOIN item NATURAL JOIN iteminformacion 
	WHERE nroorden = parametro->>'nroorden' AND centro = parametro->>'centro' AND cobertura <>0;
	--WHERE nroorden = 1056009 AND cobertura <>0;
	IF FOUND AND NOT (parametro->>'force')::boolean THEN --SOLo elimino los items con cobertura = 0
		--Se borra en cascada
		DELETE FROM iteminformacion WHERE (iditem,centro) 
		IN ( SELECT item.iditem,centro
			FROM itemvalorizada NATURAL JOIN item NATURAL JOIN iteminformacion 
			WHERE nroorden = parametro->>'nroorden' AND centro = parametro->>'centro' AND cobertura =0   
			) ;
		DELETE FROM itemvalorizada WHERE (iditem, nroorden, centro) 
		IN ( SELECT item.iditem,nroorden, centro
			FROM itemvalorizada NATURAL JOIN item NATURAL JOIN iteminformacion 
			WHERE nroorden = parametro->>'nroorden' AND centro = parametro->>'centro' AND cobertura =0
			--WHERE nroorden = 1056009 AND cobertura =0;   
			) ;

	ELSE 
		DELETE FROM consumo WHERE nroorden = parametro->>'nroorden' AND centro = parametro->>'centro';
		DELETE FROM ordvalorizada WHERE nroorden = parametro->>'nroorden' AND centro = parametro->>'centro';
--Se borra en cascada
		DELETE FROM iteminformacion WHERE (iditem,centro) IN (      SELECT iditem,centro FROM itemvalorizada  WHERE nroorden = parametro->>'nroorden' AND centro = parametro->>'centro'  ) ;
		DELETE FROM itemvalorizada WHERE nroorden = parametro->>'nroorden' AND centro = parametro->>'centro';
		DELETE FROM cambioestadosorden WHERE nroorden = parametro->>'nroorden' AND centro = parametro->>'centro';
		DELETE FROM importesorden WHERE nroorden = parametro->>'nroorden' AND centro = parametro->>'centro';
		DELETE FROM recibousuario WHERE (idrecibo,centro) IN (SELECT idrecibo,centro FROM ordenrecibo WHERE nroorden = parametro->>'nroorden' AND centro = parametro->>'centro');
		DELETE FROM importesrecibo WHERE (idrecibo,centro) IN (SELECT idrecibo,centro FROM ordenrecibo WHERE nroorden = parametro->>'nroorden' AND centro = parametro->>'centro');
		DELETE FROM recibo WHERE (idrecibo,centro) IN (SELECT idrecibo,centro FROM ordenrecibo WHERE nroorden = parametro->>'nroorden' AND centro = parametro->>'centro');
		DELETE FROM orden WHERE nroorden = parametro->>'nroorden' AND centro = parametro->>'centro';
		DELETE FROM ordenrecibo WHERE nroorden = parametro->>'nroorden' AND centro = parametro->>'centro';


	END IF;


RAISE NOTICE 'Fin.(parametro,%)',parametro;
  return parametro;

end;$function$
