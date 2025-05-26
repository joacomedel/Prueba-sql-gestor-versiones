CREATE OR REPLACE FUNCTION public.far_traerinfocoberturas_val()
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
       rafiloso RECORD;
       rmutual RECORD;
       rafilmutu RECORD;
       rverif RECORD;
       elafiliado bigint;
       vidafiliadomutual bigint;
       vquemutual integer;
       vnrodoc varchar;
       vtipodoc integer;
       vidafiliadoos bigint;
       vidafiliadososunc bigint;
       vidafiliadoamuc bigint;
       vidvalidacion integer;
       vidcentrovalidacion integer;
       vmnroregistro varchar;
       re boolean;
       tieneamuc boolean;
       rcob far_plancoberturamedicamentoafiliado;
       rcobinfomedi far_plancoberturainfomedicamentoafiliado_2;

begin

OPEN carticulo;
FETCH carticulo into rarticulo;

WHILE  found LOOP

vmnroregistro = rarticulo.mnroregistro;
--Verifico que el artÃÂ­culo estÃÂ© en far_articulo, sino esta lo inserto
SELECT * INTO rmed FROM far_medicamento WHERE mnroregistro=rarticulo.mnroregistro;
IF NOT FOUND THEN
        SELECT * INTO rmed FROM far_articulo WHERE idarticulo=rarticulo.idarticulo AND idcentroarticulo = rarticulo.idcentroarticulo;
        IF FOUND THEN
              SELECT * INTO rverif FROM medicamento WHERE mcodbarra=rmed.acodigobarra; 
              IF FOUND THEN  --Cargo en far_medicamento
                  insert into far_medicamento(idarticulo,idcentroarticulo,mnroregistro,nomenclado) values(rmed.idarticulo,rmed.idcentroarticulo,rarticulo.mnroregistro::integer,rverif.nomenclado);
                  --vmnroregistro = rarticulo.mnroregistro; 
                  vmnroregistro =concat(rmed.idarticulo,'-',rmed.idcentroarticulo);
              ELSE 
                  vmnroregistro =concat(rmed.idarticulo,'-',rmed.idcentroarticulo);
              END IF;
        ELSE
              SELECT * INTO  re FROM far_cargarmedicamento(rarticulo.mnroregistro::integer);
              SELECT * INTO rmed FROM far_medicamento WHERE mnroregistro=rarticulo.mnroregistro;
              vmnroregistro =concat(rmed.idarticulo,'-',rmed.idcentroarticulo);

        END IF;
END IF;

----------------------------------------------------------------------

IF (rarticulo.idobrasocial = 1) THEN
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
     IF FOUND THEN --Busco el IDAfiliado de la obra social que me envian
       vnrodoc = rafil.nrodoc;
       vtipodoc = rafil.tipodoc;
        SELECT into rafiloso * from far_afiliado WHERE nrodoc=vnrodoc AND idobrasocial = rarticulo.idobrasocial;
        IF FOUND THEN
         vidafiliadoos = rafiloso.idafiliado;
        ELSE
          SELECT into rafiloso * from far_afiliado WHERE idafiliado=rarticulo.idafiliado AND idobrasocial = rarticulo.idobrasocial;
           IF FOUND THEN
            vnrodoc = rafiloso.nrodoc;
            vtipodoc = rafiloso.tipodoc;
           END IF;
         vidafiliadoos = rarticulo.idafiliado;
        END IF;
    END IF;
    ----------------------------------------OTRA  MUTUAL ------------------------------------------------------------------------
    --Verifico si la obra social que me envian, tiene alguna mutual asociada y si la persona es afiliado de dicha obras social.
    SELECT INTO rmutual * FROM expendio_tiene_mutual(vnrodoc,vtipodoc) as tm
                        JOIN far_obrasocialmutual as osm ON osm.idmutual = tm
                        JOIN mutualpadron mp ON  mp.idobrasocial = osm.idmutual
                        left join mutualpadronestado mpe  ON  (mp.idmutualpadron = mpe.idmutualpadron and 
                        mp.idcentromutualpadron = mpe.idcentromutualpadron)
                        WHERE osm.idobrasocial = rarticulo.idobrasocial AND nrodoc = vnrodoc
                             and (idmutualpadronestadotipo=1 and nullvalue(mpefechafin));
                        
    IF FOUND THEN --La persona tiene una mutual, tengo que recuperar su idafiliado en la mutual
       SELECT INTO rafilmutu * FROM far_afiliado where nrodoc = vnrodoc AND tipodoc=vtipodoc AND idobrasocial = rmutual.idmutual;
       IF FOUND THEN --La persona ya esta como afiliado en la mutual
            elafiliado =rafilmutu.idafiliado;
       ELSE --Hay que cargar a la persona como afiliada de la mutual
            INSERT INTO far_afiliado(idobrasocial,aidafiliadoobrasocial,aapellidoynombre,iddireccion,nrocliente,barra,tipodoc,nrodoc)
            VALUES(rmutual.idmutual,rmutual.mpidafiliado,rmutual.mpdenominacion,rafiloso.iddireccion,rafiloso.nrocliente,rafiloso.barra,rafiloso.tipodoc,rafiloso.nrodoc);
            elafiliado = currval('far_afiliado_idafiliado_seq');
       END IF;
    ELSE --No es afiliado de una mutual
       elafiliado = null;
    END IF;
    
    vidafiliadomutual = elafiliado;
    vquemutual = rmutual.idmutual;
    
    

