CREATE OR REPLACE FUNCTION public.far_darnumeromutualesafiliado(pnrodoc character varying, ptipodoc integer, pidobrasocial integer)
 RETURNS SETOF far_afiliado
 LANGUAGE plpgsql
AS $function$DECLARE


       rpersona RECORD;
       rafil RECORD;
       rafiliado far_afiliado;

begin

for rafiliado in 
SELECT far_afiliado.* FROM far_afiliado
		      JOIN persona USING(nrodoc,tipodoc)
                      WHERE nrodoc = pnrodoc AND tipodoc = ptipodoc 
                      AND idobrasocial = 1 AND pidobrasocial <> 9 
                      AND fechafinos >= current_date - 30::integer
UNION
SELECT far_afiliado.* FROM far_afiliado
		      JOIN persona USING(nrodoc,tipodoc)
                      WHERE nrodoc = pnrodoc AND tipodoc = ptipodoc 
                      AND idobrasocial = 3 AND pidobrasocial <> 9
                      AND fechafinos >= current_date - 30::integer
                      AND expendio_tiene_amuc(pnrodoc,ptipodoc)
UNION 
SELECT far_afiliado.* FROM far_afiliado WHERE nrodoc = pnrodoc AND tipodoc = ptipodoc AND idobrasocial = pidobrasocial
UNION 
SELECT far_afiliado.* FROM far_afiliado WHERE nrodoc = pnrodoc AND tipodoc = ptipodoc AND idobrasocial = 9 AND pidobrasocial <> 9
UNION 
SELECT far_afiliado.*  
	FROM mutualpadron 
	JOIN mutualpadronestado USING(idmutualpadron,idcentromutualpadron)
	JOIN far_obrasocialmutual ON mutualpadron.idobrasocial = idmutual  
	JOIN far_afiliado USING(nrodoc,tipodoc)
	WHERE nrodoc = pnrodoc AND tipodoc = ptipodoc
		AND nullvalue(mpefechafin)
		AND idmutualpadronestadotipo = 1
		AND far_afiliado.idobrasocial = idmutual 
                AND pidobrasocial <> 9 
		AND far_obrasocialmutual.idobrasocial = pidobrasocial
		-- AND mutualpadron.idobrasocial = far_afiliado.idobrasocial;

	loop

return next rafiliado;

end loop;

end;
$function$
