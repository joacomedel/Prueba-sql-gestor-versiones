CREATE OR REPLACE FUNCTION public.asentarconsultarecetario()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

cursororden CURSOR FOR
              SELECT *
              FROM ttorden;

cursorplan CURSOR FOR
              SELECT * FROM ttconsulta;
/*
nrodoc        varchar
centro        integer
idasocconv     bigint
recibo        boolean      esto se usa para asentarrecibo()
cantordenes   integer
tipo          integer
amuc       -> double - puede ser null
efectivo   -> double - puede ser null
debito     -> double - puede ser null
credito    -> double - puede ser null
ctacte     -> double - puede ser null
sosunc     -> double
*/

dato RECORD;
plan RECORD;
recimporteorden RECORD;
rimportesorden RECORD;
rorden RECORD;
rconsumo RECORD;
tipodocu int;
cc integer;
contador integer;
respuesta boolean;
aux double precision;
aux2 double precision;
dif double precision;

BEGIN
    respuesta = false;
	open cursororden;
    FETCH cursororden into dato;
    if nullvalue(dato.cantordenes) then
       cc=1;
    else
        cc = dato.cantordenes;
    end if;
    contador = cc;
    while contador>0 loop	
        --asienta en orden
        --MaLaPi 16-01-2008 Para que verifique su existencia
          SELECT INTO rorden * FROM orden WHERE nroorden = dato.nrorecetario AND centro = dato.centro;
          IF FOUND THEN
             UPDATE orden SET fechaemision =dato.fechaemision , tipo=dato.tipo , idasocconv =dato.idasocconv
                     WHERE nroorden = dato.nrorecetario AND centro = dato.centro;
          ELSE

        	INSERT INTO orden (nroorden,centro,fechaemision,tipo,idasocconv)
                   VALUES (dato.nrorecetario,dato.centro,dato.fechaemision,dato.tipo,dato.idasocconv);
          END IF;
          --MaLaPi 16-01-2008 Para que verifique su existencia
          SELECT INTO rconsumo * FROM consumo WHERE nroorden = dato.nrorecetario AND centro = dato.centro;
          IF FOUND THEN
             UPDATE consumo SET nrodoc = dato.nrodoc ,tipodoc = dato.tipodoc
                    WHERE nroorden = dato.nrorecetario AND centro = dato.centro;
          ELSE
             INSERT INTO consumo (idconsumo,centro,nroorden,nrodoc,tipodoc)
                    VALUES (nextval('"public"."consumo_idconsumo_seq"'),dato.centro,dato.nrorecetario,dato.nrodoc,dato.tipodoc);	
          END IF;
