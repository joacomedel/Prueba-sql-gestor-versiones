CREATE OR REPLACE FUNCTION public.w_verificarconsumoafiliado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*/
DECLARE
       respuestajson jsonb;
       jsonafiliado jsonb;
       jsonconsumo jsonb;
       cpracticas refcursor;
       rpersona RECORD;
       rrecibocompleto RECORD;
       rasociacion RECORD;
       rprestador RECORD;
       rverifica RECORD;
       rpractica RECORD;
       elem RECORD;
       rseconsume RECORD;
       rrecibo RECORD;	
       vidplancoberturas INTEGER;
	
BEGIN
        --MaLaPi 31-01-2021 Lo comento para que llame al WS que emite el consumo
	--SELECT INTO respuestajson w_emitirconsumoafiliado_v2(parametro);
          SELECT INTO respuestajson w_emitirconsumoafiliado(parametro);

        
	IF FOUND THEN
		--RAISE EXCEPTION '%',respuestajson USING ERRCODE = '12666';
                RAISE EXCEPTION 'CancelarError <<%>>', respuestajson USING HINT = 'Please check your user ID';
	 END IF;

      return respuestajson;

end;
$function$
