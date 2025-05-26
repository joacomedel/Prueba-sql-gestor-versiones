CREATE OR REPLACE FUNCTION public.controljubilados()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

       cursorjubilados refcursor;
       unjubilado record;

BEGIN
 
         

   -- Reviso los jubilados cuya fechafinos es  menor o igual a current_date
    --Controlo que este sp solo se corrar exepcionalmente  hasta 15/07/2022
if (current_date<='2022-07-15')   then  
   OPEN cursorjubilados  FOR   select persona.nrodoc,persona.tipodoc,persona.fechafinos,idcertpers,trabaja,trabajaunc,ingreso from persona 
   join afiljub_borrar using(nrodoc,tipodoc)  where barra=35 and  persona.fechafinos<=current_date;

 FETCH cursorjubilados   INTO unjubilado ;

 
 WHILE FOUND LOOP
   

     
    update persona set fechafinos='2022-07-15'
    where nrodoc=unjubilado.nrodoc  and tipodoc=unjubilado.tipodoc;

    update afilsosunc set idestado=2
    where nrodoc=unjubilado.nrodoc  and tipodoc=unjubilado.tipodoc;

     FETCH cursorjubilados   INTO unjubilado ;
end loop;
close cursorjubilados;
end if;
return true;
END;$function$
