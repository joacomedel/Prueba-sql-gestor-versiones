CREATE OR REPLACE FUNCTION public.sys_generarconsumodesdelog()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	clog refcursor;
	pers RECORD;
        rrecibo RECORD;
BEGIN


    OPEN clog FOR SELECT * FROM (
			SELECT trim(split_part(split_part(lmsalida,',"fecharecibo"',1),',"nroorden":',2))::integer as nroorden,trim(split_part(split_part(lmsalida,',"nroorden":',1),'"idrecibo":',2))::integer as idrecibo,1 as centro, * 
			FROM public.w_log_mensajes 
			WHERE idusuario = 'usucmn' AND lmfechaingreso >= '2019-07-02' AND lmfechaingreso < '2019-07-04'
			AND  lmsalida ilike '%"respuesta":true%'
			AND lmoperacion = 'emitirconsumoafiliado' and not lmborrado
			) as t
			LEFT JOIN ordenrecibo USING(idrecibo,centro,nroorden)
			LEFT join orden USING(nroorden,centro)
			WHERE nullvalue(ordenrecibo.idrecibo)
			ORDER BY lmfechaingreso 
			LIMIT 10;
    FETCH clog into pers;
    WHILE  found LOOP
	DELETE FROM ttordenesgeneradas_2;
        PERFORM w_emitirconsumoafiliado(pers.lmentrada::jsonb);
        SELECT INTO rrecibo * FROM ttordenesgeneradas_2 NATURAL JOIN ordenrecibo;
        UPDATE suap_colegio_medico SET idrecibo = rrecibo.idrecibo WHERE idrecibo = pers.idrecibo AND centro = pers.centro;
        UPDATE w_log_mensajes SET lmborrado = true WHERE idlogmensajes = pers.idlogmensajes;

    fetch clog into pers;
    END LOOP;
    close clog;

return 'true';
END;
$function$
