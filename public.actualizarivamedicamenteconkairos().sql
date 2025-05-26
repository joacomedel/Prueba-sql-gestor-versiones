CREATE OR REPLACE FUNCTION public.actualizarivamedicamenteconkairos()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
/* Actualiza el tipoiva en far_articulo y el precio en far_precioarticulo 
*/
	alta refcursor;

    arthijos refcursor;

	elem RECORD;
    respuesta RECORD;
    rusuario RECORD;

BEGIN


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

--GK 2-05-2022
 
-- Busco articulo en far_articulo cuyo tipoiva difiere con el iva de medicamentosys

OPEN alta FOR 
            SELECT 
                ti.*,
                --msys.iva,
                --fa.idiva,
                fa.idcentroarticulo,
                fa.idarticulo,
                idprecioarticulo,
                vm.vmfechaini,
                round((vm.vmimporte - round((vm.vmimporte/ (1+ti.porcentaje))::numeric,2))::numeric,2) as importeiva, 
                round((vm.vmimporte/(1+ti.porcentaje))::numeric,2) as importesiniva,
                vm.vmimporte,
                m.mpresentacion,
                m.mnombre,
                adescripcion,
                acodigobarra,
                pavalor,
                pimporteiva,
                pvalorcompra,
                (pavalor * ti.porcentaje) + pavalor as precioventa 
                    
            FROM valormedicamento as vm
            NATURAL JOIN medicamento as m
            NATURAL JOIN far_medicamento  
            LEFT JOIN ( SELECT * FROM medicamentosys 
                NATURAL JOIN valormedicamento as vm 
                WHERE nullvalue(vm.vmfechafin)  AND idvalor=vm.idvalor AND ikfechainformacion=(SELECT MAX(ikfechainformacion) FROM medicamentosys 
                    WHERE idvalor=vm.idvalor)) as msys USING(mnroregistro,mcodbarra,idvalor)
            NATURAL JOIN far_articulo as fa 
            JOIN tipoiva ti ON ( CASE WHEN msys.iva=1 THEN  2= ti.idiva ELSE 1= ti.idiva END)
            JOIN far_precioarticulo as fp on fp.idarticulo = fa.idarticulo AND fp.idcentroarticulo =fa.idcentroarticulo and nullvalue(pafechafin)

            WHERE true
            AND nullvalue(vm.vmfechafin) 
            AND nullvalue(idarticulopadre) 
            --AND ((msys.iva=1 AND fa.idiva!=2) OR (msys.iva=0 AND fa.idiva!=1))
            AND fp.pimporteiva=0
            AND ti.idiva=2
            AND fa.apreciokairos


             ;



FETCH alta INTO elem;
WHILE  found LOOP
        -- GK 20
        /* Modifico el tipo de iva en far_articulo */
        UPDATE far_articulo SET idiva=elem.idiva WHERE idarticulo = elem.idarticulo AND idcentroarticulo = elem.idcentroarticulo; 

       /* Modifico el precio viegente */
       UPDATE far_precioarticulo SET pafechafin = now() WHERE idarticulo = elem.idarticulo AND nullvalue(far_precioarticulo.pafechafin) AND idcentroarticulo = elem.idcentroarticulo;
       
       /* Inserto el nuevo valor */
       INSERT INTO far_precioarticulo (idarticulo,idcentroarticulo,pafechaini,pavalor,pimporteiva,pvalorcompra,idusuariocarga)
       VALUES(
        elem.idarticulo,
        elem.idcentroarticulo,
        elem.vmfechaini,
        elem.importesiniva,
        elem.importeiva,
        round((elem.importesiniva + CASE WHEN nullvalue(elem.importeiva) THEN 0 ELSE elem.importeiva END)::numeric,2),
        rusuario.idusuario
        );

fetch alta into elem;
END LOOP;
CLOSE alta;

