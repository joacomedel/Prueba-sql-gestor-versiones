CREATE OR REPLACE FUNCTION public.far_verificaingresaafiliacion(pnrodoc character varying, ptipodoc integer, pidobrasocial integer, pidvalidacion bigint, pidcentrovalidacion integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

       rpersona RECORD;
       rafiliado RECORD;
       rafil RECORD;
       rafil2 RECORD;
       rvalidacion RECORD; 
       cafilmutual refcursor;
       
begin
--Verifico si es un afiliado de sosunc

SELECT INTO rpersona *,cliente.barra as barracli FROM persona
LEFT JOIN 
(select nrodoc,tipodoc,nrodoctitu,tipodoctitu from benefsosunc

union
select nrodoc,tipodoc,nrodoctitu,tipodoctitu from benefreci
)
as t   USING(nrodoc,tipodoc)
LEFT JOIN cliente ON cliente.nrocliente = persona.nrodoc OR cliente.nrocliente = t.nrodoctitu
 WHERE nrodoc = pnrodoc AND tipodoc = ptipodoc AND fechafinos >= current_date - 30::integer;

IF FOUND THEN
	SELECT into rafil * from far_afiliado WHERE nrodoc = pnrodoc AND tipodoc = ptipodoc AND idobrasocial = 1;
	IF NOT FOUND THEN -- Lo inserto como afiliado de sosunc
		INSERT INTO far_afiliado(idobrasocial,aidafiliadoobrasocial,aapellidoynombre,iddireccion,idcentrodireccion,nrocliente,barra,tipodoc,nrodoc,idcentroafiliado)
		VALUES(1,concat(pnrodoc,ptipodoc),concat(rpersona.nombres, ' ' , rpersona.apellido),rpersona.iddireccion,rpersona.idcentrodireccion,rpersona.nrocliente,rpersona.barracli,rpersona.tipodoc,rpersona.nrodoc,centro());

        END IF;
	SELECT into rafil * from far_afiliado WHERE nrodoc = pnrodoc AND tipodoc = ptipodoc AND idobrasocial = 9;
	IF NOT FOUND THEN -- Lo inserto como afiliado de Sin Obra Social
		INSERT INTO far_afiliado(idobrasocial,aidafiliadoobrasocial,aapellidoynombre,iddireccion,idcentrodireccion,nrocliente,barra,tipodoc,nrodoc,idcentroafiliado)
		VALUES(9,concat(pnrodoc,ptipodoc),concat(rpersona.nombres, ' ' , rpersona.apellido),rpersona.iddireccion,rpersona.idcentrodireccion,rpersona.nrocliente,rpersona.barracli,rpersona.tipodoc,rpersona.nrodoc,centro());

        END IF;
	IF expendio_tiene_amuc(pnrodoc,ptipodoc) THEN
		SELECT into rafil * from far_afiliado WHERE nrodoc = pnrodoc AND tipodoc = ptipodoc AND idobrasocial = 3;
		IF NOT FOUND THEN -- Lo inserto como afiliado de Sin Obra Social
			INSERT INTO far_afiliado(idobrasocial,aidafiliadoobrasocial,aapellidoynombre,iddireccion,idcentrodireccion,nrocliente,barra,tipodoc,nrodoc,idcentroafiliado)
			VALUES(3,concat(pnrodoc,ptipodoc),concat(rpersona.nombres, ' ' , rpersona.apellido),rpersona.iddireccion,rpersona.idcentrodireccion,rpersona.nrocliente,rpersona.barracli,rpersona.tipodoc,rpersona.nrodoc,centro());

		END IF;
	END IF;
	

END IF; --Fin de es un afiliado de sosunc
-- Busco Alguno de los Nro.Afiliado
SELECT into rafil * from far_afiliado WHERE nrodoc = pnrodoc AND tipodoc = ptipodoc LIMIT 1; 
IF FOUND THEN
--Verifico otras Mutuales
	OPEN cafilmutual FOR SELECT * FROM  mutualpadron 
				JOIN mutualpadronestado USING(idmutualpadron,idcentromutualpadron)
				JOIN far_mutual ON idobrasocial = idmutual
				LEFT JOIN far_afiliado USING(nrodoc,tipodoc,idobrasocial)
				WHERE nrodoc = pnrodoc AND tipodoc = ptipodoc
					AND nullvalue(mpefechafin)
					AND idmutualpadronestadotipo = 1
					AND nullvalue(far_afiliado.idafiliado);
	FETCH cafilmutual into rafiliado;
	WHILE  found LOOP
	-- Inserto el afiliado de cada mutual
		INSERT INTO far_afiliado(idobrasocial,aidafiliadoobrasocial,aapellidoynombre,nrocliente,barra,tipodoc,nrodoc,idcentroafiliado)
		VALUES(rafiliado.idobrasocial,rafiliado.mpidafiliado,concat(rafiliado.mpdenominacion),rafil.nrocliente,rafil.barra,ptipodoc,pnrodoc,centro());
	
	FETCH cafilmutual into rafiliado;
	END LOOP;
	CLOSE cafilmutual;

-- Doy de alta el Sin Obra Social, para el caso de que no exista
SELECT into rafil2 * from far_afiliado WHERE nrodoc = pnrodoc AND tipodoc = ptipodoc AND idobrasocial = 9;
	IF NOT FOUND THEN -- Lo inserto como afiliado de Sin Obra Social
		INSERT INTO far_afiliado(idobrasocial,aidafiliadoobrasocial,aapellidoynombre,iddireccion,idcentrodireccion,nrocliente,barra,tipodoc,nrodoc,idcentroafiliado)
		VALUES(9,concat(pnrodoc,ptipodoc),concat(rafil.nombres, ' ' , rafil.apellido),rafil.iddireccion,rafil.idcentrodireccion,rafil.nrocliente,rafil.barra,rafil.tipodoc,rafil.nrodoc,centro());

        END IF;

--Verifico si esta cargado con la Obra Social que me envian, se supone que si es una que requiere validacion, viene desde una validacion
	IF not nullvalue(pidvalidacion) THEN -- Si me envian una validacion, puedo cargar el afiliado si es que no esta cargado
	SELECT into rafil2 * from far_afiliado WHERE nrodoc = pnrodoc AND tipodoc = ptipodoc AND idobrasocial = pidobrasocial;
	   IF NOT FOUND THEN -- Lo inserto como afiliado de la Obra Social
		SELECT INTO rvalidacion * FROM far_validacion WHERE idvalidacion = pidvalidacion AND idcentrovalidacion = pidcentrovalidacion;
		INSERT INTO far_afiliado(idobrasocial,aidafiliadoobrasocial,aapellidoynombre,iddireccion,idcentrodireccion,nrocliente,barra,tipodoc,nrodoc,idcentroafiliado)
		VALUES(pidobrasocial,rvalidacion.crednumero,concat(rafil.nombres, ' ' , rafil.apellido),rafil.iddireccion,rafil.idcentrodireccion,rafil.nrocliente,rafil.barra,rafil.tipodoc,rafil.nrodoc,centro());
	   END IF;
	END IF;
        
END IF;

        
return true;
end;
$function$
