CREATE OR REPLACE FUNCTION public.contabilidad_balancecontable_asiento_patrimoniales_generico(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE rfiltros RECORD;

rusuario RECORD;

rejercicio RECORD;

rejerciciotemp RECORD;

rrevertir RECORD;

rtemp RECORD;

parametro character varying;

elasiento varchar;

BEGIN
SELECT
    INTO rusuario *
FROM
    log_tconexiones
WHERE
    idconexion = current_timestamp;

IF NOT FOUND THEN rusuario.idusuario = 25;

END IF;

EXECUTE sys_dar_filtros (pfiltros) INTO rfiltros;

IF rfiltros.accion = 'creacionapertura' THEN
        -- Tengo que mandar los datos del ejercicio ANTERIOR al que quiero hacer el asiento de apertura. (id y centro concatenados) 
        --SELECT INTO elasiento * FROM contabilidad_balancecontable_asiento_patrimoniales_apertura('{idejerciciocontable=8,idasientocierre=xxxxx}');
        IF (rfiltros.eliminar = 'true') THEN 
            SELECT
            INTO rejerciciotemp * --Obtengo los datos del ejercicio anterior
                FROM
            contabilidad_ejerciciocontable
                WHERE
            idejerciciocontable = rfiltros.idejerciciocontable;

            SELECT INTO rrevertir * FROM asientogenerico_revertir(rejerciciotemp.idasientogenerico_apertura*100+rejerciciotemp.idcentroasientogenerico_apertura);
            
            UPDATE contabilidad_ejerciciocontable
            SET
                idasientogenerico_apertura = null,
                idcentroasientogenerico_apertura = null
            WHERE
            idejerciciocontable = rfiltros.idejerciciocontable;
        END IF;
        
        SELECT
            INTO rejercicio * --Obtengo los datos del ejercicio anterior
        FROM
            contabilidad_ejerciciocontable
        WHERE
            idejerciciocontable = rfiltros.idejerciciocontable -1;

        SELECT
            INTO elasiento *
        FROM
            contabilidad_balancecontable_asiento_patrimoniales_apertura (
                concat(
                    '{idejerciciocontable=',
                    rejercicio.idejerciciocontable,
                    ',idasientocierre=',
                    rejercicio.idasientogenerico_cierre,
                    '0',
                    rejercicio.idcentroasientogenerico_cierre,
                    '}'
                )
            );

        -- Por ahora asumo que el centro es siempre 1 asi que le concateno el 0 adelante
        UPDATE contabilidad_ejerciciocontable
        SET
            idasientogenerico_apertura = SUBSTRING (
                elasiento
                FROM
                    1 FOR LENGTH(elasiento) - 2
            )::integer,
            idcentroasientogenerico_apertura = SUBSTRING (elasiento, LENGTH(elasiento) - 1, 2)::integer
        WHERE
            idejerciciocontable = rfiltros.idejerciciocontable;

    END IF;

    IF rfiltros.accion = 'creacioncierre' THEN
       IF (rfiltros.eliminar = 'true') THEN 
            SELECT
            INTO rejerciciotemp * 
                FROM
            contabilidad_ejerciciocontable
                WHERE
            idejerciciocontable = rfiltros.idejerciciocontable;
            IF(nullvalue(rejerciciotemp.eccerrado))THEN
                RAISE EXCEPTION ' Debe cerrar el ejercicio contable  %', concat(rfiltros.idejerciciocontable);
            ELSE
                SELECT INTO rtemp * FROM contabilidad_ejerciciocontable_abm(concat('accion=abrir,idejerciciocontable=',rejerciciotemp.idejerciciocontable));
                SELECT INTO rrevertir * FROM asientogenerico_revertir(rejerciciotemp.idasientogenerico_cierre_resultado*100+rejerciciotemp.idcentroasientogenerico_cierre_resultado);
                SELECT INTO rtemp * FROM contabilidad_ejerciciocontable_abm(concat('accion=cerrar,idejerciciocontable=',rejerciciotemp.idejerciciocontable));

            UPDATE contabilidad_ejerciciocontable
            SET
                idasientogenerico_cierre_resultado = null,
                idcentroasientogenerico_cierre_resultado = null
            WHERE
            idejerciciocontable = rfiltros.idejerciciocontable;
            END IF;
            
        END IF; 
        --Tengo que mandar los datos del cierre correspondiente al que quiero hacer el asiento de cierre
        SELECT
            INTO elasiento *
        FROM
            contabilidad_balancecontable_asiento_patrimoniales_cierre (
                concat(
                    '{idejerciciocontable=',
                    rfiltros.idejerciciocontable,
                    '}'
                )
            );

        UPDATE contabilidad_ejerciciocontable
        SET
            idasientogenerico_cierre = SUBSTRING (
                elasiento
                FROM
                    1 FOR LENGTH(elasiento) - 2
            )::integer,
            idcentroasientogenerico_cierre = SUBSTRING (elasiento, LENGTH(elasiento) - 1, 2)::integer
        WHERE
            idejerciciocontable = rfiltros.idejerciciocontable;

    END IF;

return elasiento;

END;$function$

