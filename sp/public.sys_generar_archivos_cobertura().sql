CREATE OR REPLACE FUNCTION public.sys_generar_archivos_cobertura()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	clog refcursor;
	pers RECORD;
        rrecibo RECORD;
        vidpadron varchar;
BEGIN

        INSERT INTO sys_cobertura_farmacia (mnroregistro,multiplicador,mcodbarra,mtroquel,fechaini)  (
        SELECT DISTINCT
	        m.mnroregistro,
        	multiplicador,
                mcodbarra,
                mtroquel,
                to_char(fechainivigencia,'YYYYMMDD') as fechaini
        FROM medicamento AS m
        NATURAL JOIN  manextra
        NATURAL JOIN plancoberturafarmacia
        LEFT JOIN sys_cobertura_farmacia using(mnroregistro,multiplicador,mcodbarra,mtroquel)
        WHERE nullvalue(fechafinvigencia) 
                and not nullvalue(mcodbarra)
                and multiplicador = 0.70
                AND nullvalue(idcoberturafacrmacia)
                AND idfarmtipoventa <> 1 --Sosunc no cubre medicamentos de venta libre
                AND idfarmtipoventa <> 7 --- No clasificado
                AND idfarmtipoventa <> 5 -- Pendiente
                AND not nullvalue(mtroquel)

                --and multiplicador = 0.55s
        );

        INSERT INTO sys_cobertura_farmacia (mnroregistro,multiplicador,mcodbarra,mtroquel,fechaini)  (
        select DISTINCT
	        m.mnroregistro,
        	multiplicador as multiplicador,
                mcodbarra,
                mtroquel,
                to_char(fechainivigencia,'YYYYMMDD') as fechaini
        FROM medicamento AS m
        NATURAL JOIN  manextra
        NATURAL JOIN plancoberturafarmacia
        LEFT JOIN sys_cobertura_farmacia using(mnroregistro,multiplicador,mcodbarra,mtroquel)
        WHERE nullvalue(fechafinvigencia) 
        and not nullvalue(mcodbarra)
        --and multiplicador = 0.70
                AND idfarmtipoventa <> 1 --Sosunc no cubre medicamentos de venta libre
                AND idfarmtipoventa <> 7 --- No clasificado
                AND idfarmtipoventa <> 5 -- Pendiente
                AND nullvalue(idcoberturafacrmacia)
                and (multiplicador = 0.55 OR multiplicador = 1  OR multiplicador = 0.4)
                AND not nullvalue(mtroquel)
        );


        SELECT INTO vidpadron afiliaciones_generaarchivopadronbeneficiarios_observer(concat('{tipoarchivo=Observer_Informar, fechafin=',current_date,'}')) as idpadron; 
        IF FOUND THEN 
--300-1
--vidpadron = '300-1';
        CREATE TEMP TABLE sys_archivotrazabilidadafiliado AS (
        select idarchivostrazabilidad,idcentroarchivostrazabilidad,nrodoc,tipodoc,atalinea 
         from far_archivotrazabilidadafiliado 
         where idarchivostrazabilidad = split_part(vidpadron::text,'-',1)::integer  and idcentroarchivostrazabilidad = split_part(vidpadron::text,'-',2)::integer
);

        COPY (select idarchivostrazabilidad,idcentroarchivostrazabilidad,nrodoc,tipodoc,atalinea from sys_archivotrazabilidadafiliado) To '/var/lib/pgsql/validacion/datos/afiliados.csv' WITH (FORMAT CSV, HEADER);


        END IF;
---- Generacion de archivo de caracteristicas

 SELECT INTO vidpadron afiliaciones_generaarchivopadron_caracteristicas_observer(concat('{tipoarchivo=Observer_caract_afil, fechafin=',current_date,'}')) as idpadron; 

         IF FOUND THEN 

        DROP TABLE IF EXISTS sys_archivotrazabilidadafiliado;

        CREATE TEMP TABLE sys_archivotrazabilidadafiliado AS (
        select idarchivostrazabilidad,idcentroarchivostrazabilidad,nrodoc,tipodoc,atalinea 
         from far_archivotrazabilidadafiliado 
         where idarchivostrazabilidad = split_part(vidpadron::text,'-',1)::integer  and idcentroarchivostrazabilidad = split_part(vidpadron::text,'-',2)::integer
);

        COPY (select idarchivostrazabilidad,idcentroarchivostrazabilidad,nrodoc,tipodoc,atalinea from sys_archivotrazabilidadafiliado) To '/var/lib/pgsql/validacion/datos/caracteristicas.csv' WITH (FORMAT CSV, HEADER);


        END IF;

-----FIN caracteristicas


        --COPY (SELECT mnroregistro,multiplicador,mcodbarra,mtroquel,fechaini from sys_cobertura_farmacia WHERE multiplicador <> 0.70) To '/var/lib/pgsql/validacion/datos/cobertura_55.csv' WITH (FORMAT CSV, HEADER);
COPY (SELECT mnroregistro,multiplicador,mcodbarra,mtroquel,fechaini from sys_cobertura_farmacia natural join medicamento natural join manextra where idfarmtipoventa in (2,3,4,6) AND multiplicador <> 0.70) To '/var/lib/pgsql/validacion/datos/cobertura_55.csv' WITH (FORMAT CSV, HEADER);
        --COPY (SELECT mnroregistro,multiplicador,mcodbarra,mtroquel,fechaini from sys_cobertura_farmacia WHERE multiplicador = 0.70) To '/var/lib/pgsql/validacion/datos/cobertura_70.csv' WITH (FORMAT CSV, HEADER);

COPY (SELECT mnroregistro,multiplicador,mcodbarra,mtroquel,fechaini from sys_cobertura_farmacia natural join medicamento natural join manextra where idfarmtipoventa in (2,3,4,6) AND multiplicador = 0.70) To '/var/lib/pgsql/validacion/datos/cobertura_70.csv' WITH (FORMAT CSV, HEADER);
        return 'true';
END;
$function$
