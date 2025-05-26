CREATE OR REPLACE FUNCTION public.actualizarpreciomedicamenteconkairos()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
/* Actualiza los valores de los articulos de farmacias que son informados por Kairos.
   Solo actualiza los productos, que tienen un precio de venta menor al que informo Kairos.
*/
	alta refcursor;
    arthijos refcursor;

	elem RECORD;
    elemaux RECORD;
    respuesta RECORD;
    rusuario RECORD;
BEGIN
--Marco con precio Kairos todos los articulos que estan asignados al rubro de pedidos de farmacia y ademas estan en la tabla medicamentos.
--MaLaPi 20-11-2013 Ahora solo marco con precio Kairos, aquellos productos que no tienen un precio de compra vigente.

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

UPDATE far_articulo SET apreciokairos = true WHERE (idarticulo,idcentroarticulo) IN (
select DISTINCT fa.idarticulo,fa.idcentroarticulo
from far_articulo as fa
NATURAL JOIN far_rubro
join medicamento  ON medicamento.mcodbarra = fa.acodigobarra 
--12-11-2018 MaLapi Saco la restriccion que impide poner como kairos los articulos que cargan precio de compra. Le agrego que sea del rubro de medicamentos.
--LEFT JOIN far_preciocompra as fpc on fpc.idarticulo = fa.idarticulo AND nullvalue(fpc.pcfechafin)
where idtipopedido = 1 AND not apreciokairos 
 and idrubro = 4 and nullvalue(idarticulopadre)
--AND nullvalue(fpc.idarticulo)

);
--Modifico todos los articulos que son de kairos y que tienen variación en el importe en medicamentos. 

OPEN alta FOR select ti.*,fa.idcentroarticulo,fa.idarticulo,idprecioarticulo,vmfechaini,
round((vmimporte - round((vmimporte/ (1+ti.porcentaje))::numeric,2))::numeric,2) as importeiva, 
round((vmimporte/(1+ti.porcentaje))::numeric,2) as importesiniva,
vmimporte,mpresentacion,mnombre,adescripcion,acodigobarra,pavalor,pimporteiva,pvalorcompra,(pavalor * ti.porcentaje) + pavalor as precioventa 
                    from valormedicamento
                    natural join medicamento
                    natural join far_medicamento 
                    natural JOIN far_articulo as fa 
                    JOIN tipoiva ti ON fa.idiva = ti.idiva
                    JOIN far_precioarticulo as fp on fp.idarticulo = fa.idarticulo AND fp.idcentroarticulo =fa.idcentroarticulo and nullvalue(pafechafin)
                    where nullvalue(vmfechafin) AND nullvalue(idarticulopadre) 
--Malapi 09/12/2014 Modifico para que solo cambio los precios si realmente cambiaron.
 and (
( not  fa.apreciokairos AND  (round((vmimporte/(1+ti.porcentaje))::numeric,2) - round(pavalor::numeric,2))  > 1.0 ) 
OR

 ( abs(round((vmimporte/(1+ti.porcentaje))::numeric,2) - round(pavalor::numeric,2)) > 0.1 AND  fa.apreciokairos )
 ) 
