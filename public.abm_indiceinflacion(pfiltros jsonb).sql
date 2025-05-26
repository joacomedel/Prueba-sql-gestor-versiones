CREATE OR REPLACE FUNCTION public.abm_indiceinflacion(pfiltros jsonb)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
    --Alba y Facu 01/2025

    --VARIABLES
    accion CHARACTER VARYING;
    resultado CHARACTER VARYING;
    id INTEGER;
    valor DOUBLE PRECISION;
    fechaDesde DATE;
    fechaHasta DATE;
    numeroMes INTEGER;

    --JSONB
    indice jsonb;

    --REGISTROS
    rnuevo RECORD;
BEGIN
    --Recuperar accion
    accion = pfiltros->>'accion';
    resultado = 'OK';

    IF (accion = 'buscarIndices') THEN
        CREATE TEMP TABLE temp_indicesinflacion AS (SELECT * FROM contabilidad_indicexinflacion ORDER BY idcontabilidad_indicexinflacion);
    END IF;

    IF (accion = 'buscarIndicesRango') THEN
        fechaDesde = pfiltros->>'fechaDesde';
        fechaHasta = pfiltros->>'fechaHasta';
        CREATE TEMP TABLE temp_indicesinflacion AS (SELECT * FROM contabilidad_indicexinflacion WHERE fechaDesde <= fechaHasta AND fechaDesde <= cixifechadesde AND fechaHasta >= cixifechahasta ORDER BY idcontabilidad_indicexinflacion);
        resultado = fechaDesde;
    END IF;

    IF (accion = 'actualizarIndice') THEN
        indice = pfiltros->'indice';
        UPDATE contabilidad_indicexinflacion SET cixivalor = CAST(indice->>'cixivalor' AS DOUBLE PRECISION) WHERE indice->>'idcontabilidad_indicexinflacion' = idcontabilidad_indicexinflacion;
        resultado = CONCAT('Indice ', indice->>'idcontabilidad_indicexinflacion', ' actualizado');
    END IF;

    IF (accion = 'ultimoIdIndice') THEN
        SELECT last_value + 1 AS nuevoIndice FROM contabilidad_indicexinflacion_idcontabilidad_indicexinflaci_seq INTO rnuevo;
        resultado = rnuevo.nuevoIndice;
    END IF;

    IF (accion = 'agregarIndice') THEN
        indice = pfiltros->'indice';
        INSERT INTO contabilidad_indicexinflacion (cixivalor, cixifechadesde, cixifechahasta, ciximes_numero) VALUES (CAST(indice->>'cixivalor' AS DOUBLE PRECISION), CAST(indice->>'cixifechadesde' AS DATE), CAST(indice->>'cixifechahasta' AS DATE), CAST(indice->>'ciximes_numero' AS INTEGER));
        resultado = CONCAT('Indice ', indice->>'idcontabilidad_indicexinflacion', ' agregado');
    END IF;

    RETURN resultado;
END;

$function$
