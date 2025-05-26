CREATE OR REPLACE FUNCTION public.w_alta_controldosisafiliado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*

SELECT * FROM w_alta_controlDosisAfiliado('{"idfichamedicainfomedicamento": 25607}'::jsonb);

*/

DECLARE
    rrespuestajson jsonb;
    rrespuesta RECORD;
    temp_row RECORD;
    dosis_total FLOAT;
    idPraxysControlDosisAnterior character varying;
BEGIN
--REPLACE(source, from_text, to_text);
    CREATE TEMP TABLE temp_dosisDiaria AS
    SELECT CAST(unnest(
        string_to_array(
            SUBSTRING(replace (fichamedicainfomedicamento.fmimdosisdiaria,',','.') 
            FROM 1 FOR (POSITION(' ' in replace (fichamedicainfomedicamento.fmimdosisdiaria,',','.') )-1)), '/'
        )
    ) AS FLOAT) AS dosis 
    FROM
	fichamedicainfomedicamento NATURAL JOIN
		fichamedicainfo NATURAL JOIN
		fichamedicatratamiento NATURAL JOIN 
		fichamedica NATURAL JOIN
		persona NATURAL JOIN
		monodroga as md LEFT JOIN
		manextra as mx USING(idmonodroga) LEFT JOIN
		medicamento as me USING(mnroregistro)
	WHERE idfichamedicainfomedicamento =  parametro->>'idfichamedicainfomedicamento'
	GROUP BY nrodoc,barra,fmimdosisdiaria,fmimfechafin,fmifecha,fmimcobertura;

	SELECT SUM(dosis) INTO dosis_total
    FROM temp_dosisDiaria;

    DROP TABLE temp_dosisDiaria;

    SELECT INTO rrespuesta 
        --ROW_NUMBER() OVER () as clave,
        array_agg(mnroregistro ORDER BY mnroregistro DESC) AS codigosalfabetareferencia,
        --mnroregistro as codigoalfabetareferencia,
        CONCAT(nrodoc,lpad(barra::text, 3, '0'))AS NroAfiliado,
        -- iddrogaprincipal_praxys	as IdDroga,
        -- drogaprincipal as Droga,
        --CAST(SUBSTRING(fmimdosisdiaria FROM 1 FOR (POSITION(' 'in fmimdosisdiaria)-1)) AS FLOAT) as DosisAlerta,
        dosis_total as DosisAlerta,
        SUBSTRING(fmimdosisdiaria FROM (POSITION(' 'in fmimdosisdiaria)+1)) as IdUnidadDosisAlerta,
        CASE 
            WHEN fmimfechafin - fmifecha = 0 THEN 365 
            ELSE fmimfechafin - fmifecha
        END AS DiasTratamiento,
        --fmimfechafin as FechaVencimiento,
        CASE
            WHEN fmimcobertura < 1 THEN fmimcobertura * 100
            ELSE fmimcobertura
        END AS PorcentajeCobertura
        -- idnombresdrogas_praxys as IdNombresDrogas,
        -- descripcion as NombresDrogas
        --parametro->>'idfichamedicainfomedicamento' AS idfichamedicainfomedicamento
    FROM 
        fichamedicainfomedicamento NATURAL JOIN
        fichamedicainfo NATURAL JOIN
        fichamedicatratamiento NATURAL JOIN 
        fichamedica NATURAL JOIN
        persona NATURAL JOIN
        monodroga as md LEFT JOIN
        manextra as mx USING(idmonodroga) LEFT JOIN
        medicamento as me USING(mnroregistro)
    WHERE idfichamedicainfomedicamento =  parametro->>'idfichamedicainfomedicamento'
    GROUP BY nrodoc,barra,fmimdosisdiaria,fmimfechafin,fmifecha,fmimcobertura;

    SELECT ultimoidcontroldosispraxys(parametro)::jsonb->>'idControlDosisPraxys' INTO idPraxysControlDosisAnterior;

    --rrespuestajson = (SELECT jsonb_agg(row_to_json(t)) FROM temp_w_alta_controldosisafiliado t);
    rrespuestajson = row_to_json(rrespuesta);
    rrespuestajson = rrespuestajson::jsonb || jsonb_build_object('idfichamedicainfomedicamento',parametro->>'idfichamedicainfomedicamento');
    rrespuestajson = rrespuestajson::jsonb || jsonb_build_object('idPraxysControlDosisAnterior',idPraxysControlDosisAnterior);

    RETURN rrespuestajson;

END;$function$