;
FETCH alta INTO elem;
WHILE  found LOOP
        -- GK 5-5-2022 Agrego UPDATE para la actualización del tipo iva según la información provista por alfabeta
        /* Modifico el tipo de iva en far_articulo */
        UPDATE far_articulo 
        SET idiva=(CASE WHEN nullvalue(iva.idiva) THEN 1 ELSE iva.idiva END )
        FROM (  SELECT msys.idiva
                FROM far_articulo
                LEFT JOIN ( 
                    SELECT * 
                    FROM medicamentosys as msys
                    NATURAL JOIN far_medicamento as fm
                    NATURAL JOIN valormedicamento as vm 
                    JOIN tipoiva ti ON ( CASE WHEN msys.iva=1 THEN  2= ti.idiva ELSE 1= ti.idiva END)
                    WHERE nullvalue(vm.vmfechafin)  
                        AND idvalor=vm.idvalor 
                        AND ikfechainformacion=(
                                                    SELECT MAX(ikfechainformacion) 
                                                    FROM medicamentosys 
                                                    WHERE idvalor=vm.idvalor
                                                )
                           ) as msys USING(idarticulo,idcentroarticulo)
               WHERE idarticulo = elem.idarticulo AND idcentroarticulo = elem.idcentroarticulo
            ) as iva 
         WHERE idarticulo = elem.idarticulo 
         AND idcentroarticulo = elem.idcentroarticulo
         AND (iva.idiva!=far_articulo.idiva); 


         -- GK 10-05-2022 si hago un UPDATE recalculo montos
        IF FOUND THEN

            SELECT INTO elemaux 
                ti.*,
                fa.idcentroarticulo,
                fa.idarticulo,
                idprecioarticulo,
                vmfechaini,
                round((vmimporte - round((vmimporte/ (1+ti.porcentaje))::numeric,2))::numeric,2) as importeiva, 
                round((vmimporte/(1+ti.porcentaje))::numeric,2) as importesiniva,
                vmimporte,
                mpresentacion,
                mnombre,
                adescripcion,
                acodigobarra,
                pavalor,
                pimporteiva,
                pvalorcompra,
                (pavalor * ti.porcentaje) + pavalor as precioventa 
            FROM valormedicamento
            NATURAL JOIN medicamento
            NATURAL JOIN far_medicamento 
            NATURAL JOIN far_articulo as fa 
            JOIN tipoiva ti ON fa.idiva = ti.idiva
            JOIN far_precioarticulo as fp on fp.idarticulo = fa.idarticulo AND fp.idcentroarticulo =fa.idcentroarticulo and nullvalue(pafechafin)
            WHERE true
            AND nullvalue(vmfechafin) 
            AND nullvalue(idarticulopadre)
            AND fa.idarticulo = elem.idarticulo
            AND fa.idcentroarticulo=elem.idcentroarticulo;


            elem.importeiva=elemaux.importeiva;
            elem.importesiniva=elemaux.importesiniva;


        END IF;

        /* Modifico el precio viegente */
        UPDATE far_precioarticulo SET pafechafin = now() WHERE far_precioarticulo.idarticulo = elem.idarticulo AND nullvalue(far_precioarticulo.pafechafin) AND idcentroarticulo = elem.idcentroarticulo;
        /* Inserto el nuevo valor */

        INSERT INTO far_precioarticulo (idarticulo,idcentroarticulo,pafechaini,pavalor,pimporteiva,pvalorcompra,idusuariocarga)
        VALUES(elem.idarticulo,elem.idcentroarticulo,elem.vmfechaini,elem.importesiniva,elem.importeiva,round((elem.importesiniva + CASE WHEN nullvalue(elem.importeiva) THEN 0 ELSE elem.importeiva END)::numeric,2),rusuario.idusuario);

fetch alta into elem;
END LOOP;
CLOSE alta;

-- Modifico el precio de los articulos hijos, en funcion de precio de los articulos padres
OPEN arthijos FOR SELECT fphijo.*,fa.idcentroarticulo,CASE WHEN nullvalue(fa.afactorcorreccion) 
                         THEN fa.afraccion ELSE  fa.afactorcorreccion END
                         ,round((( (CASE WHEN nullvalue(fp.pvalorcompra) THEN fp.pavalor ELSE fp.pvalorcompra END)
                         / CASE WHEN nullvalue(fa.afactorcorreccion) THEN fa.afraccion 
                         ELSE fa.afactorcorreccion END)/(1+porcentaje)) ::numeric ,2) as pavalorhijo
                         ,round(((fp.pavalor/ CASE WHEN nullvalue(fa.afactorcorreccion) 
                             THEN fa.afraccion ELSE fa.afactorcorreccion END)*(porcentaje))::numeric,2) as pimporteivahijo
                         FROM far_articulo as fa NATURAL JOIN tipoiva 
                         JOIN far_precioarticulo as fp on fp.idarticulo = fa.idarticulopadre 
                         and fp.idcentroarticulo = fa.idcentroarticulopadre and nullvalue(fp.pafechafin)
                         JOIN far_precioarticulo as fphijo on fphijo.idarticulo = fa.idarticulo 
                                                               and  fphijo.idcentroarticulo = fa.idcentroarticulo 
                                                               and nullvalue(fphijo.pafechafin)
                         where  not nullvalue(idarticulopadre) AND /*round((fp.pavalor / CASE WHEN nullvalue(fa.afactorcorreccion) THEN fa.afraccion ELSE fa.afactorcorreccion END) ::numeric ,2) */
                           round((( (CASE WHEN nullvalue(fp.pvalorcompra) THEN fp.pavalor ELSE fp.pvalorcompra END)
                         / CASE WHEN nullvalue(fa.afactorcorreccion) THEN fa.afraccion 
                         ELSE fa.afactorcorreccion END)/(1+porcentaje)) ::numeric ,2) > fphijo.pavalor;

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
