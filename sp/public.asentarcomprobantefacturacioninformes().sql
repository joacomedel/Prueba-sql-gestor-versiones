CREATE OR REPLACE FUNCTION public.asentarcomprobantefacturacioninformes()
 RETURNS SETOF record
 LANGUAGE plpgsql
AS $function$DECLARE

--REGISTROS

     elcomprobante RECORD;
     rinforme record;
     reginforme record;
     respclienteok RECORD;
     rnogenerarmvtoctacte  RECORD;
     rformapago  RECORD;
--CURSORES

     cinforme CURSOR FOR SELECT * FROM tempinforme group by nroinforme, idcentroinformefacturacion;
     rusuario record;
     elidusuario integer;

--VARIABLES
     elidpagocontable VARCHAR;
     resp boolean;

BEGIN
    --si el informe es ND o de turismo 
   IF (existecolumtemp('tempinforme ','idinformefacturaciontipo')) THEN
     SELECT INTO rnogenerarmvtoctacte * from tempinforme WHERE idinformefacturaciontipo=5 or idinformefacturaciontipo=3;
     if found AND (not existecolumtemp('tempfacturaventa','fvgeneramvtoctacte')) THEN
         ALTER TABLE tempfacturaventa ADD COLUMN fvgeneramvtoctacte BOOLEAN DEFAULT false;
     end if;
  else --MaLapi 11-08-2021 cuando se llama desde el facturarpendientestodos desde java, este campo no existe, hay que buscar otra forma de determinar si genera o no mivimiento en ctacte
       --MaLapi 11-08-2021 si se trata de un consumo de turismo, el informe ya existe, se genero cuando se genera el consumo
-- KR 23-05-22 TKT 4982 si el consumo fue en efectivo pero en caja quieren cambiarle la FP a cta cte entonces aqui debe hacerse el movimiento en cta cte
     SELECT INTO rnogenerarmvtoctacte * from tempinforme natural join informefacturacion  WHERE idinformefacturaciontipo=5 or idinformefacturaciontipo=3;
     if found AND (not existecolumtemp('tempfacturaventa','fvgeneramvtoctacte')) THEN
        SELECT INTO rformapago * FROM tempfacturaventacupon;
--si el informe es de turismo e inicialmente se hizo en efectivo pero ahora en caja se cambio la FP a cta cte
        IF FOUND AND (rnogenerarmvtoctacte.idformapagotipos=3 AND (rformapago.idvalorescaja<>91 or rformapago.idvalorescaja<>191 ))THEN
           ALTER TABLE tempfacturaventa ADD COLUMN fvgeneramvtoctacte BOOLEAN DEFAULT false;
        END IF;
     else
/*KR 20-01-22 TKT 4682 SI el info tiene vinculada una cta cte NO se genera el movimiento desde el comprobante facturado(aqui entra RECI, AMUC..). Aqui el tema es cuando facturan muchos informes en una misma factura, segun me dijeron no facturan asi. */
         SELECT INTO rnogenerarmvtoctacte * FROM tempinforme join 
            (SELECT idcomprobante, iddeuda, idcentrodeuda, idcomprobantetipos FROM ctactedeudacliente 
             UNION 
             SELECT idcomprobante, iddeuda, idcentrodeuda, idcomprobantetipos FROM cuentacorrientedeuda) as T
           ON(idcomprobante) = tempinforme.nroinforme*100+tempinforme.idcentroinformefacturacion AND idcomprobantetipos=21 ;

         IF FOUND AND (not existecolumtemp('tempfacturaventa','fvgeneramvtoctacte')) THEN
           ALTER TABLE tempfacturaventa ADD COLUMN fvgeneramvtoctacte BOOLEAN DEFAULT false;
         END IF;
     end if;
  end if; 
     SELECT INTO elcomprobante * FROM  asentarcomprobantefacturacion() as (nrofactura bigint, tipocomprobante integer, nrosucursal integer, tipofactura varchar, seimprime boolean);
     RAISE NOTICE 'Cargamos el comprobante (%)',elcomprobante;
    
 /* Se vincula las ordenes a la factura generadas*/
     open cinforme;
     FETCH cinforme into rinforme;
     WHILE FOUND LOOP
                UPDATE informefacturacion SET tipocomprobante=elcomprobante.tipocomprobante,nrosucursal=elcomprobante.nrosucursal,nrofactura=elcomprobante.nrofactura,tipofactura=elcomprobante.tipofactura
                WHERE nroinforme=rinforme.nroinforme AND idcentroinformefacturacion=rinforme.idcentroinformefacturacion;
                
                --cambio el estado del informefacturacion a FACTURADO
               PERFORM cambiarestadoinformefacturacion(rinforme.nroinforme::integer,rinforme.idcentroinformefacturacion,4,'GENERADO DESDE SP asentarfacturainformefacturacion');
 
               SELECT  INTO reginforme *
                       FROM informefacturacion
                       LEFT JOIN (SELECT nrodoc as nrocliente, tipodoc as barra, true as aporte
                          FROM afilpen
                          UNION
                          SELECT nrodoc as nrocliente, tipodoc as barra, true as aporte
                          FROM afiljub
                       ) as aportesafiliados USING(nrocliente, barra)
                       WHERE nroinforme=rinforme.nroinforme AND idcentroinformefacturacion=rinforme.idcentroinformefacturacion;

               IF reginforme.idinformefacturaciontipo=2 THEN
                       PERFORM vincularordenconfactura(rinforme.nroinforme::integer,rinforme.idcentroinformefacturacion);
               ELSE 
                       IF reginforme.idinformefacturaciontipo=6 AND Not nullvalue(reginforme.aporte) THEN
                                 --FALTA VER EL TEMA DE LA BARRA PQ NO DEBEN ENTRAR LOS APORTES LIC SIN HAB ACA
                                  ---- 01/10/2019 PERFORM modificaritemfacturajubilados( elcomprobante.tipocomprobante::integer,elcomprobante.nrosucursal::integer,elcomprobante.nrofactura,elcomprobante.tipofactura::varchar );
                        END IF;
               END IF; 
               
                IF reginforme.idinformefacturaciontipo=10 and elcomprobante.tipofactura='FA' THEN
  --- KR 24-02-15 Si es una FA hay que generar la deuda ESTOY EN LA ESPERA DE CUENTAS.
