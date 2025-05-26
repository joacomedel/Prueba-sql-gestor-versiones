CREATE OR REPLACE FUNCTION public.bancaingresarmovimiento()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* Ingresa la informacion de una alerta */

DECLARE
       cmovimiento CURSOR FOR SELECT * FROM temp_bancamovimiento;
       rmovimiento RECORD;
    rcuentabancariasosunc  RECORD;
        rusuario RECORD;
        unmovimiento record;
        rmovcodigo record;
        cant integer;
       vporcentajegravado double precision;
              vgasto boolean;
        concepto  varchar;
BEGIN

vgasto = false;
vporcentajegravado = 0;
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN
   rusuario.idusuario = 25;
END IF;
cant =0;
OPEN cmovimiento;
FETCH cmovimiento into rmovimiento;
WHILE  found LOOP

    /* Busco configuracion de la cuenta bancaria */
    SELECT INTO rcuentabancariasosunc *
    FROM cuentabancariasosunc
    WHERE idcuentabancaria=rmovimiento.idcuentabancaria;
  
     --Verifco si el codigo del movimiento se encuentra registrado
       SELECT INTO rmovcodigo *
       FROM bancamovimientocodigo 
       WHERE bmcodigo = rmovimiento.bmcodigo;
       IF NOT FOUND THEN
              IF (rmovimiento.bmconcepto ilike 'Com%' or rmovimiento.bmconcepto ilike 'suscripcion%') THEN  -- se trata de un movimiento que es una comision y es gravada 21
                    vgasto = true;
                    vporcentajegravado = 0.21;
             --Dani agrego el 07082020 porque sino todos los movimientos siguientes a la primer COMISION quedan como gasto   
              else 
                    vgasto = false;
                    vporcentajegravado = 0;
              END IF; 
              INSERT INTO bancamovimientocodigo(bmcodigo,bmcdescripcion,bmcgasto , bmcporcentajegravado)
              VALUES(rmovimiento.bmcodigo,rmovimiento.bmconcepto,vgasto ,vporcentajegravado );

       END IF;

     -- Verifico que el movimiento no se encuentre registrado
       SELECT INTO unmovimiento * 
       FROM bancamovimiento 
       WHERE bmnrocomprobante =rmovimiento.bmnrocomprobante
       and bmfecha=rmovimiento.bmfecha
       --- VAS 18/0423 comentamos xq se encontraron casos(SC) donde el concepto es diferente y se corresponde al mismo movimiento and bmconcepto = rmovimiento.bmconcepto
       and bmcodigo = rmovimiento.bmcodigo
       and bmsaldo = rmovimiento.bmsaldo;

            IF NOT FOUND THEN



                IF (rmovimiento.idcuentabancaria='20' OR rmovimiento.idcuentabancaria='21') THEN

                    /* Si es cuenta de MP le modifico los conceptos antes de insertar el movimiento 
                    20 es cuenta cupones, 21 es cuenta online */

                    SELECT INTO concepto * FROM modif_movimiento_mp( rmovimiento.bmnrocomprobante::varchar );

                    rmovimiento.bmconcepto = concat( rmovimiento.bmconcepto , concepto);

                    IF ( (POSITION('refund' IN rmovimiento.bmconcepto) > 0) ) THEN

                        rmovimiento.idcuentabancaria='21';

                        SELECT INTO rcuentabancariasosunc *
                        FROM cuentabancariasosunc
                        WHERE idcuentabancaria='20';

                        /* Pongo que sea 20 ya que como en el refund el credito>0, entonces necesito que en la comparacion que sigue se ingrese y se haga la insercion*/

                    END IF;

                END IF;


                IF ( ( (not nullvalue(rcuentabancariasosunc.cbsconciliacionbancariadebito)) AND rmovimiento.bmdebito>0) OR  ( (not nullvalue(rcuentabancariasosunc.cbsconciliacionbancariacredito)) AND rmovimiento.bmcredito>0) )    THEN

                     INSERT INTO bancamovimiento(bmfecha,bmconcepto,bmcodigo,bmsaldo,bmdebito,bmnrocomprobante,bmcredito,bmusuario,idcuentabancaria)
                   VALUES(rmovimiento.bmfecha,rmovimiento.bmconcepto,rmovimiento.bmcodigo,rmovimiento.bmsaldo,rmovimiento.bmdebito,rmovimiento.bmnrocomprobante,rmovimiento.bmcredito,rusuario.idusuario,rmovimiento.idcuentabancaria);
                   cant = cant +1;

                END IF;

            END IF;

FETCH cmovimiento into rmovimiento;
END LOOP;
close cmovimiento;

return cant;
END;
$function$
