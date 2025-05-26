CREATE OR REPLACE FUNCTION public.expendio_ordenauditada()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSORES
cursoritem refcursor;
cursororden refcursor;

--RECORD    
ritem RECORD;
runitemorden RECORD; 
rtieneimporte RECORD;
rorden RECORD;

--VARIABLES 
imppractica DOUBLE PRECISION;
tieneamuc BOOLEAN; 
impafiliado DOUBLE PRECISION DEFAULT 0.0;
importeamuc DOUBLE PRECISION DEFAULT 0.0;
impsosunc  DOUBLE PRECISION DEFAULT 0.0;
totalamuc DOUBLE PRECISION DEFAULT 0.0;
totalsosunc DOUBLE PRECISION DEFAULT 0.0;
totalafiliado DOUBLE PRECISION DEFAULT 0.0;

---- BelenA importes nuevos que se calculan
imp_practica DOUBLE PRECISION DEFAULT 0.0;
imp_amuc DOUBLE PRECISION DEFAULT 0.0;
imp_sosunc DOUBLE PRECISION DEFAULT 0.0;
imp_afil  DOUBLE PRECISION DEFAULT 0.0;
porcentajesosunc DOUBLE PRECISION DEFAULT 0.0;

laorden BIGINT; 
elcentro INTEGER;
cantidad INTEGER;
res VARCHAR;
BEGIN
     OPEN cursoritem FOR SELECT * 
                         FROM temp_alta_modifica_ficha_medica;
     FETCH cursoritem INTO ritem;
     WHILE  found LOOP

                laorden = ritem.nroorden;
                elcentro = ritem.centro;

                -- Obtengo los datos de la practica sin importar si fue auditada o no
                SELECT INTO runitemorden *
                FROM itemvalorizada 
                NATURAL JOIN item 
                NATURAL JOIN iteminformacion    
                WHERE  nroorden = ritem.nroorden AND centro= ritem.centro 
                       --AND iditemestadotipo=1  --- para iterar sobre todos los item de auditoria
                       AND iditem =ritem.iditem AND centro= ritem.centro;

                --RAISE EXCEPTION 'runitemorden ---------> %', runitemorden;

                --- BelenA - VAS 060525 cambiamos la forma en la que se calculan los montos luego de auditar las practicas

                    imp_practica = runitemorden.iiimporteunitario;   
                    --RAISE NOTICE ' ~ritem.imp_practica %', imp_practica;


                    IF runitemorden.iicoberturaamuc IS NOT NULL THEN
                        imp_amuc = runitemorden.iicoberturaamuc * imp_practica; --Si el afiliado no tiene amuc la cob es 0, sino es lo que indica
                    ELSE    
                        imp_amuc=0;    
                    END IF;

                    IF (ritem.cobertura::float4 /100 + runitemorden.iicoberturaamuc >= 1) THEN  -- ritem.cobertura es de la temporal
                        porcentajesosunc = 1 - runitemorden.iicoberturaamuc ;
                    ELSE
                        porcentajesosunc = ritem.cobertura::float4 /100 ;
                    END IF;

                    imp_sosunc = porcentajesosunc * imp_practica;

                    imp_afil = CASE WHEN (imp_practica - imp_amuc - imp_sosunc)>=0 THEN (imp_practica-imp_amuc-imp_sosunc) ELSE 0 END;


                IF runitemorden.iditemestadotipo=1 THEN

                    UPDATE iteminformacion SET iierror= ritem.iierror, iifechaauditoria= now(), 
                    --iicoberturasosuncauditada = (ritem.cobertura::double precision)/100,
                    iicoberturasosuncauditada = porcentajesosunc,
                    iditemestadotipo = (CASE WHEN ritem.cobertura > 0  THEN 2 ELSE 3 END),
                    iiimporteafiliadounitario=round(CAST(imp_afil AS numeric),2),
                    iiimporteamucunitario=round(CAST(imp_amuc AS numeric),2),
                    iiimportesosuncunitario=round(CAST(imp_sosunc AS numeric),2)

                    WHERE  iditem =ritem.iditem AND centro= ritem.centro;
                    UPDATE item SET cobertura= ritem.cobertura WHERE  iditem =ritem.iditem AND centro= ritem.centro;

                END IF;

               totalafiliado = totalafiliado + imp_afil;
               totalsosunc = totalsosunc + imp_sosunc;
               totalamuc = totalamuc + imp_amuc;

               impafiliado = 0.0;
               importeamuc = 0.0;
               impsosunc= 0.0;
                --RAISE NOTICE ' idpractica -> %, totalafiliado  -> % , totalsosunc -> % , totalamuc -> %', runitemorden.idpractica , totalafiliado, totalsosunc, totalamuc;
    FETCH cursoritem INTO ritem;
    END LOOP;
    CLOSE cursoritem;

    --RAISE EXCEPTION 'totalafiliado  -> % , totalsosunc -> % , totalamuc -> %', totalafiliado, totalsosunc, totalamuc;

