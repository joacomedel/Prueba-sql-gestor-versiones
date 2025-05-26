CREATE OR REPLACE FUNCTION public.sys_cargarmedicamentodesdemedicamentosys_bk()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       cvalorregistros refcursor;
       unvalorreg record;
       unvalormed record;
       rverifica record;	
       
BEGIN 

     OPEN cvalorregistros FOR select ms.lnombre,ms.mnroregistro,ms.idlaboratorio,ms.mcodbarra,ms.idfarmtipoventa,ms.mtroquel,ms.mpresentacion,ms.mnombre
				from medicamentosys as ms
				LEFT JOIN medicamento USING(mcodbarra)
				where  (nullvalue(medicamento.mnroregistro)
					 OR (nullvalue(ms.idvalor) AND ikfechainformacion >= '2015-01-01'))
                                        AND not nullvalue(ms.mcodbarra)
				GROUP BY ms.lnombre,ms.mnroregistro,ms.idlaboratorio,ms.mcodbarra,ms.idfarmtipoventa,ms.mtroquel,ms.mpresentacion,ms.mnombre;

     FETCH cvalorregistros into unvalorreg;
     WHILE FOUND LOOP
	SELECT INTO unvalormed * FROM laboratorio WHERE idlaboratorio = unvalorreg.idlaboratorio;
	IF NOT FOUND THEN
		INSERT INTO laboratorio (idlaboratorio,lnombre) VALUES(unvalorreg.idlaboratorio,unvalorreg.lnombre);
	END IF;

	SELECT INTO unvalormed * FROM medicamento 
	                         LEFT JOIN far_medicamento USING(mnroregistro,nomenclado)
	                         LEFT JOIN far_articulo USING(idarticulo,idcentroarticulo)
	                         WHERE medicamento.mnroregistro = unvalorreg.mnroregistro AND medicamento.nomenclado = true;
	IF FOUND THEN 
		IF (unvalormed.mcodbarra <> unvalormed.acodigobarra) THEN
			--El codigo de barras del medicamento es diferente del cargado en far_articulo, lo dejo asi
                          /*UPDATE medicamento SET mcodbarra = unvalormed.acodigobarra::bigint
				 		WHERE mnroregistro = unvalorreg.mnroregistro
				 		AND nomenclado = true;*/

                         /*UPDATE medicamentosys SET mcodbarra= unvalormed.acodigobarra::bigint
				 		WHERE mnroregistro = unvalorreg.mnroregistro
				 		AND nomenclado = true;*/
                          --MaLaPi 08-10-2018 dejo como valido el codigo de barra que informa Kairos, no el que se ingresa en la farmacia.
                          --MaLaPi 08-11-2018 Hay que verificar que ese codigo de barra no se este usado por otro articulo antes de cambiarlo, si es asi, hay que resolverlo a mano.
                          SELECT INTO rverifica * FROM far_articulo WHERE acodigobarra = unvalormed.mcodbarra;
                          IF FOUND THEN 
				IF rverifica.idarticulo <> unvalormed.idarticulo 
					AND rverifica.idarticulo <> unvalormed.idcentroarticulo THEN
					--MaLapi 08-11-2018 dejo guardado el idarticulo que genera el conflicto con el codigo de barra
					UPDATE medicamentosys SET mcodbarraotroarticulo = concat(rverifica.idarticulo,'-',rverifica.idcentroarticulo)
					WHERE mnroregistro = unvalorreg.mnroregistro
				 		AND nomenclado = true AND nullvalue(medicamentosys.idvalor);
				END IF;

				
                          ELSE 
				UPDATE far_articulo SET acodigobarra = unvalormed.mcodbarra 
							WHERE idarticulo = unvalormed.idarticulo 
							AND idcentroarticulo = unvalormed.idcentroarticulo;
			  END IF;
                          
                          
		ELSE
		UPDATE medicamento SET idlaboratorio = unvalorreg.idlaboratorio
				 		,idfarmtipoventa = unvalorreg.idfarmtipoventa
				 		,mtroquel = unvalorreg.mtroquel
				 		,mpresentacion = unvalorreg.mpresentacion
				 		,mnombre = unvalorreg.mnombre
				 		WHERE mnroregistro = unvalorreg.mnroregistro
				 		AND nomenclado = true;
                END IF;

	ELSE
		INSERT INTO medicamento (mnroregistro,idlaboratorio,mcodbarra,idfarmtipoventa,mtroquel,mpresentacion,mnombre)
		VALUES (unvalorreg.mnroregistro,unvalorreg.idlaboratorio,unvalorreg.mcodbarra,unvalorreg.idfarmtipoventa,unvalorreg.mtroquel,unvalorreg.mpresentacion,unvalorreg.mnombre);
	END IF;
	
     FETCH cvalorregistros into unvalorreg;
     END LOOP;
     close cvalorregistros;
     return 'Listo';
END;
$function$
