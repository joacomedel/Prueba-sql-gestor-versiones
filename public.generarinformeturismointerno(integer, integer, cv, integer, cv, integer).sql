CREATE OR REPLACE FUNCTION public.generarinformeturismointerno(integer, integer, character varying, integer, character varying, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* Se crea una nueva instancia de informefacturacion
 * PARAMETROS $1 idconsumoturismo
 *            $2 idcentroconsumoturismo
 *            $3 nrodoc
 *            $4 barra
 *            $5 tipo de factura para el informe FA o NC o ND
 *            $6 forma de pago para el informe 2 efectivo, 3 ctacte
*/

DECLARE
    pcodconsumoturismo alias for $1;
    pcentroconsumoturismo alias for $2;
    pnrodoc alias for $3;
    pbarra  alias for $4;
    ptipofactura alias for $5;
    pformapago alias for $6;

    informeF  integer;
BEGIN

     -- Creo el informe de facturacion
     SELECT INTO informeF * FROM crearinformefacturacion(pnrodoc,pbarra,3);
   -- Creo el informe facturacion Turimos
     INSERT INTO informefacturacionturismo(nroinforme, idconsumoturismo, idcentroconsumoturismo,idcentroinformefacturacion )
     VALUES(informeF,pcodconsumoturismo,pcentroconsumoturismo,centro());

     -- Actualizo el estado 1
     UPDATE informefacturacionestado SET fechafin = NOW()
     WHERE nroinforme = informeF
           and idcentroinformefacturacion=Centro()
           and  nullvalue (fechafin);
     -- genero automaticamente el 2
     INSERT INTO informefacturacionestado (nroinforme,idcentroinformefacturacion,idinformefacturacionestadotipo,fechaini,fechafin,descripcion)
            VALUES(informeF,Centro(),2,NOW(),NOW(),'Generado Automaticamente desde generarinformeturismo');

     -- Queda iniciado el estado 3
      INSERT INTO informefacturacionestado (nroinforme,idcentroinformefacturacion,idinformefacturacionestadotipo,fechaini,descripcion)
      VALUES(informeF,Centro(),3,NOW(),'Generado Automaticamente desde generarinformeturismo');


 -- Actualizo el Informe para que tenga el tipo que me mandan por parametro
      UPDATE informefacturacion SET idtipofactura = ptipofactura, idformapagotipos = pformapago
             WHERE informefacturacion.nroinforme = informeF
             AND informefacturacion.idcentroinformefacturacion = centro();

return informeF;
END;
$function$
