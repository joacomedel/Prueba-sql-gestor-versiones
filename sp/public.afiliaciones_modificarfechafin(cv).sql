CREATE OR REPLACE FUNCTION public.afiliaciones_modificarfechafin(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE 

  rffpersona RECORD;



BEGIN 

  SELECT INTO rffpersona * FROM temp_personafechafinos; 
  IF FOUND THEN 
     UPDATE persona SET fechafinos=rffpersona.fechacambio where nrodoc=rffpersona.nrodoc AND tipodoc=rffpersona.tipodoc;

     UPDATE afilsosunc SET ctacteexpendio=rffpersona.habilitactacte where nrodoc=rffpersona.nrodoc AND tipodoc=rffpersona.tipodoc;

     INSERT INTO usuariopersona (nrodoc,tipodoc,idusuario,fechacambio,motivo, upfechafincambio) VALUES     (rffpersona.nrodoc,rffpersona.tipodoc,sys_dar_usuarioactual(),rffpersona.fechacambio,rffpersona.motivo, rffpersona.fechafincambio);

  END IF;  
	 
return ' ';
end;
$function$
