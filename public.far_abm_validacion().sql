CREATE OR REPLACE FUNCTION public.far_abm_validacion()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
 --VARIABLES
  respuesta BOOLEAN;
--CURSORES
  cursoritem CURSOR FOR SELECT mcodbarra as codbarras,mtroquel as codtroquel, * FROM  recetariotp_temporal JOIN far_medicamento USING(mnroregistro) NATURAL JOIN medicamento;

--RECORD
  
  elem RECORD;  
  rlavalidacionitem RECORD;

--VARIABLES
  elidvalidacion BIGINT;
  elcentrovalidacion INTEGER;
 
BEGIN

respuesta = true;

open cursoritem;
FETCH cursoritem INTO elem; 
      
 IF nullvalue(elem.idvalidacion) THEN /*se da de alta por primera vez la validacion*/
             INSERT INTO far_validacionxml (vcadenaxml,idadesfaprocesotipo) VALUES(null, 1);
            -- elem.idvalidacion = currval('adesfa_xml_idadesfa_xml_seq'::regclass);
             elidvalidacion = currval('far_validacionxml_idvalidacionxml_seq'::regclass);
             elcentrovalidacion = centro(); 

             INSERT INTO far_validacion (idvalidacion,idcentrovalidacion,
                   codrtageneral,prestadorcodigo,fincodigo,	plan, crednumero )
			VALUES(elidvalidacion,elcentrovalidacion,0,99030565008,1, elem.idplancobertura,elem.nrodoc);

             UPDATE recetariotp_temporal SET idvalidacion = elidvalidacion                                   
                                          ,idcentrovalidacion= elcentrovalidacion; 
  ELSE 
       elidvalidacion = elem.idvalidacion;
       elcentrovalidacion = elem.idcentrovalidacion; 
                   
  END IF;                      
             
  WHILE FOUND LOOP
    
    
    
             IF nullvalue(elem.idvalidacionitem) THEN 
                    INSERT INTO far_validacionitems (idvalidacion,idcentrovalidacion,codbarras,codtroquel,
                        importeunitario,descripcion,cantidadsolicitada,	
                        cantidadaprobada,porcentajecobertura,importeacargoafiliado,	impotecobertura )
                    VALUES(elidvalidacion,elcentrovalidacion,elem.codbarras, elem.codtroquel,elem.importeunitario,           
                    elem.descripcion, elem.rtpicantidad,elem.rtpicantidad,elem.rtpipcobertura                     
                     ,elem.importeacargoafiliado,elem.impotecobertura);
 
--KR 08-05 inserto el estado del item de la validacion
                   INSERT INTO far_validacionitemsestado (idvalidacionitemsestadotipo,idvalidacionitem ,idcentrovalidacionitem)
                    VALUES(1,currval('far_validacionitems_idvalidacionitem_seq'::regclass), centro()); 

                 

                   UPDATE recetariotp_temporal SET 
                                      idvalidacionitem= currval('far_validacionitems_idvalidacionitem_seq'::regclass)
                                     ,idcentrovalidacionitem= centro()        
                                   
                   WHERE mnroregistro= elem.mnroregistro;

               ELSE 
                   UPDATE far_validacionitems SET porcentajecobertura= elem.rtpipcobertura
                                     ,cantidadsolicitada= elem.rtpicantidad
                                     ,cantidadaprobada= elem.rtpicantidad
                                     ,importeacargoafiliado = elem.importeacargoafiliado
                                     ,impotecobertura =elem.impotecobertura
                                     ,codbarras=elem.codbarras
                                     ,codtroquel= elem.codtroquel
                                     ,importeunitario = elem.importeunitario
                                     ,descripcion = elem.descripcion
                                   
                   WHERE idvalidacionitem= elem.idvalidacionitem AND idcentrovalidacionitem=elem.idcentrovalidacionitem;

               END IF;
 
FETCH cursoritem INTO elem;
END LOOP;
CLOSE cursoritem;



return respuesta;
END;$function$
