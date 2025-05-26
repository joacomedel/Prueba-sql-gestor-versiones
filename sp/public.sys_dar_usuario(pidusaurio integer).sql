CREATE OR REPLACE FUNCTION public.sys_dar_usuario(pidusaurio integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       
        rusuario RECORD;
        vrespuesta varchar;
      
BEGIN 
SELECT INTO rusuario * FROM usuario WHERE idusuario = pidusaurio;
IF NOT FOUND THEN 
   vrespuesta = 'Siges';
ELSE
   vrespuesta = rusuario.login;
END IF;

return vrespuesta;
END;
$function$
