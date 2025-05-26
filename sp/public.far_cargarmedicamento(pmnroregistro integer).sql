CREATE OR REPLACE FUNCTION public.far_cargarmedicamento(pmnroregistro integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare

re boolean;
elidarticulo bigint;

rpreciosugerido RECORD;
rmedicamento RECORD;
rfarmedicamento RECORD;

rmedicamentosys RECORD;

rarticulo RECORD;

rmed RECORD;
rverifica RECORD;
rarti RECORD;

begin

re = false;

--Malapi 25-08-2015 Verifico si existe el medicamento como articulo de la farmacia

SELECT INTO rmed * 
FROM medicamento 
WHERE mnroregistro=pmnroregistro;

RAISE NOTICE 'Voy a cargar el Nro.Registro (%)',pmnroregistro;

IF FOUND THEN 
    -- Busco articulo
    SELECT INTO rarti * 
    FROM far_articulo 
    WHERE  acodigobarra=rmed.mcodbarra;
    
    IF FOUND THEN
        -- 24-09-2019 MaLaPi Verifico si ese articulo ya no existe con otro nro de registro
        SELECT INTO rverifica * 
        FROM far_medicamento 
        WHERE  
            idarticulo = rarti.idarticulo 
            AND idcentroarticulo = rarti.idcentroarticulo;
                  
        IF FOUND THEN 
            -- Guardo registro
            INSERT INTO far_medicamentohistorico(idarticulo,idcentroarticulo,mnroregistro,nomenclado,mhidusuario)
            VALUES(rverifica.idarticulo,rverifica.idcentroarticulo,rverifica.mnroregistro,rmed.nomenclado,sys_dar_usuarioactual());

            -- Limpiaza vinculos 
            DELETE FROM far_medicamento WHERE mnroregistro=pmnroregistro AND nomenclado=rmed.nomenclado;

            UPDATE far_medicamento 
            SET mnroregistro =pmnroregistro ,nomenclado = rmed.nomenclado 
            WHERE idarticulo = rarti.idarticulo AND idcentroarticulo = rarti.idcentroarticulo;

        ELSE

            -- Controlo que el mnroregistro no ese vinculado con otro articulo
             SELECT INTO rverifica * 
             FROM far_medicamento 
             WHERE   
                mnroregistro=pmnroregistro
                AND nomenclado=rmed.nomenclado;

            IF FOUND THEN
                UPDATE far_medicamento 
                SET idarticulo =rarti.idarticulo ,idcentroarticulo = rarti.idcentroarticulo
                WHERE  
                    mnroregistro=pmnroregistro
                    AND nomenclado=rmed.nomenclado;
            ELSE
                INSERT INTO far_medicamento(idarticulo,idcentroarticulo,mnroregistro,nomenclado)
                VALUES(rarti.idarticulo,rarti.idcentroarticulo,pmnroregistro,rmed.nomenclado);
            END IF;
        END IF;

        -- Si el articulo tiene la marca de baja en kairos, marco que ya no es un articulo kairos 
        SELECT INTO rmedicamentosys * FROM medicamentosys WHERE mnroregistro=pmnroregistro AND nullvalue(idvalor) AND mbaja=1;

        -- NUEVO 26/10/2023
        IF FOUND THEN
            UPDATE far_articulo SET apreciokairos=false
            WHERE  
                idarticulo=rarti.idarticulo
                AND idcentroarticulo=rarti.idcentroarticulo;
        END IF;
    ELSE 

        -- Si no existe un articulo con ese codigo de barra 


        -- Creo temporal con los datos del articulo
        IF NOT  iftableexists('far_articulo_temp') THEN 
            CREATE TEMP TABLE far_articulo_temp (   
                idarticulo bigint,  
                idrubro INTEGER,   
                adescripcion VARCHAR,   
                astockmin DOUBLE PRECISION ,  
                astockmax DOUBLE PRECISION ,  
                acomentario TEXT,   
                idiva BIGINT,  
                adescuento DOUBLE PRECISION,  
                acodigointerno BIGINT,  
                acodigobarra VARCHAR,  
                apreciokairos BOOLEAN DEFAULT false,  
                afechavto DATE,  
                aprecioventa DOUBLE PRECISION,  
                accion VARCHAR,  
                idarticulopadre bigint,  
                afraccion DOUBLE PRECISION DEFAULT 1,  
                apreciocompra DOUBLE PRECISION,   
                idcentroarticulo INTEGER DEFAULT centro(),   
                idusuario INTEGER,   
                idprecioarticulosugerido INTEGER,   
                idcentroprecioarticulosuerido INTEGER,  
                afactorcorreccion DOUBLE PRECISION DEFAULT 1, 
                motivo  VARCHAR,
                idcentroarticulopadre INTEGER,
                mnroregistro INTEGER
                ) ;

        ELSE
            DELETE FROM far_articulo_temp;
        END IF;

        -- Reviso si no cambio de codigo de barra 
        SELECT INTO rarti * 
        FROM far_articulo 
        NATURAL JOIN far_medicamento
        WHERE   
                mnroregistro=pmnroregistro
                AND nomenclado=rmed.nomenclado;
        
        IF FOUND THEN

             RAISE NOTICE 'Voy a modificacodigobarra el articulo Nro.Registro (%)',pmnroregistro;
                           
            INSERT INTO far_articulo_temp (idarticulo,idcentroarticulo,mnroregistro,acodigobarra,idiva,accion)
                SELECT 
                idarticulo,
                idcentroarticulo,
                pmnroregistro,
                medicamento.mcodbarra,
                CASE WHEN msys.iva=1 THEN 2 ELSE 1 END,
                'modificacodigobarra'
            FROM medicamento
            NATURAL JOIN valormedicamento
            NATURAL JOIN far_medicamento
            -- Agrego para obtener mbaja y iva 
            LEFT JOIN medicamentosys as msys ON (msys.mnroregistro=medicamento.mnroregistro AND msys.idvalor=valormedicamento.idvalor)
            WHERE   
                medicamento.mnroregistro=pmnroregistro 
                AND nullvalue(vmfechafin)
            LIMIT 1;

        ELSE
                            
            RAISE NOTICE 'Voy a insertar el articulo Nro.Registro (%)',pmnroregistro;
                           
            INSERT INTO far_articulo_temp (idrubro,adescripcion,astockmin,astockmax,acomentario,idiva,adescuento,acodigobarra,accion,aprecioventa,apreciokairos,idusuario,mnroregistro)
                SELECT 
                    4,
                    concat(medicamento.mnombre,' ',medicamento.mpresentacion),0,0,'',
                    CASE WHEN msys.iva=1 THEN 2 ELSE 1 END,
                    0,
                    CASE WHEN nullvalue(medicamento.mcodbarra) THEN (nextval('codigosbarrasnulos')*100+centro())::text ELSE medicamento.mcodbarra END 
                    ,'insertar',
                    valormedicamento.vmimporte,
                    CASE WHEN msys.mbaja=1 THEN false ELSE true END ,
                    25,
                    pmnroregistro
                FROM medicamento
                NATURAL JOIN valormedicamento
                -- Agrego para obtener mbaja y iva 
                LEFT JOIN medicamentosys as msys ON (msys.mnroregistro=medicamento.mnroregistro AND msys.idvalor=valormedicamento.idvalor)
                WHERE   
                    medicamento.mnroregistro=pmnroregistro 
                    AND nullvalue(vmfechafin)
                LIMIT 1;

        
            SELECT INTO rmedicamento * FROM medicamento WHERE mnroregistro=pmnroregistro LIMIT 1;
            --se puede cambiar por un performace 
            SELECT * into re FROM far_abmarticulo();

            -- en far_abmarticulo se le agrega el idarticulo en caso de hacer un insert 
            SELECT INTO rarticulo * FROM far_articulo_temp WHERE mnroregistro=pmnroregistro LIMIT 1;

            IF NOT nullvalue(rarticulo.idarticulo)  THEN  

                SELECT INTO rfarmedicamento * 
                FROM far_medicamento 
                WHERE  
                    mnroregistro=pmnroregistro
                    AND nomenclado=rmedicamento.nomenclado;
                -- Si no existe un registro para el mnroregistro hago un insert 
                IF NOT FOUND THEN
                    INSERT INTO far_medicamento(idarticulo,idcentroarticulo,mnroregistro,nomenclado)
                    VALUES(rarticulo.idarticulo,rarticulo.idcentroarticulo,pmnroregistro,rmed.nomenclado);
                ELSE 
                    -- Si existe, guardo hist del los datos actuales 
                    INSERT INTO far_medicamentohistorico(idarticulo,idcentroarticulo,mnroregistro,nomenclado,mhidusuario)
                    VALUES(rfarmedicamento.idarticulo,rfarmedicamento.idcentroarticulo,pmnroregistro,rmed.nomenclado,sys_dar_usuarioactual());
                    
                    -- UPDATE con el nuevo idarticulo
                    UPDATE far_medicamento 
                    SET     
                        idarticulo =rarticulo.idarticulo 
                        ,idcentroarticulo = rarticulo.idcentroarticulo
                    WHERE  
                        mnroregistro=pmnroregistro
                        AND nomenclado=rmedicamento.nomenclado;
                END IF;
                
                -- far_abmarticulo deja registro de precio sugerido, es necesario marcar como aprobado el registro 
                SELECT INTO rpreciosugerido * 
                FROM far_precioarticulosugerido 
                WHERE   
                    idarticulo = rarticulo.idarticulo 
                    AND idcentroarticulo = rarticulo.idcentroarticulo
                    AND nullvalue(pasfechafin);
                
                IF FOUND THEN 

                    UPDATE far_articulo_temp 
                    SET 
                        idprecioarticulosugerido= rpreciosugerido.idprecioarticulosugerido,         
                        idcentroprecioarticulosuerido = rpreciosugerido.idcentroprecioarticulosuerido, 
                        motivo = 'GA - Al dar de alta un medicamento';
                    
                    SELECT * into re FROM far_modificarconpreciosugerido();
            
                END IF;
            END IF;
        END IF;



    END IF;
END IF;

return re;
end;$function$
