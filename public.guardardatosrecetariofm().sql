CREATE OR REPLACE FUNCTION public.guardardatosrecetariofm()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  respuesta BOOLEAN;
  closrece CURSOR FOR SELECT idfichamedicapreauditada,idcentrofichamedicapreauditada,1 as cantidad,ri.idrecetarioitem as iditem   ,
'98'::varchar as idnomenclador ,'01'::varchar as idcapitulo ,'01'::varchar as idsubcapitulo  ,'01'::varchar as idpractica 
 ,25 as fmpaidusuario,false as fmpaporeintegro,0 as idauditoriaodontologiacodigo
,nrodocuso as nrodoc,tipodocuso as tipodoc,idprestador,3 as idauditoriatipo,fechauso,'Generado guardardatosrecetariofm' ::varchar as fmpadescripcion
,0 as fmpaiimporteiva,ri.importeapagar  as fmpaiimportetotal,
 ' ' ::varchar as descripciondebito, ridebito as importedebito,1 AS fmpacantidad
,idmotivodebito as idmotivodebitofacturacion,ou.tipo,ri.idrecetarioitem,ri.centro,14 as tipo,ri.importe as fmpaiimportes
              ,                              ri.mnroregistro       ,ri.nomenclado         
				  FROM facturaordenesutilizadas NATURAL JOIN ordenesutilizadas as ou  
                                  JOIN recetarioitem as ri ON (ou.nroorden=ri.nrorecetario and ou.centro=ri.centro)
                                LEFT JOIN fichamedicapreauditadaitemrecetario AS fmpir ON (fmpir.idrecetarioitem=ri.idrecetarioitem and fmpir.centro=ri.centro)
                                 WHERE nroregistro=64677  and  nullvalue(idfichamedicapreauditada) ;

  elem RECORD;
  rfichamedica RECORD;
   vidfichamedicapreauditada BIGINT;
  
BEGIN



respuesta = true;




open closrece;
FETCH closrece INTO elem;
--3 es el idauditoriatipo de recetarios
SELECT INTO rfichamedica * FROM fichamedica
 WHERE nrodoc = elem.nrodoc AND tipodoc = elem.tipodoc AND idauditoriatipo = 3;
IF NOT FOUND THEN
   INSERT INTO fichamedica (nrodoc,tipodoc,fmdescripcion,idauditoriatipo)
   VALUES (elem.nrodoc,elem.tipodoc,'Generado automaticamente desde una pre auditoria en guardardatosrecetariofm',3);

   SELECT INTO rfichamedica * FROM fichamedica
   WHERE nrodoc = elem.nrodoc AND tipodoc = elem.tipodoc AND idauditoriatipo = 3;

END IF;

WHILE FOUND LOOP


IF nullvalue(elem.idfichamedicapreauditada) THEN

      INSERT INTO fichamedicapreauditada
      (fmpaporeintegro,idauditoriaodontologiacodigo,idnomenclador,idcapitulo,idsubcapitulo,idpractica
      ,fmpacantidad,fmpaidusuario,fmpafechaingreso,idfichamedica,idcentrofichamedica,fmpadescripcion
      ,fmpaiimportes,fmpaiimporteiva,fmpaiimportetotal,
      fmpaimportedebito,fmpadescripciondebito,idmotivodebitofacturacion,tipo)
      VALUES(elem.fmpaporeintegro,0,elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica
      ,elem.fmpacantidad,elem.fmpaidusuario,CURRENT_TIMESTAMP,rfichamedica.idfichamedica,rfichamedica.idcentrofichamedica,elem.fmpadescripcion
      ,elem.fmpaiimportes,elem.fmpaiimporteiva,elem.fmpaiimportetotal,
      elem.importedebito,elem.descripciondebito,elem.idmotivodebitofacturacion, elem.tipo);

      vidfichamedicapreauditada = currval('fichamedicapreauditada_idfichamedicapreauditada_seq'::regclass);


     
        IF elem.tipo = 14 or elem.tipo= 37 THEN
               
               INSERT INTO fichamedicapreauditadaitemrecetario
               (idrecetarioitem,centro,idfichamedicapreauditada,idcentrofichamedicapreauditada,fmpaifechaingreso)
               VALUES(elem.idrecetarioitem,elem.centro,vidfichamedicapreauditada,centro(),CURRENT_TIMESTAMP);

               UPDATE fichamedicapreauditada SET mnroregistro= elem.mnroregistro
                                    ,nomenclado=elem.nomenclado
                WHERE idfichamedicapreauditada = vidfichamedicapreauditada
                AND idcentrofichamedicapreauditada = centro();
              
      
      END IF;
  

END IF;


FETCH closrece INTO elem;

END LOOP;
CLOSE closrece;



return respuesta;
END;
$function$
