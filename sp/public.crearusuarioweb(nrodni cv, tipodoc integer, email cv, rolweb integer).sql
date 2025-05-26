CREATE OR REPLACE FUNCTION public.crearusuarioweb(nrodni character varying, tipodoc integer, email character varying, rolweb integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
   select * from crearusuarioweb(nrodni,tipodoc,email,rolweb)

* Recibe como parametros el  numero de documento, tipo documento y mail
* Retorna boolean true si se a creado el usuario correctamente
*/
DECLARE
       pnrodoc alias for $1;
        ptipodoc alias for $2;
       pemail alias for $3;
       prolweb alias for $4;

     elusuario character varying;
      pwdtempo character varying;
    
       datoPersona RECORD;
       datoUsuario RECORD;
        datoUsuarioWeb RECORD;
        
       idusuariosecuencia integer;
begin
/* Busco los datos de la persona*/

            SELECT INTO datoPersona *
            FROM public.persona WHERE persona.nrodoc=pnrodoc and persona.tipodoc=ptipodoc;
            
            IF (datoPersona.barra=32) THEN
               /* Busco el usuario siges */
          
                     SELECT INTO datoUsuario *
               FROM public.usuario WHERE usuario.dni=pnrodoc and usuario.tipodoc=ptipodoc;

                        IF not FOUND THEN
                        /* no existe el usuario siges */
        
                         elusuario='dni' || datoPersona.nrodoc;
 
                         INSERT INTO usuario(contrasena,dni,nombre,tipodoc,apellido,login,umail,usamenudinamico)                         VALUES(md5(datoPersona.nrodoc),datoPersona.nrodoc,datoPersona.nombres,datoPersona.tipodoc,datoPersona.apellido,elusuario,pemail,false);

                        INSERT INTO usuarioconfiguracion(dni,ucactivo)values(datoPersona.nrodoc,true);

                          /*afiliado de sosunc solo insertamos por ahora*/
                         INSERT INTO w_usuariorolwebsiges(dni,idrolweb)values(datoPersona.nrodoc,prolweb);

                         end if;

                      update persona set email=pemail  WHERE persona.nrodoc=pnrodoc and persona.tipodoc=ptipodoc;
          
       ELSE
               /* Busco el usuario siges  para no barra 32 */
          
               SELECT INTO datoUsuario *
               FROM public.w_usuarioafiliado  WHERE public.w_usuarioafiliado.nrodoc=pnrodoc and public.w_usuarioafiliado.tipodoc=ptipodoc;
   
                IF not FOUND THEN
                        /* no existe el usuarioweb  afiliado siges */
                      elusuario='dni' || datoPersona.nrodoc;
                      pwdtempo=md5(pnrodoc);

                    INSERT INTO w_usuarioweb(uwnombre,uwcontrasenia,uwmail,uwsuscripcionnl,uwverificador,uwactivo,uwlimpiar)   
                  VALUES(elusuario,pwdtempo,pemail,true,null,true,false);

                     idusuariosecuencia = currval('w_usuarioweb_idusuarioweb_seq');
                       
                    INSERT INTO w_usuarioafiliado(nrodoc,tipodoc,idusuarioweb)                                
                                           values(datoPersona.nrodoc,datoPersona.tipodoc,idusuariosecuencia);

                     /*afiliado de sosunc solo insertamos por ahora*/
                         INSERT INTO w_usuariorolweb(idusuarioweb,idrolweb)values(idusuariosecuencia,prolweb);


                        INSERT INTO w_usuariorolwebsiges(idusuarioweb,idrolweb)values(idusuariosecuencia,prolweb);




                update persona set email=pemail  WHERE persona.nrodoc=pnrodoc and persona.tipodoc=ptipodoc;


                end if;


         END IF;
              
return true;

end;
$function$
