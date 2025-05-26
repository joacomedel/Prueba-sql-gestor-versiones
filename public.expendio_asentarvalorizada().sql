CREATE OR REPLACE FUNCTION public.expendio_asentarvalorizada()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE



/*
cantidad           integer
importe            double
idnomenclador      varchar
idcapitulo         varchar
idsubcapitulo      varchar
idpractica         varchar
idplancob          varchar
auditada           boolean
*/
--CURSORES
nuevas refcursor;

items refcursor;
              

torden refcursor;
--CURSOR FOR               SELECT *               FROM temporden;

--CURSOR FOR                  SELECT *                         from ttordenesgeneradas;

--RECORD
datoorden RECORD;
nueva RECORD;
unitem RECORD;
dato RECORD;
untemoorden record;
rcargarficha RECORD;

--VARIABLES
identitem int;
respuesta boolean;
especialidad varchar;
alcance varchar;
nomenclador varchar;
capitulo varchar;
subcapitulo varchar;
practicaitem varchar;
plan varchar;
norden int;
tipe integer;
pplancobertura varchar;
ppractica varchar;
pconvenio varchar;
nombsprof varchar;
apellprof varchar;
nromat integer;
indice integer;
res VARCHAR;
BEGIN
    respuesta = false;
    norden = 0;
 
    --  crea la tabla temporal TTOrdenesGeneradas
IF NOT  iftableexists('ttordenesgeneradas') THEN

    CREATE TEMP TABLE ttordenesgeneradas(
/*campo que defino para saber las ordenes que ya se guardaron. Las ordenes que estan en ttordenesgeneradas se guardan para generar el recibo de esas ordenes*/
           estaenitem BOOLEAN DEFAULT false,
           nroorden   bigint,
           centro     int4
           ) WITHOUT OIDS;

END IF;

SELECT  * INTO respuesta FROM expendio_asentarorden(); --guarda en ttordenesgeneradas
IF (respuesta) THEN
                   OPEN nuevas FOR  SELECT * FROM ttordenesgeneradas WHERE not estaenitem;
                   fetch nuevas into nueva;
                    WHILE found LOOP

                     RAISE NOTICE 'expendio_asentarvalorizada (%) ',nueva;
                   OPEN torden FOR  SELECT * FROM temporden;
                   fetch torden into untemoorden;
                      RAISE NOTICE 'expendio_asentarvalorizada temporden (%) ',untemoorden;
                   --  Asienta en ordenvalorizada
                   /*Malapi 17-09/2013_ Modifico para que en nromaticula se guarde el id prestador en lugar de la matricula.*/    	
	                        INSERT INTO ordvalorizada(centro,nroorden,malcance,nromatricula,mespecialidad,ordenreemitida,centroreemitida)
                              VALUES (nueva.centro,nueva.nroorden,'',untemoorden.idprestador,'',null,null);


                            -- Asienta en ItemsValorizada
	                        open items FOR SELECT * FROM tempitems;
                            FETCH items into unitem;
                            WHILE found LOOP
                                    RAISE NOTICE 'expendio_asentarvalorizada tempitems (%) ',unitem;          
			         nomenclador = unitem.idnomenclador  ;
			         capitulo =  unitem.idcapitulo  ;
			         subcapitulo =  unitem.idsubcapitulo  ;
			         practicaitem =  unitem.idpractica ;			
			         INSERT INTO item(cantidad,importe,idnomenclador,idcapitulo,idsubcapitulo,idpractica,cobertura)
			                             VALUES (unitem.cantidad,unitem.importe,nomenclador,capitulo,subcapitulo,practicaitem,unitem.porcentaje);			
			                             identitem = currval('"public"."item_iditem_seq"');			
                                  INSERT INTO itemvalorizada (iditem,nroorden,centro,idplancovertura,auditada)
                                         VALUES (identitem,nueva.nroorden,nueva.centro,unitem.idplancob,unitem.auditada);		
                                  IF untemoorden.tipo =48   THEN -- verifico si se trata de una orden de odontologia
                                     INSERT INTO ordenodonto (nroorden,iditem ,idzonadental, idpiezadental , idletradental ,centro)
                                     VALUES(nueva.nroorden,identitem,unitem.idzonadental,unitem.idpiezadental,unitem.idletradental,nueva.centro);
                                  END IF;

                                  IF untemoorden.tipo =4   THEN 
                                   INSERT INTO ordconsulta(centro,nroorden,idplancovertura)
                                   VALUES (nueva.centro,nueva.nroorden,unitem.idplancob);
                                  END IF;
			--	  IF untemoorden.tipo =56   THEN -- Se trata de una Orden en Linea, puede ser que se deba guardar un error.

                        --       IF nueva.centro= 1 THEN 
                        --       KR 29-01-20 SOLO guardo en la tabla si la orden es emitida en central
