CREATE OR REPLACE FUNCTION public.far_migrarplancoberturamedicamento()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
  	cursorarticulos CURSOR FOR
select idplan,mnroregistro,coporcentaje,comontofijo,cocomentario
from far_temp_coberturas
     join far_medicamento using(mnroregistro)
where idplan in
(
select idplancobertura from far_plancobertura where idobrasocial in
	(
	select idobrasocial
	from far_obrasocial
	where (
	osdescripcion ilike ('%apm%')
	or osdescripcion ilike ('%osde binario%')
	or osdescripcion ilike ('%galeno%')
	or osdescripcion ilike ('%swiss%')
	or osdescripcion ilike ('%issn%')
	)
	)
);


	rarticulo RECORD;
	rartexistente record;
	elidmovimientostock integer;
	elidarticulo bigint;
	contador integer;
	elidajuste  integer;
	resp boolean;

BEGIN

    OPEN cursorarticulos;
   -- start transaction;
    contador=0;
    FETCH cursorarticulos into rarticulo;
    WHILE  found LOOP

           insert into far_plancoberturamedicamento(idplancobertura,mnroregistro,pcmporcentaje,pcmmontofijo,pcmcomentario)
           values(rarticulo.idplan,rarticulo.mnroregistro,rarticulo.coporcentaje,rarticulo.comontofijo,rarticulo.cocomentario);
           contador = contador + 1;
           /*
           if contador=1000 THEN
              commit;
              contador=0;
             -- start TRANSACTION;
           end if;
           */
    fetch cursorarticulos into rarticulo;
    END LOOP;
    close cursorarticulos;


return 'true';
END;
$function$
