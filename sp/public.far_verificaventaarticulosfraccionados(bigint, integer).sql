CREATE OR REPLACE FUNCTION public.far_verificaventaarticulosfraccionados(bigint, integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
     pidordenventa  alias for $1;
     pidcentroordenventa  alias for $2;
     alta CURSOR FOR SELECT * FROM far_articulo 
			NATURAL JOIN far_ordenventaitem 
			NATURAL JOIN far_lote 
			WHERE not nullvalue(idarticulopadre) 
			AND lstock < 0
			AND idordenventa = pidordenventa AND idcentroordenventa = pidcentroordenventa;
    
     idajuste VARCHAR;
     todosidajuste VARCHAR;
     elem RECORD;
     rusuario record;
BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;
todosidajuste = '';
OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP

SELECT INTO idajuste * FROM far_stockarticulofraccionado(elem.idarticulo,elem.idcentroarticulo);

todosidajuste = concat(todosidajuste ,'-',idajuste);

fetch alta into elem;
END LOOP;
CLOSE alta;

return todosidajuste;
 
END;
$function$
