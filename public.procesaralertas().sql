CREATE OR REPLACE FUNCTION public.procesaralertas()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
* Este SP es el que ejecutas las funciones de alertas
*/
DECLARE
       rsalertas record;
       cursoralerta refcursor;
       cursorusualert refcursor;
       rsusualert  record;
       result varchar;
       laformula varchar;
       losparam varchar;
       f varchar;
       salida boolean;
       arr_param text[];
       arr_resul text[];
       losparametros varchar;
       param_real varchar;
       los_param_real varchar;
       elidcentro integer;
       elidalerta bigint;
       elidcentroconf integer;
       elidalertaconf  bigint;
       i integer;
       long integer;
       elasunto varchar;
BEGIN
     
  
     
     /*Busco todas las alertas configuradas*/
     OPEN cursoralerta FOR SELECT concat(
                                   concat('idcentroalerta@',idcentroalerta,'|'),
                                   concat('idalerta@',idalerta,'|'),
                                   concat('aleasunto@',aleasunto,'|'),
                                   concat('idalertaconfigura@',idalertaconfigura,'|'),
                                   concat('idcentroalertaconfigura@',idcentroalertaconfigura,'|'),
                                   concat('acfnombre@',acfnombre,'|'),
                                   concat('acfparametros@',acfparametros,'|')
                                   
                                   
                                   ) as r

                        FROM  alerta
                        NATURAL JOIN alertaconfigura
                        NATURAL JOIN alertaconfigurafuncion
                       --Dani reeemplazo  currentdate+1       por current_date ya que las alertas se corren a las 7:00 AM
                        LEFT JOIN (  SELECT  idalertaconfigura,idcentroalertaconfigura
                                     FROM alertaresultado
                                     WHERE date(arfecha) =(current_date)
                                   )as resultado USING (idalertaconfigura,idcentroalertaconfigura)
                        WHERE alerta_ejecutarfuncionalerta(idalerta,idcentroalerta)
                              and (nullvalue(acfechafinconfigura) OR acfechafinconfigura >= now())
                              and ( nullvalue(resultado.idalertaconfigura) and nullvalue(resultado.idcentroalertaconfigura));
     
     FETCH cursoralerta INTO rsalertas;
     WHILE FOUND LOOP

                  arr_resul = string_to_array(rsalertas.r, '|');
                  -- 1 Obtengo la formula que desea ejecutarse para la alerta
                  laformula = arreglo_darvalorclave(arr_resul,'acfnombre','@');

                  -- 2 Obtengo los parametros reales a partir de los parametros formales
                  losparametros = arreglo_darvalorclave(arr_resul,'acfparametros','@');
                 
                  los_param_real='';
                  if (length(losparametros)>0) THEN
                              arr_param = string_to_array(losparametros, '#');
                              FOR i  IN array_lower(arr_param,1) .. array_upper(arr_param,1) LOOP
                              --   IF arreglo[i] IN
                                   param_real = arreglo_darvalorclave(arr_resul,arr_param[i],'@');
                                   los_param_real =  concat(los_param_real,',',param_real);

                              END LOOP;
                              -- quito la primer coma
                              los_param_real = substring(los_param_real from 2 for length(los_param_real));
                  END IF;
                  
                  -- 3 armo el llamado a la funcion
                   laformula = concat (laformula , '(',los_param_real,')');
                   f = concat ( 'SELECT ' , laformula);
                  --   RAISE NOTICE 'Formula  del execute f (%)',f;

                   -- 4 Obtengo el resultado de la ejecucion de la formula
                   EXECUTE  f INTO result ;
                   RAISE NOTICE 'Resultado de  execute f (%)',result;

                  -- 5 Genero cada uno de los resultados para los usuarios configurados
                  elidalerta = arreglo_darvalorclave(arr_resul,'idalerta','@');
                  elidcentro = arreglo_darvalorclave(arr_resul,'idcentroalerta','@');

                  elidalertaconf = arreglo_darvalorclave(arr_resul,'idalertaconfigura','@');
                  elidcentroconf = arreglo_darvalorclave(arr_resul,'idcentroalertaconfigura','@');
                  elasunto = arreglo_darvalorclave(arr_resul,'aleasunto','@');

                   OPEN cursorusualert  FOR SELECT *
                   FROM alertagrupousuario
                   WHERE idalerta = elidalerta and  idcentroalerta = elidcentro;
                   FETCH cursorusualert INTO rsusualert;

                  WHILE FOUND LOOP	


                      --Dani reeemplazo  currentdate+1       por current_date ya que las alertas se corren a las 7:00 AM
                                INSERT INTO alertaresultado(idalertaconfigura,idcentroalertaconfigura,idusuario,arfecha,arresultado,arasunto)
                                  VALUES(elidalertaconf,elidcentroconf,rsusualert.idusuario,now(),result,elasunto);
                                  FETCH cursorusualert INTO rsusualert;
                   END LOOP;
                  CLOSE cursorusualert;

                   FETCH cursoralerta INTO rsalertas;
         END LOOP;
         CLOSE cursoralerta;
         salida =true;

RETURN 	salida;
END;
$function$