/*open cursorplan;
fetch cursorplan into plan;
INSERT INTO ordconsulta(centro, nroorden, idplancovertura) values(dato.centro, dato.nrorecetario, plan.idplancobertura);*/
            if not nullvalue(dato.amuc) AND (dato.amuc <> 0) then
                 aux = round(CAST(dato.amuc/cc AS numeric),2);
                 /*if contador > 1 then
                    INSERT INTO importesorden
                        VALUES (dato.nrorecetario,dato.centro,1,aux);
                 ELSE
                     if (aux*cc<>dato.amuc) then
                        aux2=aux*cc;
                         dif = dato.amuc-aux2;
                         aux = aux +dif;
                     end if;
                     INSERT INTO importesorden (nroorden,centro,idformapagotipos,importe)
                            VALUES (dato.nrorecetario,dato.centro,1,aux);
                 end if;*/
                --MaLaPi 16-01-2008 Para que verifique su existencia
                IF contador < 2 THEN
                if (aux*cc<>dato.amuc) then
                        aux2=aux*cc;
                         dif = dato.amuc-aux2;
                         aux = aux +dif;
                     end if;
                END IF;
                SELECT INTO rimportesorden * FROM importesorden WHERE nroorden = dato.nrorecetario AND centro = dato.centro AND idformapagotipos = 1;
                IF FOUND THEN
                   UPDATE importesorden SET importe = aux WHERE nroorden = dato.nrorecetario AND centro = dato.centro AND idformapagotipos = 1;
                ELSE
                    INSERT INTO importesorden (nroorden,centro,idformapagotipos,importe)
                              VALUES (dato.nrorecetario,dato.centro,1,aux);
                 END IF;
            end if;
            if not nullvalue(dato.efectivo)  AND (dato.efectivo <> 0) then

                 aux = round(CAST(dato.efectivo/cc AS numeric),2);
                  IF contador < 2 THEN
                     if (aux*cc<>dato.efectivo) then
                        aux2=aux*cc;
                         dif = dato.efectivo-aux2;
                         aux = aux +dif;
                     end if;
                  END IF;
                /* if contador > 1 then
                    INSERT INTO importesorden
                        VALUES (dato.nrorecetario,dato.centro,2,aux);
                 ELSE
                     if (aux*cc<>dato.efectivo) then
                        aux2=aux*cc;
                         dif = dato.efectivo-aux2;
                         aux = aux +dif;
                     end if;
                     INSERT INTO importesorden
                            VALUES (dato.nrorecetario,dato.centro,2,aux);
                 end if;*/
                SELECT INTO rimportesorden * FROM importesorden WHERE nroorden = dato.nrorecetario AND centro = dato.centro AND idformapagotipos = 2;
                IF FOUND THEN
                   UPDATE importesorden SET importe = aux WHERE nroorden = dato.nrorecetario AND centro = dato.centro AND idformapagotipos = 2;
                ELSE
                    INSERT INTO importesorden (nroorden,centro,idformapagotipos,importe)
                              VALUES (dato.nrorecetario,dato.centro,2,aux);
                 END IF;

            end if;
            if not nullvalue(dato.cuentacorriente)  AND (dato.cuentacorriente <> 0) then
             --MaLaPi 16-01-2008 Para que verifique su existencia
                 aux = round(CAST(dato.cuentacorriente/cc AS numeric),2);
                 IF contador < 2 THEN
                     if (aux*cc<>dato.cuentacorriente) then
                        aux2=aux*cc;
                         dif = dato.cuentacorriente-aux2;
                         aux = aux +dif;
                     end if;
                  END IF;
                  SELECT INTO rimportesorden * FROM importesorden WHERE nroorden = dato.nrorecetario AND centro = dato.centro AND idformapagotipos = 3;
                  IF FOUND THEN
                     UPDATE importesorden SET importe = aux WHERE nroorden = dato.nrorecetario AND centro = dato.centro AND idformapagotipos = 3;
                  ELSE
                          INSERT INTO importesorden (nroorden,centro,idformapagotipos,importe)
                              VALUES (dato.nrorecetario,dato.centro,3,aux);
                  END IF;
                 /*if contador > 1 then
                    INSERT INTO importesorden
                        VALUES (dato.nrorecetario,dato.centro,3,aux);
                 ELSE
                     if (aux*cc<>dato.cuentacorriente) then
                        aux2=aux*cc;
                         dif = dato.cuentacorriente-aux2;
                         aux = aux +dif;
                     end if;
                     INSERT INTO importesorden
                            VALUES (dato.nrorecetario,dato.centro,3,aux);
                 end if;*/

                -- INSERT INTO importesorden
                  --      VALUES (dato.nrorecetario,dato.centro,3,round(cast(dato.cuentacorriente/cc as numeric),2));
            end if;
           if not nullvalue(dato.debito)  AND (dato.debito <> 0) then

             aux = round(CAST(dato.debito/cc AS numeric),2);
              --MaLaPi 16-01-2008 Para que verifique su existencia
                 IF contador < 2 THEN
                      if (aux*cc<>dato.debito) then
                        aux2=aux*cc;
                         dif = dato.debito-aux2;
                         aux = aux +dif;
                     end if;
                  END IF;
                  SELECT INTO rimportesorden * FROM importesorden WHERE nroorden = dato.nrorecetario AND centro = dato.centro AND idformapagotipos = 4;
                  IF FOUND THEN
                     UPDATE importesorden SET importe = aux WHERE nroorden = dato.nrorecetario AND centro = dato.centro AND idformapagotipos = 4;
                  ELSE
                          INSERT INTO importesorden (nroorden,centro,idformapagotipos,importe)
                              VALUES (dato.nrorecetario,dato.centro,4,aux);
                  END IF;
                /* if contador > 1 then
                    INSERT INTO importesorden
                        VALUES (dato.nrorecetario,dato.centro,4,aux);
                 ELSE
                     if (aux*cc<>dato.debito) then
                        aux2=aux*cc;
                         dif = dato.debito-aux2;
                         aux = aux +dif;
                     end if;
                     INSERT INTO importesorden
                            VALUES (dato.nrorecetario,dato.centro,4,aux);
                 end if;*/

            --    INSERT INTO importesorden
             --           VALUES (dato.nrorecetario,dato.centro,4,round(cast(dato.debito/cc as numeric),2));
            end if;
            if not nullvalue(dato.credito)  AND (dato.credito <> 0) then

             aux = round(CAST(dato.credito/cc AS numeric),2);
             --MaLaPi 16-01-2008 Para que verifique su existencia
                 IF contador < 2 THEN
                       if (aux*cc<>dato.credito) then
                        aux2=aux*cc;
                         dif = dato.credito-aux2;
                         aux = aux +dif;
                     end if;
                  END IF;
                  SELECT INTO rimportesorden * FROM importesorden WHERE nroorden = dato.nrorecetario AND centro = dato.centro AND idformapagotipos = 5;
                  IF FOUND THEN
                     UPDATE importesorden SET importe = aux WHERE nroorden = dato.nrorecetario AND centro = dato.centro AND idformapagotipos = 5;
                  ELSE
                          INSERT INTO importesorden (nroorden,centro,idformapagotipos,importe)
                              VALUES (dato.nrorecetario,dato.centro,5,aux);
                  END IF;

                /* if contador > 1 then
                    INSERT INTO importesorden
                        VALUES (dato.nrorecetario,dato.centro,5,aux);
                 ELSE
                     if (aux*cc<>dato.credito) then
                        aux2=aux*cc;
                         dif = dato.credito-aux2;
                         aux = aux +dif;
                     end if;
                     INSERT INTO importesorden
                            VALUES (dato.nrorecetario,dato.centro,5,aux);
                 end if;
            */
             --    INSERT INTO importesorden
              --          VALUES (dato.nrorecetario,dato.centro,5,round(cast(dato.credito/cc as numeric),2));
            end if;
            if not nullvalue(dato.sosunc)  AND (dato.sosunc <> 0) then
                 /*INSERT INTO importesorden
                        VALUES (dato.nrorecetario,dato.centro,6,round(cast(dato.sosunc/cc as numeric),2));*/
                 --MaLaPi 16-01-2008 Para que verifique su existencia
                  SELECT INTO rimportesorden * FROM importesorden WHERE nroorden = dato.nrorecetario AND centro = dato.centro AND idformapagotipos = 6;
                  IF FOUND THEN
                     UPDATE importesorden SET importe = aux WHERE nroorden = dato.nrorecetario AND centro = dato.centro AND idformapagotipos = 6;
                  ELSE
                          INSERT INTO importesorden (nroorden,centro,idformapagotipos,importe)
                              VALUES (dato.nrorecetario,dato.centro,6,ound(cast(dato.sosunc/cc as numeric),2));
                  END IF;

            end if;

            SELECT INTO recimporteorden * FROM importesorden WHERE nroorden = dato.nrorecetario;
            IF NOT FOUND THEN
               INSERT INTO importesorden (nroorden,centro,idformapagotipos,importe)
                        VALUES (dato.nrorecetario,dato.centro,10,0);
            END IF;
    --  inserta las ordenes en ttordenesgeneradas
            INSERT INTO ttordenesgeneradas(nroorden,centro)
                VALUES (dato.nrorecetario,dato.centro);
		--VALUES (100000,1);
            contador=contador-1;
    end loop;
    close cursororden;
    respuesta = true;
    return respuesta;	
END;
$function$
