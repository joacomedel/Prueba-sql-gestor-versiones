CREATE OR REPLACE FUNCTION public.sistema_abmpanelreportes()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Ingresa la informacion de una alerta */

DECLARE
	calertas CURSOR FOR SELECT * FROM temporal_panelreportes;
	ralerta RECORD;
	rverifica record;
	rverificausuario record;
	
        rusuario RECORD;
        

BEGIN


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

SELECT INTO rverifica * FROM temporal_panelreportes LIMIT 1;

IF (rverifica.accion = 'elimina') THEN
	UPDATE configuraadminprocesos_exportarexcel SET capee_activo = false 
	WHERE idconfiguraadminprocesosexportarexcel = rverifica.idconfiguraadminprocesosexportarexcel;
ELSE

IF(nullvalue(rverifica.idconfiguraadminprocesosexportarexcel)) THEN 
    
		INSERT INTO configuraadminprocesos_exportarexcel(idconfiguraadminprocesos,idmodulo,capee_nombreboton,capee_etiquetaboton,capee_clavescolumnas
								,capee_tituloventana,capee_spsql,capee_nombrearchivo,idmenu,capee_ayuda,capee_tipo,capee_unahoja) 
		VALUES(15,null,'boton1',rverifica.capee_etiquetaboton,rverifica.capee_clavescolumnas
		,rverifica.capee_tituloventana,rverifica.capee_spsql,rverifica.capee_nombrearchivo,null,rverifica.capee_ayuda,rverifica.capee_tipo,rverifica.capee_unahoja);
		rverifica.idconfiguraadminprocesosexportarexcel = currval('configuraadminprocesos_export_idconfiguraadminprocesosexpor_seq'::regclass);
	ELSE 
		UPDATE configuraadminprocesos_exportarexcel
					SET capee_etiquetaboton = rverifica.capee_etiquetaboton
					,capee_clavescolumnas = rverifica.capee_clavescolumnas
					,capee_tituloventana = rverifica.capee_tituloventana
					,capee_spsql = rverifica.capee_spsql
					,capee_nombrearchivo = rverifica.capee_nombrearchivo
					,capee_ayuda = rverifica.capee_ayuda
                                        ,capee_tipo = rverifica.capee_tipo
                                        ,capee_unahoja = rverifica.capee_unahoja
		WHERE idconfiguraadminprocesosexportarexcel = rverifica.idconfiguraadminprocesosexportarexcel;

				
		DELETE FROM configuraadminprocesos_exportarexcel_usuario 
		WHERE idconfiguraadminprocesosexportarexcel = rverifica.idconfiguraadminprocesosexportarexcel;
	

	END IF;

OPEN calertas;
FETCH calertas into ralerta;
WHILE  found LOOP

        INSERT INTO configuraadminprocesos_exportarexcel_usuario(idconfiguraadminprocesosexportarexcel,idusuario) 
		VALUES(rverifica.idconfiguraadminprocesosexportarexcel,ralerta.idusuario);   

      

FETCH calertas into ralerta;
END LOOP;
close calertas;

END IF;
return true;

END;

$function$
