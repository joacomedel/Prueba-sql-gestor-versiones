CREATE OR REPLACE FUNCTION public.calcularvalorespractica(ppcvfechaingreso timestamp without time zone)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*Calcula los valores de la practica segun la configuracion establecida
en la tabla practconvval
SELECT calcularvalorespractica('{fechaingreso=1900-01-01,idasocconv=0 }')
SELECT calcularvalorespractica('{fechaingreso=1900-01-01,idasocconv=122 }')
SELECT calcularvalorespractica('{fechaingreso=1900-01-01,idasocconv=127 }')
*/

DECLARE
	alta refcursor; 
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	rpracticavalor RECORD;
	resultado boolean;
	valorh1 float4;
	valorh2 float4;
	valorh3 float4;    	
	valorgs float4;	
	importeprac float4;
	verificar RECORD;
    vidusuario INTEGER;   
	errores boolean;
	rsindecimal  RECORD;
	rfiltros RECORD;
BEGIN

--EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

vidusuario = sys_dar_usuarioactual();

OPEN alta FOR select nomen.idnomenclador
                     ,nomen.idcapitulo
                     ,nomen.idsubcapitulo
                     ,nomen.idpractica
                     ,nomen.honorario1
                     ,nomen.honorario2
                     ,nomen.honorario3
                     ,nomen.honorariogs
                     ,CASE WHEN not nullvalue(practconvvalcantidad.cantidadh1) 
				AND practconvvalcantidad.cantidadh1 > 1 
				AND not practconvval.fijoh1 --Si el valor es fijo ya se multiplico por la cantidad
				THEN practconvvalcantidad.cantidadh1 ELSE nomen.cantidad1 END as cantidad1 
                     ,nomen.cantidad2
                     ,nomen.cantidad3
                     ,nomen.cantigasto
                     ,practconvval.fijoh1
                     ,practconvval.idtvh1
                     ,practconvval.h1
                     ,practconvval.fijoh2
                     ,practconvval.idtvh2
                     ,practconvval.h2
                     ,practconvval.fijoh3
                     ,practconvval.idtvh3
                     ,practconvval.h3
                     ,practconvval.fijogs
                     ,practconvval.idtvgs
                     ,practconvval.gasto
                     ,practconvval.internacion
                     ,practconvval.idasocconv
                     ,practconvval.pcvfechainicio
                     from
                     (Select nomencladoruno.idnomenclador
                             ,nomencladoruno.idcapitulo
                             ,nomencladoruno.idsubcapitulo
                             ,nomencladoruno.idpractica
                             ,nomencladoruno.pmhonorario1 as honorario1
                             ,nomencladoruno.pmhonorario2 as honorario2
                             ,nomencladoruno.pmhonorario3 as honorario3
                             ,nomencladoruno.pmgastos     as honorariogs
                             ,nomencladoruno.pmcantidad1 as cantidad1
                             ,nomencladoruno.pmcantidad2 as cantidad2
                             ,nomencladoruno.pmcantidad3 as cantidad3
                             ,nomencladoruno.pmcantgastos  as cantigasto
                             FROM nomencladoruno
                     UNION
                     Select nomencladordos.idnomenclador
                            ,nomencladordos.idcapitulo
                            ,nomencladordos.idsubcapitulo
                            ,nomencladordos.idpractica
                            ,nomencladordos.pmhonorario1  as honorario1
                            ,0                            as honorario2
                            ,0                            as honorario3
                            ,nomencladordos.pmgastos      as honorariogs
                            ,nomencladordos.pmcantidad1   as cantidad1
                            ,0                            as cantidad2
                            ,0                            as cantidad3
                            ,nomencladordos.pmcantgastos as cantigasto
                            FROM nomencladordos
                     ) as nomen
                     Natural Join practconvval
                     LEFT JOIN practconvvalcantidad USING(idpractconvval, idasocconv, idsubcapitulo, idcapitulo, idpractica, idnomenclador, internacion)
                     WHERE practconvval.tvvigente
                           AND pcvfechaingreso ilike concat('%',ppcvfechaingreso,'%')
                         --  AND (rfiltros.fechaingreso = '1900-01-01' OR pcvfechaingreso >= rfiltros.fechaingreso)
			--  AND (rfiltros.idasocconv = 0 OR rfiltros.idasocconv = idasocconv)
;
FETCH alta INTO elem;
WHILE  found LOOP

