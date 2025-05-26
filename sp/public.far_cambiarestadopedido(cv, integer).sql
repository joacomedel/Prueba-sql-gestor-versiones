CREATE OR REPLACE FUNCTION public.far_cambiarestadopedido(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

   	elidpedido integer;
   	elidcentropedido integer;
   	elidestado integer;
        rusuario record;

BEGIN
     elidpedido =  split_part($1, '|',1);
     elidcentropedido =  split_part($1, '|',2);
     elidestado = $2;

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

     UPDATE far_pedidoestado
     SET pefechafin = now()
     WHERE idpedido =elidpedido
           and idcentropedido = elidcentropedido
           and nullvalue(pefechafin);

     INSERT INTO far_pedidoestado(idestadotipo,idpedido,idcentropedido,peidusuario)
     VALUES(elidestado,elidpedido,elidcentropedido,rusuario.idusuario);


return 'true';
END;
$function$
