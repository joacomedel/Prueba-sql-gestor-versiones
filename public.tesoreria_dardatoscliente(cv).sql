CREATE OR REPLACE FUNCTION public.tesoreria_dardatoscliente(character varying)
 RETURNS SETOF cliente
 LANGUAGE plpgsql
AS $function$DECLARE

 rafiliado cliente;
 rpersona RECORD;
 
BEGIN 
    SELECT INTO rpersona * FROM persona WHERE nrodoc = $1;

    IF FOUND AND (rpersona.barra <30 OR (rpersona.barra>100 AND rpersona.barra<130)) THEN
       SELECT INTO rafiliado c.* 
	FROM cliente  as c
	LEFT JOIN benefsosunc as bs ON bs.nrodoctitu = nrocliente AND bs.tipodoctitu = c.barra AND bs.nrodoc = $1
	LEFT JOIN benefreci as br ON br.nrodoctitu = nrocliente AND br.tipodoctitu = c.barra AND br.nrodoc = $1
        WHERE ( not nullvalue(bs.nrodoctitu) OR not nullvalue(br.nrodoctitu)) 
        LIMIT 1;
    ELSE 
        SELECT INTO rafiliado * FROM cliente WHERE  nrocliente ilike concat('%',$1,'%');
    END IF; 
    

return next rafiliado;

end;

$function$
