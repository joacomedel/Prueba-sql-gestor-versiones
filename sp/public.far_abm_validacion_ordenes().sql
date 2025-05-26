CREATE OR REPLACE FUNCTION public.far_abm_validacion_ordenes()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
 --VARIABLES
  respuesta BOOLEAN;
--CURSORES
  cvalidacion CURSOR FOR SELECT * FROM  tempfar_validacion;
  cvalidacionitem CURSOR FOR SELECT * FROM  tempfar_validacionitems;

--RECORD
  
  rvalidacionitem RECORD;  
  rvalidacion RECORD;

--VARIABLES
  elidvalidacion BIGINT;
  elcentrovalidacion INTEGER;
 
BEGIN

respuesta = true;

OPEN cvalidacion;
FETCH cvalidacion INTO rvalidacion; 
     WHILE FOUND LOOP   
	INSERT INTO far_validacion (idvalidacion, codrtageneral, desrtageneral,	menrtageneral, nroreferencia, tipomsj, codaccion, 	idmsj,	iniciotrxfecha,	iniciotrxhora, terminaltipo, terminalnumero, prestadorcodigo, prestadordireccion, prestadorcodparafin,
	encretipomatricula, encrenromatricla, encretipoprescriptor, fincodigo, plan, crednumero, fechareceta,	tipotratamiento,	instcodigo,	retiratipodoc, retiranrodoc,	retiranrotelefono
--, vnroreceta 
)
	VALUES(rvalidacion.idvalidacion
		, rvalidacion.codrtageneral
		, rvalidacion.desrtageneral
		, rvalidacion.menrtageneral
		, rvalidacion.nroreferencia
		, rvalidacion.tipomsj
		, rvalidacion.codaccion
		, rvalidacion.idmsj
		, rvalidacion.iniciotrxfecha
		, rvalidacion.iniciotrxhora
		, rvalidacion.terminaltipo
		, rvalidacion.terminalnumero
		, rvalidacion.prestadorcodigo
		, rvalidacion.prestadordireccion
		, rvalidacion.prestadorcodparafin
		, rvalidacion.encretipomatricula
		, rvalidacion.encrenromatricla
		, rvalidacion.encretipoprescriptor
		, rvalidacion.fincodigo
		, rvalidacion.plan
		, rvalidacion.crednumero
		, rvalidacion.fechareceta
		, rvalidacion.tipotratamiento
		, rvalidacion.instcodigo
		, rvalidacion.retiratipodoc
		, rvalidacion.retiranrodoc
		, rvalidacion.retiranrotelefono
             --   , rvalidacion.vnroreceta
);--31/10/2024 Alba y Facu modifican agregando la nueva columna de la validacion
           IF existecolumtemp('tempfar_validacion','vnroreceta') THEN
                  --- VAR 011124 guardo el numero de la receta
                  UPDATE far_validacion SET vnroreceta = rvalidacion.vnroreceta
                  WHERE  idvalidacion = rvalidacion.idvalidacion  AND idcentrovalidacion =centro();

           END IF;
FETCH cvalidacion INTO rvalidacion; 
END LOOP;
CLOSE cvalidacion;
             

OPEN cvalidacionitem;
FETCH cvalidacionitem INTO rvalidacionitem; 
     WHILE FOUND LOOP      
    
            INSERT INTO far_validacionitems (idvalidacion,idcentrovalidacion,codbarras,codtroquel, alfabeta,
                        importeunitario,descripcion, codrta, mensajerta, codautorizacion,  cantidadsolicitada,
                        cantidadaprobada,porcentajecobertura,importeacargoafiliado, impotecobertura )
            VALUES(rvalidacionitem.idvalidacion, centro(),rvalidacionitem.codbarras, rvalidacionitem.codtroquel,rvalidacionitem.alfabeta
		,rvalidacionitem.importeunitario, rvalidacionitem.descripcion, rvalidacionitem.codrta, rvalidacionitem.mensajerta		 ,rvalidacionitem.codautorizacion, rvalidacionitem.cantidadsolicitada, rvalidacionitem.cantidadaprobada
		,rvalidacionitem.porcentajecobertura, rvalidacionitem.importeacargoafiliado, rvalidacionitem.importecobertura );
 

	
                   INSERT INTO far_validacionitemsestado (idvalidacionitemsestadotipo,idvalidacionitem ,idcentrovalidacionitem)
                    VALUES(1,currval('far_validacionitems_idvalidacionitem_seq'::regclass), centro()); 

               
 
FETCH cvalidacionitem INTO rvalidacionitem; 
END LOOP;
CLOSE cvalidacionitem;



return respuesta;
END;$function$
