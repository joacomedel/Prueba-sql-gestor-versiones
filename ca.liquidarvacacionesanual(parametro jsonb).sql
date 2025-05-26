CREATE OR REPLACE FUNCTION ca.liquidarvacacionesanual(parametro jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
* Procedimiento que calcula la cantidad de dias que corresponde de vacaciones de todos los empleados activos y lo almacena en la tabla "...."
* Se envia el nrodoc de la persona que esta ejecutando el proceso
* SELECT ca.liquidarvacacionesanual('{"nrodoc": "43947118"}')
*/

DECLARE
    --CURSOR
    cpersona refcursor;
    --RECORD
	rdatospersona record;
	rdatoscalcvacaciones record;
	rdatosexistelicencia record;
	rdatoslicencia record;
	rdatoslicenciafarm record;
    --VARIABLES
	fechaproceso date;
    usuariojson jsonb;
BEGIN

    SET search_path = ca, pg_catalog;
    fechaproceso = '2024-01-01';
    -- fechaproceso = CURRENT_DATE;

    select into usuariojson * FROM public.sys_dar_usuario_web(parametro);
    
    -- Verifico si la licencia existe
    SELECT INTO rdatoslicencia * 
    FROM ca.licenciatipo 
    WHERE idconveniolic = 1 AND TRIM(ltdescripcion) ILIKE CONCAT('LICENCIA ANUAL %', EXTRACT(YEAR FROM fechaproceso), '%')
    ORDER BY ltdecreto;

    -- CREO LA LAO QUE CORRESPONDE AL AÑO
    IF NOT FOUND THEN 
        INSERT INTO ca.licenciatipo (ltdescripcion,	ltdecreto,	ltdiascorridos,	ltmigrarsueldo,	ltpordia,	ltcanhoraspermiso,	idconveniolic,	ltpermiterango)
        VALUES(CONCAT('LICENCIA ANUAL ORDINARIA AÑO ', EXTRACT(YEAR FROM fechaproceso)), CONCAT('LICENCIA ANUAL ORDINARIA AÑO ', EXTRACT(YEAR FROM fechaproceso)), true, false, false, null, 1, true)
        RETURNING * INTO rdatoslicencia; -- Captura todo lo generado 

        RAISE NOTICE 'licencia generada, %', rdatoslicencia;
    END IF;

    --Verifico si la licencia de farmacia existe
    SELECT INTO rdatoslicenciafarm * 
    FROM ca.licenciatipo 
    WHERE idconveniolic = 2 AND TRIM(ltdescripcion) ILIKE CONCAT('LICENCIA ANUAL %', EXTRACT(YEAR FROM fechaproceso), '%')
    ORDER BY ltdecreto;
    -- CREO LA LAO QUE CORRESPONDE AL AÑO EN FARMACIA
    IF NOT FOUND THEN 
        INSERT INTO ca.licenciatipo (ltdescripcion,	ltdecreto,	ltdiascorridos,	ltmigrarsueldo,	ltpordia,	ltcanhoraspermiso,	idconveniolic,	ltpermiterango)
        VALUES(CONCAT('LICENCIA ANUAL ORDINARIA AÑO ', EXTRACT(YEAR FROM fechaproceso), ' (FARMA)'), CONCAT('LICENCIA ANUAL ORDINARIA AÑO ', EXTRACT(YEAR FROM fechaproceso)), true, false, false, null, 2, true)
        RETURNING * INTO rdatoslicenciafarm; -- Captura todo lo generado 

        RAISE NOTICE 'licencia generada, %', rdatoslicencia;
    END IF;
    
    --VERIFICO SI LA LICENCIA EXISTE EN "licenciatipoonline"
    SELECT INTO rdatosexistelicencia * FROM ca.licenciatipoonline WHERE idlicenciatipo = rdatoslicencia.idlicenciatipo;
    IF NOT FOUND THEN
        INSERT INTO ca.licenciatipoonline (idlicenciatipo)
        VALUES (rdatoslicencia.idlicenciatipo);
    END IF;

    --VERIFICO SI LA LICENCIA DE FARMACIA EXISTE EN "licenciatipoonline"
    SELECT INTO rdatosexistelicencia * FROM ca.licenciatipoonline WHERE idlicenciatipo = rdatoslicenciafarm.idlicenciatipo;
    IF NOT FOUND THEN
        INSERT INTO ca.licenciatipoonline (idlicenciatipo)
        VALUES (rdatoslicenciafarm.idlicenciatipo);
    END IF;

    OPEN cpersona for SELECT * FROM ca.persona 
            NATURAL JOIN ca.empleado
            NATURAL JOIN ca.categoriaempleado
            NATURAL JOIN ca.grupoliquidacionempleado
        WHERE
           cefechainicio <=NOW() AND  
           (cefechafin>=NOW() or nullvalue(cefechafin))
           AND idgrupoliquidaciontipo = 1 
           AND idcategoriatipo=1;
    LOOP
    FETCH cpersona INTO rdatospersona;		
        EXIT WHEN NOT FOUND;

        --Verifico que si existe la configuracion de la licencia para la persona
        SELECT INTO rdatosexistelicencia * FROM ca.licenciatipoconfiguracion WHERE idpersona = rdatospersona.idpersona AND idlicenciatipo = rdatoslicencia.idlicenciatipo;

        IF NOT FOUND THEN
            IF fechaproceso >= rdatospersona.emfechaantiguedadvacaciones THEN
                PERFORM ca.liquidarvacaciones(fechaproceso, rdatospersona.idpersona);
                -- Busco los datos de la temporal
                SELECT INTO rdatoscalcvacaciones * FROM liquidacionvacacionesempleados WHERE idpersona = rdatospersona.idpersona;
                -- RAISE EXCEPTION 'prueba, (%), (%)', rdatospersona, rdatoscalcvacaciones;
                IF rdatospersona.idconvenio = 1 THEN
                    -- Genero el registro en la tabla de licenciatipoconfiguracion
                    INSERT INTO ca.licenciatipoconfiguracion 
                    (idlicenciatipo, ltcdescripcion,	ltccontidaddias,	ltccontidaddiassaldos,	ltcusuariocarga, idpersona)
                    VALUES (rdatoslicencia.idlicenciatipo, CONCAT('L.A.O. - ', EXTRACT(YEAR FROM fechaproceso)), rdatoscalcvacaciones.cantdiasvacaciones, 0, CAST(usuariojson->>'idusuario' AS INTEGER), rdatoscalcvacaciones.idpersona);
                ELSE
                    INSERT INTO ca.licenciatipoconfiguracion 
                    (idlicenciatipo, ltcdescripcion,	ltccontidaddias,	ltccontidaddiassaldos,	ltcusuariocarga, idpersona)
                    VALUES (rdatoslicenciafarm.idlicenciatipo, CONCAT('L.A.O. (FARMA) - ', EXTRACT(YEAR FROM fechaproceso)), rdatoscalcvacaciones.cantdiasvacaciones, 0, CAST(usuariojson->>'idusuario' AS INTEGER), rdatoscalcvacaciones.idpersona);
                END IF;
                RAISE NOTICE 'Configuracion, (%) -- (%) -- (%)', rdatoscalcvacaciones, rdatospersona, fechaproceso;
            END IF;
        END IF;

    END LOOP;
    CLOSE cpersona;
    
 return true;
END;
$function$
