CREATE OR REPLACE FUNCTION public.far_dararticulosparacoberturas()
 RETURNS SETOF far_articulo
 LANGUAGE plpgsql
AS $function$DECLARE

       carticulo CURSOR FOR SELECT *
                   FROM tfar_articulo;
                   --WHERE nullvalue(idarticulo) OR idarticulo = 0;
       
       rarticulo2 far_articulo;
       rarticulo RECORD;
	rmed RECORD;
        rverif RECORD;
        re boolean;

begin

OPEN carticulo;
FETCH carticulo into rarticulo;
WHILE  found LOOP
--vmnroregistro = rarticulo.mnroregistro;
--Verifico que el arti­culo esta en far_articulo, sino esta lo inserto
SELECT * INTO rmed FROM far_medicamento WHERE mnroregistro=rarticulo.mnroregistro;
IF NOT FOUND THEN
        SELECT * INTO rmed FROM far_articulo WHERE idarticulo=rarticulo.idarticulo AND idcentroarticulo = rarticulo.idcentroarticulo;
        IF FOUND THEN
              SELECT * INTO rverif FROM medicamento WHERE mcodbarra=rmed.acodigobarra; 
              IF FOUND THEN  --Cargo en far_medicamento
                  insert into far_medicamento(idarticulo,idcentroarticulo,mnroregistro,nomenclado) values(rmed.idarticulo,rmed.idcentroarticulo,rarticulo.mnroregistro::integer,rverif.nomenclado);
                  --vmnroregistro = rarticulo.mnroregistro; 
                  --vmnroregistro =concat(rmed.idarticulo,'-',rmed.idcentroarticulo);
              --ELSE 
                  --vmnroregistro =concat(rmed.idarticulo,'-',rmed.idcentroarticulo);
              END IF;
        ELSE
              SELECT * INTO  re FROM far_cargarmedicamento(rarticulo.mnroregistro::integer);
              SELECT * INTO rmed FROM far_medicamento WHERE mnroregistro=rarticulo.mnroregistro;
              UPDATE tfar_articulo SET idarticulo = rmed.idarticulo,idcentroarticulo= rmed.idcentroarticulo 
                       WHERE mnroregistro=rarticulo.mnroregistro;
              --vmnroregistro =concat(rmed.idarticulo,'-',rmed.idcentroarticulo);

        END IF;
ELSE 
	IF nullvalue(rarticulo.idarticulo) OR rarticulo.idarticulo = 0 THEN
		UPDATE tfar_articulo SET idarticulo = rmed.idarticulo,idcentroarticulo= rmed.idcentroarticulo WHERE mnroregistro=rarticulo.mnroregistro;
	END IF;
END IF;

FETCH carticulo into rarticulo;
END LOOP;


for rarticulo2 in 
SELECT far_articulo.* FROM far_articulo
		      JOIN tfar_articulo USING(idarticulo,idcentroarticulo)
	loop

return next rarticulo2;

end loop;

end;
$function$