valorh1 = 0;
valorh2 = 0;
valorh3 = 0;
valorgs = 0;
importeprac = 0;
       IF (elem.fijoh1 = FALSE ) THEN /*Quiere decir que se usa una tabla de valores para determinar el costo*/
           SELECT INTO valorh1 * FROM obtenervalorxcategoria('*',elem.h1,elem.idasocconv);
           valorh1 = elem.honorario1 * elem.cantidad1 * valorh1;
       ELSE /*Quiere decir que el valor es fijo*/
            valorh1 = elem.h1;
       END IF;
       IF (elem.fijoh2 = FALSE ) THEN /*Quiere decir que se usa una tabla de valores para determinar el costo*/
            SELECT INTO valorh2 * FROM obtenervalorxcategoria('*',elem.h2,elem.idasocconv);
            valorh2 = elem.honorario2 * elem.cantidad2 * valorh2;
       ELSE /*Quiere decir que el valor es fijo*/
       valorh2 =  elem.h2;
       END IF;
       IF (elem.fijoh3 = FALSE ) THEN /*Quiere decir que se usa una tabla de valores para determinar el costo*/
           SELECT INTO valorh3 * FROM obtenervalorxcategoria('*',elem.h3,elem.idasocconv);
           valorh3 = elem.honorario3 * elem.cantidad3 * valorh3;
       ELSE /*Quiere decir que el valor es fijo*/
            valorh3 = elem.h3;
       END IF;
       IF (elem.fijogs = FALSE ) THEN /*Quiere decir que se usa una tabla de valores para determinar el costo*/
         SELECT INTO valorgs * FROM obtenervalorxcategoria('*',elem.gasto,elem.idasocconv);
         valorgs = elem.honorariogs * elem.cantigasto * valorgs;
       ELSE /*Quiere decir que el valor es fijo*/
            valorgs = elem.gasto;
       END IF;

/*KR 16-11-20 Algunas asociaciones tendras valores enteros, como CMN */
       SELECT INTO rsindecimal * FROM asocconvenio WHERE idasocconv=elem.idasocconv;
       IF FOUND THEN 
            IF (rsindecimal.acvalorsindecimal) THEN 
               importeprac = round(valorh1 + valorh2 +  valorh3 + valorgs);
            ELSE 
               importeprac = valorh1 + valorh2 +  valorh3 + valorgs;
            END IF;
       END IF;

      IF (importeprac >= 0) THEN
         SELECT INTO rpracticavalor * FROM practicavalores WHERE idasocconv = to_number(elem.idasocconv,'99999999')
                                                                 AND idsubespecialidad = elem.idnomenclador
                                                                 AND idcapitulo = elem.idcapitulo
                                                                 AND idsubcapitulo = elem.idsubcapitulo
                                                                 AND idpractica = elem.idpractica
                                                                 AND internacion = elem.internacion;
         IF FOUND THEN
                  IF (to_number(to_char(rpracticavalor.importe, '9999999999.99'),'9999999999.99') <> to_number(to_char(importeprac, '9999999999.99'),'9999999999.99')) THEN

                     INSERT INTO practicavaloresmodificados(idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,importe,internacion,fechamodif,pvmidusuario,pvmfechainivigencia,pvmfechafinvigencia)
                     VALUES (to_number(elem.idasocconv,'99999999'),elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica,to_number(to_char(rpracticavalor.importe, '9999999999.99'),'9999999999.99'),elem.internacion,now(),vidusuario,rpracticavalor.pvfechainivigencia,rpracticavalor.pvfechafinvigencia);

                IF (importeprac > 0) THEN

                     UPDATE practicavalores SET importe = to_number(to_char(importeprac, '9999999999.99'),'9999999999.99'),pvidusuario = vidusuario
,pvfechainivigencia = elem.pcvfechainicio
                                             WHERE idasocconv = to_number(elem.idasocconv,'99999999')
                                                                 AND idsubespecialidad = elem.idnomenclador
                                                                 AND idcapitulo = elem.idcapitulo
                                                                 AND idsubcapitulo = elem.idsubcapitulo
                                                                 AND idpractica = elem.idpractica
                                                                 AND internacion = elem.internacion;
                   ELSE 
					   		 --MaLaPi 06-09-2022 Si el valor de la practica calculado es cero (0) ya no esta configurado para esa asociacion
							 DELETE FROM practicavalores WHERE idasocconv = to_number(elem.idasocconv,'99999999')
                                                                 AND idsubespecialidad = elem.idnomenclador
                                                                 AND idcapitulo = elem.idcapitulo
                                                                 AND idsubcapitulo = elem.idsubcapitulo
                                                                 AND idpractica = elem.idpractica
                                                                 AND internacion = elem.internacion;
		   END IF;
                 END IF;
         ELSE
               IF importeprac > 0 THEN   
               INSERT INTO practicavalores (idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,importe,internacion,pvidusuario,pvfechainivigencia)
                  VALUES (to_number(elem.idasocconv,'99999999'),elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica,to_number(to_char(importeprac, '9999999999.99'),'9999999999.99'),elem.internacion,vidusuario,elem.pcvfechainicio);
               END IF; 
         END IF;
         
          
     END IF;
RAISE NOTICE 'calcularvalorespractica: Listo (%) elem ',elem;
FETCH alta INTO elem;
errores = FALSE;
END LOOP;
CLOSE alta;                  	
resultado = 'true';
RETURN resultado;
END;
$function$
