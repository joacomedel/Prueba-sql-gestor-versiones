CREATE OR REPLACE FUNCTION public.w_crearusuarioafiliadoapp(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
* Crea el usuario para la app. Si es titular invoca al SP w_crearusuarioweb, SINO lo crea
* Recibe como parametros el  numero de documento, tipo documento y mail
* Retorna boolean true si se a creado el usuario correctamente
*/
DECLARE
       rcontrolusuario record ;      
       rpersona RECORD;
       rusuario RECORD;
       idusuariosecuencia integer;      
       respuestajson jsonb;
       respuestajson_info jsonb;
       respuesta varchar;
       rdatos RECORD;

       versionapp varchar;
     
begin
/* Busco los datos de la persona*/
       versionapp = parametro ->> 'versionapp';         
       IF versionapp IS NULL THEN
          versionapp = '1.0.0'; /*Valor por defecto de la app si no lo envian en la llamada*/
       END IF;
       SELECT INTO rpersona * FROM persona WHERE nrodoc=parametro->>'nombreusr' and tipodoc=1 and barra<30
                                               and fechafinos>=current_date;
       IF FOUND THEN 
              SELECT INTO rcontrolusuario * 
		   FROM w_usuarioweb 		   
		   WHERE uwnombre=rpersona.nrodoc; 
   	      IF  NOT FOUND  THEN  
   			SELECT INTO rusuario *
			FROM w_usuarioafiliado  WHERE nrodoc=rpersona.nrodoc and tipodoc=1;
			IF NOT FOUND THEN  /*CREO EL USUARIO*/
			       INSERT INTO w_usuarioweb(uwnombre,uwcontrasenia,uwsuscripcionnl,uwverificador,uwactivo,uwlimpiar)   
				VALUES(rpersona.nrodoc,md5(rpersona.nrodoc),true,null,true,false);
				idusuariosecuencia = currval('w_usuarioweb_idusuarioweb_seq');        
				/*afiliado de sosunc solo insertamos por ahora el rol =1*/
				INSERT INTO w_usuariorolweb(idusuarioweb,idrolweb)values(idusuariosecuencia,1);               
				INSERT INTO w_usuarioafiliado(nrodoc,tipodoc,idusuarioweb)                             
					VALUES(rpersona.nrodoc,rpersona.tipodoc,idusuariosecuencia);                   		
				
			END IF;
		  
	     END IF;	
--KR 28-04-21 POR ahora en el sp devolvemos los datos del usuario que se dieron de alta
             SELECT INTO rdatos p.nrodoc, uwmail, uwcontrasenia as contrasena, p.tipodoc,apellido, nombres,apellido||', '||nombres as apeynom,    idusuarioweb	,uwnombre, uwmail	,idrolweb, rodescripcion,peactivo , text_concatenar(concat(idpermiso::varchar,'-', pepagina ,'#')) as paginas, uwtipo as tipousr, idusuarioweb as idusr
                FROM w_usuarioweb NATURAL JOIN w_usuariorolweb NATURAL JOIN w_rolweb NATURAL JOIN w_permisorolweb NATURAL JOIN  w_permiso
	        LEFT JOIN w_usuarioafiliado USING (idusuarioweb)
	        LEFT JOIN persona as p USING (nrodoc,tipodoc)
                
  	     WHERE uwactivo AND peactivo  and uwtipo <> 3 AND (uwnombre = parametro->>'nombreusr' or nullvalue( parametro->>'nombreusr'))                           
                        AND  (uwmail = parametro->>'uwmail' or nullvalue(parametro->>'uwmail')) 
	     group by uwmail, uwcontrasenia, p.nrodoc,p.tipodoc,nombres ,apellido, idusuarioweb,uwnombre, uwmail,idrolweb, rodescripcion,peactivo
             ORDER BY idrolweb;
             IF FOUND THEN 
                      /*respuestajson_info = '{ "'|| vaccion  || '":' || row_to_json(rdatos ) || '}';*/
                      respuestajson_info = '{ "versionapp":"'|| versionapp || '", "alta":' || row_to_json(rdatos ) || '}';
	              respuestajson = respuestajson_info ;
                  
             END IF ;        
  	

          
	ELSE 
		 --RAISE EXCEPTION 'R-006, Los datos informados no corresponden a un afiliado de la Obra Social o su estado actual no es activo.';  
                 --sl 20/08 - Cambio mensaje ya que ahora se valida en el back las contraseñas y siempre da este error cuando esta mal algun dato
		 RAISE EXCEPTION 'R-006, El usuario / contraseña ingresados no coinciden con ningún usuario registrado';  
 
        END IF;       
      
return respuestajson ;

end;
$function$
