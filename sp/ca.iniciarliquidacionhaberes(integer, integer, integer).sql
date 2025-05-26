CREATE OR REPLACE FUNCTION ca.iniciarliquidacionhaberes(integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
* Este SP es el que inicializa una liquidacion en base a la liquidacion anterior
* No se tienen en cuenta tanto a los tipos de conceptos adicionales extraordinarios como a las deuducciones extraordinarias
*/
DECLARE
       elmes integer;

       elanio integer;

       eltipo integer;
       rsliquidacion record;
       anteriorliq record;
       cursorempleadoconcepto refcursor;
       cursorempleadocsinliq refcursor;
       unempleadoconcepto record;
       salida boolean;
       codliquidacion integer;
       respuesta record;
       unempsinliq record;
       resp boolean;
       elidusuario integer;
       rusuario record;
       datoempaux record;

BEGIN
     elmes = $1;
     elanio = $2;
     eltipo = $3;

     SET search_path =pg_catalog, ca, public ;
     /* Verifico que no exista una liquidacion para ese mes y ese anio*/
     SELECT INTO rsliquidacion * FROM liquidacion WHERE limes= elmes and lianio=elanio and idliquidaciontipo=eltipo;
     IF FOUND THEN
              salida = false; -- ya existe una liquidacion para ese mes y ese anio
     ELSE
              /* Se guarda la informacion del usuario que genero el comprobante */
              SELECT INTO rusuario * FROM public.log_tconexiones WHERE idconexion=current_timestamp;
              IF not found THEN
                   elidusuario = 25;
              ELSE
                    elidusuario = rusuario.idusuario;
              END IF;
     
     
          /* Recupero la clave de la liquidacion del mes anterior */
          /*si se trata de una liq extraordinaria, es decir tipo 5 o 6 la creo en base a la ultima liq de tipo 1 o 2 pues las extraordinarias 
          son muy esporadicas y si traiga la ultima liq de dicho tipo puede que traiga datos muy viejos*/
          /*5 extraordinaria de farmacia, 6 extraordinaria de sosunc*/
         /* Dani modifico el 2025-05-06 para el caso de las extraordinarias,
            ya que debe traer los datos de referencia de la ultima liq regular para crear la nueva extraordinaria*/

     if(eltipo=5) then 
            SELECT INTO anteriorliq * FROM liquidacion WHERE  idliquidaciontipo=2  and lianio=elanio and limes=elmes 
                                                              order by lianio desc ,limes  desc limit 1;
     end if;
    if(eltipo=6) then 
            SELECT INTO anteriorliq * FROM liquidacion WHERE  idliquidaciontipo=1  and lianio=elanio and limes=elmes 
                                                              order by lianio desc ,limes  desc limit 1;
    end if;
    if(eltipo<>5 and eltipo<>6) then 
           SELECT INTO anteriorliq * FROM liquidacion WHERE  idliquidaciontipo=eltipo order by lianio desc ,limes  desc limit 1;
    end if;
           
  /* SE CREA LA NUEVA LIQUIDACION */
           INSERT INTO liquidacion (lianio,limes,idliquidaciontipo )VALUES(elanio,elmes,eltipo);
           codliquidacion = currval('ca.liquidacion_idliquidacion_seq');

           /* Recupero cada uno de los conceptos de los empleados ACTIVOS  de la liquidacion anterior */
             OPEN cursorempleadoconcepto FOR SELECT DISTINCT *
             FROM ca.concepto
             NATURAL JOIN   ca.conceptoempleado
             NATURAL JOIN ca.empleado
             NATURAL JOIN ca.categoriaempleado
	     JOIN   (select max(cefechainicio) as cefechainicio,idcategoria,idpersona  
                     from ca.categoriaempleado
                     where  ( idcategoriatipo=1   or  idcategoriatipo=5) 
                            and ( cefechafin>=concat(elanio,'-',elmes,'-','01')::date or nullvalue(cefechafin) ) 
                     group by idpersona,idcategoria
             ) AS T using(idcategoria ,idpersona,cefechainicio)
             LEFT JOIN ca.afip_situacionrevistaempleado  USING (idpersona) --25-03-2019 para que no genere liq si esta con liqSGH
             WHERE  coautomatico  
		
                    AND idafip_situacionrevista = 1 
                    -- comento VAS 171224 and ( asrefechahasta>=to_date(concat(elanio,'-',elmes,'-1'),'YYYY-MM-DD') or nullvalue(asrefechahasta) ) 
                    AND ( asrafechadesde<=to_date(concat(elanio,'-',elmes,'-1'),'YYYY-MM-DD') 
                          AND ( asrefechahasta >= to_date(concat(elanio,'-',elmes,'-1'),'YYYY-MM-DD')+ interval '1 month'- interval '1 day ' or nullvalue(asrefechahasta) )
                         ) 
                    AND  ( idcategoriatipo=1/*or  idcategoriatipo=4*/ or  idcategoriatipo=5)  
                    AND idliquidacion=anteriorliq.idliquidacion
             
                    AND ( cefechafin>=to_date(concat(elanio,'-',elmes,'-1'),'YYYY-MM-DD')+ interval '1 month'- interval '1 day ' or nullvalue(cefechafin) )  
                    order by idpersona;

          
                  FETCH cursorempleadoconcepto INTO unempleadoconcepto;
                  WHILE FOUND LOOP

                    select  into datoempaux * from conceptoempleado natural join ca.concepto natural join empleado where idpersona=unempleadoconcepto.idpersona and idconcepto=unempleadoconcepto.idconcepto
                      and idliquidacion=codliquidacion;
                 IF FOUND THEN
                           RAISE EXCEPTION 'EXISTEN DATOS ERRONEOS PARA el legajo (%) y concepto  (%)// idpersona = (%)  // idconcepto =(%) // idliquidacion=(%)
 :',datoempaux.emlegajo,datoempaux.codescripcion,unempleadoconcepto.idpersona,unempleadoconcepto.idconcepto,codliquidacion;
                  ELSE
                          --- ANTES DE INSERTAR corroborar si es un concepto tipo retencion y es una liq aguinaldo que traiga el mismo % de la ultima liquidacion de sueldo

                            INSERT INTO conceptoempleado (idpersona,idconcepto,cemonto,ceporcentaje,idliquidacion,idusuario)
                             VALUES(unempleadoconcepto.idpersona,unempleadoconcepto.idconcepto,unempleadoconcepto.cemonto,unempleadoconcepto.ceporcentaje,codliquidacion,elidusuario);
                  
                  END IF;   

                     FETCH cursorempleadoconcepto INTO unempleadoconcepto;
                  END LOOP;
                  CLOSE cursorempleadoconcepto;

               SELECT INTO respuesta ca.recalcularvaloresconcepto (elmes, elanio, eltipo,t.idpersona )
               FROM  (SELECT DISTINCT idpersona
                       FROM ca.empleado
                       NATURAL JOIN ca.categoriaempleado
                       WHERE idcategoriatipo=1 
/*Dani modifico el 29/10-2019*/
               
                   and ( cefechafin>=concat(elanio,'-',elmes,'-','01')::date  or nullvalue(cefechafin)) ) as t;

              /* Si hay algun empleado nuevo activo, al que no se le ha realizado ahun una liquidacion */
              OPEN cursorempleadocsinliq FOR
                    SELECT ca.empleado.*
                    FROM ca.empleado
                    NATURAL JOIN ca.persona
                    natural join ca.categoriaempleado
                    natural join ca.grupoliquidacionempleado  -- grupo al que esta vinculado el empleado
                    natural join ca.grupoliquidacionliquidaciontipo -- tipo liquidacion vinculado al grupo
                    LEFT JOIN ca.afip_situacionrevistaempleado  USING (idpersona) --25-03-2019 para que no genere liq si esta con liqSGH
                    where  idliquidaciontipo =eltipo  -- la persona tiene que estar vinculada a ese grupo de liquidacion
                       
            and idcategoriatipo=1 and (cefechafin>=concat(elanio,'-',elmes,'-','01')::date or nullvalue(cefechafin) )  
             -- activa su categoria
                          
/* and  idafip_situacionrevista <> 13   and ( asrefechahasta>=CURRENT_DATE or nullvalue(asrefechahasta) )    -- si esta con lic. Sin GHaberes*/
and  idafip_situacionrevista =1   and ( asrefechahasta>=to_date(concat(elanio,'-',elmes,'-1'),'YYYY-MM-DD') or nullvalue(asrefechahasta) ) 
                          
                           and idpersona not in    -- no tiene conceptos en la nueva liquidacion
                                         (SELECT idpersona
                                           FROM ca.conceptoempleado
                                           WHERE idliquidacion = codliquidacion );
              FETCH cursorempleadocsinliq INTO unempsinliq;
              while FOUND LOOP
                         resp = iniciarliquidacionhaberesempleado (elmes, elanio, eltipo, unempsinliq.idpersona);
                         resp = recalcularvaloresconcepto (elmes, elanio, eltipo, unempsinliq.idpersona);
                         FETCH cursorempleadocsinliq INTO unempsinliq;
              END loop;
              CLOSE cursorempleadocsinliq;
              /* FIN : Si hay algun empleado nuevo, al que no se le ha realizado ahun una liquidacion */

           salida =true;
     END IF;

return 	salida;
END;
$function$
