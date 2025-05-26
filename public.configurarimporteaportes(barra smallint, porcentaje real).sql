CREATE OR REPLACE FUNCTION public.configurarimporteaportes(barra smallint, porcentaje real)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

personas cursor for (SELECT * FROM persona NATURAL JOIN aporteconfiguracion  
                  where (persona.barra=$1) and  nullvalue(aporteconfiguracion.acfechafin)
                      );
	

	personaaux record;
	resultado boolean;
	nrodocaux varchar;
         tipodocaux int;
         
       brutoaumento float;
       brutoaportar float;
         brutoimporte float;
       


BEGIN

open personas;
resultado = false;

fetch personas into personaaux; 

    raise notice '%', personaaux.barra;
 raise notice '%', personaaux.apellido;
    
   while FOUND loop
        update aporteconfiguracion set acfechafin=now() where nrodoc=personaaux.nrodoc and   tipodoc=personaaux.tipodoc and nullvalue(acfechafin);

      brutoaumento = (personaaux.acimportebruto + ((personaaux.acimportebruto/100)*$2));
       brutoaportar = ((brutoaumento/100)*personaaux.acporcentaje);
      brutoimporte=  brutoaumento + ((brutoaumento/100)*personaaux.acporcentaje);

         INSERT INTO aporteconfiguracion(idcentroaporteconfiguracion,nrodoc,tipodoc,acporcentaje,acimportebruto,acimporteaporte,acfechafin,acfechainicio)
VALUES(centro(),personaaux.nrodoc,personaaux.tipodoc,personaaux.acporcentaje,brutoaumento,brutoaportar,null,now()::date);
     resultado=true;
     fetch  personas into personaaux;
   end loop;


    
  

close personas;
return resultado;
END;


/*
IF  (nullvalue(personaaux.nrodoc)) then
 
    resultado=false;
else
    resultado=true;

END IF;
 */ 
$function$
