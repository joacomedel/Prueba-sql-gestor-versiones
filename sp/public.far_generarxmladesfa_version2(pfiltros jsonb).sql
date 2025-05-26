CREATE OR REPLACE FUNCTION public.far_generarxmladesfa_version2(pfiltros jsonb)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
	--Alba y Facu 11/2024

	--VARIABLES
	xmlAdesfa CHARACTER VARYING;
        nroItem INTEGER;

	--RECORDS
	rvalidacion RECORD;
	rencabezado RECORD;
        rnombrevalidador RECORD;
        rprovinciaprescrip RECORD;

	--JSONB
	encabezadomensajejson jsonb;
	encabezadorecetajson jsonb;
	detallerecetajson jsonb;
        itemsjson jsonb;
        itemjson jsonb;

BEGIN
        --Extraer encabezados
	encabezadomensajejson = pfiltros->'EncabezadoMensaje';
	encabezadorecetajson = pfiltros->'EncabezadoReceta';
	detallerecetajson = pfiltros->'detalleReceta';
        itemsjson = detallerecetajson->'lositem';

        --Mapeo prepaga
        SELECT * FROM adesfa_prepagas WHERE idobrasocial = pfiltros->>'idobrasocial' INTO rnombrevalidador;

        --Mapeo de provincia
        SELECT * FROM adesfa_provincia WHERE idprovincia = encabezadorecetajson->>'idprovincia' INTO rprovinciaprescrip;

        --Mapeo de OSocial para cancelaciones
        SELECT * FROM far_validacion WHERE (nroreferencia = encabezadomensajejson->>'NroReferencia' AND codaccion = '290020') INTO rvalidacion;

	--Se marcan con (*) los valores requeridos
	--Encabezado
	xmlAdesfa = '<MensajeADESFA version="2.0">';--(*)

	--Encabezado mensaje
	xmlAdesfa = xmlAdesfa || '<EncabezadoMensaje>';--(*)
        IF (encabezadomensajejson->>'CodAccion' = '20010') THEN
    	   xmlAdesfa = concat(xmlAdesfa, '<NroReferencia>', encabezadomensajejson->>'NroReferencia', '</NroReferencia>');
        END IF;
    	xmlAdesfa = concat(xmlAdesfa, '<TipoMsj>', encabezadomensajejson->>'TipoMsj', '</TipoMsj>');--(*)
    	xmlAdesfa = concat(xmlAdesfa, '<CodAccion>',encabezadomensajejson->>'CodAccion', '</CodAccion>');--(*)
    	xmlAdesfa = concat(xmlAdesfa, '<IdMsj>',encabezadomensajejson->>'IdMsj', '</IdMsj>');--(*)    
    	xmlAdesfa = xmlAdesfa || '<InicioTrx>';--(*)
        	xmlAdesfa = concat(xmlAdesfa, '<Fecha>',encabezadomensajejson->>'FechaReceta', '</Fecha>');--(*)
        	xmlAdesfa = concat(xmlAdesfa, '<Hora>',encabezadomensajejson->>'Hora', '</Hora>');--(*)
    	xmlAdesfa = xmlAdesfa || '</InicioTrx>';--(*)
        xmlAdesfa = xmlAdesfa || '<Terminal>';--(*)
        	xmlAdesfa = xmlAdesfa || '<Tipo>PC</Tipo>';
        	xmlAdesfa = xmlAdesfa || '<Numero>1</Numero>';
        xmlAdesfa = xmlAdesfa || '</Terminal>';--(*)
    	xmlAdesfa = xmlAdesfa || '<Software>';--(*)
        	xmlAdesfa = xmlAdesfa || '<Nombre>SIGESFarma</Nombre>';
        	xmlAdesfa = xmlAdesfa || '<Version>1.0</Version>';
    	xmlAdesfa = xmlAdesfa || '</Software>';--(*)
    	xmlAdesfa = xmlAdesfa || '<Validador>';--(*)
        	xmlAdesfa = xmlAdesfa || '<Nombre></Nombre>';--(*)
            xmlAdesfa = xmlAdesfa || '<Verison/>';--(*)
    	xmlAdesfa = xmlAdesfa || '</Validador>';--(*)
        xmlAdesfa = xmlAdesfa || '<VersionMsj>2.0</VersionMsj>';
    	xmlAdesfa = xmlAdesfa || '<Prestador>';--(*)
        	xmlAdesfa = xmlAdesfa || '<Cuit>30590509643</Cuit>';--(*)
        	xmlAdesfa = xmlAdesfa || '<Sucursal/>';
        	xmlAdesfa = xmlAdesfa || '<RazonSocial/>';
        	xmlAdesfa = concat(xmlAdesfa, '<Codigo>',encabezadomensajejson->>'Prestador_Codigo', '</Codigo>');--(*)
    	xmlAdesfa = xmlAdesfa || '</Prestador>';--(*)
        IF (encabezadomensajejson->>'CodAccion' <> '20010') THEN
    	    xmlAdesfa = xmlAdesfa || '<SetCaracteres>AX</SetCaracteres>';
        END IF;
	xmlAdesfa = xmlAdesfa || '</EncabezadoMensaje>';

	--Encabezado receta
	xmlAdesfa = xmlAdesfa || '<EncabezadoReceta>';--(*)

    IF (encabezadomensajejson->>'CodAccion' <> '20010') THEN
       xmlAdesfa = xmlAdesfa || '<Prescriptor>';
        	xmlAdesfa = xmlAdesfa || '<Apellido/>';
        	xmlAdesfa = xmlAdesfa || '<Nombre/>';
        	xmlAdesfa = concat(xmlAdesfa, '<TipoMatricula>',encabezadorecetajson->>'TipoMatricula', '</TipoMatricula>');
                xmlAdesfa = concat(xmlAdesfa, '<Provincia>', (CASE WHEN nullvalue(rprovinciaprescrip.idadesfa_provincia) THEN encabezadomensajejson->>'TipoMatricula' ELSE rprovinciaprescrip.idadesfa_provincia END), '</Provincia>');        	
                xmlAdesfa = concat(xmlAdesfa, '<NroMatricula>', (CASE WHEN ((nullvalue(encabezadorecetajson->>'Prescriptor_NroMatricula')) OR (encabezadorecetajson->>'Prescriptor_NroMatricula' = '')) THEN '0'
 ELSE encabezadorecetajson->>'Prescriptor_NroMatricula' END), '</NroMatricula>');        	
        	xmlAdesfa = concat(xmlAdesfa, '<TipoPrescriptor>',encabezadorecetajson->>'TipoPrescriptor', '</TipoPrescriptor>');
        	xmlAdesfa = xmlAdesfa || '<Cuit/>';
    	xmlAdesfa = xmlAdesfa || '</Prescriptor>';    	    
    END IF;

    	xmlAdesfa = xmlAdesfa || '<Beneficiario>';
        	xmlAdesfa = xmlAdesfa || '<TipoDoc/>';
        	xmlAdesfa = xmlAdesfa || '<NroDoc/>';
        	xmlAdesfa = xmlAdesfa || '<Apellido/>';
        	xmlAdesfa = xmlAdesfa || '<Nombre/>';
        	xmlAdesfa = xmlAdesfa || '<Sexo/>';
        	xmlAdesfa = xmlAdesfa || '<FechaNacimiento/>';
        	xmlAdesfa = xmlAdesfa || '<Parentesco/>';
        	xmlAdesfa = xmlAdesfa || '<EdadUnidad/>';
        	xmlAdesfa = xmlAdesfa || '<Edad/>';
    	xmlAdesfa = xmlAdesfa || '</Beneficiario>';
    	xmlAdesfa = xmlAdesfa || '<Financiador>';--(*)
        	xmlAdesfa = concat(xmlAdesfa, '<Codigo>', (rnombrevalidador.idadesfa_prepagas)::varchar(255), '</Codigo>');--(*)
            xmlAdesfa = concat(xmlAdesfa, '<Cuit>',encabezadorecetajson->>'Financiador_Cuit', '</Cuit>');
        	xmlAdesfa = xmlAdesfa || '<Sucursal/>';
    	xmlAdesfa = xmlAdesfa || '</Financiador>';--(*)
    	xmlAdesfa = xmlAdesfa || '<Credencial>';--(*)
        	xmlAdesfa = concat(xmlAdesfa, '<Numero>',encabezadorecetajson->>'Credencial_Numero', '</Numero>');--(*)
            xmlAdesfa = concat(xmlAdesfa, '<Track>', (CASE WHEN nullvalue(encabezadorecetajson->>'Track') THEN '' ELSE encabezadorecetajson->>'Track' END), '</Track>');
            --hay un tag CSS que no aparece en el formato de la version 2.0 (en autorizacion y cancelacion)
            xmlAdesfa = xmlAdesfa || '<Version/>';
        	xmlAdesfa = xmlAdesfa || '<Vencimiento/>';
        	xmlAdesfa = concat(xmlAdesfa, '<ModoIngreso>', (CASE WHEN (nullvalue(encabezadorecetajson->>'ModoIngreso')) THEN 'A' ELSE encabezadorecetajson->>'ModoIngreso' END ), '</ModoIngreso>');
        	xmlAdesfa = xmlAdesfa || '<EsProvisorio/>';
        	xmlAdesfa = concat(xmlAdesfa, '<Plan>', (CASE WHEN (nullvalue(encabezadorecetajson->>'idplancobertura')) THEN '1' ELSE encabezadorecetajson->>'idplancobertura' END), '</Plan>');

        	IF(encabezadorecetajson->>'CodAccion' <> '20010') THEN
            	xmlAdesfa = concat(xmlAdesfa, '<cvc2>', (CASE WHEN (nullvalue(encabezadorecetajson->>'codseguridad')) THEN '' ELSE encabezadorecetajson->>'codseguridad' END), '</cvc2>');  	 
        	END IF;

    	xmlAdesfa = xmlAdesfa || '</Credencial>';--(*)

    	IF (encabezadomensajejson->>'CodAccion' <> '20010') THEN
            	xmlAdesfa = xmlAdesfa || '<CoberturaEspecial/>';
            	xmlAdesfa = xmlAdesfa || '<Preautorizacion>';
            	    xmlAdesfa = xmlAdesfa || '<Codigo/>';
            	    xmlAdesfa = xmlAdesfa || '<Fecha/>';
            	xmlAdesfa = xmlAdesfa || '</Preautorizacion>';

    	END IF;   	 

    	xmlAdesfa = concat(xmlAdesfa, '<FechaReceta>',encabezadorecetajson->>'FechaReceta', '</FechaReceta>');--(*)

    	xmlAdesfa = xmlAdesfa || '<Dispensa>';--(*)
        	xmlAdesfa = concat(xmlAdesfa, '<Fecha>',encabezadorecetajson->>'FechaReceta', '</Fecha>');--(*)
        	xmlAdesfa = concat(xmlAdesfa, '<Hora>',encabezadorecetajson->>'Hora', '</Hora>');--(*)       	 
    	xmlAdesfa = xmlAdesfa || '</Dispensa>';--(*)
    	IF (encabezadomensajejson->>'CodAccion' <> '20010') THEN
    	xmlAdesfa = xmlAdesfa || '<Formulario>';
        	xmlAdesfa = xmlAdesfa || '<Fecha/>';
        	xmlAdesfa = xmlAdesfa || '<Tipo/>';
        	xmlAdesfa = concat(xmlAdesfa, '<Numero>', CASE WHEN nullvalue(encabezadorecetajson->>'nroReceta') THEN '' ELSE encabezadorecetajson->>'nroReceta' END, '</Numero>');
        	xmlAdesfa = xmlAdesfa || '<Serie/>';
        	xmlAdesfa = xmlAdesfa || '<NroAutEspecial/>';
        	xmlAdesfa = xmlAdesfa || '<NroFormulario/>';
    	xmlAdesfa = xmlAdesfa || '</Formulario>';
    	xmlAdesfa = concat(xmlAdesfa, '<TipoTratamiento>',encabezadorecetajson->>'TipoTratamiento', '</TipoTratamiento>');--(*)
    	xmlAdesfa = xmlAdesfa || '<Diagnostico/>';
    	xmlAdesfa = xmlAdesfa || '<Institucion>';
        	xmlAdesfa = xmlAdesfa || '<Codigo></Codigo>';--(*)
        	xmlAdesfa = xmlAdesfa || '<Cuit/>';
        	xmlAdesfa = xmlAdesfa || '<Sucursal/>';
    	xmlAdesfa = xmlAdesfa || '</Institucion>';
    	xmlAdesfa = xmlAdesfa || '<Retira>';
        	xmlAdesfa = xmlAdesfa || '<Apellido/>';
        	xmlAdesfa = xmlAdesfa || '<Nombre/>';
        	xmlAdesfa = xmlAdesfa || '<TipoDoc/>';
        	xmlAdesfa = xmlAdesfa || '<NroDoc/>';
        	xmlAdesfa = xmlAdesfa || '<NroTelefono/>';
    	xmlAdesfa = xmlAdesfa || '</Retira>';
        END IF;
	xmlAdesfa = xmlAdesfa || '</EncabezadoReceta>';--(*)

	--Detalle receta
	xmlAdesfa = xmlAdesfa || '<DetalleReceta>';--(*)
        nroItem = 0;
	WHILE nroItem < jsonb_array_length(itemsjson) LOOP
                itemjson = itemsjson->nroItem;
        	xmlAdesfa = xmlAdesfa || '<Item>';
            	xmlAdesfa = concat(xmlAdesfa, '<NroItem>', itemjson->>'NroItem', '</NroItem>');--(*)
                IF (encabezadomensajejson->>'CodAccion' = '20010') THEN
    	           xmlAdesfa = xmlAdesfa || '<CodAutOri></CodAutOri>';
                END IF;
            	xmlAdesfa = concat(xmlAdesfa, '<CodBarras>', itemjson->>'CodBarras', '</CodBarras>');--(*)
            	xmlAdesfa = concat(xmlAdesfa, '<CodTroquel>', itemjson->>'troquel', '</CodTroquel>');--(*)
            	xmlAdesfa = xmlAdesfa || '<Alfabeta></Alfabeta>';
            	xmlAdesfa = xmlAdesfa || '<Kairos/>';
            	xmlAdesfa = xmlAdesfa || '<Codigo/>';
                IF (encabezadomensajejson->>'CodAccion' <> '20010') THEN
                    xmlAdesfa = concat(xmlAdesfa, '<ImporteUnitario>' ,itemjson->>'ImporteUnitario' , '</ImporteUnitario>');--(*)
            	    xmlAdesfa = concat(xmlAdesfa, '<CantidadSolicitada>' , itemjson->>'CantidadSolicitada', '</CantidadSolicitada>');--(*)
            	    xmlAdesfa = xmlAdesfa || '<PorcentajeCobertura></PorcentajeCobertura>';--(*)
            	    xmlAdesfa = xmlAdesfa || '<CodPreautorizacion/>';
            	    xmlAdesfa = xmlAdesfa || '<ImporteCobertura></ImporteCobertura>';--(*)
            	    xmlAdesfa = xmlAdesfa || '<ExcepcionPrescripcion></ExcepcionPrescripcion>';--(*)
            	    xmlAdesfa = xmlAdesfa || '<Diagnostico/>';
            	    xmlAdesfa = xmlAdesfa || '<DosisDiaria/>';
            	    xmlAdesfa = xmlAdesfa || '<DiasTratamiento/>';
            	    xmlAdesfa = xmlAdesfa || '<Generico/>';
            	    xmlAdesfa = xmlAdesfa || '<CodConflicto/>';
            	    xmlAdesfa = xmlAdesfa || '<CodIntervencion/>';
            	    xmlAdesfa = xmlAdesfa || '<CodAccion/>';    	           
                END IF;

        	xmlAdesfa = xmlAdesfa || '</Item>';
                nroItem = nroItem + 1;
	END LOOP;
	xmlAdesfa = xmlAdesfa || '</DetalleReceta>';--(*)

	--Cierre encabezado
	xmlAdesfa = xmlAdesfa || '</MensajeADESFA>'; --(*)

	RETURN xmlAdesfa;
END;










$function$
