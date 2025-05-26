CREATE OR REPLACE FUNCTION public.w_ordenrecibo_informacion_json_token(parametro jsonb)
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
		FROM importesrecibo
		NATURAL JOIN ordenrecibo 
 --Agrego KR 13-04-20 
                ,SUM(iiiaimportesinauditoria) AS    importessinauditoria                            
                ,SUM(iiiaimporteconauditoria) AS  importesconauditoria
                ,SUM(iiiaimportetotal) AS  importetotal
		 where 
		 -- idrecibo = 752123  AND  centro = 1
		 idrecibo = parametro->>'idrecibo' AND  centro = parametro->>'centro' 
                GROUP BY idformapagotipos, importe
 ) as t
) as detalleimportes
,
 (
select  array_to_json(array_agg(row_to_json(t)))
    from ( 
		SELECT idrecibo,nroorden,centro,concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica) as codigoconvenio,split_part(pdescripcion,'|(antes)|',1) as descripcioncodigoconvenio,cobertura,cantidad,importe as importeunitario,iierror as erroritem,iditemestadotipo
		FROM ordenrecibo 
		NATURAL JOIN orden
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