--KR 16-07-21 Ahora se genera con el comprobante la deuda
--                     PERFORM generardeudaordenesinstitucion(rinforme.nroinforme::integer);
               END IF ; 

               -- Verifico si sr trata de un informe de facturacion ND 5-Nota Debito
              --- VAS 22-10-2014
               IF reginforme.idinformefacturaciontipo=5 THEN
  --- VAS 22-10-2014              
--    SELECT INTO resp * FROM generarpagoctactepagonoafil_nd (concat(rinforme.nroinforme,'-',rinforme.idcentroinformefacturacion::varchar));
              SELECT INTO resp * FROM generarpagoctactepagoprestador_nd (concat(rinforme.nroinforme,'-',rinforme.idcentroinformefacturacion::varchar));
               END IF ;
            
          IF reginforme.idinformefacturaciontipo<>13 THEN 
              --KR 07-08 solo genero movimiento en la ctacte si el informe no es de expendio reintegro

              ---- VAS 25-04-2047 Actualizo el numero de comprobante de facturacion correspondiente al informe
              UPDATE ctactedeudacliente SET movconcepto = concat('Informe: ',rinforme.nroinforme,' - ' ,rinforme.idcentroinformefacturacion::varchar,
              elcomprobante.tipofactura,' :',elcomprobante.nrosucursal,'-',elcomprobante.nrofactura)
              WHERE idcomprobantetipos=21 and (idcomprobante / 100) = rinforme.nroinforme;

          ELSE

--KR 28-02-18 llamo a un nuevo SP facturacion_expendioreintegro que realiza las acciones correspondientes a la facturacion de un reintegro
/*
 -- KR 07-08-17 genero la minuta
              PERFORM generarminutapagoexpendioreintegro(rinforme.nroinforme::integer,rinforme.idcentroinformefacturacion);
              SELECT INTO elidpagocontable generarordenpagodesdeinforme(rinforme.nroinforme ,rinforme.idcentroinformefacturacion);
 */
             PERFORM facturacion_expendioreintegro(rinforme.nroinforme::integer,rinforme.idcentroinformefacturacion);              
          END IF;
     
 --KR 14-03-19 Verifico que el cliente del pendiente de facturacion sea el mismo que se facturo

          SELECT INTO  respclienteok facturaventa_cliente_correcto(concat('{tipofactura=',elcomprobante.tipofactura,', tipocomprobante=',elcomprobante.tipocomprobante,', nrosucursal=',elcomprobante.nrosucursal,', nrofactura=',elcomprobante.nrofactura,'}')) as clienteok;
     /*     IF NOT(respclienteok.clienteok) THEN
              RAISE EXCEPTION ' El cliente del comprobante de facturación NO ES EL MISMO que estaba pendiente de facturar (en el informe)!! %', reginforme USING HINT = 'Verificar el comprobante de facturacion impreso.';
          END IF; 
*/


     FETCH cinforme into rinforme;
     END LOOP;
     CLOSE cinforme;

    /* Se guarda la informacion del usuario que genero el comprobante */
    SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
    IF not found THEN
             elidusuario = 25;
    ELSE
        elidusuario = rusuario.idusuario;
    END IF;

    INSERT INTO facturaventausuario (tipocomprobante,nrosucursal, nrofactura, tipofactura, idusuario, nrofacturafiscal )
    VALUES   (elcomprobante.tipocomprobante,elcomprobante.nrosucursal,elcomprobante.nrofactura, elcomprobante.tipofactura,elidusuario,elcomprobante.nrofactura);
 
 

  RETURN NEXT elcomprobante;
END;$function$