--KR 16-04-20 Modifico para que realice las acciones sobre todas las ordenes que estan en la temporal, no sola la primera
--KR 07-05-20 Busco el convenio con el que se expendio la orden para saber si el importe a cargo del afiliado va a efectivo o cta cte

     OPEN cursororden FOR SELECT nroorden, centro, uwpformapagotipodefecto 
                          FROM temp_alta_modifica_ficha_medica 
                          NATURAL JOIN orden 
                          NATURAL JOIN (SELECT DISTINCT idasocconv,idconvenio,acdecripcion 
                                        FROM  asocconvenio 
                                        WHERE acactivo AND aconline 
                          ) as asocconvenio 
                          JOIN w_usuariowebprestador USING(idconvenio) 
--1062 ES usudesa
--2942: usudesab
                          WHERE idusuarioweb<>1062 and idusuarioweb<>2942   
                          --AND   idusuarioweb<>5601 --- VAS 130924 SACO A ROCA UN CONVENIO UNA SOLA FORMA DE PAGOOOOO 
                        -- BelenA 06/05/25 se vuelve a agregar a GralRoca porque usan las ordenes online
                            GROUP BY nroorden, centro, uwpformapagotipodefecto;
     FETCH cursororden INTO rorden;
     WHILE  found LOOP
       laorden = rorden.nroorden;
       elcentro = rorden.centro; 
       SELECT INTO rtieneimporte * FROM importesorden  WHERE nroorden = rorden.nroorden AND centro = rorden.centro;
       IF FOUND THEN  
         
--ahora tengo que recalcular los importes que se guardaron en importesorden e importesrecibo 

        UPDATE importesorden SET importe = round(CAST(totalafiliado AS numeric),2) WHERE idformapagotipos = rorden.uwpformapagotipodefecto AND nroorden = laorden AND centro = elcentro;
        UPDATE importesorden SET importe =  round(CAST(totalamuc AS numeric),2) WHERE idformapagotipos = 1 AND nroorden = laorden AND centro = elcentro;
        UPDATE importesorden SET importe = round(CAST(totalsosunc AS numeric),2) WHERE idformapagotipos = 6 AND nroorden = laorden AND centro = elcentro;

        UPDATE importesrecibo SET importe = round(CAST(totalafiliado AS numeric),2)
           FROM ( SELECT idrecibo, centro FROM ordenrecibo WHERE  nroorden = laorden AND centro = elcentro) AS T
           WHERE idformapagotipos = 2 AND importesrecibo.idrecibo = T.idrecibo AND importesrecibo.centro = T.centro;
        UPDATE importesrecibo SET importe = round(CAST(totalafiliado AS numeric),2)
           FROM ( SELECT idrecibo, centro FROM ordenrecibo WHERE  nroorden = laorden AND centro = elcentro) AS T
           WHERE idformapagotipos = 3 AND importesrecibo.idrecibo = T.idrecibo AND importesrecibo.centro = T.centro;
        UPDATE importesrecibo SET importe =  round(CAST(totalamuc AS numeric),2) 
           FROM ( SELECT idrecibo, centro FROM ordenrecibo WHERE  nroorden = laorden AND centro = elcentro) AS T
           WHERE idformapagotipos = 1 AND importesrecibo.idrecibo = T.idrecibo AND importesrecibo.centro = T.centro;
        UPDATE importesrecibo SET importe = round(CAST(totalsosunc AS numeric),2)  
           FROM ( SELECT idrecibo, centro FROM ordenrecibo WHERE  nroorden = laorden AND centro = elcentro) AS T
           WHERE idformapagotipos = 6 AND importesrecibo.idrecibo = T.idrecibo AND importesrecibo.centro = T.centro;
  
        /*
        UPDATE recibo SET importerecibo= round(CAST(T.totalrecibo AS numeric),2),
                  importeenletras=convertinumeroalenguajenatural(T.totalrecibo::numeric) 
        FROM ( SELECT idrecibo, centro, sum(importe) as totalrecibo FROM ordenrecibo NATURAL JOIN importesrecibo
                                         WHERE  nroorden = laorden AND centro = elcentro
              GROUP BY idrecibo, centro) AS T
        WHERE recibo.idrecibo = T.idrecibo AND recibo.centro = T.centro;
        */

        UPDATE recibo
        SET importerecibo = round(CAST(totalafiliado AS numeric),2)
        ,importeenletras=convertinumeroalenguajenatural(round(CAST(totalafiliado AS numeric),2)) 
        FROM ( SELECT idrecibo, centro FROM ordenrecibo WHERE  nroorden = laorden AND centro = elcentro) AS T
        WHERE recibo.idrecibo = T.idrecibo AND recibo.centro = T.centro;

