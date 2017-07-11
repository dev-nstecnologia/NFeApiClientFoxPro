DEFINE CLASS nfeapi AS Custom
	FUNCTION emitirNFe
	PARAMETERS token, conteudo, tpConteudo
		url = "https://nfe.ns.eti.br/nfe/issue"
		retorno = this.enviaConteudoParaAPI(token, conteudo, url, tpConteudo)
		RETURN retorno
	ENDFUNC
	
	FUNCTION consultaStatusProcessamento
	PARAMETERS token, CNPJ, nsNRec
		conteudo = '{"X-AUTH-TOKEN": "' + token + '", "CNPJ": "' + CNPJ + '", "nsNRec": "' + nsNRec + '"}'
		url = "https://nfe.ns.eti.br/nfe/issue/status"
		retorno = this.enviaConteudoParaAPI(token, conteudo, url, "json")
		RETURN retorno
	ENDFUNC
	
	FUNCTION downloadNFe
	PARAMETERS token, chNFe, tpDown
		conteudo = '{"X-AUTH-TOKEN": "' + token + '", "chNFe": "' + chNFe + '", "tpDown": "' + tpDown + '"}'
		url = "https://nfe.ns.eti.br/nfe/get"
		retorno = this.enviaConteudoParaAPI(token, conteudo, url, "json")
		RETURN retorno
	ENDFUNC
	
	FUNCTION downloadNFeAndSave
	PARAMETERS token, chNFe, tpDown, caminho, isShow
	DECLARE INTEGER ShellExecute IN "Shell32.dll" ; 
	INTEGER hwnd, ; 
	STRING lpVerb, ; 
	STRING lpFile, ; 
	STRING lpParameters, ; 
	STRING lpDirectory, ; 
	LONG nShowCmd 
	
		retorno = this.downloadNFe(token, chNFe, tpDown)
		
		Obj = NEWOBJECT("jsonHelper", "qdfoxjson.prg")
		Obj = Obj.Parse(retorno)
		
		IF(Obj.status == 200) THEN
			IF LEN(caminho) > 0 THEN
				IF (!(FILE(caminho))) THEN
					this.criaPastas(caminho)
				ENDIF
				IF (!(RIGHT(caminho, 1) == "\")) THEN
					caminho = caminho + "\"
				ENDIF
			ENDIF
			
			tpDownUpper = UPPER(tpDown)
			IF(AT("X", tpDownUpper) <> 0) THEN
				STRTOFILE(Obj.xml, caminho + chNFe + "-procNfe.xml")
			ELSE
				IF(AT("J", tpDownUpper) <> 0) THEN
					json = this.separaJson(retorno)
					STRTOFILE(json, caminho + chNFe + "-procNfe.json")
				ENDIF
			ENDIF
			IF(AT("P", tpDownUpper) <> 0) THEN
				STRTOFILE(STRCONV(Obj.pdf, 14), caminho + chNFe + "-procNfe.pdf")
				IF(isShow == 1) THEN
					Shellexecute(0,"Open", (caminho + chNFe + "-procNfe.pdf"), "","",7)
				ENDIF
			ENDIF
			
		ENDIF
		
		RETURN retorno
	ENDFUN
	
	FUNCTION enviaConteudoParaAPI
	PARAMETERS token, conteudo, url, tpConteudo
		loHTTP = CREATEOBJECT("WinHttp.WinHttpRequest.5.1")
		loHTTP.Open("POST", url, .F.)
		loHTTP.SetRequestHeader("X-AUTH-TOKEN", token)
		
		DO CASE
		CASE (tpConteudo == "txt") 
		    loHTTP.SetRequestHeader("content-type", "text/plain")
		CASE (tpConteudo == "xml") 
			loHTTP.SetRequestHeader("content-type", "application/xml")
		CASE (tpConteudo == "json") 
		    loHTTP.SetRequestHeader("content-type", "application/json")
		ENDCASE
		 
		loHTTP.Send(conteudo)
		RETURN  loHTTP.ResponseBody
	ENDFUNC
	
	FUNCTION criaPastas
	PARAMETERS caminho
		ALINES(diretorios, caminho,.T.,"\")
		atual = ""
		FOR i=1 TO ALEN(diretorios)
			atual = atual + diretorios[i]
			&&IF (!(FILE(atual))) THEN
			IF (!(DIRECTORY(atual))) THEN
				MKDIR(atual)
			ENDIF
			atual = atual + "\"
		NEXT
	ENDFUNC
	
	FUNCTION separaJson
	PARAMETERS retorno
		inicio = AT('nfeProc"', retorno) + 9
		fim = LEN(retorno)
		IF(AT('pdf":', retorno) <> 0) THEN
			fim = AT('pdf"', retorno) - 2
		ENDIF
		json = SUBSTR(retorno, inicio, fim - inicio)
		RETURN json
	ENDFUNC
ENDDEFINE