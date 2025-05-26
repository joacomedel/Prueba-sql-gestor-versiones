CREATE OR REPLACE FUNCTION public.far_dardatoscliente(character varying)
 RETURNS SETOF far_afiliado
 LANGUAGE plpgsql
AS $function$DECLARE

 rafiliado far_afiliado;

BEGIN 

for rafiliado in SELECT idafiliado, idobrasocial,aidafiliadoobrasocial,CASE WHEN NULLVALUE(aapellidoynombre) THEN concat(apellido,', ', nombres) ELSE aapellidoynombre END as aapellidoynombre,CASE WHEN nullvalue(T.iddireccion) THEN p.iddireccion else t.iddireccion END as iddireccion,CASE WHEN nullvalue(nrocliente) THEN p.nrodoc ELSE nrocliente END as nrocliente ,CASE WHEN nullvalue(t.barra) THEN tipodoc ELSE t.barra END as barra,tipodoc,nrodoc, idcentroafiliado, p.idcentrodireccion
FROM persona as p
full outer JOIN
(
SELECT  far_afiliado.* , concat(cliente.nrocliente::text,'-',cliente.barra::text) as idcliente  
FROM far_afiliado 
LEFT JOIN (SELECT DISTINCT ON (p.nrodoc, p.tipodoc)  p.nrodoc, p.tipodoc, nombres, apellido, nrodoctitu, tipodoctitu  FROM persona as p NATURAL JOIN benefsosunc  ) as bs USING(nrodoc, tipodoc)  
LEFT JOIN cliente  ON(case when nullvalue(nrodoctitu) then far_afiliado.nrodoc ELSE nrodoctitu end)=cliente.nrocliente  and (case when nullvalue(tipodoctitu) then far_afiliado.tipodoc ELSE tipodoctitu end)=cliente.barra 

) AS T USING (nrodoc, tipodoc) 
WHERE nrodoc ilike concat('%',$1,'%') or aapellidoynombre ILIKE concat('%',$1,'%')  OR aidafiliadoobrasocial  ILIKE concat('%',$1,'%') OR 
concat(nrodoc,tipodoc) ilike concat(/*'%',*/$1,'%')
	loop

return next rafiliado;

end loop;

end;

$function$
