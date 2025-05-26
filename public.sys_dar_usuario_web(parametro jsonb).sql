CREATE OR REPLACE FUNCTION public.sys_dar_usuario_web(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
        rusuario RECORD;
        vrespuesta jsonb;
BEGIN
SET search_path TO public;
IF not nullvalue(parametro->>'uwnombre') THEN
       SELECT INTO rusuario * FROM w_usuarioweb WHERE uwnombre= parametro->>'uwnombre';
       IF NOT FOUND THEN
           SELECT INTO rusuario * FROM w_usuarioweb WHERE idusuarioweb = 1062; --Usuario usudesa
           vrespuesta = row_to_json(rusuario);
       ELSE
           vrespuesta = row_to_json(rusuario);
       END IF;
ELSE
       SELECT INTO rusuario * FROM usuario WHERE dni= parametro->>'w_nrodoc' OR dni= parametro->>'nrodoc';
       IF NOT FOUND THEN
           SELECT INTO rusuario * FROM usuario WHERE idusuario = 25;
           vrespuesta = row_to_json(rusuario);
       ELSE
           vrespuesta = row_to_json(rusuario);
       END IF;
END IF;
return vrespuesta;
END;$function$
