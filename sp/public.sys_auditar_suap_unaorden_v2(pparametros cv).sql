CREATE OR REPLACE FUNCTION public.sys_auditar_suap_unaorden_v2(pparametros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$  DECLARE

       ccursor refcursor;
       ccursororden refcursor;
      
        
        rfiltros RECORD;
        rusuario RECORD;
        elem RECORD;
        elemorden  RECORD;
        rprestador RECORD;
    rvalores RECORD;
        rverifica2 RECORD;
        rfacturapractica RECORD;
        rverificadebito RECORD;
    rverificaconf RECORD;
        rverificaestado RECORD;
        rcontrolcoseguro RECORD;
        rctagastodebito RECORD;
        rverificacoseguro RECORD;
        rcosegurodescontado RECORD;
        rverifica RECORD;
    rverificalinea RECORD;
        rcosegurofichamedicapreauditada  RECORD;
    rhayquedebitar RECORD;
        rasociacion RECORD;
        
        vidasocparapagar VARCHAR; 
        vcategoria VARCHAR; 
        vbandera VARCHAR;
       vbuscarconsumo VARCHAR; 
    vpracticaqueaudito  VARCHAR; 
    vimporte double precision;
    vimportecoseguro double precision;
    vimportefacturadomenoscoseguro double precision;
    vimportecosegurofalta double precision;
    vimportesincoseguro boolean;
    vidsuapcolegiomedico bigint;
    vcantidad INTEGER;
        vusarasocorden BOOLEAN;
    

  BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

     EXECUTE sys_dar_filtros(pparametros) INTO rfiltros;

vidasocparapagar = '0';
vusarasocorden = true;
--MaLaPi 19/12/2022 Busco el asocconvenio que se esta auditando, para tomar de ahi los valores, pues ahora se usa coseguros para expender
SELECT INTO rasociacion * FROM factura  JOIN asocconvenio ON acidprestador = idprestador WHERE nroregistro=rfiltros.nroregistro AND anio = rfiltros.anio;
IF FOUND THEN 
    vidasocparapagar = rasociacion.idasocconv;
    vusarasocorden = false;
END IF;

--MaLaPi 19/11/2020 Coloco en cero todos los NroRecibo que nos son validos
vbandera = true;
vbuscarconsumo = true;
--Para Cada Orden
OPEN ccursororden FOR SELECT CASE WHEN not nullvalue(planb.idprestador) THEN planb.idprestador ELSE plana.idprestador END as idprestador
,replace(CASE WHEN not nullvalue(plana.pcuit) THEN plana.pcuit ELSE planb.pcuit END,'-','') as pcuit
,CASE WHEN not nullvalue(planb.pcategoria) THEN planb.pcategoria ELSE plana.pcategoria END::varchar as pcategoria
,nroorden,centro,idasocconv,suap_colegio_medico.*,categoriaefector::varchar,coseguro.*
,CASE WHEN NOT nullvalue(categoria_efector) AND trim(categoria_efector) <> '' THEN categoria_efector  
      WHEN NOT nullvalue(plana.pcategoria) THEN plana.pcategoria END as categoriaseleccionada 
            FROM suap_colegio_medico
            LEFT JOIN ordenrecibo USING(idrecibo,centro)
            LEFT JOIN (SELECT importe as importecoseguro, idrecibo,centro FROM importesrecibo WHERE idformapagotipos = 2 ) as coseguro USING(idrecibo,centro)
            LEFT JOIN orden USING(nroorden,centro)
            LEFT JOIN ordenonlineinfoextra USING(nroorden,centro)
            LEFT JOIN ordvalorizada USING(nroorden,centro)
            LEFT JOIN prestador as plana  ON idprestador = nromatricula
            LEFT JOIN prestador as  planb ON replace(planb.pcuit,'-','') = cuit_efector
            WHERE nroregistro=rfiltros.nroregistro AND anio = rfiltros.anio AND nullvalue(scmprocesado)
                          --AND cuit_efector <> '27247048788' --AND  cuit_efector <> '20118413025'
                           AND  nroorden = rfiltros.nroorden AND centro = rfiltros.centro
                        --AND idrecibo IN (790722,791178,787238,789586,800154)
            --AND idasocconv = 128

                        --AND (cuit_efector = rfiltros.cuit_efector OR nullvalue(rfiltros.cuit_efector))--'27206913873'
                        --AND CASE WHEN not nullvalue(plana.idprestador) THEN plana.idprestador ELSE planb.idprestador END <  10054963972
                        -- AND ( nullvalue(orden.tipo) OR nullvalue(rfiltros.tipoenlinea) 
                         --    OR  (not nullvalue(rfiltros.tipoenlinea) AND rfiltros.tipoenlinea = 56 AND orden.tipo = 56 )
                          --   OR  (not nullvalue(rfiltros.tipoenlinea) AND rfiltros.tipoenlinea = 2 AND orden.tipo <> 56 ))
                        --ORDER BY idprestador
            --Limit 10
;
FETCH ccursororden INTO elemorden;
WHILE  found LOOP 
                
                IF vusarasocorden  THEN
                    vidasocparapagar = elemorden.idasocconv;
                END IF;
                  
        vbandera = true;
                
                SELECT INTO rverifica2 * FROM suap_colegio_medico WHERE idsuapcolegiomedico = elemorden.idsuapcolegiomedico;
                IF FOUND AND not nullvalue(rverifica2.scmprocesado) THEN
                   RAISE NOTICE 'SYS::RN ya audite el  idsuapcolegiomedico (%)',rverifica2.idsuapcolegiomedico;
                   vbandera = false;
                ELSE 
                    RAISE NOTICE 'SYS::RN NO encontre auditado el  idsuapcolegiomedico (%)',rverifica2.idsuapcolegiomedico;
                END IF;

               IF nullvalue(elemorden.nroorden) AND (trim(elemorden.recibo_siges) ilike 'A%' OR  trim(elemorden.recibo_siges) ilike '0' OR  trim(elemorden.recibo_siges) ilike '')  THEN 
            --No me envian el codigo de Siges, sino que el Codigo de SUAP, no puedo encontrar la orden la marco como un debito
            IF rfiltros.confiarenvalorpractica = 'si' THEN
                        -- Solo lo puedo debitar, su puedo confiar en el valor de las practicas
                INSERT INTO facturadebitoimputacionpendiente(nrocuentacgasto,idplancobertura,idnomenclador,idcapitulo,idsubcapitulo,idpractica
                ,importedebito,nroregistro,anio,motivo,idmotivodebitofacturacion,fidtipo,idprestador) 
                VALUES (50340,'1', CASE WHEN rfiltros.esbioquimico = 'si' THEN '07' ELSE '12' END,CASE WHEN rfiltros.esbioquimico = 'si' THEN '42' ELSE '66' END,CASE WHEN rfiltros.esbioquimico = 'si' THEN '00' ELSE '01' END,CASE WHEN rfiltros.esbioquimico = 'si' THEN '0001' ELSE '01' END,elemorden.valor_practica - elemorden.valor_coseguro,rfiltros.nroregistro,rfiltros.anio,concat('No se envia el Nro.Autorizacion, no se puede auditar. Se envia:',elemorden.recibo_siges,' Cod.Practica:',elemorden.codigo_practica,'Cod.Interno:',elemorden.idsuapcolegiomedico),5,8,elemorden.idprestador);
                        UPDATE suap_colegio_medico SET scmprocesado = now() WHERE idsuapcolegiomedico = elemorden.idsuapcolegiomedico;  
            END IF;

             END IF;

               RAISE NOTICE 'SYS::RN Auditamos (%)',elemorden;
        IF nullvalue(elemorden.nroorden) THEN 
            --Error, la orden no existe, no deberia pasar nunca
            vbandera = false;
            RAISE NOTICE 'SYS::RN No encuentro el nro de orden, no se puede auditar(%)',elemorden.nroorden;
        END IF;
        IF nullvalue(elemorden.idprestador) /*OR (elemorden.pcuit not ilike elemorden.cuit_efector)*/ THEN 
            --Malapi 04-11-2019 Quito el control de  elemorden.pcuit not ilike elemorden.cuit_efector pues el CMN cuando el prestador es agrupador me envia el CUIT del agrupador, por ejemplo Imagenes del SUR
            --Error, el prestador no existe o se cambio 
            vbandera = false;
            RAISE NOTICE 'SYS::RN No encuentro el prestador no existe o se cambio (%)',elemorden.cuit_efector;
        END IF;

        IF vbandera THEN

            IF elemorden.cant > 1 THEN 
                    RAISE NOTICE 'SYS::RN La cantidad es mayor a 1 (%),(%),(%) - OJO CON LOS IMPORTES ',elemorden.idrecibo,elemorden.centro,elemorden.codigo_practica;
                    elemorden.valor_practica = elemorden.valor_practica / elemorden.cant;
             END IF; 
                         
                vcategoria = CASE WHEN elemorden.categoriaseleccionada ilike 'D' THEN 'E' ELSE elemorden.categoriaseleccionada END;
                RAISE NOTICE 'SYS::RN obtenerdatosfichamedicaauditada_convigencia_suap (%),(%),(%),(%)',elemorden.nroorden,elemorden.centro,vidasocparapagar,vcategoria;      
 RAISE NOTICE 'SYS::RN  vbuscarconsumo >>(%)',vbuscarconsumo;
        IF vbuscarconsumo THEN 
            PERFORM obtenerdatosfichamedicaauditada_convigencia_suap_v2(concat('{ nroorden=',elemorden.nroorden,' ,centro=',elemorden.centro,' ,idasocconv=',vidasocparapagar,',categoriaapagar=',vcategoria,',esodonto=null}'));
            vbuscarconsumo = false;
        END IF;

        OPEN ccursor FOR SELECT type_fichamedicaauditadav2.*
                            ,i.idnomenclador as idnor,i.idcapitulo as idcor,i.idsubcapitulo as idsor,i.idpractica as idpor
                            FROM type_fichamedicaauditadav2
                            LEFT JOIN  item as i USING(iditem,centro) 
                                             
                                                     ;
        FETCH ccursor INTO elem;
        WHILE  found LOOP
            vpracticaqueaudito = CASE  WHEN elem.idnor = '07' THEN concat(elem.idcor,elem.idpor) ELSE  concat(elem.idcor,elem.idsor,elem.idpor) END;
             RAISE NOTICE 'SYS::RN  vpracticaqueaudito >>(%)',vpracticaqueaudito;
             SELECT INTO rverificalinea * FROM suap_colegio_medico 
                            WHERE codigo_practica = vpracticaqueaudito
                            AND recibo_siges = elemorden.recibo_siges 
                            AND nroregistro = elemorden.nroregistro AND anio = elemorden.anio AND nullvalue(scmprocesado)
                 LIMIT 1;
                 IF FOUND THEN 
                    vidsuapcolegiomedico = rverificalinea.idsuapcolegiomedico;
                    RAISE NOTICE 'SYS::RN Voy a tomar para auditar la linea idsuapcolegiomedico (%) y practica (%)',rverificalinea.idsuapcolegiomedico,vpracticaqueaudito;  
                 ELSE 
                    vidsuapcolegiomedico = -1;
                    RAISE NOTICE 'SYS::RN no se encontro la practica (%)  en la tabla a procesar suap_colegio_medico ',vpracticaqueaudito;
                 END IF;
            IF vidsuapcolegiomedico <> -1 THEN --Tengo practicas por auditar 
            SELECT INTO rfacturapractica * 
                        FROM suap_colegio_medico 
                               WHERE nroregistro=elemorden.nroregistro AND anio = elemorden.anio AND nullvalue(scmprocesado)
                               AND cuit_efector = elemorden.cuit_efector 
                                AND idrecibo = elemorden.idrecibo
                                AND centro = elemorden.centro
                                AND trim(codigo_practica) = vpracticaqueaudito;
            
            
            RAISE NOTICE 'SYS::RN Practica de SUAP que voy a Auditar (%)',vpracticaqueaudito;      
            -- Busco la cuenta de gasto del debito, por las dudas que la necesite
            SELECT INTO rctagastodebito ftp.*        
            FROM mapeoctascontablesgastoventa as mccgv  
            JOIN ftipoprestacion as ftp ON(mccgv.   nrocuentacgasto=ftp.    nrocuentac  ) 
            WHERE ( mccgv.idnomenclador =elem.idnomenclador ) 
            AND ( mccgv.idcapitulo =elem.idcapitulo OR mccgv.idcapitulo ='**'  ) 
                                  AND (  mccgv.idsubcapitulo =elem.idsubcapitulo OR mccgv.idsubcapitulo ='**' ) 
                                  AND ( mccgv.idpractica =elem.idpractica OR mccgv.idpractica ='**' ) 
            LIMIT 1;

        --Para cada Item de la Orden
        vimportesincoseguro = true;
        IF nullvalue(elem.idfichamedicapreauditada) OR elemorden.cant > 1 THEN 
            RAISE NOTICE 'SYS::RN Valores (%),(%),(%) ',elem.importexcategoria,elem.importepv,rfacturapractica.valor_practica;
            vimporte = CASE WHEN nullvalue(elem.importexcategoria) THEN elem.importepv  ELSE elem.importexcategoria END;
            RAISE NOTICE 'SYS::RN Valores vimporte (%)',vimporte; 
            -- Para el caso donde el colegio medico factura menos que el valor por categoria, asumo que es el valor anterior
            -- 13-12-2019 Solo tomo esta regla cuando no tengo la fecha de vigente en los valores historicos
            --20-01-2020 Solo se puede aplicar esta regla, si podemos confiar en los valores que envia Colegio Medico
            RAISE NOTICE 'SYS::RN confiarenvalorpractica (%) convanteriorfechafin (%) valor_practica (%) ',rfiltros.confiarenvalorpractica,elem.convanteriorfechafin,rfacturapractica.valor_practica; 
            IF rfiltros.confiarenvalorpractica = 'si' AND nullvalue(elem.convanteriorfechafin) AND not nullvalue(rfacturapractica.valor_practica) AND vimporte > rfacturapractica.valor_practica THEN 
               RAISE NOTICE 'SYS::RN Tengo que tomar el valor anterior lo intuyo (%),(%)',vimporte,elem.anteriorvalorcategoria; 
               vimporte = CASE WHEN not nullvalue(elem.anteriorvalorcategoria) THEN elem.anteriorvalorcategoria ELSE rfacturapractica.valor_practica END;
                          
            END IF;
            -- 13/12/2019 Para el caso donde el colegio medico factura de mas y tengo cargado el inicio y fin de vigencia de los valores anteriores, uso lo que tengo cargado                        
            IF  not nullvalue(elem.convanteriorfechafin) AND elem.fechaemision::date <= elem.convanteriorfechafin THEN 
               RAISE NOTICE 'SYS::RN Tengo que tomar el valor anterior (%),(%)',vimporte,elem.anteriorvalorcategoria; 
               vimporte = CASE WHEN not nullvalue(elem.anteriorvalorcategoria) THEN elem.anteriorvalorcategoria ELSE vimporte END;
              
            END IF;
            --vimportecoseguro = CASE WHEN elemorden.valor_coseguro < elemorden.importecoseguro THEN elemorden.valor_coseguro ELSE elemorden.importecoseguro END;  
            SELECT INTO rfacturapractica * 
                FROM suap_colegio_medico 
               WHERE nroregistro=elemorden.nroregistro AND anio = elemorden.anio AND nullvalue(scmprocesado)
                   AND cuit_efector = elemorden.cuit_efector 
                    AND idrecibo = elemorden.idrecibo
                                AND centro = elemorden.centro
                                AND codigo_practica = vpracticaqueaudito
                LIMIT 1;
            IF FOUND THEN 
                --MaLaPi 21-12-2022 esto no se puede calcular aqui, pues el coseguro se coloca completo en la columna y el valor de la practica corresponde al del item en particular
                --vimportefacturadomenoscoseguro =  CASE WHEN not nullvalue(rfacturapractica.valor_practica) THEN rfacturapractica.valor_practica ELSE vimporte END - CASE WHEN nullvalue(rfacturapractica.valor_coseguro) THEN 0 ELSE rfacturapractica.valor_coseguro END;
                vimportecoseguro = CASE WHEN nullvalue(rfacturapractica.valor_coseguro) THEN 0 ELSE rfacturapractica.valor_coseguro END;
                RAISE NOTICE 'SYS::RN Encontre la practica de la orden (%) ',rfacturapractica.codigo_practica;
                --MaLapi 12-12--2022 Si el importe que ellos me facturan es mayor al que deberia pagar, tengo que hacer un debito por la diferencia en el valor pactado
                SELECT INTO rhayquedebitar rfacturapractica.valor_practica as valorfacturado
                ,vimporte as valorpracticasosunc
                ,rfacturapractica.valor_practica - vimporte as importedebito
                ,concat('Dif V:Valor pactado: OSU:',vimporte,' FAC:',rfacturapractica.valor_practica) as motivodebito
                ,6 as idmotivodebitofacturacion
                ,(rfacturapractica.valor_practica - vimporte) > 1 as hayquedebitar; --Solo hay que debitar si nos facturan mas de lo convenido
                  IF rhayquedebitar.hayquedebitar THEN 
                  --Malapi 07/08/2023 Si en los filtros piden que no se hagan debitos por diferencia de valor no se hacen
                  RAISE NOTICE 'SYS::RN Hay que hacer debito por Diferencia de Valor (%) importe (%)',rhayquedebitar.hayquedebitar,rhayquedebitar;
                  IF pparametros ilike '%aplicardebitodiferenciavalor%' THEN 
                  IF rfiltros.aplicardebitodiferenciavalor = 'no' THEN

                    SELECT INTO rhayquedebitar rfacturapractica.valor_practica as valorfacturado
                    ,rfacturapractica.valor_practica as valorpracticasosunc
                    ,rfacturapractica.valor_practica - rfacturapractica.valor_practica as importedebito
                    ,'' as motivodebito
                    ,6 as idmotivodebitofacturacion
                   ,false as hayquedebitar; --Solo hay que debitar si nos facturan mas de lo convenido
                 
                  END IF;
                  ELSE
                       --RAISE NOTICE 'SYS::RN Hay que hacer debito por Diferencia de Valor (%) importe (%)',rhayquedebitar.hayquedebitar,rhayquedebitar.importedebito;
                 END IF;
                 END IF;               
                 --MaLapi 04-02-2020 Si el valor que me factura colegio medico es menor, tomo el que ellos dicen
                         IF not nullvalue(rfacturapractica.valor_practica) AND vimporte > rfacturapractica.valor_practica THEN
                           RAISE NOTICE 'SYS::RN Colegio Mendico factura menos (%),(%)',vimporte,rfacturapractica.valor_practica; 
                            vimporte = rfacturapractica.valor_practica;
                          
                        END IF;
             ELSE 
                --vimportefacturadomenoscoseguro = vimporte;
                vimportecoseguro = 0;
                RAISE NOTICE 'SYS::RN No encontre la practica de la orden (%) ',elemorden.codigo_practica;
                SELECT INTO rhayquedebitar 0.0 as valorfacturado
                ,0.0 as valorpracticasosunc
                ,0.0 as importedebito
                ,'' as motivodebito
                ,6 as idmotivodebitofacturacion
                ,false as hayquedebitar;
                
             END IF;
            RAISE NOTICE 'SYS::RN El Importe (%) , el coseguro del prestador (%) ',vimporte,vimportecoseguro;
            INSERT INTO fichamedicapreauditada_fisica(
                idnomenclador,idcapitulo,idsubcapitulo,idpractica,fmpacantidad,fmpaidusuario
                ,iditem,centro,nroregistro,anio,nroorden,nrodoc,tipodoc,idprestador,idauditoriatipo,fechauso,importe,idplancobertura,
                fmpaiimportes,fmpaiimporteiva,fmpaiimportetotal,descripciondebito,importedebito,idmotivodebitofacturacion,tipo) 
            VALUES (elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica,elem.cantidad,rusuario.idusuario
                ,elem.iditem,elem.centro,rfiltros.nroregistro,rfiltros.anio,elemorden.nroorden,elem.nrodoc,elem.tipodoc,elemorden.idprestador,6,elem.fechaemision,elem.importepv,elem.idplancovertura::integer
                ,vimporte,'0',vimporte,NULL,'0',NULL,elem.tipo);

        
            --MaLaPi 13-12-2022 Aplico un debito por diferencia de valor pactado, si corresponde
            IF rhayquedebitar.hayquedebitar THEN
                RAISE NOTICE 'SYS::RN Hay diferencia de valor pactado... debito(%)',rhayquedebitar; 
                UPDATE fichamedicapreauditada_fisica SET 
                       fmpaiimportes =  rhayquedebitar.valorfacturado
                        ,fmpaiimporteiva = 0
                        ,fmpaiimportetotal = rhayquedebitar.valorpracticasosunc
                        ,descripciondebito = rhayquedebitar.motivodebito
                        ,importedebito = rhayquedebitar.importedebito
                        ,idmotivodebitofacturacion = rhayquedebitar.idmotivodebitofacturacion
                WHERE nroorden = elemorden.nroorden AND centro = elemorden.centro;
            END IF;
            
                 IF rfiltros.restacoseguro ilike 'Si' THEN
				 	
                           SELECT INTO rverificacoseguro * FROM suap_colegio_medico
                                                    WHERE nroregistro = rfiltros.nroregistro 
                                                                AND anio = rfiltros.anio AND scmdebitoconseguro = false 
                                                                AND nullvalue(scmfacturadaantes)
                                                                AND idrecibo = elemorden.idrecibo AND centro = elemorden.centro;
					           IF FOUND THEN --MaLaPi 05-02-2020 Verifico si ya le aplique el coseguro en alguna otra practica     

                               IF vimportesincoseguro THEN

                                   IF nullvalue(elemorden.importecoseguro)  THEN   elemorden.importecoseguro = 0; END IF;   

                                 --MaLaPi 01-11-2019 Verifico si puedo confiar en el coseguro que me factura el prestador, su es menor o igual, puedo dejar que lo reste en la practica que necesite, sino, tengo que buscar la forma de descontarlo yo. Si son muchas practicas, el prestador lo resta en algunas practicas dependiendo del importe de las mismas. Solo me tengo que preocupar por esto, su hay que restar coseguros.

                                  SELECT INTO rcontrolcoseguro * FROM (
                                         SELECT sum(importe) as importecosegurososunc, idrecibo,centro 
                                         FROM importesrecibo 
                                         NATURAL JOIN ordenrecibo
                                         WHERE idformapagotipos = 2
                                             AND nroorden = elemorden.nroorden AND centro = elemorden.centro
                                         GROUP BY idrecibo,centro 
                                         ) as sosunc
                                         LEFT JOIN (
                                         SELECT max(valor_coseguro) as importecoseguroprestador,idrecibo,centro
                                         FROM suap_colegio_medico
                                         JOIN ordenrecibo USING(idrecibo,centro)
                                         WHERE nroorden = elemorden.nroorden AND centro = elemorden.centro
                                         GROUP BY idrecibo,centro
                                    ) as prestador USING(idrecibo,centro);
                                    IF FOUND THEN   

                                        IF rcontrolcoseguro.importecosegurososunc >= rcontrolcoseguro.importecoseguroprestador THEN 
                                         -- Confiamos en el coseguro que nos envian a nivel de practica
                                         vimportecoseguro = rcontrolcoseguro.importecoseguroprestador;
                                         RAISE NOTICE 'SYS::RN Confiamos en su Coseguro (%) ',vimportecoseguro; 
                                        ELSE
                                         --Tengo que buscar la forma de descontarlo yo
                                         vimportecoseguro = rcontrolcoseguro.importecosegurososunc;
                                        --  vimportecoseguro = CASE WHEN vimportecoseguro <> 0 AND vimportecoseguro < elemorden.importecoseguro THEN vimportecoseguro ELSE elemorden.importecoseguro END; 

                                          RAISE NOTICE 'SYS::RN NO Confiamos en su Coseguro (%) ',vimportecoseguro; 
                                        END IF;
                                     END IF;
            

                                    RAISE NOTICE 'SYS::RN Resto el coseguro (%),(%),(%) ',vimportecoseguro,elemorden.valor_coseguro,elemorden.importecoseguro; 
                                         --MaLaPi 25/11/2020 Puede ser que tenga que repartir el coseguro en varias practicas. 
                                          --Verifico cuanto coseguro ya desconte 
                                         SELECT INTO rcosegurodescontado sum(scmcoseguroaplicado) as importecosegurodescontado,idrecibo,centro
                                         FROM suap_colegio_medico
                                         JOIN ordenrecibo USING(idrecibo,centro)
                                         WHERE nroorden = elemorden.nroorden AND centro = elemorden.centro
                                         GROUP BY idrecibo,centro;
                                          IF FOUND THEN 
										  RAISE NOTICE 'SYS::RN Resto el coseguro (%),(%)',vimportecoseguro,rcosegurodescontado.importecosegurodescontado; 
                                              IF rcosegurodescontado.importecosegurodescontado < vimportecoseguro THEN
                                               --MaLaPi hay hay que seguir descontando
                                                vimportecosegurofalta = round((vimportecoseguro - rcosegurodescontado.importecosegurodescontado)::numeric,2);
                                                SELECT INTO rcosegurofichamedicapreauditada * 
                                                FROM fichamedicapreauditada_fisica  
                                                    WHERE nroorden = elemorden.nroorden AND centro = elemorden.centro;
										RAISE NOTICE 'SYS::RN Resto el coseguro (%),(%),(%)',vimportecoseguro,rcosegurodescontado.importecosegurodescontado,vimportecosegurofalta; 
                            IF rcosegurofichamedicapreauditada.fmpaiimportes > vimportecosegurofalta THEN

                                UPDATE fichamedicapreauditada_fisica SET fmpaiimportes = fmpaiimportes - vimportecosegurofalta
                                    ,fmpaiimportetotal = fmpaiimportetotal - vimportecosegurofalta
                                    ,fmpadescripcion = concat('Se usa para restar corseguro ',vimportecosegurofalta,' Coseguro Total:',vimportecoseguro)
                                WHERE nroorden = elemorden.nroorden AND centro = elemorden.centro;
                                UPDATE suap_colegio_medico SET scmcoseguroaplicado = vimportecosegurofalta 
                                    WHERE idsuapcolegiomedico = vidsuapcolegiomedico AND idrecibo = elemorden.idrecibo AND centro = elemorden.centro;
                                UPDATE suap_colegio_medico SET scmdebitoconseguro = true WHERE idrecibo = elemorden.idrecibo AND centro = elemorden.centro;
								RAISE NOTICE 'SYS::RN Resto el coseguro Listo termine de descontar'; 
                             ELSE

                                UPDATE fichamedicapreauditada_fisica SET fmpaiimportes =  fmpaiimportes - rcosegurofichamedicapreauditada.fmpaiimportes
                                    ,fmpaiimportetotal = fmpaiimportetotal - rcosegurofichamedicapreauditada.fmpaiimportes
                                    ,fmpadescripcion = concat('Se usa para restar corseguro ',rcosegurofichamedicapreauditada.fmpaiimportes,' Coseguro Total:',vimportecoseguro)
                                    WHERE nroorden = elemorden.nroorden AND centro = elemorden.centro;
                                UPDATE suap_colegio_medico SET scmcoseguroaplicado = rcosegurofichamedicapreauditada.fmpaiimportes 
                                    WHERE idsuapcolegiomedico = vidsuapcolegiomedico AND idrecibo = elemorden.idrecibo AND centro = elemorden.centro;
									RAISE NOTICE 'SYS::RN Resto el coseguro Aun falta'; 
                               END IF;
                             END IF;
                           END IF;
                                           
                                           --GET DIAGNOSTICS vcantidad = ROW_COUNT;
                                           --RAISE NOTICE 'SYS::RN Actualizo (%) filas en resta coseguros',vcantidad;    
                                           --UPDATE suap_colegio_medico SET scmdebitoconseguro = true WHERE idrecibo = elemorden.idrecibo AND centro = elemorden.centro; 
                                       
                            END IF;
            END IF; --MaLaPi 05-02-2020 Verifico si ya le aplique el coseguro en alguna otra practica   
            END IF;
                        
                        
            SELECT INTO rverificaestado * FROM consumo WHERE nroorden = elemorden.nroorden AND centro = elemorden.centro;
             IF FOUND AND rverificaestado.anulado THEN 
            --Verifico si la orden esta anulada, en ese caso hay que debitarla por el total
            --Debito el valor facturado si es que lo envian 
                UPDATE fichamedicapreauditada_fisica SET fmpaiimportes = fmpaiimportes
                        ,fmpaiimporteiva = 0
                        ,fmpaiimportetotal = 0
                        ,descripciondebito = concat('Esta orden, se encuentra Anulada en SOSUNC ')
                        ,importedebito = fmpaiimportes
                        ,idmotivodebitofacturacion = 5 --Otro
                WHERE nroorden = elemorden.nroorden AND centro = elemorden.centro;
             END IF;
                          
            
            PERFORM alta_modifica_preauditoria_odonto_v1(elemorden.nroorden,elemorden.centro);
        ELSE 
          RAISE NOTICE 'SYS::RN Ya existe!! (%) ',concat(elem.idfichamedicapreauditada,'-',elem.idcentrofichamedicapreauditada);
                  UPDATE suap_colegio_medico SET scmfacturadaantes = concat(elem.idfichamedicapreauditada,'-',elem.idcentrofichamedicapreauditada)
                                 WHERE suap_colegio_medico.idsuapcolegiomedico = vidsuapcolegiomedico;

           -- Si ya existe, verifico que ya se facturo en otro Nro.de Registro, si es asi, aplico un debito
           SELECT INTO rverifica idprestador,replace(pcuit,'-','') as pcuit,pcategoria,nroorden,centro,idasocconv,suap_colegio_medico.*
            ,facturaordenesutilizadas.nroregistro as nroregistroanterior
            FROM suap_colegio_medico
            LEFT JOIN ordenrecibo USING(idrecibo,centro)
            LEFT JOIN orden USING(nroorden,centro)
            LEFT JOIN ordvalorizada USING(nroorden,centro)
            LEFT JOIN prestador ON idprestador = nromatricula
            LEFT JOIN facturaordenesutilizadas USING(nroorden,centro,tipo)
                        WHERE suap_colegio_medico.nroregistro=rfiltros.nroregistro 
                             AND suap_colegio_medico.anio = rfiltros.anio 
                             --AND scmfacturadaantes <> concat(elem.idfichamedicapreauditada,'-',elem.idcentrofichamedicapreauditada)
                              AND  facturaordenesutilizadas.nroregistro <> rfiltros.nroregistro
                              AND idrecibo = elemorden.idrecibo AND centro = elemorden.centro;
                        
                        IF FOUND THEN  -- Ya se facturo y lo que me quieren facturar es la practica 460001, genero un debito por ese importe
                                    RAISE NOTICE 'SYS::RN Ya y es en otra fichamedica!! (%) ',rverifica;
                        --MaLaPi 07-02-2020 Verifico si ya registre el debito para esa orden 
                                        SELECT INTO rverificadebito * FROM facturadebitoimputacionpendiente 
                                          WHERE nroregistro = rfiltros.nroregistro AND anio = rfiltros.anio AND idprestador = elemorden.idprestador 
                                          AND concat(idnomenclador,idcapitulo,idsubcapitulo,idpractica) = concat(elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica)
                                          AND idrecibo = rverifica.idrecibo AND centro = rverifica.centro;

                                        IF NOT FOUND THEN 

                                        RAISE NOTICE 'SYS::RN vamos a ver si confiamos en los valores!! (%)(%) ',rverifica.valor_practica,rfiltros.confiarenvalorpractica; 
                    IF not nullvalue(rverifica.valor_practica) AND rfiltros.confiarenvalorpractica = 'si' THEN 
                        RAISE NOTICE 'SYS::RN Confiamos!! (%)(%) ',elemorden.valor_practica,elemorden.valor_coseguro; 
                        INSERT INTO facturadebitoimputacionpendiente(nrocuentacgasto,idplancobertura,idnomenclador,idcapitulo,idsubcapitulo,idpractica
                        ,importedebito,nroregistro,anio,motivo,idmotivodebitofacturacion,fidtipo,idprestador,idrecibo,centro,nroorden) 
                        VALUES (rctagastodebito.nrocuentac,'1',elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica,elemorden.valor_practica - elemorden.valor_coseguro,rfiltros.nroregistro
                        ,rfiltros.anio,concat('Orden ya facturada en Nro.Reg ',rverifica.nroregistroanterior,'Nro Recibo: ',rverifica.idrecibo,'-',rverifica.centro,' NroOrden ',rverifica.nroorden,'-',rverifica.centro,' Afiliado: ',rverifica.nro_afiliado,' ',rverifica.ape_nom_afil),5,8,elemorden.idprestador,rverifica.idrecibo,rverifica.centro,rverifica.nroorden);
                    ELSE
                        RAISE NOTICE 'SYS::RN Ya existe!! y no tengo el valor que me facturan (%) ',elem;
                        RAISE NOTICE 'SYS::RN Valores (%),(%),(%) ',elem.importexcategoria,elem.importepv,elemorden.valor_practica;
                        vimporte = CASE WHEN nullvalue(elem.importexcategoria) THEN elem.importepv  ELSE elem.importexcategoria END;
                        RAISE NOTICE 'SYS::RN Valores vimporte (%)',vimporte; 

                        INSERT INTO facturadebitoimputacionpendiente(nrocuentacgasto,idplancobertura,idnomenclador,idcapitulo,idsubcapitulo,idpractica
                        ,importedebito,nroregistro,anio,motivo,idmotivodebitofacturacion,fidtipo,idprestador,idrecibo,centro,nroorden) 
                        VALUES (rctagastodebito.nrocuentac,'1',elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica,vimporte,rfiltros.nroregistro
                        ,rfiltros.anio,concat('Orden ya facturada en Nro.Reg ',rverifica.nroregistroanterior,'Nro Recibo: ',rverifica.idrecibo,'-',rverifica.centro,' NroOrden ',rverifica.nroorden,'-',rverifica.centro,' Afiliado: ',rverifica.nro_afiliado,' ',rverifica.ape_nom_afil),5,8,elemorden.idprestador,rverifica.idrecibo,rverifica.centro,rverifica.nroorden);  
                    END IF;
                --END IF;
                   END IF; --El Debito ya esta registrado para esa practica y orden
                        ELSE 
                            RAISE NOTICE 'SYS::RN Ya existe!! pero no la encontre  (%),(%), se trata del mismo registro, puede ser que la cantidad sea > 1 ',elemorden.idrecibo,elemorden.centro;

                        END IF;

        END IF;
                 
                 RAISE NOTICE 'SYS::RN Voy a marcar como auditada una linea para el codigo (%),recibo (%) registro (%),anio (%)',vpracticaqueaudito,elemorden.recibo_siges,elemorden.nroregistro,elemorden.anio;
                 --SELECT INTO rverificalinea * FROM suap_colegio_medico 
                 --                             WHERE codigo_practica = vpracticaqueaudito
                 --                                     AND recibo_siges = elemorden.recibo_siges 
                  --                                      AND nroregistro = elemorden.nroregistro AND anio = elemorden.anio AND nullvalue(scmprocesado)
                 --LIMIT 1;
                 --IF FOUND THEN 
                    RAISE NOTICE 'SYS::RN Confirmo que algo actualizo idsuapcolegiomedico (%)',vidsuapcolegiomedico;  
                    UPDATE suap_colegio_medico SET scmprocesado = now() WHERE idsuapcolegiomedico = vidsuapcolegiomedico;
                -- END IF;
        END IF; --Si el vidsuapcolegiomedico <> -1
        fetch ccursor into elem;
        END LOOP;
        CLOSE ccursor;

        
        END IF;

fetch ccursororden into elemorden;
END LOOP;
CLOSE ccursororden;

   RETURN 'true';
  END;
$function$
