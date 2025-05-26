CREATE OR REPLACE FUNCTION public.asentarorden(tipoc integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

cursororden CURSOR FOR
              SELECT *
              FROM ttorden;
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
resp bigint;
tipodocu int;
cc integer;
contador integer;
respuesta boolean;
aux double precision;
aux2 double precision;
dif double precision;

BEGIN
    respuesta = false;
    resp = 0;
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
        	INSERT INTO orden
                   VALUES (nextval('"public"."orden_nroorden_seq"'),dato.centro,CURRENT_TIMESTAMP,dato.tipo,dato.idasocconv);
            resp = currval('"public"."orden_nroorden_seq"');
	        SELECT tipodoc INTO tipodocu
                   FROM persona
                   WHERE nrodoc = dato.nrodoc;
	--aienta en consumo
            INSERT INTO consumo
                    VALUES (nextval('"public"."consumo_idconsumo_seq"'),dato.centro,resp,dato.nrodoc,tipodocu);	
    --asienta en importesorden
            if not nullvalue(dato.amuc) AND (dato.amuc <> 0) then
                 aux = round(CAST(dato.amuc/cc AS numeric),2);
                 if contador > 1 then
                    INSERT INTO importesorden
                        VALUES (resp,dato.centro,1,aux);
                 ELSE
                     if (aux*cc<>dato.amuc) then
                        aux2=aux*cc;
                         dif = dato.amuc-aux2;
                         aux = aux +dif;
                     end if;
                     INSERT INTO importesorden
                            VALUES (resp,dato.centro,1,aux);
                 end if;
            end if;
            if not nullvalue(dato.efectivo)  AND (dato.efectivo <> 0) then

                 aux = round(CAST(dato.efectivo/cc AS numeric),2);
                 if contador > 1 then
                    INSERT INTO importesorden
                        VALUES (resp,dato.centro,2,aux);
                 ELSE
                     if (aux*cc<>dato.efectivo) then
                        aux2=aux*cc;
                         dif = dato.efectivo-aux2;
                         aux = aux +dif;
                     end if;
                     INSERT INTO importesorden
                            VALUES (resp,dato.centro,2,aux);
                 end if;

            end if;
            if not nullvalue(dato.cuentacorriente)  AND (dato.cuentacorriente <> 0) then

                 aux = round(CAST(dato.cuentacorriente/cc AS numeric),2);
                 if contador > 1 then
                    INSERT INTO importesorden
                        VALUES (resp,dato.centro,3,aux);
                 ELSE
                     if (aux*cc<>dato.cuentacorriente) then
                        aux2=aux*cc;
                         dif = dato.cuentacorriente-aux2;
                         aux = aux +dif;
                     end if;
                     INSERT INTO importesorden
                            VALUES (resp,dato.centro,3,aux);
                 end if;
                -- INSERT INTO importesorden
                  --      VALUES (resp,dato.centro,3,round(cast(dato.cuentacorriente/cc as numeric),2));
            end if;
           if not nullvalue(dato.debito)  AND (dato.debito <> 0) then

             aux = round(CAST(dato.debito/cc AS numeric),2);
                 if contador > 1 then
                    INSERT INTO importesorden
                        VALUES (resp,dato.centro,4,aux);
                 ELSE
                     if (aux*cc<>dato.debito) then
                        aux2=aux*cc;
                         dif = dato.debito-aux2;
                         aux = aux +dif;
                     end if;
                     INSERT INTO importesorden
                            VALUES (resp,dato.centro,4,aux);
                 end if;

            --    INSERT INTO importesorden
             --           VALUES (resp,dato.centro,4,round(cast(dato.debito/cc as numeric),2));
            end if;
            if not nullvalue(dato.credito)  AND (dato.credito <> 0) then

             aux = round(CAST(dato.credito/cc AS numeric),2);
                 if contador > 1 then
                    INSERT INTO importesorden
                        VALUES (resp,dato.centro,5,aux);
                 ELSE
                     if (aux*cc<>dato.credito) then
                        aux2=aux*cc;
                         dif = dato.credito-aux2;
                         aux = aux +dif;
                     end if;
                     INSERT INTO importesorden
                            VALUES (resp,dato.centro,5,aux);
                 end if;

             --    INSERT INTO importesorden
              --          VALUES (resp,dato.centro,5,round(cast(dato.credito/cc as numeric),2));
            end if;
            if not nullvalue(dato.sosunc)  AND (dato.sosunc <> 0) then
                 INSERT INTO importesorden
                        VALUES (resp,dato.centro,6,round(cast(dato.sosunc/cc as numeric),2));
            end if;

    --  inserta las ordenes en ttordenesgeneradas
            INSERT INTO ttordenesgeneradas(nroorden,centro)
                VALUES (resp,dato.centro);
		--VALUES (100000,1);
            contador=contador-1;
    end loop;
    close cursororden;

     --  Llama a asentarfacturaventa()
 	select * into respuesta
           from asentarfacturaventa(tipoc,'FA'); --guarda en ttfacturasgeneradas

    respuesta = true;
    return respuesta;	
END;
$function$
