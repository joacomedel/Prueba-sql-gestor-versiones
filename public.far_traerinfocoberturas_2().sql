CREATE OR REPLACE FUNCTION public.far_traerinfocoberturas_2()
 RETURNS SETOF far_plancoberturainfomedicamentoafiliado_2
 LANGUAGE plpgsql
AS $function$DECLARE

       carticulo CURSOR FOR SELECT *
                           FROM tfar_articulo;

--               tfar_articulo(mnroregistro,idafiliado,idobrasocial)

       rarticulo RECORD;
       rmed RECORD;
       rpersona RECORD;
       rafiliado RECORD;
       rafil RECORD;
       elafiliado bigint;
       vnrodoc varchar;
       vtipodoc integer;
       vidafiliadoos bigint;
       vidafiliadososunc bigint;
       vidafiliadoamuc bigint;
       vidvalidacion integer;
       vmnroregistro varchar;
       re boolean;
       tieneamuc boolean;
       rcob far_plancoberturainfomedicamentoafiliado_2;

begin

OPEN carticulo;
FETCH carticulo into rarticulo;

WHILE  found LOOP

--Verifico que el artÃ­culo estÃ© en far_articulo, sino esta lo inserto
vmnroregistro = rarticulo.mnroregistro;

SELECT * INTO rmed FROM far_medicamento WHERE mnroregistro=rarticulo.mnroregistro;
IF NOT FOUND THEN       
       
        SELECT * INTO rmed FROM far_articulo WHERE idarticulo=rarticulo.idarticulo AND idcentroarticulo=rarticulo.idcentroarticulo;
        
        IF FOUND THEN
              vmnroregistro =concat(rmed.idarticulo,'-',rmed.idcentroarticulo);
        ELSE
              SELECT * INTO  re FROM far_cargarmedicamento(rarticulo.mnroregistro::integer);
        END IF;
END IF;

----------------------------------------------------------------------

IF (rarticulo.idobrasocial = 1 OR rarticulo.idobrasocial = 9) THEN

     IF length(rarticulo.idafiliado) > 8  THEN

       --Me envian un nrodoc + tipodoc

       --Es un afiliado de Sosunc, puede no estar cargado en far_afiliado

       vnrodoc = substring(rarticulo.idafiliado from 1 for 8 );

       vtipodoc = substring(rarticulo.idafiliado from 9 for 1 )::integer;

     ELSE

       --Envian el Idafiliado de alguna obra social

       SELECT into rafil * from far_afiliado WHERE idafiliado=rarticulo.idafiliado  limit 1;

      IF FOUND THEN

          vnrodoc = rafil.nrodoc;

          vtipodoc = rafil.tipodoc;

          vidafiliadoos = rarticulo.idafiliado;

       END IF;

     END IF;

ELSE

    -- No es Afiliado de SOSUNC, debe estar cargado en far_afiliado

    SELECT into rafil * from far_afiliado WHERE idafiliado=rarticulo.idafiliado limit 1;

    vnrodoc = rafil.nrodoc;

    vtipodoc = rafil.tipodoc;

    vidafiliadoos = rarticulo.idafiliado;

END IF;

SELECT INTO rpersona *,cliente.barra as barracli FROM persona
LEFT JOIN benefsosunc USING(nrodoc,tipodoc)
LEFT JOIN cliente ON cliente.nrocliente = persona.nrodoc OR cliente.nrocliente = benefsosunc.nrodoctitu
 WHERE nrodoc = vnrodoc AND tipodoc = vtipodoc AND fechafinos >= current_date - 30::integer;

IF FOUND THEN

