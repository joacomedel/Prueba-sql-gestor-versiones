CREATE OR REPLACE FUNCTION public.asistencial_abmnovedadesjubilados(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
    
 --RECORD
       rfiltros RECORD;
       rnovedad  RECORD;
 --VARIABLES 
       vaccion VARCHAR;
       vtarea VARCHAR;
BEGIN

 EXECUTE sys_dar_filtros($1) INTO rfiltros ;  	
 vaccion = rfiltros.accion;
 
 IF vaccion  ilike '%eliminar%' THEN  

 	UPDATE temporal_jubilados SET tjborrado	 = now(),    observaciones = concat(observaciones, '. ', rfiltros.observaciones , ' Eliminada desde SP asistencial_abmnovedadesjubilados')
          WHERE idjubilados	 =  rfiltros.idjubilados;

 ELSE 
   SELECT INTO vtarea  tadescripcion FROM tareaadherente WHERE idtareaadherente = rfiltros.idtareaadherente;
 
   IF not nullvalue(rfiltros.idjubilados) THEN /*EL dato existe, hay que actualizarlo*/
     UPDATE temporal_jubilados 
        SET observaciones = rfiltros.observaciones,
            importeaporte = rfiltros.importeaporte,
            total = rfiltros.importeconiva,
            importebruto = rfiltros.importebruto,
            porcentaje = rfiltros.porcentaje,
            mesaporte= rfiltros.mesaporte,
            anioaporte = rfiltros.anioaporte,
            importeconiva= rfiltros.importeconiva,
            presentonota= rfiltros.presentonota,
           -- incrementomasivo= rfiltros.incrementomasivo,
            idtareaadherente = rfiltros.idtareaadherente,
            tarea = vtarea,
            nombres = rfiltros.nombres,
            nroafiliado = concat(rfiltros.nrodoc,'-', rfiltros.barra),
            nrodoc = rfiltros.nrodoc,
            barra = rfiltros.barra,
            periodo =  rfiltros.periodo,
            tjusuariomodifica = sys_dar_usuarioactual()
          WHERE  idjubilados =  rfiltros.idjubilados;
    ELSE 
      INSERT INTO temporal_jubilados (nombres,nroafiliado,tarea,periodo,importeaporte,iva,total,nrodoc,barra,importebruto,porcentaje,mesaporte,anioaporte,importeconiva,presentonota,observaciones,idtareaadherente) VALUES (rfiltros.nombres,concat(rfiltros.nrodoc,'-', rfiltros.barra),vtarea ,rfiltros.periodo,rfiltros.importeaporte,rfiltros.importeconiva-rfiltros.importeaporte,rfiltros.importeconiva,rfiltros.nrodoc,rfiltros.barra,rfiltros.importebruto,rfiltros.porcentaje,rfiltros.mesaporte,rfiltros.anioaporte,rfiltros.importeconiva,rfiltros.presentonota, rfiltros.observaciones,rfiltros.idtareaadherente);
  
   END IF;
  END IF;
     
return 'true';
END;$function$
