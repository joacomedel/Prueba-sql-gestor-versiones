CREATE OR REPLACE FUNCTION public.far_generarinformefacturacionfarmacia(integer, integer, character varying, integer, character varying, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
/* Se crea una nueva instancia de informefacturacion
 * PARAMETROS $1 idordenventa
 *            $2 idcentroordenventa
 *            $3 nrodoc
 *            $4 barra
 *            $5 tipo de factura para el informe FA o NC o ND
 *            $6 forma de pago para el informe 2 efectivo, 3 ctacte
*/

DECLARE
    codordenventa alias for $1;
    centroordenventa alias for $2;
    nrodoc alias for $3;
    barra  alias for $4;
    tipofactura alias for $5;
    formapago alias for $6;
    informeF  integer;
    nrocuentacontable integer;
    importexx  DOUBLE PRECISION;
    resp refcursor;
BEGIN

     -- Creo el informe de facturacion
     SELECT INTO informeF * FROM crearinformefacturacion(nrodoc,barra,3);
   -- Creo el informe facturacion Turimos
     INSERT INTO informefacturacionfarmacia
            (nroinforme , idcentroinformefacturacion ,  idordenventa ,idcentroordenventa)
     VALUES(informeF,codordenventa,centroordenventa,centro());

     -- Actualizo el estado 1
     UPDATE informefacturacionestado SET fechafin = NOW()
     WHERE nroinforme = informeF
           and idcentroinformefacturacion=Centro()
           and  nullvalue (fechafin);
     -- genero automaticamente el 2
     INSERT INTO informefacturacionestado (nroinforme,idcentroinformefacturacion,idinformefacturacionestadotipo,fechaini,fechafin,descripcion)
            VALUES(informeF,Centro(),2,NOW(),NOW(),'Generado Automaticamente desde generarinformefacturacionfarmacia');

     -- Queda iniciado el estado 3
      INSERT INTO informefacturacionestado (nroinforme,idcentroinformefacturacion,idinformefacturacionestadotipo,fechaini,descripcion)
      VALUES(informeF,Centro(),3,NOW(),'Generado Automaticamente desde generarinformefacturacionfarmacia');


 -- Actualizo el Informe para que tenga el tipo que me mandan por parametro
      UPDATE informefacturacion SET idtipofactura = tipofactura, idformapagotipos = formapago
             WHERE informefacturacion.nroinforme = informeF
             AND informefacturacion.idcentroinformefacturacion = centro();

  -- Creo los items del informe de facturacion
     CREATE TEMP TABLE ttinformefacturacionitem
     (nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion VARCHAR);
     nrocuentacontable =123;
     importexx = 66;
     INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
     VALUES (informeF,nrocuentacontable,1,importexx,'Aljo');
     SELECT INTO resp * FROM insertarinformefacturacionitem();

return informeF;
END;
$function$
