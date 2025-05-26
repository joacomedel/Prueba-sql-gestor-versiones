CREATE OR REPLACE FUNCTION public.eliminarresumen(recep integer, elanio integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE 
--RECORD
        datoreclibrofact RECORD;
        datorecepcion RECORD;
--VARIABLES
       elregistro  integer;
       elanio integer;
BEGIN

elregistro=$1;
elanio=$2;



select into datoreclibrofact *  from reclibrofact where numeroregistro=elregistro and anio=elanio;
if found then 
   


select into datorecepcion  * from recepcion where  idrecepcion=datoreclibrofact.idrecepcion  and idcentroregional=datoreclibrofact.idcentroregional;

if found then 

delete  from  reclibrofact_catgastoactividad where  idrecepcion=datoreclibrofact.idrecepcion  and idcentroregional=datoreclibrofact.idcentroregional;

delete  from  reclibrofact_formpago where  idrecepcion=datoreclibrofact.idrecepcion  and idcentroregional=datoreclibrofact.idcentroregional;

delete  from   reclibrofact_actividadcentroscosto where  idrecepcion=datoreclibrofact.idrecepcion  and idcentroregional=datoreclibrofact.idcentroregional;

delete   from   mapeocompcompras  where  idrecepcion=datoreclibrofact.idrecepcion  and idcentroregional=datoreclibrofact.idcentroregional;

delete   from   reclibrofactitemscentroscosto  where  idrecepcion=datoreclibrofact.idrecepcion  and idcentroregional=datoreclibrofact.idcentroregional;

  delete   from   fechasfact  where  idrecepcion=datoreclibrofact.idrecepcion  and idcentroregional=datoreclibrofact.idcentroregional;
  update factura set idresumen=null, anioresumen=null where idresumen=datoreclibrofact.numeroregistro and anioresumen=datoreclibrofact.anio;
  delete    from   festados where nroregistro=datoreclibrofact.numeroregistro and anio=datoreclibrofact.anio;
  delete    from   facturacionfechas where nroregistro=datoreclibrofact.numeroregistro and anio=datoreclibrofact.anio;
update reclibrofact set idrecepcionresumen=null, idcentroregionalresumen=null where idrecepcionresumen=datoreclibrofact.idrecepcion  and idcentroregionalresumen=datoreclibrofact.idcentroregional;
    
 
delete    from   reclibrofact where numeroregistro=datoreclibrofact.numeroregistro and anio=datoreclibrofact.anio;
 
  delete    from   recepcion where  idrecepcion=datoreclibrofact.idrecepcion  and idcentroregional=datoreclibrofact.idcentroregional;  
   delete    from   comprobante where  idcomprobante=datorecepcion.idcomprobante and idcentroregional=datorecepcion.idcentroregional;  

 delete    from   factura where nroregistro=datoreclibrofact.numeroregistro and anio=datoreclibrofact.anio;
  

end if;


end if;


return '';

END;
$function$
