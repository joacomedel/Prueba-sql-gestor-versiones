CREATE OR REPLACE FUNCTION public.w_app_traertipodoc(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
* SELECT  w_app_traertipodoc('{}')
*/
DECLARE
       respuestajson jsonb;
BEGIN

	select into respuestajson row_to_json(arrayTipodoc) 
		from (
		select  array_to_json(array_agg(row_to_json(t))) as tipodoc
			from ( 
					SELECT * FROM tiposdoc
				) as t
		) as arrayTipodoc;

return respuestajson;

end;
 
$function$
