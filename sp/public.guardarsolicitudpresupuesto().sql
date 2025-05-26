CREATE OR REPLACE FUNCTION public.guardarsolicitudpresupuesto()
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
    --VARIABLES
    resultado boolean;
    idpres INTEGER;
    idpresitem INTEGER;
    cursorsolpre refcursor;
    cursorsolpreitem refcursor;
    idcentrosolp INTEGER;
    --CURSORES

		
BEGIN
 
 OPEN cursorsolpre  FOR   SELECT * FROM tempsolicitudpresupuesto;
 open    cursorsolpreitem FOR SELECT  * FROM tempsolpresitem;


resultado = true;


--open cursorsolpre;
FETCH cursorsolpre INTO elem;
IF FOUND THEN
   SELECT INTO regpre * FROM solicitudpresupuesto
                        WHERE solicitudpresupuesto.idsolicitudpresupuesto=elem.idsol AND solicitudpresupuesto.idcentrosolicitudpresupuesto= elem.idcentrosol;
        IF NOT FOUND THEN

             INSERT INTO solicitudpresupuesto (spfechaingreso, spfechavencimiento, spdescripcion,spdescripciondiagnostico, idfichamedicainfo,idcentrofichamedicainfo)
             VALUES (CURRENT_DATE,elem.spfechavencimiento,elem.spdescripcion,elem.spdescripciondiagnostico,elem.idfichamedicainfo,elem.idcentrofichamedicainfo);

             SELECT INTO idpres currval('solicitudpresupuesto_idsolicitudpresupuesto_seq');
             SELECT INTO idcentrosolp centro();
        ELSE
             UPDATE solicitudpresupuesto SET spfechavencimiento=elem.spfechavencimiento, spdescripcion=elem.spdescripcion, spdescripciondiagnostico=elem.spdescripciondiagnostico
             WHERE solicitudpresupuesto.idsolicitudpresupuesto=elem.idsol AND solicitudpresupuesto.idcentrosolicitudpresupuesto= elem.idcentrosol;

             idpres = elem.idsol;
             idcentrosolp = elem.idcentrosol;

        END IF;
        IF (not nullvalue(elem.idpase)) THEN --KR 05-02-19 Relaciono el pase de la nota con la SP
            UPDATE paseinfodocumento SET idsolicitudpresupuesto= idpres, idcentrosolicitudpresupuesto= centro(), pidmotivo = concat (pidmotivo, ' SE generó la SP a la cuál se vincula la nota. ')
            WHERE idpase = elem.idpase AND idcentropase = elem.idcentropase;
        END IF;
END IF;
CLOSE cursorsolpre;


--KR 01-10-19 Modifico el estado de los items del presupuesto que fueron eliminados a CANCELADO

  UPDATE solicitudpresupuestoitemestado SET spfechahasta = CURRENT_DATE
  WHERE (idsolicitudpresupuestoitem, idcentrosolpreitem) IN 
 (SELECT idsolicitudpresupuestoitem, idcentrosolpreitem FROM solicitudpresupuestoitem LEFT JOIN tempsolpresitem USING (idsolicitudpresupuestoitem, idcentrosolpreitem) WHERE nullvalue(tempsolpresitem.idsolicitudpresupuestoitem) AND idsolicitudpresupuesto=idpres AND idcentrosolicitudpresupuesto=idcentrosolp);

  INSERT INTO solicitudpresupuestoitemestado (spfechadesde, idsolicitudpresupuestoitemestadotipo, idsolicitudpresupuestoitem, idcentrosolpreitem)
  SELECT CURRENT_DATE, 4, idsolicitudpresupuestoitem, idcentrosolpreitem
  FROM solicitudpresupuestoitem LEFT JOIN tempsolpresitem USING (idsolicitudpresupuestoitem, idcentrosolpreitem) WHERE nullvalue(tempsolpresitem.idsolicitudpresupuestoitem) AND idsolicitudpresupuesto=idpres AND idcentrosolicitudpresupuesto=idcentrosolp;
              
  
--open cursorsolpreitem;
FETCH cursorsolpreitem INTO elemitem;

