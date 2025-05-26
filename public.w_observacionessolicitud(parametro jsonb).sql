CREATE OR REPLACE FUNCTION public.w_observacionessolicitud(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
select from w_abmctactecliente('{"NroDocumento":"34812699","operacion":"alta"}'::jsonb);
*/

DECLARE

       respuestajson jsonb;
      
--RECORD
       rcliente RECORD;
       rrespuesta RECORD;
begin 	

	
	SELECT INTO respuestajson array_to_json(array_agg(row_to_json(t)))
           FROM (
				SELECT p.nombres AS usuario, tefechaini, tetnombre, tecomentarioexterno, tecomentariointerno, teresaltar, tet.idturnoestadotipo, tet.teticono   FROM w_turno
					NATURAL JOIN w_turnoestado AS te
					JOIN w_turnoestadotipo	AS tet USING (idturnoestadotipo)
					LEFT JOIN w_usuarioafiliado AS ua ON (te.idusuarioweb = ua.idusuarioweb)		--SL 21/03/24 - Agrego condicion para traer el usuario
					LEFT JOIN w_usuariorolwebsiges AS uws ON (te.idusuarioweb = uws.idusuarioweb)           --SL 21/03/24 - Agrego condicion para traer el usuario
					LEFT JOIN persona AS p ON (ua.nrodoc = p.nrodoc OR uws.dni = p.nrodoc)		        --SL 21/03/24 - Agrego condicion para traer la persona
				WHERE idcentroturno = (parametro->>'idcentroturno') AND idturno = (parametro->>'idturno') 
				--and tecomentarioexterno <> null and tecomentariointerno <> null
				GROUP BY uws.dni, p.nombres, te.tefechaini, tet.tetnombre, te.tecomentarioexterno, te.tecomentariointerno, te.teresaltar, tet.idturnoestadotipo  
				ORDER BY tefechaini DESC
           ) as t ; 
    	
 return respuestajson;

end;

$function$
