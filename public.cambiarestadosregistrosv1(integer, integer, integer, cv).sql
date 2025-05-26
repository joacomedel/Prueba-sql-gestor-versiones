CREATE OR REPLACE FUNCTION public.cambiarestadosregistrosv1(integer, integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--REGISTRO
elresumen record; 
unresumen record;
losresumenes refcursor;
	
--VARIABLES
estadofactres INTEGER;
elidusuario INTEGER;




BEGIN

--KR 04-12-19 agregue para que se guarde el usuario en los cambios de estados de un registro
  SELECT INTO elidusuario * FROM sys_dar_usuarioactual();

  INSERT INTO festados (fechacambio,nroregistro,anio,tipoestadofactura,observacion,idusuario) VALUES 
                               (CURRENT_DATE,$1,$2,$3,$4,elidusuario);

--invoco al sp que guarda los datos de auditoria en las fichas medicas. 
  PERFORM alta_modifica_preauditoria_fichamedica($1,$2);
   
   OPEN losresumenes FOR SELECT * FROM factura WHERE  idresumen =$1  and anioresumen=$2;
   FETCH losresumenes INTO unresumen;
   WHILE  found LOOP

             INSERT INTO festados (fechacambio,nroregistro,anio,tipoestadofactura,observacion,idusuario) VALUES 
                                 (CURRENT_DATE,unresumen.nroregistro,unresumen.anio,$3,$4,elidusuario);
      
             PERFORM alta_modifica_preauditoria_fichamedica($1,$2);             

        FETCH losresumenes INTO unresumen;

             
    END LOOP;
    CLOSE losresumenes;


 SELECT INTO elresumen idresumen,anioresumen FROM factura WHERE not nullvalue(idresumen) and not nullvalue(anioresumen) and nroregistro=$1 and anio=$2;

IF FOUND THEN

             
       SELECT INTO estadofactres tipoestadofactura  
       FROM factura NATURAL JOIN festados 
       WHERE nullvalue(festados.fefechafin) and idresumen=elresumen.idresumen and anioresumen=elresumen.anioresumen and tipoestadofactura<>$3;

       IF NOT FOUND THEN --PASO EL RESUMEN AL estado correspondiente
            INSERT INTO festados (fechacambio,nroregistro,anio,tipoestadofactura,observacion,idusuario)
	    VALUES (CURRENT_DATE,elresumen.idresumen,elresumen.anioresumen,$3,$4,elidusuario);
		
       END IF;
END IF; 



return true;
END;

$function$
