CREATE OR REPLACE FUNCTION public.expendio_tiene_amuc(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

        pnrodoc alias for $1;
        ptipodoc alias for $2;
        tieneamuc boolean;
        aux RECORD;
        rpersona RECORD;
        barra integer;
BEGIN
              tieneamuc = false;
               SELECT  INTO rpersona * FROM persona WHERE nrodoc=pnrodoc and tipodoc = ptipodoc;
               barra = rpersona.barra;
               IF barra = 30 THEN
		SELECT INTO aux * FROM afilidoc WHERE afilidoc.nrodoc=pnrodoc and afilidoc.tipodoc = ptipodoc ;
		IF FOUND and aux.mutu THEN
				tieneamuc = true;
		 END IF;
		END IF;
			
				IF barra = 31 THEN
					SELECT INTO aux * FROM afilinodoc WHERE afilinodoc.nrodoc=pnrodoc and afilinodoc.tipodoc = ptipodoc;
					IF FOUND and aux.mutu THEN
						   tieneamuc = true;
					 END IF;
				END IF;
				IF barra = 32 THEN
					SELECT INTO aux * FROM afilisos WHERE afilisos.nrodoc=pnrodoc and afilisos.tipodoc = ptipodoc;
				    IF FOUND and aux.mutu THEN
						tieneamuc = true;
					 END IF;
				END IF;
				IF barra = 33 THEN
					SELECT INTO aux * FROM afilirecurprop WHERE afilirecurprop.nrodoc=pnrodoc and afilirecurprop.tipodoc=ptipodoc;
					IF FOUND and aux.mutu THEN
						tieneamuc = true;
					END IF;
				END IF;
				/*IF barra = 34 THEN
					SELECT INTO aux * FROM afilibec WHERE afilibec.nrodoc=pnrodoc and afilibec.tipodoc =ptipodoc ;
					IF FOUND and aux.mutu THEN
						tieneamuc = true;
					END IF;
				END IF;
				IF barra = 35 THEN
					SELECT INTO aux * FROM afiljub WHERE afiljub.nrodoc=pnrodoc and afiljub.tipodoc =ptipodoc ;
					IF FOUND and aux.mutu THEN
						tieneamuc = true;
					END IF;
				END IF;*/
				/*IF barra = 36 THEN
					SELECT INTO aux * FROM afilpen WHERE afilpen.nrodoc=pnrodocand AND afilpen.tipodoc =ptipodoc ;
					IF FOUND and aux.mutu THEN
						tieneamuc = true;
					END IF;
				END IF;*/
				IF barra = 37 THEN
					SELECT INTO aux * FROM afiliauto WHERE afiliauto.nrodoc=pnrodoc and  afiliauto.tipodoc   =ptipodoc ;
                   IF FOUND and aux.mutu THEN
						tieneamuc = true;
					END IF;
				END IF;

                                IF barra >= 1 AND barra < 30 THEN
					SELECT INTO aux * FROM benefsosunc WHERE benefsosunc.nrodoc=pnrodoc and  benefsosunc.tipodoc =ptipodoc ;
                                         IF FOUND and aux.mutual THEN
						tieneamuc = true;
					END IF;
				END IF;
return tieneamuc;
END;$function$
