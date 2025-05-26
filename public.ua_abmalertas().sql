CREATE OR REPLACE FUNCTION public.ua_abmalertas()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Ingresa la informacion de una alerta */

DECLARE
	calertas CURSOR FOR SELECT * FROM temporal_alertagrupousuario;
	ralerta RECORD;
	rverifica record;
	rverificausuario record;
	
        rusuario RECORD;
        

BEGIN


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

SELECT INTO rverifica * FROM temporal_alertagrupousuario LIMIT 1;

IF (rverifica.accion = 'elimina') THEN
	DELETE FROM alertagrupousuario WHERE idalerta = rverifica.idalerta AND idcentroalerta = rverifica.idcentroalerta;
	DELETE FROM alertaconfigura WHERE idalerta = rverifica.idalerta AND idcentroalerta = rverifica.idcentroalerta;
	DELETE FROM alerta WHERE idalerta = rverifica.idalerta AND idcentroalerta = rverifica.idcentroalerta;
ELSE

IF(nullvalue(rverifica.idalerta)) THEN 
		INSERT INTO alerta(aleasunto,aletexto,alefechainicio,idusuariocreacion) 
		VALUES(rverifica.aleasunto,rverifica.aletexto,rverifica.alefechainicio,rusuario.idusuario);
		rverifica.idalerta = currval('alerta_idalerta_seq'::regclass);
		rverifica.idcentroalerta = centro();
		
		INSERT INTO alertaconfigura(idalerta,idcentroalerta,idalertaconfiguratipo,accadacuanto,acfechafinconfigura,acdiadelasemana,idalertaconfigurafuncion)
		VALUES(rverifica.idalerta,rverifica.idcentroalerta,rverifica.idalertaconfiguratipo,rverifica.accadacuanto,rverifica.acfechafinconfigura,rverifica.acdiadelasemana,rverifica.idalertaconfigurafuncion);
	ELSE 
		UPDATE alerta SET aleasunto = rverifica.aleasunto
                                 ,aletexto = rverifica.aletexto
                                 ,alefechainicio = rverifica.alefechainicio
                                ,idusuariocreacion = rusuario.idusuario
		WHERE idalerta = rverifica.idalerta AND idcentroalerta = rverifica.idcentroalerta;

		UPDATE alertaconfigura SET idalertaconfiguratipo = rverifica.idalertaconfiguratipo
				,accadacuanto = rverifica.accadacuanto
				,acfechafinconfigura = rverifica.acfechafinconfigura
				,acdiadelasemana = rverifica.acdiadelasemana
				,idalertaconfigurafuncion =rverifica.idalertaconfigurafuncion
		WHERE idalerta = rverifica.idalerta AND idcentroalerta = rverifica.idcentroalerta;

		
		DELETE FROM alertagrupousuario 
		WHERE idalerta = rverifica.idalerta AND idcentroalerta = rverifica.idcentroalerta;
	

	END IF;

OPEN calertas;
FETCH calertas into ralerta;
WHILE  found LOOP

        INSERT INTO alertagrupousuario(idalerta,idcentroalerta,idusuario) 
		VALUES(rverifica.idalerta,rverifica.idcentroalerta,ralerta.idusuario);   

      

FETCH calertas into ralerta;
END LOOP;
close calertas;

END IF;
return true;

END;

$function$
