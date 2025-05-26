CREATE OR REPLACE FUNCTION public.alta_modifica_ficha_medica()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  respuesta BOOLEAN;
  
  cursorficha CURSOR FOR SELECT * FROM  tempfichamedicainfo;
  elem RECORD;
  raux record;
 
BEGIN

respuesta = true;

open cursorficha;
FETCH cursorficha INTO elem;
WHILE FOUND LOOP

IF not nullvalue(elem.eliminar) AND elem.eliminar THEN  
-- Hay que eliminar el info

 DELETE FROM  fichamedicainfo
 WHERE idfichamedicatratamiento = elem.idfichamedicatratamiento 
 AND idcentrofichamedicatratamiento = elem.idcentrofichamedicatratamiento and
 idfichamedicainfo = elem.idfichamedicainfo  AND idcentrofichamedicainfo = elem.idcentrofichamedicainfo;
              

ELSE 
 
      SELECT INTO raux *  FROM fichamedicatratamiento
                        WHERE  idfichamedicatratamientotipo= elem.idfichamedicatratamientotipo
                        AND idfichamedica=elem.idfichamedica
                        AND idcentrofichamedica = elem.idcentrofichamedica;
      IF NOT FOUND THEN
       INSERT INTO fichamedicatratamiento (idfichamedicatratamientotipo,idfichamedica,idcentrofichamedica,fmtfechainicio) VALUES(
                  elem.idfichamedicatratamientotipo,elem.idfichamedica,elem.idcentrofichamedica,elem.fmtfechainicio);

         elem.idfichamedicatratamiento = currval('public.fichamedicatratamiento_idfichamedicatratamiento_seq');
         elem.idcentrofichamedicatratamiento = centro();

      ELSE

          update fichamedicatratamiento
                        set fmtfechainicio=elem.fmtfechainicio
                        where idfichamedicatratamiento = raux.idfichamedicatratamiento
                        and idcentrofichamedicatratamiento = raux.idcentrofichamedicatratamiento;

          elem.idfichamedicatratamiento = raux.idfichamedicatratamiento;
          elem.idcentrofichamedicatratamiento = raux.idcentrofichamedicatratamiento;

      end if;

      if nullvalue(elem.idfichamedicainfo) then
       INSERT INTO fichamedicainfo 
      (fmifecha,fmiauditor,fmidescripcion,idfichamedicatratamiento,idcentrofichamedicatratamiento,idfichamedicainfotipos) 
      VALUES(elem.fmifecha,elem.fmiauditor,elem.fmidescripcion,elem.idfichamedicatratamiento,elem.idcentrofichamedicatratamiento
      ,elem.idfichamedicainfotipos);

	elem.idfichamedicainfo = currval('fichamedicainfo_idfichamedicainfo_seq');
        elem.idcentrofichamedicatratamiento = centro();

      else

               UPDATE fichamedicainfo
                   SET  fmifecha = elem.fmifecha
                  ,fmiauditor = elem.fmiauditor
                  ,fmidescripcion = elem.fmidescripcion
                  ,idfichamedicatratamiento = elem.idfichamedicatratamiento
                  ,idcentrofichamedicatratamiento = elem.idcentrofichamedicatratamiento
                  ,idfichamedicainfotipos = elem.idfichamedicainfotipos
              WHERE idfichamedicatratamiento = elem.idfichamedicatratamiento 
              AND idcentrofichamedicatratamiento = elem.idcentrofichamedicatratamiento and
              idfichamedicainfo = elem.idfichamedicainfo  AND idcentrofichamedicainfo = elem.idcentrofichamedicainfo;
                         
      END IF;

  /*  IF not nullvalue(elem.infomedicamentos) AND (elem.infomedicamentos) THEN 
	 IF nullvalue(elem.idfichamedicainfomedicamento) THEN
            INSERT INTO fichamedicainfomedicamento(idplancoberturas,idarticulo,idcentroarticulo,idmonodroga,idfichamedicainfo,idcentrofichamedicainfo,fmimcobertura)
            VALUES(elem.idplancoberturas,elem.idarticulo,elem.idcentroarticulo,elem.idmonodroga,elem.idfichamedicainfo,elem.idcentrofichamedicainfo,elem.fmimcobertura);
	 
         ELSE

	    UPDATE fichamedicainfomedicamento 
		SET idplancoberturas = elem.idplancoberturas
		  ,idarticulo = elem.idarticulo
		  ,idcentroarticulo = elem.idcentroarticulo
		  ,idmonodroga = elem.idmonodroga
		  ,idfichamedicainfo = elem.idfichamedicainfo
		  ,idcentrofichamedicainfo = elem.idcentrofichamedicainfo
		  ,fmimcobertura = elem.fmimcobertura
	    WHERE idfichamedicainfomedicamento = elem.idfichamedicainfomedicamento
		AND idcentrofichamedicainfomedicamento = elem.idcentrofichamedicainfomedicamento;

         END IF;
     
     END IF; */


END IF;

FETCH cursorficha INTO elem;
END LOOP;
CLOSE cursorficha;


return respuesta;
END;
$function$
