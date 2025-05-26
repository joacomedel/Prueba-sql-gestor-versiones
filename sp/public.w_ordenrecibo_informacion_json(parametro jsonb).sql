CREATE OR REPLACE FUNCTION public.w_ordenrecibo_informacion_json(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
{"centro": 1, "idrecibo": 752123}
--Info para generar los json
https://hashrocket.com/blog/posts/faster-json-generation-with-postgresql
*/
DECLARE
       respuestajson jsonb;

begin

SELECT into respuestajson row_to_json(t)
FROM (
SELECT idrecibo,centro,nroorden,fecharecibo,imputacionrecibo,
 (
select  array_to_json(array_agg(row_to_json(t)))
    from ( 
		SELECT CASE WHEN idformapagotipos = 6 THEN 'Cubre Sosunc'  WHEN idformapagotipos = 1 THEN 'Cubre Amuc' WHEN idformapagotipos = 3 THEN 'Otra Cta.Cte'  ELSE 'Paga el Afiliado' END as formapago,importe 
		FROM ordenrecibo 
		NATURAL JOIN importesrecibo
		 where 
		 -- idrecibo = 752123  AND  centro = 1
		 idrecibo = parametro->>'idrecibo' AND  centro = parametro->>'centro' 
 ) as t
) as detalleimportes
,
 (
select  array_to_json(array_agg(row_to_json(t)))
    from ( 
		SELECT idrecibo,nroorden,centro,concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica) as codigoconvenio,split_part(pdescripcion,'|(antes)|',1) as descripcioncodigoconvenio,cobertura,cantidad,importe as importeunitario,case when anulado then 'La orden fue Anulada -- Practica Rechazada' else iierror end as erroritem
,case when anulado then 3 else iditemestadotipo end as iditemestadotipo 
		FROM ordenrecibo 
		NATURAL JOIN orden
                NATURAL JOIN consumo --Si la orden esta anulada, no importa la auditoria, se debe marcar el rechazo por anulacion
		NATURAL JOIN ordvalorizada
		NATURAL JOIN itemvalorizada
		NATURAL JOIN item
         	NATURAL JOIN practica
                LEFT JOIN iteminformacion USING(iditem,centro)
		 where --idrecibo = 752123  AND  centro = 1
			idrecibo = parametro->>'idrecibo'
			AND  centro = parametro->>'centro' 
 ) as t
) as detallepracticas
FROM ordenrecibo 
NATURAL JOIN recibo
 where --idrecibo = 752123  AND  centro = 1
	idrecibo = parametro->>'idrecibo'
	AND  centro = parametro->>'centro' 
 ) as t;

	IF NOT FOUND THEN
		--DELETE FROM ttordenesgeneradas;
		--SELECT INTO rrecibocompleto * FROM recibo WHERE idrecibo = rrecibo.idrecibo AND centro = centro(); 
		--respuestajson = row_to_json(rrecibocompleto);
		RAISE EXCEPTION 'No se encontro el recibo.(rrecibo,%)',parametro;
	 END IF;

      return respuestajson;

end;
$function$
