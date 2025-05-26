CREATE OR REPLACE FUNCTION public.far_marcarordencomoirregular(pidordenventa bigint, pidcentroordenventa integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
     resp boolean;
     rcliente record;
     vcuil varchar;
begin

     select INTO resp * FROM far_cambiarestadoordenventa(pidordenventa,pidcentroordenventa,17);
     IF resp THEN
	SELECT INTO rcliente * FROM cliente 
				NATURAL JOIN far_ordenventa
				LEFT JOIN persona ON far_ordenventa.nrocliente = persona.nrodoc 
						--AND far_ordenventa.barra = persona.tipodoc
				WHERE idordenventa = pidordenventa AND 
					idcentroordenventa = pidcentroordenventa;
	IF FOUND THEN 
		IF nullvalue(rcliente.cuitini) 
			OR  nullvalue(rcliente.cuitmedio) 
			OR  nullvalue(rcliente.cuitfin) THEN
			SELECT INTO vcuil * FROM generarcuil(rcliente.nrocliente,rcliente.sexo);

			UPDATE cliente SET cuitini= split_part(vcuil,'-',1), cuitmedio= split_part(vcuil,'-',2), cuitfin= split_part(vcuil,'-',3)
					WHERE nrocliente = rcliente.nrocliente AND barra = rcliente.barra;
		END IF;
	END IF;
     END IF;

     return resp;
end;
$function$
