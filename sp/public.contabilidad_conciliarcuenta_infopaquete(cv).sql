CREATE OR REPLACE FUNCTION public.contabilidad_conciliarcuenta_infopaquete(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
	laleyenda character varying;
	rparam record;
        raseintoitem record;
        rpaquete record;
        
BEGIN
/**
Este SP retorna el la leyenda a utilizar para armar los paquetes de los mayores
*/
  laleyenda ='';
  EXECUTE sys_dar_filtros($1) INTO rparam;
  -- Si se trata de un nuevo asiento debemos insertar en la tabla la leyenda del paquete vinculado a sa cuenta
  --contabilidad_info(concat('{idasientogenericoitem=',rmayor.idasientogenericoitem,',idcentroasientogenericoitem=',rmayor.idcentroasientogenericoitem,',nrocuentac=',rmayor.idCuenta,',acid_h=',rmayor.D_H,'}'))
  -- Si se trata de una modificacion se debe modificar la leyenda del item del paquete  
  -- RAISE NOTICE 'SYS::idasientogenericoitem, idcentroasientogenericoitem, idCuenta (%) (%) (%)',NEW.idasientogenericoitem , NEW.idcentroasientogenericoitem,NEW.idCuenta;

-- Busco el asiento al que quiero generar el paquete
   SELECT  INTO raseintoitem * 
   FROM  asientogenericoitem 
   WHERE idasientogenericoitem = rparam.idasientogenericoitem
          AND idcentroasientogenericoitem = rparam.idcentroasientogenericoitem;

-- genero la leyenda del paquetito
 laleyenda = contabilidad_info(concat('{idasientogenericoitem=',raseintoitem.idasientogenericoitem,',idcentroasientogenericoitem=',raseintoitem.idcentroasientogenericoitem,',nrocuentac=',raseintoitem.nrocuentac,',acid_h=',raseintoitem.acid_h,'}'));

 
-- corroboro si hay un paquete generado
  SELECT INTO rpaquete * 
  FROM contabilidad_conciliar_asientogenericoitem
  WHERE idasientogenericoitem = rparam.idasientogenericoitem
        AND idcentroasientogenericoitem = rparam.idcentroasientogenericoitem;

  IF FOUND THEN -- existe y debo modificarlo
               
      --   RAISE NOTICE 'SYS:: es un UPDATE ';
	 UPDATE contabilidad_conciliar_asientogenericoitem 
	 SET  ccileyenda = laleyenda
	 WHERE idcentroasientogenericoitem = raseintoitem.idcentroasientogenericoitem   
	      AND idasientogenericoitem = raseintoitem.idasientogenericoitem;
   ELSE 
        -- RAISE NOTICE 'SYS:: es un INSERT ';
     	 INSERT INTO contabilidad_conciliar_asientogenericoitem(idasientogenericoitem,idcentroasientogenericoitem,ccileyenda)
	 VALUES(raseintoitem.idasientogenericoitem,raseintoitem.idcentroasientogenericoitem,laleyenda);
   
   END IF;
   
  return laleyenda;
END;
$function$