-- Modifico el precio de los articulos hijos, en funcion de precio de los articulos padres
OPEN arthijos FOR 
    SELECT 
        fphijo.*,
        fa.idcentroarticulo,
        CASE WHEN nullvalue(fa.afactorcorreccion) THEN fa.afraccion ELSE  fa.afactorcorreccion END,
        round((( (CASE WHEN nullvalue(fp.pvalorcompra) THEN fp.pavalor ELSE fp.pvalorcompra END) / CASE WHEN nullvalue(fa.afactorcorreccion) THEN fa.afraccion ELSE fa.afactorcorreccion END)/(1+porcentaje)) ::numeric ,2) as pavalorhijo,
        round(((fp.pavalor/ CASE WHEN nullvalue(fa.afactorcorreccion) THEN fa.afraccion ELSE fa.afactorcorreccion END)*(porcentaje))::numeric,2) as pimporteivahijo
    FROM far_articulo as fa 
    NATURAL JOIN tipoiva 
    JOIN far_precioarticulo as fp on fp.idarticulo = fa.idarticulopadre AND fp.idcentroarticulo = fa.idcentroarticulopadre AND nullvalue(fp.pafechafin)
    JOIN far_precioarticulo as fphijo on fphijo.idarticulo = fa.idarticulo 
                        and  fphijo.idcentroarticulo = fa.idcentroarticulo 
                        and nullvalue(fphijo.pafechafin)
    
    WHERE  not nullvalue(idarticulopadre) 
    AND round((( (CASE WHEN nullvalue(fp.pvalorcompra) THEN fp.pavalor ELSE fp.pvalorcompra END) 
        / CASE WHEN nullvalue(fa.afactorcorreccion) THEN fa.afraccion ELSE fa.afactorcorreccion END)/(1+porcentaje)) ::numeric ,2) > fphijo.pavalor;

FETCH arthijos INTO elem;
WHILE  found LOOP

       /* Modifico el precio viegente */
       UPDATE far_precioarticulo SET pafechafin = now() WHERE far_precioarticulo.idarticulo = elem.idarticulo AND nullvalue(far_precioarticulo.pafechafin) AND idcentroarticulo = elem.idcentroarticulo;
       /* Inserto el nuevo valor */

       INSERT INTO far_precioarticulo (idarticulo,idcentroarticulo,pafechaini,pavalor,pimporteiva,pvalorcompra,idusuariocarga)
       VALUES(elem.idarticulo,elem.idcentroarticulo,elem.pafechaini,elem.pavalorhijo,elem.pimporteivahijo,round((elem.pavalorhijo + CASE WHEN nullvalue(elem.pimporteivahijo) THEN 0 ELSE elem.pimporteivahijo END)::numeric,2),rusuario.idusuario);

fetch arthijos into elem;
END LOOP;
CLOSE arthijos;

--SELECT INTO respuesta * FROM far_arreglarprecioarticulo();

-- Modifico el precio de los articulos Hermanos de un articulo Kairos
-- 19-04-2022 GK Agrego control de estado vinculo hermanos ( 4- desviculado)
OPEN arthijos FOR 
    SELECT 
        fph.idarticulo,
        fph.idcentroarticulo,
        fpk.pafechaini,
        fpk.pavalor,
        fpk.pimporteiva,
        fpk.pvalorcompra,
        fpk.idusuariocarga
    FROM far_precioarticulohermano as ph 
    LEFT JOIN far_articuloestado as fae on fae.idarticulo = ph.idarticulokairo AND fae.idcentroarticulo = ph.idcentroarticulokairo AND nullvalue(aefechafin)
    LEFT JOIN far_precioarticulo as fpk on fpk.idarticulo = ph.idarticulokairo 
        and fpk.idcentroarticulo = ph.idcentroarticulokairo 
        and nullvalue(fpk.pafechafin)
    LEFT JOIN far_precioarticulo as fph on fph.idarticulo = ph.idarticulohermano 
        and  fph.idcentroarticulo = ph.idcentroarticulohermano 
        and nullvalue(fph.pafechafin)
    WHERE fpk.pavalor <> fph.pavalor
        AND idarticuloestadotipo=2;

FETCH arthijos INTO elem;
WHILE  found LOOP

       /* Modifico el precio viegente */
       UPDATE far_precioarticulo SET pafechafin = now() WHERE far_precioarticulo.idarticulo = elem.idarticulo AND nullvalue(far_precioarticulo.pafechafin) AND idcentroarticulo = elem.idcentroarticulo;
       /* Inserto el nuevo valor */

       INSERT INTO far_precioarticulo (idarticulo,idcentroarticulo,pafechaini,pavalor,pimporteiva,pvalorcompra,idusuariocarga)
       VALUES(elem.idarticulo,elem.idcentroarticulo,elem.pafechaini,elem.pavalor,elem.pimporteiva,elem.pvalorcompra,elem.idusuariocarga);

fetch arthijos into elem;
END LOOP;
CLOSE arthijos;

return 'true';
END;$function$
