CREATE OR REPLACE FUNCTION public.expendio_asentarorden()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

cursororden CURSOR FOR
              SELECT *
              FROM temporden;
              
/*importeorden CURSOR FOR
               SELECT SUM(amuc)as amuc,SUM(afiliado) as afiliado,SUM(sosunc) as sosunc
               FROM  tempitems ;*/
   
    
dato RECORD;
datoimporte RECORD;
rexiste RECORD;
ranticipo RECORD;
elnroorden bigint;
elidformapagotipos bigint;
contador integer;
respuesta boolean;


BEGIN
    respuesta = false;
  
 
    SELECT INTO dato * FROM temporden; 
    SELECT INTO datoimporte SUM(amuc)as amuc,SUM(afiliado) as afiliado,SUM(sosunc) as sosunc,max(idplancob) as idplancob  FROM  tempitems; 
    
    if nullvalue(dato.cantordenes) OR (dato.autogestion) then
       contador =1;
    else
        contador  = dato.cantordenes;
    end if;
 
    while contador>0 loop	
                   --asienta en orden
       	           INSERT INTO orden(nroorden,centro,fechaemision,tipo,idasocconv,nroordeninter,centroordeninter)
                   VALUES (nextval('"public"."orden_nroorden_seq"'),centro(),CURRENT_TIMESTAMP,dato.tipo,dato.idasocconv,dato.numorden,dato.ctroorden);
                   elnroorden = currval('"public"."orden_nroorden_seq"');
	
	               --aienta en consumo
                   INSERT INTO consumo(idconsumo,centro,nroorden,nrodoc,tipodoc)
                   VALUES (nextval('"public"."consumo_idconsumo_seq"'),centro(),elnroorden,dato.nrodoc,dato.tipodoc);	

                   IF not nullvalue(datoimporte.amuc) AND (datoimporte.amuc <> 0) THEN   -- importe amuc
                         INSERT INTO importesorden(nroorden,centro,idformapagotipos,importe)
                         VALUES (elnroorden,centro(),1,round(CAST(datoimporte.amuc AS numeric),2));

                   END IF;
                   
                  IF not nullvalue(datoimporte.afiliado) AND (datoimporte.afiliado <> 0) THEN  -- importe afiliado
                        if not nullvalue(dato.enctacte) AND (dato.enctacte )THEN
                             elidformapagotipos = 3;  -- cta cte 
                          ELSE
                              --MaLaPi 19-09-2019 Si se trata de un consumo con plan de cobertura 12 (Reciprocidad) va siempre en cta. cte
                              IF not nullvalue(datoimporte.idplancob) AND datoimporte.idplancob = 12 THEN
                                   elidformapagotipos = 3;  -- cta cte 
                              ELSE 
                                   elidformapagotipos = 2;  -- efectivo
                              END IF;
                          END IF;
             --KR 09-08 modifique para que tome la forma de pago del radiobutton
                          IF NOT nullvalue(dato.formapago) AND datoimporte.idplancob <> 12 THEN
                                elidformapagotipos = dato.formapago;  
                          END IF; 
--KAR 01-12-22 SI la orden es de un anticipo de reintegro, el porcentaje es al 100 y el importe afiliado <> null y el 100% de la practica, entonces la forma de pago es sosunc, si la cobertura no es al 100 entonces el afiliado debe pagar el porcentaje no cubierto
--ESTO es para cuando hay mas de una practica con distintas coberturas. 
                         IF existecolumtemp('temporden', 'anticiporeintegro') THEN
                          IF (dato.tipo=20 and dato.anticiporeintegro is not null and    dato.anticiporeintegro) THEN 
                             SELECT INTO ranticipo SUM(afiliado) as afiliado,SUM(sosunc) as sosunc,max(idplancob) as idplancob FROM  tempitems WHERE porcentaje <>100;      
                             IF FOUND AND ranticipo is not null THEN
                                    datoimporte=ranticipo;
                             ELSE 

                             END IF;

--si ranticipo is null significa que solo hay una cobertura, al 100
                             IF ranticipo is not null THEN
                               SELECT INTO ranticipo SUM(afiliado) as afiliado,SUM(sosunc) as sosunc,max(idplancob) as idplancob FROM  tempitems WHERE porcentaje=100;       
                               IF FOUND AND ranticipo is not null THEN --PAGA SOSUNC elidformapagotipos=6
                                  INSERT INTO importesorden(nroorden,centro,idformapagotipos,importe)
                                  VALUES (elnroorden,centro(),6,round(CAST(ranticipo.afiliado AS numeric),2) );
                               END IF;
                             ELSE 
                                elidformapagotipos=6;
                             END IF;
                           END IF;
                          END IF;
                          INSERT INTO importesorden(nroorden,centro,idformapagotipos,importe)
                          VALUES (elnroorden,centro(),elidformapagotipos,round(CAST(datoimporte.afiliado AS numeric),2) );
                   END IF;

--KR 12-06-20 SI el plan es 12 o 29 y la forma de pago es sosunc, la modifico para que sea 3 y vaya a la cta cte de la osreci en cuestion
--KR 08-07-20 Después de hablar con Carola se entendió que solo el plan 12 va a cta cte, el 29 a sosunc...luego se le cobra a la osreci en el proceso que genera el informefacturacionreci
                   IF not nullvalue(datoimporte.sosunc)  AND (datoimporte.sosunc <> 0) then
                      IF (datoimporte.idplancob=12 /* OR datoimporte.idplancob = 29*/) then 
                           elidformapagotipos =3;                          
                      ELSE 
                         elidformapagotipos =6;
                      END IF;
                  
                      SELECT INTO rexiste * from importesorden where nroorden=elnroorden and centro= centro() and idformapagotipos=elidformapagotipos;
                      IF FOUND THEN 
                         UPDATE importesorden set importe = round(CAST(datoimporte.sosunc+importe AS numeric),2)  
                                      where nroorden=elnroorden and centro= centro() and idformapagotipos=elidformapagotipos;
                      ELSE 
                         INSERT INTO importesorden(nroorden,centro,idformapagotipos,importe)
                         VALUES (elnroorden,centro(),elidformapagotipos, round(CAST(datoimporte.sosunc AS numeric),2) );
                      END IF;
                      
                   END IF;

                   --  inserta las ordenes en ttordenesgeneradas
                  INSERT INTO ttordenesgeneradas(nroorden ,centro) VALUES (elnroorden,centro());
		          
                  contador = contador-1;


   
    end loop;
    
    respuesta = true;
    return respuesta;	
END;$function$