-- Es Afiliado de SOSUNC
   SELECT into rafil * from far_afiliado WHERE nrodoc = vnrodoc AND tipodoc = vtipodoc and idobrasocial=1;

   IF NOT FOUND then

   -- NO estÃ¡ cargado en far_afiliado para SOSUNC

      INSERT INTO far_afiliado(idobrasocial,aidafiliadoobrasocial,aapellidoynombre,iddireccion,nrocliente,barra,tipodoc,nrodoc)
      VALUES(1,rarticulo.idafiliado,concat(rpersona.nombres,' ' , rpersona.apellido),rpersona.iddireccion,rpersona.nrocliente,rpersona.barracli,rpersona.tipodoc,rpersona.nrodoc);

      elafiliado = currval('far_afiliado_idafiliado_seq');

   ELSE

       elafiliado = rafil.idafiliado;

   END IF;

   vidafiliadososunc = elafiliado;

   IF nullvalue(vidafiliadoos) THEN

      vidafiliadoos =vidafiliadososunc;

   END IF;

-------------------------- AMUC

tieneamuc = false;

tieneamuc = expendio_tiene_amuc(vnrodoc,vtipodoc);

if tieneamuc then
   SELECT into rafil * from far_afiliado  WHERE nrodoc = vnrodoc AND tipodoc = vtipodoc and idobrasocial=3;
   IF NOT FOUND then
   -- NO estÃ¡ cargado en far_afiliado para AMUC o el plan no esta vigente
            INSERT INTO far_afiliado(idobrasocial,aidafiliadoobrasocial,aapellidoynombre,iddireccion,nrocliente,barra,tipodoc,nrodoc)
            VALUES(3,rarticulo.idafiliado,concat(rpersona.nombres,' ' , rpersona.apellido),rpersona.iddireccion,rpersona.nrocliente,rpersona.barracli,rpersona.tipodoc,rpersona.nrodoc);
            elafiliado = currval('far_afiliado_idafiliado_seq');
      else
          -- Alguna vez estuvo en far_afiliado para AMUC, entonces solo recupero el idafiliado
            elafiliado = rafil.idafiliado;
     end if;

ELSE --NO TIENE AMUC
    elafiliado = null;

end if;

vidafiliadoamuc = elafiliado;

-------------------------- AMUC

END IF;

--vmnroregistro = rarticulo.mnroregistro;
vidvalidacion = rarticulo.idvalidacion;


IF (rarticulo.idobrasocial = 9) THEN -- Se vende sin obra social

vidafiliadososunc = null;
vidafiliadoamuc = null;
vidvalidacion = null;
END IF;


FETCH carticulo into rarticulo;

END LOOP;

CLOSE carticulo;




for rcob in 

SELECT idobrasocial,
  idplancobertura ,
  idafiliado ,
  coberturas.mnroregistro,
  prioridad ,
  porccob ,
  montofijo ,
  pcdescripcion ,
  coberturas.detalle as detallecob ,
  coberturas.codautorizacion ,
  0 as cantidadaprobada,
  idarticulo ,
  idcentroarticulo ,
  idrubro ,
  adescripcion ,
  precio ,
  rdescripcion ,
  astockmin ,
  astockmax ,
  acomentario ,
  idiva ,
  adescuento ,
  acodigointerno ,
  acodigobarra ,
  f.detalle ,
  lstock ,
  troquel ,
  presentacion ,
  laboratorio ,
  idlaboratorio ,
  monodroga ,
  idmonodroga ,
  porciva  FROM (select *
                 from far_traercoberturasarticuloafiliado_4
                 (vmnroregistro,vidafiliadoos,vidafiliadososunc,vidafiliadoamuc,vidvalidacion)
                ) as coberturas
                JOIN far_buscarinfomedicamentos_2(concat('%',vmnroregistro,'%')) as f
			ON f.mnroregistro = coberturas.mnroregistro OR (f.idarticulo = trim(split_part(coberturas.mnroregistro,'-',1))  AND f.idcentroarticulo = trim(split_part(coberturas.mnroregistro,'-',2)))
		--JOIN far_validacionitems as vi  ON  (f.acodigobarra = vi.codbarras AND idvalidacion = vidvalidacion )



--select * from far_traercoberturasarticuloafiliado (vmnroregistro,vidafiliadoos,vidafiliadososunc,vidafiliadoamuc,vidvalidacion)
--(vmnroregistro,5415,null,null,vidvalidacion)

--	('7592',null,5408,5409)
-- ('41671',5415,null,null,152)

	loop

return next rcob;

end loop;

end;$function$
