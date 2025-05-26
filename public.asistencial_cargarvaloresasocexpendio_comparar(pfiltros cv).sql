CREATE OR REPLACE FUNCTION public.asistencial_cargarvaloresasocexpendio_comparar(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE

--RECORD
  rfiltros RECORD;
  relem RECORD;
  
--CURSORES
  cursorarchi REFCURSOR;
 

--VARIABLES
  vquery VARCHAR; 
  respuesta varchar;
  vvaloranterior float;
  vpromedio float;
  vcantidadvalores integer;
  vseguir boolean;
  vcalcularvalorexpendio boolean;
  rusuario RECORD;
  
   
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

vcalcularvalorexpendio = false;
IF rfiltros.calcularexpendio = 'si' THEN
     vcalcularvalorexpendio = true;
END IF;

OPEN cursorarchi FOR select string_to_array(replace(replace(a::text,'(',''),')',''),',') as unfila
			from comparacion_valores_practica as a
                        WHERE idnomenclador <> ''
			--limit 10
			;
	FETCH cursorarchi into relem;
	    WHILE  found LOOP

		vvaloranterior = 0.0;
		vseguir = true;
		vcantidadvalores = 0;
		vpromedio = 0;
		update comparacion_valores_practica set soniguales ='SI' where idcvpprimary = relem.unfila[1];
		FOR i IN 9 .. array_upper(relem.unfila,1) LOOP
		  IF relem.unfila[i] <> '' THEN 
		         vcantidadvalores = vcantidadvalores + 1;
	                 IF vvaloranterior = 0 THEN
				vvaloranterior =  relem.unfila[i]::float;
			 END IF;
			 IF vvaloranterior <> relem.unfila[i]::float THEN
				vseguir = false;
			END IF;
			IF not vseguir THEN 
			  update comparacion_valores_practica set soniguales ='NO' where idcvpprimary = relem.unfila[1];
			END IF;

			vpromedio = vpromedio + relem.unfila[i]::float;
			--RAISE NOTICE 'Conuslta (%,%)',vseguir,relem.unfila[i];
		  END IF;
		  
		  exit when not vseguir and not vcalcularvalorexpendio;  
		 
		END LOOP;

                IF vcantidadvalores > 0 THEN
		   update comparacion_valores_practica set valorexpendio = round((vpromedio / vcantidadvalores)::numeric,2)  where idcvpprimary = relem.unfila[1];
                ELSE 
                   update comparacion_valores_practica set valorexpendio = 0  where idcvpprimary = relem.unfila[1];
                END IF;
		
	     FETCH cursorarchi INTO relem;
	    END LOOP;
	CLOSE cursorarchi;

respuesta = 'oki';


return respuesta;
END;
$function$
