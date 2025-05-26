CREATE OR REPLACE FUNCTION public.guardarhistoricolegajodh49(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        cursorauxi refcursor;
        elemdh49 record;
	elemcursor record;
        meanterior integer;
        anioanterior integer;

    
/*Se carga la tabla dh49_historicoinfo con los datos que ingresan en la tabla dh49.
si el cuil informado en dh49 tiene un legajo diferente o no existe , entonces se actualiza  en dh49_historicoinfo
*/

BEGIN

   OPEN cursorauxi FOR SELECT nrolegajo,cuil
                    FROM dh49
                    WHERE dh49.mesingreso = $1
	            AND dh49.anioingreso = $2
                    group by nrolegajo,cuil;  


FETCH cursorauxi INTO elemcursor;
WHILE found Loop
    if ($1=1) then 
       meanterior=12;
       anioanterior=$2 -1;
       SELECT INTO elemdh49 * FROM dh49_historicoinfo WHERE dh49_historicoinfo.dhimes= meanterior    AND dh49_historicoinfo.dhianio= anioanterior  and
       dhicuil=elemcursor.cuil;
    else
       meanterior=$1 -1 ;
       anioanterior=$2;
       SELECT INTO elemdh49 * FROM dh49_historicoinfo WHERE dh49_historicoinfo.dhimes= meanterior    AND dh49_historicoinfo.dhianio= anioanterior and
       dhicuil=elemcursor.cuil; 
    end if;


IF (not FOUND )THEN

   insert into dh49_historicoinfo (dhifechaini,dhifechafin,dhimes,dhianio,dhicuil,dhinrodoc,dhilegajo)
   values(now(),null,$1,$2,elemcursor.cuil,substring(elemcursor.cuil,3,length(elemcursor.cuil)-3),elemcursor.nrolegajo);
else
    if(elemdh49.dhilegajo<>elemcursor.nrolegajo) then 
    /*actualiza*/
      update dh49_historicoinfo set dhifechafin=now() WHERE dh49_historicoinfo.dhimes= meanterior   AND dh49_historicoinfo.dhianio= anioanterior and 
      dhicuil=elemcursor.cuil; 
      insert into dh49_historicoinfo (dhifechaini,dhifechafin,dhimes,dhianio,dhicuil,dhinrodoc,dhilegajo)
      values(now(),null,$1,$2,elemcursor.cuil,substring(elemcursor.cuil,3,length(elemcursor.cuil)-3),elemcursor.nrolegajo);
    end if;

end if;

FETCH cursorauxi INTO elemcursor;

end loop;
close cursorauxi ;
return true;
END;
$function$
