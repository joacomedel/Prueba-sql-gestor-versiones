CREATE OR REPLACE FUNCTION public.guardardatospresupuesto()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Se guarda la informacion de los items del informe de facturacion cuyo numero se pasa por parametro
* Este SP es usado para insertar items de los informes de AMUC
* Tablas que se modifican: Informefacturacion,informefacturacionestado,informefacturacionitem
*/

DECLARE
	--RECORDS
	elem RECORD;
    elemitem RECORD;
    regpreitem RECORD;
    regpre RECORD;
    regestado RECORD;
    --VARIABLES
	resultado boolean;
    idpres INTEGER;
    idpresitem INTEGER;
    centropres INTEGER;
    idmaxestado INTEGER;
    --CURSORES

    cursorpre refcursor;
     cursorpreitem refcursor;
	
		
BEGIN
 
 
  OPEN cursorpreitem  FOR     SELECT *      FROM temppresitem;
  resultado = true;

 
  SELECT INTO elem * FROM  temppresupuesto;
  IF nullvalue(elem.idpresup) THEN --KR 03-10-19 modifique de lugar el insert, si es nulo no existe el presupuesto
       INSERT INTO presupuesto (pfechaemision, pfechavencimiento, idprestador,idsolicitudpresupuesto,idcentrosolicitudpresupuesto,observacion)
       VALUES (CURRENT_DATE,elem.pfechavencimiento,elem.idprestador,elem.idsol, elem.idcentrosol,elem.observacion);

       SELECT INTO idpres currval('presupuesto_idpresupuesto_seq');
        
  ELSE 
       UPDATE presupuesto SET pfechavencimiento=elem.pfechavencimiento, observacion=elem.observacion
       WHERE presupuesto.idpresupuesto=elem.idpresup AND presupuesto.idcentropresupuesto= elem.idcentropres
       AND presupuesto.idsolicitudpresupuesto= elem.idsol AND presupuesto.idcentrosolicitudpresupuesto=elem.idcentrosol;

       idpres = elem.idpresup;
  
  END IF;
FETCH cursorpreitem INTO elemitem;

WHILE FOUND LOOP --guardo los items del presupuesto y los dejoe en estado pendiente(1), si ya no estan en el presupuesto, si ya pertenecen al presupusto actualizo sus datos

            SELECT INTO regpreitem * FROM presupuestoitem
                                     WHERE presupuestoitem.idpresupuestoitem =elemitem.idpreitem AND presupuestoitem.idcentropresupuestoitem= elemitem.idcentropreitem
                                     AND presupuestoitem.idpresupuesto = elemitem.idpresupuesto AND presupuestoitem.idcentropresupuesto=elemitem.idcentropresupuesto;
            IF NOT FOUND THEN	 
                INSERT INTO presupuestoitem ( idcentropresupuesto, idpresupuesto,  pidiscriminante, picoditem,picantidad, piimporte,picoddescripcion,piimporteiva,piimportetotalconiva,piimportetotalsiniva, idiva)
                VALUES (CASE WHEN nullvalue(regpreitem.idcentropresupuesto) THEN centro() ELSE regpreitem.idcentropresupuesto END, idpres,elemitem.pidiscriminante,elemitem.picoditem,elemitem.picantidad,elemitem.pimporte, elemitem.picoddescripcion,elemitem.piimporteiva,elemitem.piimportetotalconiva,elemitem.piimportetotalsiniva,elemitem.idiva);

                SELECT INTO idpresitem currval('presupuestoitem_idpresupuestoitem_seq');

                INSERT INTO presupuestoitemestado (idpresupuestoitem, idcentropresupuestoitem,idpresupuestoitemestadotipo,pifechadesde)
                VALUES (idpresitem,centro(), 1,CURRENT_DATE);
                
                
            ELSE
                UPDATE presupuestoitem SET piimporte=elemitem.pimporte, picantidad = elemitem.picantidad, piimporteiva = elemitem.piimporteiva
                                           ,piimportetotalconiva = elemitem.piimportetotalconiva
                                           ,piimportetotalsiniva = elemitem.piimportetotalsiniva
                                           ,idiva = elemitem.idiva
                 WHERE presupuestoitem.idpresupuestoitem =elemitem.idpreitem AND presupuestoitem.idcentropresupuestoitem= elemitem.idcentropreitem
                                     AND presupuestoitem.idpresupuesto = elemitem.idpresupuesto AND presupuestoitem.idcentropresupuesto=elemitem.idcentropresupuesto;

                SELECT INTO idmaxestado max(presupuestoitemestado.idpresupuestoitemestado)
                FROM presupuestoitemestado
                WHERE presupuestoitemestado.idpresupuestoitem =elemitem.idpreitem AND presupuestoitemestado.idcentropresupuestoitem= elemitem.idcentropreitem;
               

                SELECT INTO regestado *
                FROM presupuestoitemestado
                WHERE presupuestoitemestado.idpresupuestoitem =elemitem.idpreitem AND presupuestoitemestado.idcentropresupuestoitem= elemitem.idcentropreitem
                  AND presupuestoitemestado.idpresupuestoitemestado= idmaxestado;

                IF (regestado.idpresupuestoitemestadotipo <> elemitem.idpresupuestoitemestadotipo) THEN

                        UPDATE presupuestoitemestado SET pifechahasta = CURRENT_DATE
                        WHERE presupuestoitemestado.idpresupuestoitem =elemitem.idpreitem AND presupuestoitemestado.idcentropresupuestoitem= elemitem.idcentropreitem
                        AND presupuestoitemestado.idpresupuestoitemestado = idmaxestado AND presupuestoitemestado.idcentropresupuestoitemestado=elemitem.idcentropreitem;

                        INSERT INTO presupuestoitemestado (idpresupuestoitem, idcentropresupuestoitem,idpresupuestoitemestadotipo,pifechadesde)
                        VALUES (elemitem.idpreitem,elemitem.idcentropreitem,elemitem.idpresupuestoitemestadotipo,CURRENT_DATE);
                END IF;



            END IF;
            FETCH cursorpreitem INTO elemitem;
END LOOP;
CLOSE cursorpreitem;



return true;
end;

$function$
