CREATE OR REPLACE FUNCTION public.observer_procesarvademecum(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 

Número de producto N 6
Nombre C 50
Código de presentación C 3
Cantidad del envase N 7 2
Precio unitario N 12 2
Fecha vigencia precio C 8
Troquel C 10
Código de barras C 13
Código de Alfabeta C 6
IdTipodeProducto C 4
Id de TiposProductos.txt
*/
DECLARE

--RECORD
  rfiltros RECORD;
  relem RECORD;
  
--CURSORES
  cursorarchi REFCURSOR;
 

--VARIABLES
  ptipoarchivo VARCHAR; 
  respuesta varchar;
  contenido varchar;
  separador varchar;
  encabezado varchar;
  nombrearchivo varchar;
  finarchivo varchar;
  enter varchar;
  fila varchar;
  idarchivo BIGINT;
  rusuario RECORD;
  vfechageneracion DATE;
  vpadronactivosal TIMESTAMP;
  
   
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;


OPEN cursorarchi FOR SELECT * FROM observer_productos;
FETCH cursorarchi into relem;

	    WHILE  found LOOP

 FETCH cursorarchi INTO relem;
	    END LOOP;
	CLOSE cursorarchi;

respuesta = concat('lala','-' ,centro());


return respuesta;
END;
$function$
