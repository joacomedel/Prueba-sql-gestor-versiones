CREATE OR REPLACE FUNCTION public.alta_modifica_auditoria_medica_turno(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  respuesta VARCHAR;
  vusuario INTEGER; 
--RECORD
  rexisteturno RECORD;
  radutoriamedica RECORD;
  rfiltros RECORD;
 
BEGIN

 EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

 vusuario = sys_dar_usuarioactual();

   SELECT INTO radutoriamedica *  FROM fichamedica WHERE  nrodoc= rfiltros.nrodoc AND tipodoc=rfiltros.tipodoc AND idauditoriatipo = 5;
   IF NOT FOUND THEN
	       INSERT INTO fichamedica(tipodoc,nrodoc,fmdescripcion,idauditoriatipo) 
	       VALUES(rfiltros.tipodoc,rfiltros.nrodoc,'Generada Automaticamente desde SP alta_modifica_auditoria_medica_turno',5);
	       radutoriamedica.idfichamedica = currval('public.fichamedica_idfichamedica_seq');
	       radutoriamedica.idcentrofichamedica = centro();
    END IF;
    UPDATE fichamedica SET fmdescripcion = rfiltros.comentario--concat(fmdescripcion, '. ',rfiltros.comentario) 				
		WHERE idfichamedica= radutoriamedica.idfichamedica AND idcentrofichamedica = radutoriamedica.idcentrofichamedica AND idauditoriatipo= 5;
--Verifico que la persona no tenga un turno vigente
    SELECT INTO rexisteturno * FROM fichamedicaitempendiente NATURAL JOIN fichamedicaitempendienteestado
         WHERE nrodoc= rfiltros.nrodoc AND tipodoc=rfiltros.tipodoc AND idauditoriatipo = 5 AND nullvalue(fmipfechafin) AND idfichamedicaemisionestadotipo=1 AND nroreintegro = rfiltros.nroorden AND idcentroregional = rfiltros.centro;
    IF NOT FOUND THEN     
	INSERT INTO fichamedicaitempendiente(tipodoc,nrodoc,idfichamedica,idcentrofichamedica,idauditoriatipo,nroreintegro,idcentroregional) 
	VALUES(rfiltros.tipodoc,rfiltros.nrodoc,radutoriamedica.idfichamedica,radutoriamedica.idcentrofichamedica,5,rfiltros.nroorden,rfiltros.centro);
--KR 01-07-19 se inserta en la tabla fichamedicaitempendienteestado con trigger disparado al insertar en fichamedicaitempendiente
        respuesta = concat('{ idfichamedicaitempendiente=',currval('fichamedicaitempendiente_idfichamedicaitempendiente_seq'::regclass),', idcentrofichamedicaitempendiente=',centro(),'}');
    ELSE 
        respuesta = concat('{ idfichamedicaitempendiente=',rexisteturno.idfichamedicaitempendienteestado,', idcentrofichamedicaitempendiente=',rexisteturno.idcentrofichamedicaitempendienteestado,'}');
    END IF;
 
return respuesta;
END;
$function$
