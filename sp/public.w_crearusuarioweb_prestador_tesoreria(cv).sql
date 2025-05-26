CREATE OR REPLACE FUNCTION public.w_crearusuarioweb_prestador_tesoreria(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/*
* select * from w_crearusuarioweb(nrodni,tipodoc,email,rolweb)
* Recibe como parametros el  numero de documento, tipo documento y mail
* Retorna boolean true si se a creado el usuario correctamente
*/
DECLARE
       rfiltros record ;
       cprestador REFCURSOR;
       rprestador RECORD;
       idusuariosecuencia integer;
       respuesta character varying;
begin
       
      -- EXECUTE sys_dar_filtros($1) INTO rfiltros;
       -- Busco los datos de los prestadores
       OPEN cprestador FOR SELECT DISTINCT idprestador,pcuit,pemail
                            FROM ordenpagocontable
                            NATURAL JOIN prestador
                            LEFT JOIN w_usuarioprestador USING (idprestador)
                            WHERE  opcfechaingreso >='2019-07-01'
                                   AND not nullvalue(pcuit) 
                                   AND idprestador<>8 -- que no sea UNC 
                                   AND nullvalue(w_usuarioprestador.idprestador)
                                   AND pcuit ilike '30-70986792-6'
;  
       FETCH cprestador INTO rprestador;
       WHILE FOUND LOOP
      -- recorro cada uno de los prestadores

                  INSERT INTO w_usuarioweb(uwnombre,uwcontrasenia,uwmail,uwsuscripcionnl,uwverificador,uwactivo,uwlimpiar,uwtipo)   
		   	      VALUES(rprestador.pcuit,md5(rprestador.pcuit),rprestador.pemail,true,null,true,false,3);
		  idusuariosecuencia = currval('w_usuarioweb_idusuarioweb_seq');        
		  INSERT INTO w_usuariorolweb(idusuarioweb,idrolweb)values(idusuariosecuencia,15); -- el rol prestador es 15               
		  INSERT INTO w_usuarioprestador(idusuarioweb,idprestador) VALUES(idusuariosecuencia ,rprestador.idprestador);
			
                  FETCH cprestador INTO rprestador;       
      END LOOP;
      CLOSE cprestador ;	
return '';

end;
$function$