ELSE 
       INSERT INTO importesorden(nroorden,centro,idformapagotipos,importe) VALUES (laorden,elcentro,rorden.uwpformapagotipodefecto,round(CAST(totalafiliado AS numeric),2) );
       IF totalamuc>0 THEN
            INSERT INTO importesorden(nroorden,centro,idformapagotipos,importe) VALUES (laorden,elcentro,1,round(CAST(totalamuc AS numeric),2) );
       END IF;
       INSERT INTO importesorden(nroorden,centro,idformapagotipos,importe) VALUES (laorden,elcentro,6,round(CAST(totalsosunc AS numeric),2) );

       INSERT INTO importesrecibo ( idrecibo , centro  , idformapagotipos,importe)
                (SELECT idrecibo ,centro ,  idformapagotipos , round(CAST(SUM(importe) AS numeric),2)
                 FROM importesorden NATURAL JOIN ordenrecibo WHERE  nroorden = laorden AND centro = elcentro
                 GROUP BY idformapagotipos, idrecibo,centro ,  idformapagotipos);

        -- Se agrega que se modifique el importe en el recibo
        UPDATE recibo
        SET importerecibo = round(CAST(totalafiliado AS numeric),2)
        ,importeenletras=convertinumeroalenguajenatural(round(CAST(totalafiliado AS numeric),2))
        FROM ( SELECT idrecibo, centro FROM ordenrecibo WHERE  nroorden = laorden AND centro = elcentro) AS T
        WHERE recibo.idrecibo = T.idrecibo AND recibo.centro = T.centro;
    
END IF; 

-- KR 26-07-19 si todos los items de la orden son rechazados, entonces la orden se anula 

 SELECT INTO cantidad count(*) as cant
                     FROM  (
                SELECT count(*) as cantidad
                            FROM iteminformacion NATURAL JOIN itemvalorizada
                            WHERE nroorden = laorden and centro= elcentro
                     ) as items
                     JOIN (
                SELECT count(*) as cantidad
                            FROM iteminformacion NATURAL JOIN itemvalorizada
                            WHERE nroorden = laorden and centro= elcentro AND iditemestadotipo=3
                     ) as itemsauditado USING(cantidad);
 IF cantidad=1 THEN  --se rechazan todos los items
    PERFORM expendio_cambiarestadoorden (laorden, elcentro, 2); 
 END IF; 

--KR 13-4-20 invoco al SP que modifica el valor que paga por practica el afiliado luego de la auditoria

 SELECT INTO res * FROM w_importeafiliadoorden(CONCAT(laorden,'-',elcentro));
FETCH cursororden INTO rorden;
END LOOP;
CLOSE cursororden;

RETURN '';
END;
$function$
