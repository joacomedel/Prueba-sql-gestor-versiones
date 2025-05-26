CREATE OR REPLACE FUNCTION public.conciliacionbancariacerrar(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
    rliq RECORD;
    rusuario RECORD;
    rconciliacion  RECORD;
    saldofinalconciliacion double precision;
    montomaximodiferenciaaux double precision;
BEGIN

saldofinalconciliacion =0;

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN
   rusuario.idusuario = 25;
END IF;

           

SELECT INTO rconciliacion *  FROM conciliacionbancaria WHERE 
      conciliacionbancaria.idconciliacionbancaria =$1 and  conciliacionbancaria.idcentroconciliacionbancaria =$2;

if found then
/*calculo el saldo final de la conciliacion*/
             select into saldofinalconciliacion conciliacionbancariamontofinal($1,$2);
             saldofinalconciliacion=round(saldofinalconciliacion::numeric,2);

  --Dani agrego el 30092020 como conclusion de la reunion del dia con Tere para que no cierre una conciliacion con diferencia
  --BelenA 26/02/25 se cambia como se calcula el cierre ya que ahora se guardara un cbmontomaximodiferencia y se vera que la diferencia sea menor o igual a ese
montomaximodiferenciaaux = (saldofinalconciliacion::double precision)-(rconciliacion.cbsaldofinalbco::double precision);
       --RAISE EXCEPTION 'montomaximodiferenciaaux =   % ', montomaximodiferenciaaux;
        --IF (saldofinalconciliacion=rconciliacion.cbsaldofinalbco) THEN 
        IF ( abs(montomaximodiferenciaaux)<= rconciliacion.cbmontomaximodiferencia) THEN 
              --Actualizo el saldo final de la conciliacion
                    UPDATE conciliacionbancaria 
                    SET cbsaldofinalcb=saldofinalconciliacion 
                    WHERE idconciliacionbancaria=$1 and idcentroconciliacionbancaria=$2;

             -- Cambio el estado 
                    UPDATE conciliacionbancariaestado
                    SET cbcefechafin=NOW()
                     WHERE idconciliacionbancaria=$1 and idcentroconciliacionbancaria=$2 and nullvalue(cbcefechafin);

             -- Ingreso el nuevo estado  
             INSERT INTO 
 conciliacionbancariaestado(cbcefechaini,cbcedescripcion,idconciliacionbancaria,idcentroconciliacionbancaria,idusuario,idconciliacionbancariaestadotipo)
             VALUES(now(), 'Cerrada desde SP ConciliacionBancariaCerrar',$1,$2,rusuario.idusuario,2);

        END IF;
end if;
return true;
END;$function$
