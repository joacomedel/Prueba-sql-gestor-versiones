CREATE OR REPLACE FUNCTION public.far_generarxmladesfa(pfiltros jsonb)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

	--Alba y Facu 11/2024

	--VARIABLES
	xmlAdesfa CHARACTER VARYING;
    nroItem INTEGER;
    noEsCancelSWISS boolean;

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

     noEsCancelSWISS = (encabezadorecetajson->>'CodAccion' <> '20010') OR (pfiltros->>'idobrasocial' <> '800006' AND pfiltros->>'idobrasocial' <> '4013');

	--Se marcan con (*) los valores requeridos
	--Encabezado
	xmlAdesfa = '<?xml version="1.0" encoding="ISO-8859-1"?>';--(*)
	xmlAdesfa = xmlAdesfa || '<MensajeADESFA version="3.1.0">';--(*)

	--Encabezado mensaje
	xmlAdesfa = xmlAdesfa || '<EncabezadoMensaje>';--(*)
        IF (NOT nullvalue(encabezadomensajejson->>'NroReferencia')) THEN
    	xmlAdesfa = concat(xmlAdesfa, '<NroReferencia>', encabezadomensajejson->>'NroReferencia', '</NroReferencia>');
        END IF;
    	xmlAdesfa = concat(xmlAdesfa, '<TipoMsj>', encabezadomensajejson->>'TipoMsj', '</TipoMsj>');--(*)
    	xmlAdesfa = concat(xmlAdesfa, '<CodAccion>',encabezadomensajejson->>'CodAccion', '</CodAccion>');--(*)
    	xmlAdesfa = concat(xmlAdesfa, '<IdMsj>',encabezadomensajejson->>'IdMsj', '</IdMsj>');--(*)    
    	xmlAdesfa = xmlAdesfa || '<InicioTrx>';--(*)
        	xmlAdesfa = concat(xmlAdesfa, '<Fecha>',encabezadomensajejson->>'FechaReceta', '</Fecha>');--(*)
        	xmlAdesfa = concat(xmlAdesfa, '<Hora>',encabezadomensajejson->>'Hora', '</Hora>');--(*)
    	xmlAdesfa = xmlAdesfa || '</InicioTrx>';--(*)
    	xmlAdesfa = xmlAdesfa || '<Software>';--(*)
        	xmlAdesfa = xmlAdesfa || '<CodigoADESFA>0</CodigoADESFA>';--(*)
        	xmlAdesfa = xmlAdesfa || '<Nombre>SIGESFarma</Nombre>';
        	xmlAdesfa = xmlAdesfa || '<Version>1.0</Version>';
    	xmlAdesfa = xmlAdesfa || '</Software>';--(*)
    	xmlAdesfa = xmlAdesfa || '<Validador>';--(*)
        	xmlAdesfa = xmlAdesfa || '<CodigoADESFA>0</CodigoADESFA>';--(*)
        	xmlAdesfa = concat(xmlAdesfa, '<Nombre>', (CASE WHEN (rnombrevalidador.idadesfa_prepagas = '500807' OR rvalidacion.fincodigo = '500807') THEN 'IMED' ELSE 'SIGESFarma' END), '</Nombre>');--(*)
    	xmlAdesfa = xmlAdesfa || '</Validador>';--(*)
    	xmlAdesfa = xmlAdesfa || '<Prestador>';--(*)
        	xmlAdesfa = xmlAdesfa || '<CodigoADESFA>0</CodigoADESFA>';
        	xmlAdesfa = xmlAdesfa || '<Cuit>0</Cuit>';--(*)
        	xmlAdesfa = xmlAdesfa || '<Sucursal></Sucursal>';
        	xmlAdesfa = xmlAdesfa || '<RazonSocial></RazonSocial>';
            --xmlAdesfa = xmlAdesfa || '<Codigo>99015123005</Codigo>';        	
            xmlAdesfa = concat(xmlAdesfa, '<Codigo>',encabezadomensajejson->>'Prestador_Codigo', '</Codigo>');--(*)
    	xmlAdesfa = xmlAdesfa || '</Prestador>';--(*)
	xmlAdesfa = xmlAdesfa || '</EncabezadoMensaje>';

	--Encabezado receta
	xmlAdesfa = xmlAdesfa || '<EncabezadoReceta>';--(*)
    IF(noEsCancelSWISS) THEN
        xmlAdesfa = xmlAdesfa || '<Validador>';--(*)
        	xmlAdesfa = xmlAdesfa || '<CodigoADESFA>0</CodigoADESFA>';--(*)
        	xmlAdesfa = xmlAdesfa || '<Nombre/>';
    	xmlAdesfa = xmlAdesfa || '</Validador>';--(*)
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
    END IF;

    	xmlAdesfa = xmlAdesfa || '<Financiador>';--(*)
        	xmlAdesfa = xmlAdesfa || '<CodigoADESFA>0</CodigoADESFA>';
        	xmlAdesfa = concat(xmlAdesfa, '<Codigo>', CASE WHEN noEsCancelSWISS THEN (rnombrevalidador.idadesfa_prepagas)::varchar(255) ELSE pfiltros->>'idobrasocial' END, '</Codigo>');--(*)
                xmlAdesfa = concat(xmlAdesfa, '<Cuit>',encabezadorecetajson->>'Financiador_Cuit', '</Cuit>');
        	xmlAdesfa = xmlAdesfa || '<Sucursal/>';
    	xmlAdesfa = xmlAdesfa || '</Financiador>';--(*)

    	xmlAdesfa = xmlAdesfa || '<Credencial>';--(*)
        	xmlAdesfa = concat(xmlAdesfa, '<Numero>',encabezadorecetajson->>'Credencial_Numero', '</Numero>');--(*)
                xmlAdesfa = concat(xmlAdesfa, '<Track>', (CASE WHEN nullvalue(encabezadorecetajson->>'Track') THEN '' ELSE encabezadorecetajson->>'Track' END), '</Track>');
        	xmlAdesfa = xmlAdesfa || '<Version/>';
        	xmlAdesfa = xmlAdesfa || '<Vencimiento/>';

        	xmlAdesfa = concat(xmlAdesfa, '<ModoIngreso>', (CASE WHEN (nullvalue(encabezadorecetajson->>'ModoIngreso')) THEN 'A' ELSE encabezadorecetajson->>'ModoIngreso' END ), '</ModoIngreso>');

        	xmlAdesfa = xmlAdesfa || '<EsProvisorio/>';

        	xmlAdesfa = concat(xmlAdesfa, '<Plan>', (CASE WHEN (nullvalue(encabezadorecetajson->>'idplancobertura')) THEN '1' ELSE encabezadorecetajson->>'idplancobertura' END), '</Plan>');

        	IF(encabezadorecetajson->>'CodAccion' <> '20010') THEN
            	IF ((encabezadorecetajson->>'idobrasocial' = '1178') OR (encabezadorecetajson->>'idobrasocial' = '1942') OR ((encabezadorecetajson->>'idobrasocial' = '1034'))) THEN
                	xmlAdesfa = concat(xmlAdesfa, '<cvc2>', (CASE WHEN (nullvalue(encabezadorecetajson->>'codseguridad')) THEN '' ELSE encabezadorecetajson->>'codseguridad' END), '</cvc2>');
             	END IF;
            ELSE
                IF (pfiltros->>'idobrasocial' = '800006' OR pfiltros->>'idobrasocial' = '4013') THEN
                    xmlAdesfa = concat(xmlAdesfa, '<cvc2>', pfiltros->>'idobrasocial', '</cvc2>');
                END IF; 
        	END IF;

    	xmlAdesfa = xmlAdesfa || '</Credencial>';--(*)

    	IF (noEsCancelSWISS) THEN
            	xmlAdesfa = xmlAdesfa || '<CoberturaEspecial/>';
            	xmlAdesfa = xmlAdesfa || '<Preautorizacion>';
            	xmlAdesfa = xmlAdesfa || '<Codigo/>';
            	xmlAdesfa = xmlAdesfa || '<Fecha/>';
            	xmlAdesfa = xmlAdesfa || '</Preautorizacion>';
                xmlAdesfa = concat(xmlAdesfa, '<FechaReceta>',encabezadorecetajson->>'FechaReceta', '</FechaReceta>');--(*)
    	END IF;   	 

    	xmlAdesfa = xmlAdesfa || '<Dispensa>';--(*)
        	xmlAdesfa = concat(xmlAdesfa, '<Fecha>',encabezadorecetajson->>'FechaReceta', '</Fecha>');--(*)
        	xmlAdesfa = concat(xmlAdesfa, '<Hora>',encabezadorecetajson->>'Hora', '</Hora>');--(*)       	 
    	xmlAdesfa = xmlAdesfa || '</Dispensa>';--(*)

    	IF (noEsCancelSWISS) THEN
    	xmlAdesfa = xmlAdesfa || '<Formulario>';
        	xmlAdesfa = xmlAdesfa || '<Fecha/>';
        	xmlAdesfa = xmlAdesfa || '<Tipo/>';
        	--xmlAdesfa = xmlAdesfa || '<Numero>543210</Numero>';
        	xmlAdesfa = concat(xmlAdesfa, '<Numero>', CASE WHEN nullvalue(encabezadorecetajson->>'nroReceta') THEN '' ELSE encabezadorecetajson->>'nroReceta' END, '</Numero>');
        	xmlAdesfa = xmlAdesfa || '<Serie/>';
        	xmlAdesfa = xmlAdesfa || '<NroAutEspecial/>';
        	xmlAdesfa = xmlAdesfa || '<NroFormulario/>';
    	xmlAdesfa = xmlAdesfa || '</Formulario>';
    	xmlAdesfa = concat(xmlAdesfa, '<TipoTratamiento>',encabezadorecetajson->>'TipoTratamiento', '</TipoTratamiento>');--(*)
    	xmlAdesfa = xmlAdesfa || '<Diagnostico/>';
    	xmlAdesfa = xmlAdesfa || '<Institucion>';
        	xmlAdesfa = xmlAdesfa || '<CodigoADESFA>0</CodigoADESFA>';
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
        IF(noEsCancelSWISS) THEN
            xmlAdesfa = xmlAdesfa || '<DetalleReceta>';--(*)
            nroItem = 0;
	        WHILE nroItem < jsonb_array_length(itemsjson) LOOP
              itemjson = itemsjson->nroItem;
        	  xmlAdesfa = xmlAdesfa || '<Item>';
            	xmlAdesfa = concat(xmlAdesfa, '<NroItem>', itemjson->>'NroItem', '</NroItem>');--(*)
            	xmlAdesfa = concat(xmlAdesfa, '<CodBarras>', itemjson->>'CodBarras', '</CodBarras>');--(*)
            	xmlAdesfa = concat(xmlAdesfa, '<CodTroquel>', itemjson->>'troquel', '</CodTroquel>');--(*)
            	xmlAdesfa = xmlAdesfa || '<Alfabeta></Alfabeta>';
            	xmlAdesfa = xmlAdesfa || '<Kairos/>';
            	xmlAdesfa = xmlAdesfa || '<Codigo/>';
            	xmlAdesfa = concat(xmlAdesfa, '<ImporteUnitario>' ,itemjson->>'ImporteUnitario' , '</ImporteUnitario>');--(*)
            	xmlAdesfa = concat(xmlAdesfa, '<CantidadSolicitada>' , itemjson->>'CantidadSolicitada', '</CantidadSolicitada>');--(*)
            	xmlAdesfa = xmlAdesfa || '<PorcentajeCobertura></PorcentajeCobertura>';--(*)
            	xmlAdesfa = xmlAdesfa || '<CodPreautorizacion/>';
            	xmlAdesfa = xmlAdesfa || '<ImporteCobertura></ImporteCobertura>';--(*)
            	xmlAdesfa = xmlAdesfa || '<Diagnostico/>';
            	xmlAdesfa = xmlAdesfa || '<DosisDiaria/>';
            	xmlAdesfa = xmlAdesfa || '<DiasTratamiento/>';
            	xmlAdesfa = xmlAdesfa || '<Generico/>';
        	  xmlAdesfa = xmlAdesfa || '</Item>';
                nroItem = nroItem + 1;
	        END LOOP;
	        xmlAdesfa = xmlAdesfa || '</DetalleReceta>';--(*)
        END IF;

	--Cierre encabezado
	xmlAdesfa = xmlAdesfa || '</MensajeADESFA>'; --(*)

	RETURN xmlAdesfa;
END;$function$
