CREATE OR REPLACE FUNCTION public.far_abmarticulo_hnos()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
cursorarticulos CURSOR FOR SELECT *
                           FROM far_articulo_hnos_temp;
                          
        rarticulo RECORD;
	resp boolean;
        rexistehno RECORD;
  
BEGIN

                   
OPEN cursorarticulos;
FETCH cursorarticulos into rarticulo;
WHILE  found LOOP

IF (rarticulo.hermanos) THEN 
	SELECT INTO rexistehno * FROM far_precioarticulohermano 
	WHERE  (idarticulokairo =rarticulo.idarticulokairo AND idcentroarticulokairo = rarticulo.idcentroarticulokairo) OR 
	(idarticulohermano =rarticulo.idarticulohermano AND idcentroarticulohermano = rarticulo.idcentroarticulohermano);

IF NOT FOUND THEN

	INSERT INTO far_precioarticulohermano(idarticulokairo,idcentroarticulokairo,idarticulohermano,idcentroarticulohermano)
      VALUES ( rarticulo.idarticulokairo,rarticulo.idcentroarticulokairo,rarticulo.idarticulohermano,rarticulo.idcentroarticulohermano);

        PERFORM far_cambiarestadoarticulo(rarticulo.idarticulokairo, rarticulo.idcentroarticulokairo, 2, 'Se vinculan como hermanos. ');
        PERFORM far_cambiarestadoarticulo(rarticulo.idarticulohermano, rarticulo.idcentroarticulohermano, 2, 'Se vinculan como hermanos. ');
	

ELSE
    
     UPDATE far_precioarticulohermano SET idarticulokairo = rarticulo.idarticulokairo, idcentroarticulokairo = rarticulo.idcentroarticulokairo  
		,idarticulohermano = rarticulo.idarticulohermano, idcentroarticulohermano = rarticulo.idcentroarticulohermano  
       WHERE (idarticulokairo =rarticulo.idarticulokairo AND idcentroarticulokairo = rarticulo.idcentroarticulokairo) OR 
 (idarticulohermano =rarticulo.idarticulohermano AND idcentroarticulohermano = rarticulo.idcentroarticulohermano);

      PERFORM far_cambiarestadoarticulo(rarticulo.idarticulokairo, rarticulo.idcentroarticulokairo, 2, 'Se vinculan como hermanos. ');
        PERFORM far_cambiarestadoarticulo(rarticulo.idarticulohermano, rarticulo.idcentroarticulohermano, 2, 'Se vinculan como hermanos. ');
                   
END IF;

ELSE 
     PERFORM far_cambiarestadoarticulo(rarticulo.idarticulokairo, rarticulo.idcentroarticulokairo, 4, 'Se desvincula de su hermano. ');
     PERFORM far_cambiarestadoarticulo(rarticulo.idarticulohermano, rarticulo.idcentroarticulohermano, 4 ,'Se desvincula de su hermano. ');
	



END IF;

fetch cursorarticulos into rarticulo;
END LOOP;
close cursorarticulos;

return true;

END;
$function$
