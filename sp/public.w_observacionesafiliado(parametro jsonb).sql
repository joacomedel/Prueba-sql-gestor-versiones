CREATE OR REPLACE FUNCTION public.w_observacionesafiliado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
select from w_abmctactecliente('{"NroDocumento":"34812699","operacion":"alta"}'::jsonb);
*/

DECLARE

       respuestajson jsonb;
      
--RECORD
			rturno RECORD;
       rcliente RECORD;
       rrespuesta RECORD;
begin 

	
	SELECT INTO respuestajson array_to_json(array_agg(row_to_json(t)))
           FROM (
                   select * from w_turno  
											natural JOIN w_turnoestado  
											NATURAL join w_turnoestadotipo  --Agregado 30/11/2020
											where tipodoc = (parametro->>'tipodoc')::SMALLINT and nrodoc = (parametro->>'doc') and idrolweb = (parametro->>'idrolweb')::SMALLINT
											and teresaltar = 1 
											order by idturno asc
           ) as t ; 
	

/*
    		SELECT INTO rturno * FROM  w_turno  
											natural JOIN w_turnoestado 
											--where tipodoc = (parametro->>'tipodoc')::SMALLINT and nrodoc = (parametro->>'nrodoc') 
											where tipodoc = (parametro->>'tipodoc')::SMALLINT and nrodoc = (parametro->>'doc') 
											and teresaltar = 1 
											order by idturno desc;
	*/		
	--			 respuestajson = row_to_json(rturno);
        
				return respuestajson;

end;
 $function$