--KR 24-11-22 saco el centro, ahora lo guardamos para todos 
				     --Lo comento hasta que este como sincronizable la tabla
--KR 08-11-22 guardo la info de importes amuc, sosunc y afiliado
                                     INSERT INTO iteminformacion(iditem,centro,iierror,iicomentario,iiobservacion,iiimportesosuncunitario,iiimporteamucunitario,iiimporteafiliadounitario)
                                     VALUES(identitem,nueva.centro,unitem.tierror,'Ninguno',unitem.iiobservacion,round(unitem.sosunc::numeric, 2) ,round(unitem.amuc::numeric, 2), round(unitem.afiliado::numeric, 2));
                                     IF existecolumtemp('tempitems', 'porcentajesugerido') THEN

                                           
                                            UPDATE iteminformacion SET iiimporteunitario = unitem.importe,
                                                                       iicoberturaamuc = (unitem.iicoberturaamuc::double precision),
                                                                       iicoberturasosuncexpendida = (unitem.porcentaje::double precision/100),
                                                                       iicoberturasosuncsugerida= (unitem.porcentajesugerido::double precision/100),
                                                                       iditemestadotipo	= (CASE WHEN unitem.auditoria THEN 1 ELSE 4 END),
                                                                       iiimportesosuncunitario = round(unitem.iiimportesosuncunitario::numeric,2), 
                                                                       iiimporteamucunitario = round(unitem.iiimporteamucunitario::numeric,2), 
                                                                       iiimporteafiliadounitario = round(unitem.afiliado::numeric,2),
--round(unitem.iiimporteafiliadounitario::numeric,2),
                                                                       idconfiguracion = unitem.idconfiguracion
                                                                    WHERE  iditem= identitem AND centro=nueva.centro;
                               --      END IF;
                
                                    /*KR 06-04-20 inserto en la tabla de valores de los item*/
                                    SELECT INTO res * FROM w_importeafiliadoorden(CONCAT(nueva.nroorden,'-',nueva.centro));
                                  

                                  END IF;
 						

                                  FETCH items into unitem;
                            END LOOP;
                            close items;

/*updateo el campo para saber las ordenes que ya se guardaron. Las ordenes que estan en ttordenesgeneradas se guardan para generar el recibo de esas ordenes
*/
                            UPDATE ttordenesgeneradas SET estaenitem=true 
                             WHERE nroorden=nueva.nroorden AND centro=nueva.centro;
                        
                        CLOSE torden;  

                      

                       SELECT INTO untemoorden * FROM  temporden LIMIT 1;
                       --KR 23-06-22 Genero pendiente en caja para facturar pendientos todos RECIPROCIDAD PARA orden de RECIPROCIDAD 
                       IF untemoorden.tipo = 20  THEN
                              PERFORM expendio_generarinformependientecaja('');
                       END IF; 
                      -- Verifico si hay un reintegro asociado a la orden descomentar

                       IF (untemoorden.tipo = 55) THEN
                          INSERT INTO reintegroorden (nroreintegro,anio,idcentroregional,centro,nroorden,tipo)
                          VALUES(untemoorden.nroreintegro, untemoorden.anio, untemoorden.idcentroreintegro,nueva.centro, nueva.nroorden,untemoorden.tipo); 
                     /* KR 01-08-17 descomentar al poner en produccion el expendio reintegro */
                        PERFORM liquidarreintegroexpendido();

                        UPDATE reintegro SET tipoformapago =T.tipoformapago
                            FROM (SELECT nroreintegro,anio,idcentroregional,tipoformapago.tipoformapago 
                                  FROM reintegroorden NATURAL JOIN importesorden NATURAL JOIN mapeoformapagotipostipoformapago NATURAL JOIN tipoformapago
                                  WHERE nroorden=nueva.nroorden AND centro=nueva.centro) AS T
                            WHERE reintegro.nroreintegro=T.nroreintegro AND reintegro.anio=T.anio AND 
reintegro.idcentroregional=T.idcentroregional; 

 
                       END IF;
              --MaLaPi 28/02/2023 Lo bajo porque sino me da un error
                fetch nuevas into nueva;
                END LOOP; 
                close nuevas;
                   
    end if;
    return respuesta;	

END;$function$