WHILE FOUND LOOP --guardo los items del presupuesto y los dejoe en estado pendiente(1), si ya no estan en el presupuesto, si ya pertenecen al presupusto actualizo sus datos

            SELECT INTO regpreitem * FROM solicitudpresupuestoitem
                                     WHERE solicitudpresupuestoitem.idsolicitudpresupuestoitem=elemitem.idsolicitudpresupuestoitem AND solicitudpresupuestoitem.idcentrosolpreitem= elemitem.idcentrosolpreitem;
            IF NOT FOUND THEN
                INSERT INTO solicitudpresupuestoitem (idsolicitudpresupuesto, idcentrosolicitudpresupuesto, spcoditem, spcoddescripcion, spdiscriminante, spcantidad)
                 VALUES (idpres, centro(), elemitem.spcoditem,elemitem.spcoddescripcion,elemitem.spdiscriminante,elemitem.spcantidad);

                SELECT INTO idpresitem currval('solicitudpresupuestoitem_idsolicitudpresupuestoitem_seq');

                INSERT INTO solicitudpresupuestoitemestado (spfechadesde, idsolicitudpresupuestoitemestadotipo, idsolicitudpresupuestoitem, idcentrosolpreitem)
                VALUES (CURRENT_DATE, 1, idpresitem,centro());
        /*  KR 03-10-19 ESTO NO TIENE SENTIDO. Desde la app no me informan si el estado es cancelado, lo se pq no viene en la temporal de los items. Tampoco debo si esta volver a poner el item en estado pendiente. Tengo un sp (445-1) que tiene mas de 40 veces el estado 1 para los items!! 
No encontré que se llame al SP de algun lugar donde esto tenga sentido. Por eso lo comento. 

  ELSE
                UPDATE solicitudpresupuestoitem SET spcantidad=elemitem.spcantidad
                 WHERE solicitudpresupuestoitem.idsolicitudpresupuestoitem=elemitem.idsolicitudpresupuestoitem AND solicitudpresupuestoitem.idcentrosolpreitem= elemitem.idcentrosolpreitem;
                IF elemitem.idsolicitudpresupuestoitemestadotipo = 4 THEN --EL 4 ES CANCELADO

                      UPDATE solicitudpresupuestoitemestado SET spfechahasta = CURRENT_DATE
                      WHERE solicitudpresupuestoitemestado.idsolicitudpresupuestoitem=elemitem.idsolicitudpresupuestoitem AND solicitudpresupuestoitemestado.idcentrosolpreitem= elemitem.idcentrosolpreitem
                      AND solicitudpresupuestoitemestado.idsolicitudpresupuestoitemestadotipo= 1;

                      INSERT INTO solicitudpresupuestoitemestado (spfechadesde, idsolicitudpresupuestoitemestadotipo, idsolicitudpresupuestoitem, idcentrosolpreitem)
                      VALUES (CURRENT_DATE, elemitem.idsolicitudpresupuestoitemestadotipo, elemitem.idsolicitudpresupuestoitem,elemitem.idcentrosolpreitem);

               ELSE
                       UPDATE solicitudpresupuestoitemestado SET spfechahasta = CURRENT_DATE
                      WHERE solicitudpresupuestoitemestado.idsolicitudpresupuestoitem=elemitem.idsolicitudpresupuestoitem AND solicitudpresupuestoitemestado.idcentrosolpreitem= elemitem.idcentrosolpreitem
                      AND solicitudpresupuestoitemestado.idsolicitudpresupuestoitemestadotipo= 4;

                      INSERT INTO solicitudpresupuestoitemestado (spfechadesde, idsolicitudpresupuestoitemestadotipo, idsolicitudpresupuestoitem, idcentrosolpreitem)
                      VALUES (CURRENT_DATE, elemitem.idsolicitudpresupuestoitemestadotipo, elemitem.idsolicitudpresupuestoitem,elemitem.idcentrosolpreitem);

               END IF;
*/
            END IF;
            FETCH cursorsolpreitem INTO elemitem;
END LOOP;
CLOSE cursorsolpreitem;

  

return true;
end;
$function$
