CREATE OR REPLACE FUNCTION public.dar_datosclienteos(nrodocos character varying, tipodocos smallint)
 RETURNS SETOF cliente
 LANGUAGE plpgsql
AS $function$DECLARE

infocliente cliente;

BEGIN 

 for infocliente in  SELECT *
 FROM cliente
 NATURAL JOIN
    (SELECT nrodoctitu as nrocliente,tipodoctitu as barra,nrodoc,tipodoc 
    FROM benefsosunc  NATURAL JOIN persona 
    UNION SELECT nrodoctitu as nrocliente,tipodoctitu as barra,nrodoc,tipodoc 
    FROM benefreci NATURAL JOIN persona 

    UNION 

    SELECT nrodoc as nrocliente,tipodoc as barra,nrodoc,tipodoc 
    FROM afilsosunc NATURAL JOIN persona 
    
    UNION 

    SELECT nrodoc as nrocliente, tipodoc as barra,nrodoc,tipodoc 
    FROM afilreci NATURAL JOIN persona ) as datoscliente
WHERE nrodoc=nrodocOS AND tipodoc=tipodocOS

loop

return next infocliente;

end loop;


end;
$function$
