CREATE OR REPLACE FUNCTION public.abmcorreo()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$declare
      ccorreo CURSOR FOR SELECT  *
                        FROM  temp_correo;
                       
	  elem RECORD;
	  rplanillacorreo RECORD;
      vresultado bigint;

BEGIN

vresultado = 0;

OPEN ccorreo;
FETCH ccorreo INTO elem;
WHILE  found LOOP


	SELECT INTO rplanillacorreo *
		 FROM planillacorreo as p
		 JOIN entrega as e USING(identrega)
		 WHERE  idcorreo=elem.idcorreo  AND nullvalue(fecha);

	IF NOT FOUND THEN
	       INSERT INTO entrega(idcomprobante,nombre,apellido,fecha,idtipoentrega) VALUES (null,null,null,null,5);
	       rplanillacorreo.identrega = currval(('entrega_identrega_seq'::text));
               INSERT INTO planillacorreo(identrega,idcorreo)  VALUES(rplanillacorreo.identrega,elem.idcorreo);
               rplanillacorreo.idplanillacorreo = currval('planillacorreo_idplanillacorreo_seq'::text);
	END IF;


	IF elem.accion = 'cargar' THEN 

		IF nullvalue(elem.idrecepcion) THEN

			INSERT INTO comprobante(fechahora) VALUES (CURRENT_TIMESTAMP);
			INSERT INTO recepcion(idcomprobante,idtiporecepcion,fecha,nombre,apellido,idcorreo)
			VALUES (currval('comprobante_idcomprobante_seq'::text),1,CURRENT_DATE,elem.nombre,elem.apellido,elem.idcorreo);
			
			
			INSERT INTO recitemcorreo(idrecepcion,identrega,idplanillacorreo,destinatario,descripcion)
			VALUES (currval('recepcion_idrecepcion_seq'::text),rplanillacorreo.identrega,rplanillacorreo.idplanillacorreo,elem.destinatario,elem.descripcion);
		ELSE 
			IF nullvalue(elem.eliminar) THEN 
				UPDATE recepcion SET nombre = elem.nombre,apellido = elem.apellido
				WHERE idrecepcion = elem.idrecepcion AND idcentroregional = elem.idcentroregional;
				
				UPDATE recitemcorreo SET destinatario = elem.destinatario,descripcion = elem.descripcion
				WHERE idrecepcion = elem.idrecepcion AND idcentroregional = elem.idcentroregional;
			ELSE
				/*DELETE FROM comprobante WHERE (idcomprobante) IN (select idcomprobante
					FROM recepcion 
					WHERE idrecepcion = elem.idrecepcion AND idcentroregional = elem.idcentroregional 
				     );*/

				DELETE FROM recitemcorreo WHERE idrecepcion = elem.idrecepcion AND idcentroregional = elem.idcentroregional;
				DELETE FROM recepcion WHERE idrecepcion = elem.idrecepcion AND idcentroregional = elem.idcentroregional; 
			END IF;
		END IF;
	END IF;

	IF elem.accion = 'enviar' THEN 
		INSERT INTO comprobante(fechahora) VALUES (CURRENT_TIMESTAMP);

		UPDATE entrega set idcomprobante=currval('comprobante_idcomprobante_seq'::text)
			,fecha=elem.fechaentrega
			,nombre=elem.nombreentrega
			,apellido=elem.apellidoentrega 
			WHERE identrega=elem.identrega;

	END IF;
fetch ccorreo into elem;
END LOOP;
CLOSE ccorreo;




return vresultado;
END;
$function$
