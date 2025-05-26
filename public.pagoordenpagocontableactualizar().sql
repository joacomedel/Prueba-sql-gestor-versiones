CREATE OR REPLACE FUNCTION public.pagoordenpagocontableactualizar()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
       elnuevoreg record;
       rpagoopc  record;
       rchequera record;
       descriptpago varchar;
       infofechas varchar;
BEGIN
      elnuevoreg = NEW;

       SELECT INTO rchequera *
       FROM chequera
       NATURAL JOIN cheque
       JOIN cuentabancariasosunc USING (idcuentabancaria)
       JOIN valorescaja ON (idvalorescajacuentab = idvalorescaja)
       WHERE idcheque = elnuevoreg.idcheque  AND idcentrocheque = elnuevoreg.idcentrocheque;
-- WHERE idcheque = 356  AND idcentrocheque =1;
       -- verifico si el cheque se encuentra vinculado a una OPC
       -- si esto ocurre actualizo los datos del pago
       SELECT INTO rpagoopc *
       FROM pagoordenpagocontable
       WHERE idcheque = elnuevoreg.idcheque  AND idcentrocheque = elnuevoreg.idcentrocheque;

       IF FOUND THEN -- Si el cheque esta vinculado a una opc
                IF(rchequera.idchequeratipo = 1 ) THEN  --idchequeratipo= 1 Continuo
                            infofechas = concat(' F.Emision:',elnuevoreg.cfechaconfeccion);
                END IF;
                IF(rchequera.idchequeratipo = 2 )THEN --  	idchequeratipo= 2 Diferido ///
                            infofechas = concat(' F.Emision:',elnuevoreg.cfechaconfeccion,' F.Cobro:',elnuevoreg.cfechacobro);
                END IF;
                descriptpago = concat('#',rchequera.descripcion,' CH:',elnuevoreg.cnumero::varchar,', Chra:',elnuevoreg.chnumero,infofechas,rpagoopc.popobservacion);

                UPDATE pagoordenpagocontable
                SET popobservacion = descriptpago
                WHERE idpagoordenpagocontable = rpagoopc.idpagoordenpagocontable
                     AND idcentropagoordenpagocontable = rpagoopc.idcentropagoordenpagocontable;
     
        END IF;
        RETURN NEW;
END;
$function$