END IF;
/*Malapi 17-02-2014 Comento la busqueda por tipodoc pues me da errores cuando en Siges el tipodoc esta mal cargado o desactualizado
  Malapi 21-05-2014 Elimino la ventana de los 30 dias adicionales para las coberturas con validacion 
*/
SELECT INTO rpersona *,cliente.barra as barracli FROM persona
LEFT JOIN benefsosunc USING(nrodoc,tipodoc)
LEFT JOIN cliente ON cliente.nrocliente = persona.nrodoc OR cliente.nrocliente = benefsosunc.nrodoctitu
WHERE  nrodoc = vnrodoc /*AND tipodoc = vtipodoc*/ AND fechafinos >=  current_date /*- 30::integer*/;
IF FOUND THEN
-- Es Afiliado de SOSUNC
   SELECT into rafil * from far_afiliado WHERE nrodoc = vnrodoc AND tipodoc = vtipodoc and idobrasocial=1;
   IF NOT FOUND then  -- NO esta cargado en far_afiliado para SOSUNC
      INSERT INTO far_afiliado(idobrasocial,aidafiliadoobrasocial,aapellidoynombre,iddireccion,nrocliente,barra,tipodoc,nrodoc)
      VALUES(1,rarticulo.idafiliado,concat(rpersona.nombres, ' ' , rpersona.apellido),rpersona.iddireccion,rpersona.nrocliente,rpersona.barracli,rpersona.tipodoc,rpersona.nrodoc);
      elafiliado = currval('far_afiliado_idafiliado_seq');
   ELSE
       elafiliado = rafil.idafiliado;
   END IF;
ELSE --La persona no tiene sosunc
elafiliado = null;
END IF;
vidafiliadososunc = elafiliado;
IF nullvalue(vidafiliadoos) and not nullvalue(vidafiliadososunc) THEN
      vidafiliadoos =vidafiliadososunc;
END IF;
-------------------------- AMUC
tieneamuc = expendio_tiene_amuc(vnrodoc,vtipodoc);

if tieneamuc then
   SELECT into rafil * from far_afiliado  WHERE nrodoc = vnrodoc AND tipodoc = vtipodoc and idobrasocial=3;
   IF NOT FOUND then
   -- NO esta cargado en far_afiliado para AMUC o el plan no esta vigente
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

--vmnroregistro = rarticulo.mnroregistro;
vidvalidacion = rarticulo.idvalidacion;
vidcentrovalidacion = rarticulo.idcentrovalidacion;

IF (rarticulo.idobrasocial = 9) THEN -- Se vende sin obra social

vidafiliadososunc = null;
vidafiliadomutual = null;
vquemutual = null;
vidafiliadoamuc = null;
vidvalidacion = null;
vidcentrovalidacion = null;
END IF;
--GK 24-05-2022 Agrego case con precio importeunitario sacado de la validación
for rcobinfomedi in SELECT idobrasocial,
  idplancobertura ,
  idafiliado ,
  coberturas.mnroregistro,
  prioridad ,
  porccob ,
  montofijo ,
  pcdescripcion ,
  coberturas.detalle as detallecob ,
  coberturas.codautorizacion ,
  case when nullvalue(rarticulo.cantvendida) then CASE WHEN nullvalue(vi.cantidadaprobada) THEN 0 ELSE vi.cantidadaprobada END else rarticulo.cantvendida END as cantidadaprobada,
  idarticulo ,
  idcentroarticulo ,
  idrubro ,
  adescripcion ,
  precio,
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
                 from far_traercoberturasarticuloafiliado_3
                 (vmnroregistro,vidafiliadoos,vidafiliadososunc,vidafiliadoamuc,vidvalidacion,vidafiliadomutual,vquemutual,vidcentrovalidacion)
                ) as coberturas
                --JOIN far_buscarinfomedicamentos(concat('%',vmnroregistro,'%')) as f ON f.mnroregistro = coberturas.mnroregistro OR (f.idarticulo = trim(split_part(coberturas.mnroregistro,'-',1))  AND f.idcentroarticulo = trim(split_part(coberturas.mnroregistro,'-',2)))
                 JOIN far_buscarinfomedicamentosteniendoclave(vmnroregistro) as f
			ON f.mnroregistro = coberturas.mnroregistro OR (f.idarticulo = trim(split_part(coberturas.mnroregistro,'-',1))  AND f.idcentroarticulo = trim(split_part(coberturas.mnroregistro,'-',2)))
		JOIN far_validacionitems as vi  ON  (f.acodigobarra = vi.codbarras AND idvalidacion = vidvalidacion )

	loop
return next rcobinfomedi;
end loop;
FETCH carticulo into rarticulo;
END LOOP;
CLOSE carticulo;
end;$function$
