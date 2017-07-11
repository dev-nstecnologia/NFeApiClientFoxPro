* qdfoxJSON.PRG
* Quick & Dirty Foxpro JSON parser
*
* Author  : Victor Espina
* Version : 1.8
* Last upd: Marzo 2013
*
* -------------------------------------------------------------------------
* VERSION HISTORY
* VES 	Mar 10, 2014	1.8		- Metodo faltante encodeArray()
*                               - Mejora en metodo ToJSON() de JSONArray
*                               - Compatibilidad con versiones anteriores a 9 SP2
*                               - Propiedad canonicalNotation pasa a valor .T. por omision
*
* VES   Ene 24, 2014	1.7		- Correccion en metodo Parse para casos de propiedades con nombre que empieza con $.
*
* VES	Mar 14, 2013	1.6		- Nuevo parametro pnDSID en encodeCursor() y parseCursor()
*                               - Correccion en metodo Parse() para valores null (cortesia de Cesar Gomez)
*
* VES	Oct, 7, 2012	1.6		- Correccion en _encodeValue para caso de arrays vacios
*
* VES	Oct, 6, 2012	1.6		- Cambios varios para lograr compatibilidad con VFP 6
*
* VES	Abr 14, 2012	1.5		- Correccion en el manejo de CR y LF en _encodeString y _decodeString (Juan Pablo Martín P, Espana)
*                               - Correccion en el metodo _encodeValue y Parse para el manejo de valores numericos (cortesia de Juan Pabloe Martin y Rafael Cano)
*
* VES   Mar 27, 2012	1.4		- Internal changes to handle special characters in string values
*								- Bug fixed in Clone() method of JSONObject class (reported and fixed by Claudio Luna)
* 								- New Canonical property in jsonHelper class
*
* VES   ?               1.3     - New Clone() method in JSONObject class
*
* VES	Feb 10, 2012	1.2		- Bug fixes in parseCursor() and encodeCursor() methods of jsonHelper class
*
* VES	Feb 9, 2012		1.1		- OOP rewrite
*                               - Added support for VFP objects
*                               - Added support to JSONObject() to be initialized with the response from a given URL
*                               - Added "stringDelimitator" property to jsonHelper class
*								- Added "quotePropertyNames" property to jsonHelper class
*
* VES	Jan 31, 2012	1.0		Initial version 
* -------------------------------------------------------------------------
*
* Usage:
* SET PROCEDURE TO qdfoxJSON ADDITIVE
* JSONStart()
*
* 1. Encoding an object to a JSON string using JSONObject (this is the preferred method):
*      myObject = JSONObject()
*      myObject.add("Name","foo")
*      myObject.add("Age",40)
*      jsonString = myObject.ToJSON()
*      ?jsonString --> "{name:'foo', age:40}"
*
*    To use canonical notation:
*     JSON.canonicalNotation = .T.
*     ?myObject.ToJSON() --> '{"name":"foo", "age":40}'
*
* 2. Encoding an object to a JSON string:
*      myObject = CREATEOBJECT("Empty")
*      ADDPROPERTY("Name","foo")
*      ADDPROPERTY("Age",40)
*      jsonString = JSON.Encode(myObject)
*
* 3. Parsing a JSON string using JSONObject (this is the preferred method):
*      myObject = JSONObject(jsonString)
*
* 4. Parsing a JSON string using Parse() method:
*      myObject = JSON.Parse(jsonString)
*
* 5. Creating a JSONObject manually:
*      myObject = JSONObject("{name:'Foo',age:40}")
*      ?myObject.Name --> 'Foo'
*      ?myObject.Age --> 40
*      myObject.Add("Sex","Male")
*      ?myObject.Sex --> 'Male'
*
*      myObject.addArray("Hobbies","['Read','Trekking','Football']")
*      ?myObject.Hobbies.Count --> 3
*      ?myObject.Hobbies[2] --> 'Trekking'  && Doesn't work in VFP6
*      ?myObject.Hobbies.Item[2] --> 'Trekking'   && Will work in all versions
*
*      myObject.Add("Car","{Maker:'Hyundai',Model:'Accent',Year:2007}")
*      ?myObject.Car.Maker --> "Hyundai"
*      myObject.Car.Add("Engine","V4 1.3 lts")
*      ?myObject.Car.Engine --> 'V4 1.3 lts'
*
* 6. Creating a JSONObject from a declared schema: [1]
*      JSON.declareSchema("User",;
*          "{loginName:string,"+;
*          " fullName:string,"+;
*          " password:string,"+;
*          " lastLogin:datetime}")
*      myObject = JSONObject("schema:User")
*      ?myObject.Schema --> User
*      myObject.loginName = "vespina"
*      
* 7. Create a JSON object and import its values from a table row:
*      JSON.declareSchema("Customer","{id:numeric,name:string,balance:numeric,active:boolean}")
*      SELECT customers
*      LOCATE FOR id = 25
*      oCustomer = JSONObject("schema:Customer")
*      oCustomer.Import("customers")
*      ?oCustomer.Id --> 25
*
* 8. Update a data record from a JSON object:
*      oCustomer = JSONObject("schema:Customer")
*      oCUstomer.Id = 25
*      oCUstomer.Name = "VICTOR ESPINA"
*      oCustomer.Balance = 1244.23
*      oCustomer.Active = .T.
*      SELECT customers
*      APPEND BLANK
*      oCustomer.Export("customers")
*      ?id --> 25
*      ?name --> 'VICTOR ESPINA'
*
* 9. Creating an schema instance and initializes with an external source
*      SELECT Users
*      LOCATE FOR id = 25
*      oUser = JSONObject("schema:User", "users")
*      ?oUser.id --> 25
*
* 10. Encode a data cursor:   [2]
*       cCursorData = JSON.encodeCursor("QDATA")
*       USE IN QDATA
*
* 11. Restore a data cursor from JSON string:
*       JSON.parseCursor(cCursorData)
*       SELECT QDATA
*
* 12. Convert an array in a JSON-friendly object:
*       object = JSONArray(@array)
*
* 13. Create a JSON-friendly array object from a JSON string:
*       object = JSONArray("['Red','Yellow','Green']")
*       ?object[1] --> 'Red'
*
* 14. Use a JSON array object to get a JSON representation of an array:
*       object = JSONArray(@array)
*       cJSON = object.ToJSON()
*
* 15. Export the contents of a JSON array object to a VFP array:
*       LOCAL ARRAY myArray[1]
*       object = JSONArray("['Red','Yellow','Green']")
*       object.ToArray(@myArray)
*       ?myArray[1] --> 'Red'
*
* 16. Parsing the result of a URL call in JSON format:
*     object = JSONObject("url:http://weather.yahooapis.com/forecastjson?w=2502265")
*
*
* NOTES:
* [1] JSON schemas is a personal adaptation of the JSON syntax and
*     it is not supported by JSON.org standards.  The idea is to 
*     declare a object "schema" or data structure and then use it
*     to create empty instances that follows the schema properties.
*
*     This allow us, i.e., to declare a "User" schema and use it every time 
*     we need to handle user's data. This way, if we later need to add
*     a new property to User objects, all we have to do is to change
*     the schema and the new property will be available to the entire
*     app. Is important to understand that this is not supossed to 
*     substitute your custom classes... is more like to have the ability
*     to declare and use data structures to represent complex data.
*
*     A schema definition string contains one or more "property:type" pairs
*     separated with comma and enclosed within curly brackets:
*
*     {name:string,fullName:string,age:numeric,dateOfBirth:datetime}
*
*     The recognized data types are:
*      string
*      numeric
*      boolean
*      date
*      datetime
*      array (parsed as a Collection instance)
*
*     You can also declare object properties, by following the same rules:
*   
*     {name:string,fullName:string,personalInfo:{age:numeric,dob:date},password:string}
*
*     this will create an object with the following interface:
*
*     object
*       .name
*       .fullName
*       .personalInfo
*         .age
*         .dob
*       .password
*
*
* [2] Take in consideration that encoding and decoding data cursors can be
*     a very time & CPU consuming tasks. This functions are intended to be
*     used with small data cursors.
*
*
*
* IMPORTANT NOTE:
* Altough this parser follows the general rules for JSON strings as
* described in JSON.org, and because of that it should work for 
* deserializing any JSON-compatible string, the main goal for this
* library is to be used with Foxpro objects. 
*
* DON'T TAKE FOR GRANTED THAT THIS LIBRARY WILL WORK WITH JSON
* STRINGS GENERATED BY OTHER JSON PARSERS, NOR THE JSON STRING
* GENERATED BY THIS LIBRARY SHOULD WORK WITH OTHER JSON PARSERS.
*
* Altough this library should work with any kind of object, it
* contains an special class called JSONObject wich is very
* light (based on EMPTY class) and can be used to create and recreate
* JSON-compatible objects. In most cases, we recomend to use JSONObject
* to represent data objects instead your own clases, unless they are
* base on the EMPTY class.
*
* NOTE ON ARRAY VALUES AND COLLECTION OBJECTS
* JSON.Encode() will accept array-type values or properties but, take on
* consideration that JSON.Parse() will parse this arrays values as 
* Collections. In the same way, object properties that are based on
* Collection class will be encoded as array values.
*
* ***********************************************
* **          I N T E R F A C E S              **
* ***********************************************
*
* -------------------------------------
* jsonHelper Class
* -------------------------------------
* string Version
* collection Schemas
* char stringDelimitator
* bool quotePropertyNames
* bool canonicalNotation
* (object) Parse(string jsonString)
* (int) parseCursor(string jsonString [,string cursorAlias, int DSID])
* (string) Encode(object Object)
* (string) encodeArray(array arrayValue)
* (string) encodeCursor([string cursorAlias, int DSID])
* (void) declareSchema(string schemaName, string jsonSchema)
* (bool) isSchema(object objectToVerify, string schemaName)
* (bool) isObject(string jsonString)
* (bool) isArray(string jsonString)
*
* -------------------------------------
* JSONObject Class
* -------------------------------------
* string Schema
* (void) Add(string propertyName, variant propertyValue)
* (object) Add(string propertyName, arrayValue)
* (object) Add(string propertyName, string jsonString)
* (object) addArray(string propertyName)
* (string) ToJSON()
* (void) Parse(string jsonString)
* (void) Import(object | alias)
* (void) Export(object | alias)
* (bool) Is(string schemaName)
*
* -------------------------------------
* JSONArray Class
* -------------------------------------
* int Lines
* int Columns
* (string) TOJSON()
* (int) ToArray(@arrayVar)
*
*
#DEFINE CRLF					CHR(13) + CHR(10)
#DEFINE VFP_NOENCODABLE_PROPS	"-controls-controlcount-objects-parent-class-baseclass-classlibrary-parentclass-helpcontextid-whatsthishelpid-top-left-width-height-picture-_customproplist-"


*******************************************
** 
**           F U N C T I O N S
**
*******************************************

* JSONStart
* Class loader
PROCEDURE JSONStart
 PUBLIC JSON
 JSON = CREATEOBJECT("jsonHelper")
ENDPROC


* JSONObject
* Quick function to create empty JSON-friendly objects
*
* Usage:
* o = JSONObject()             && Empty object
* o = JSONObject(cMyJSONStr)   && Recreates a object
*
PROCEDURE JSONObject(pcJSON)
 RETURN CREATEOBJECT("JSONObject",pcJSON)
ENDPROC


* JSONArray
* Takes an array an convert it to a JSONArray
PROCEDURE JSONArray(paArray)
 IF PCOUNT() = 1
  RETURN CREATEOBJECT("JSONArray",@paArray)
 ELSE
  RETURN CREATEOBJECT("JSONArray")
 ENDIF
ENDPROC




*******************************************
** 
**             C L A S S E S 
**
*******************************************

* jsonHelper (Class)
* JSON implementation class
*
DEFINE CLASS jsonHelper AS Custom
 *
 Version = "1.8"
 Schemas = NULL
 stringDelimitator = [']
 quotePropertyNames = .F.
 canonicalNotation = .T.
 
 
 * Class constructor
 PROCEDURE Init
  THIS.Schemas = CREATEOBJECT("Collection")
  THIS.declareSchema("Cursor","{name:string, schemax:array, rows:array}")
 ENDPROC
 
 * Property Accesors
 PROCEDURE canonicalNotation_Assign(vNewVal)
  THIS.canonicalNotation = m.vNewVal
  IF m.vNewVal
   THIS.quotePropertyNames = .T.
   THIS.stringDelimitator = ["]
  ELSE
   THIS.quotePropertyNames = .F.
   THIS.stringDelimitator = [']  
  ENDIF 
 ENDPROC
 
 
 *******************************************
 **       P U B L I C   M E T H O D S 
 *******************************************
 
 * Parse
 * Takes a JSON string and returns the original object
 PROCEDURE Parse(pcJSON)
	 *
	 LOCAL oObjects, i, oResult, lIsArray, lIsVFP, cVFPClass
	 STORE .F. TO lIsArray, lIsVFP

     DO CASE
        CASE LEFT(pcJSON,1) = "["
             lISArray = .T.
             oResult = JSONArray()
             
        CASE LEFT(pcJSON,5) == "{vfp:"
			 LOCAL oVFPInfo
			 oVFPInfo = JSON.Parse(STRT(LEFT(pcJSON,AT("}",pcJSON)),"vfp:true,",""))
			 pcJSON = SUBSTR(pcJSON,AT("{",pcJSON,2))
			 oResult = CREATEOBJECT(oVFPInfo.className)
			 lIsVFP = .T.
			
	    OTHERWISE 
	         #IF VERSION(5) >= 800
	          oResult = CREATEOBJECT("Empty")		 
	         #ELSE
	          oResult = CREATEOBJECT("JSONEmpty")
	         #ENDIF
	 ENDCASE
	 pcJSON = SUBSTR(pcJSON,2,LEN(pcJSON) - 2) 
	 
	 LOCAL oPairs, j, cPair, cProp, cValue, uValue, oObj, cObj, nBlockCount, nSep
	 oObjects = THIS._Split(pcJSON)
	 
	 FOR i = 1 TO oObjects.Count
	  *
	  cObj = oObjects.Item[i]
	  IF EMPTY(cObj)
	   LOOP
	  ENDIF
	  
	  IF lIsArray AND THIS.IsObject(cObj)
	   oResult.Add(THIS.Parse(cObj))
	   LOOP
	  ENDIF

	  oPairs = THIS._Split(cObj)
	  #IF VERSION(5) >= 800
	   oObj = CREATEOBJECT("Empty")
	  #ELSE
	   oObj = CREATEOBJECT("JSONEmpty")
	  #ENDIF
	  FOR j = 1 TO oPairs.Count
	   *
	   cPair = ALLTRIM(oPairs.Item[j])
	   IF lIsArray
	    cValue = cPair
	   ELSE
	    nSep = AT(":",cPair)
	    cProp = CHRTRAN(LEFT(cPair, nSep - 1),["'],[])
	    cValue = ALLTRIM(SUBSTR(cPair, nSep + 1))
	   ENDIF
	   
	   * VES Ene 24, 2014
	   * Si la propiedad empieza con $, se elimina pues es algo
	   * particular de JavaScript que no es compatible con VFP
	   IF !lIsArray AND LEFT(cPRop,1) = "$"
	    cProp = SUBSTR(cProp,2)
	   ENDIF
	   
	   DO CASE
	      CASE LEFT(cValue,1) $ ['"]    && String value
	           uValue = THIS._decodeString( LEFT(SUBSTR(cValue,2),LEN(cValue) - 2) )
	           
	      CASE LEFT(cValue,1) = [@]   && Date/DateTime
	           cValue = SUBSTR(cValue,2)
	           IF LEN(cValue) = 8
	            uValue = CTOD(TRANSFORM(cValue,"@R ^9999-99-99"))
	           ELSE
	            uValue = CTOT(TRANSFORM(cValue,"@R ^9999-99-99 99:99:99"))
	           ENDIF
	      
	      CASE INLIST(cValue,"true","false")  && Boolean value
	           uValue = (cValue == "true")
	         
	      CASE UPPER(cValue) == "NULL" OR UPPER(cValue) == ".NULL." && Null value  &&  cesar
	           uValue = NULL
	            
	      CASE LEFT(cValue,1) = [{]   && Object
	           uValue = THIS.Parse(cValue)
	           
	      CASE LEFT(cValue,1) = "["   && Array
	           uValue = THIS.Parse(cValue)
	 
	      CASE INLIST(LOWER(cValue),"string","numeric","date","datetime","boolean","array")  && Schema
	           DO CASE
	              CASE cValue == "string"
	                   uValue = ""
	                   
	              CASE cValue == "numeric"
	                   uValue = 0.0
	                   
	              CASE cValue == "date"
	                   uValue = {}
	                   
	              CASE cValue == "datetime"
	                   uValue = {//::}
	                   
	              CASE cValue == "boolean"
	                   uValue = .F.
	                   
	              CASE cValue == "array"
	                   uValue = CREATEOBJECT("Collection")
	           ENDCASE
	           
	      OTHERWISE                   && Numeric value
	           uValue = VAL(STRTRAN(cValue, ".", SET("POINT")))  && JuanPa, Abril 13 2012

	   ENDCASE

       DO CASE
          CASE lIsArray
               oResult.Add(uValue)
               
          CASE lIsVFP
               STORE uValue TO oResult.&cProp
               
          OTHERWISE
	           ADDPROPERTY(oResult,cProp,uValue)
	   ENDCASE
	   *
	  ENDFOR
	  
	  *
	 ENDFOR
	 
	 RETURN oResult
	 *
 ENDPROC
 
 
 * parseCursor
 * Takes a JSON string and recreates the original cursor
 PROCEDURE parseCursor(pcJSON, pcAlias, pnDSID)
	 *
	 IF VARTYPE(pnDSID) = "N"      && VES Mar 14, 2013
	  SET DATASESSION TO (pnDSID)
	 ENDIF

	 * Decode JSON
	 LOCAL oCursor
	 oCursor = JSONObject(pcJSON)	 
	 
	 * Check that object passed is a cursor object
	 IF NOT oCursor.Is("Cursor")
	  RETURN .F.
	 ENDIF
	 
	 * If a custom cursor name was passed, replace original name with the new one
	 LOCAL cCursorAlias
	 cCursorAlias = oCursor.Name
	 IF VARTYPE(pcAlias) = "C"
	  cCursorAlias = pcAlias
	 ENDIF
	 
	 * Get cursor schema. JSON arrays are allways unidimensinal, so we have to 
	 * export the array to a valid VFP structure-array
	 LOCAL ARRAY aSchemaX[1]
	 LOCAL ARRAY aSchema[1]
	 oCursor.Schemax.ToArray(@aSchemax)
	 DIMENSION aSchema[ALEN(aSchemaX,1) / 18,18]
	 ACOPY(aSchemaX, aSchema)
	 RELEASE aSchemaX
	 
	 * Creates cursor
	 SELECT 0
	 CREATE CURSOR (cCursorAlias) FROM ARRAY aSchema
	 
	 * Load cursor data. Sadly, an empty-based object cannot be used
	 * to fill a data record using GATHER NAME. So, we prepare a 
	 * macro-substitution REPLACE to fill each row manually. 
	 IF oCursor.Rows.Count > 0
	  LOCAL oRow, cReplace,i
      cReplace = ""
      FOR i = 1 TO FCOUNT()
       cReplace = cReplace + IIF(i > 1,",","") + FIELD(i) + " WITH oRow." + FIELD(i)
      ENDFOR
      cReplace = "REPLACE " + cReplace
	  FOR EACH oRow IN oCursor.Rows
	   APPEND BLANK
	   &cReplace
	  ENDFOR
	 ENDIF
	 
	 RELEASE oCursor
	 *
 ENDPROC
 
 
 * Encode
 * Takes a object and returns a json representation
 PROCEDURE Encode(poObj)
   	 *
	 LOCAL aProps[1]
	 LOCAL nCount, i, cJSON, cProp, lIsArray, lIsVFP, cVFPClass
	 nCount = AMEMBERS(aProps,poObj,1)   && Get member list
	 lIsVFP = (TYPE("poObj.baseClass")="C" AND LOWER(poObj.Class)<>"jsonempty")
	 cJSON = "{"
	 FOR i = 1 TO nCount   && Cycle trough members
	  *
	  DO CASE
	     CASE aProps[i,2] = "Property"    && Just process property members
	          cProp = aProps[i,1]
	          IF lISVFP AND LOWER(cProp) == "class"
	           cVFPClass = poObj.Class
	           LOOP
	          ENDIF
	          #IF VERSION(5) >= 800
 	           IF lISVFP AND "-" + LOWER(cProp) + "-" $ VFP_NOENCODABLE_PROPS
 	          #ELSE
 	           IF "-" + LOWER(cProp) + "-" $ VFP_NOENCODABLE_PROPS
 	          #ENDIF
	           LOOP
	          ENDIF
	          *lIsArray = (TYPE("poObj." + cProp,1) = "A")
	          lIsArray = (TYPE("ALEN(poObj." + cProp + ")") = "N")
	          * Encode the property and add it to the JSON chain
	          IF NOT lISArray
	           cJSON = cJSON + IIF(LEN(cJSON) > 1,",","") + ;
	                   IIF(THIS.quotePropertyNames,THIS.stringDelimitator,"") + ;
	                   LOWER(cProp) + ;
	                   IIF(THIS.quotePropertyNames,THIS.stringDelimitator,"") + ;
	                   ":" + ALLTRIM(THIS._encodeValue(poObj.&cProp))
	          ELSE
	           LOCAL ARRAY aValues[1]
	           ACOPY(poObj.&cProp, aValues)
	           cJSON = cJSON + IIF(LEN(cJSON) > 1,",","") + ;
	                   IIF(THIS.quotePropertyNames,THIS.stringDelimitator,"") + ;
	                   LOWER(cProp) + ;
	                   IIF(THIS.quotePropertyNames,THIS.stringDelimitator,"") + ;
	                   ":" + THIS._encodeValue(@aValues)
	          ENDIF
	  ENDCASE
	  *
	 ENDFOR
	 cJSON = cJSON + "}"
	 
	 IF lISVFP
	  cJSON = "{vfp:true,className:" + THIS.stringDelimitator + cVFPClass + THIS.stringDelimitator + "}" + cJSON
	 ENDIF
	 
	 RETURN cJSON
  	 *
 ENDPROC
 
 
 * encodeArray
 * Takes an array or a collection and generate a JSON representation
 *
 PROCEDURE encodeArray(puArrayOrCollection)
  RETURN THIS._EncodeValue(@puArrayOrCollection)
 ENDPROC
 
 
 * encodeCursor
 * Takes a cursor alias and generate a JSON representation of cursor schema & data
 PROCEDURE encodeCursor(pcAlias, pnDSID)
	 *
	 IF PCOUNT() = 0
	  pcAlias = ALIAS()
	 ENDIF
	 
	 IF VARTYPE(pnDSID) = "N"      && VES Mar 14, 2013
	  SET DATASESSION TO (pnDSID)
	 ENDIF
	 
	 LOCAL oCursor,oRow
	 oCursor = JSONObject("schema:Cursor")
	 oCursor.Schema = "Cursor"
	 oCursor.Name = pcAlias
	 
	 LOCAL ARRAY aSchema[1]
	 AFIELDS(aSchema, pcalias)
	 oCursor.Schemax = JSONArray(@aSchema)
	 
	 SELECT (pcAlias)
	 GO TOP
	 SCAN
	  SCATTER NAME oRow MEMO
	  oCursor.Rows.Add(oRow)
	 ENDSCAN
	 
	 RETURN oCursor.ToJSON()
	 *
 ENDPROC
 
 
 * declareSchema
 * Declares an JSON schema
 PROCEDURE declareSchema(pcName, pcSchema)
	 *
	 IF PCOUNT() <> 2
	  #IF NOT "06.00" $ VERSION()
 	   THROW "JSON2: JSON.declareSchema: invalid parameter count"
 	  #ENDIF
	  RETURN NULL
	 ENDIF
	 
	 THIS.Schemas.Add( pcSchema, LOWER(pcName) )
	 *
 ENDPROC
 
 
 * isSchema
 * Check if the passed object implements an specific schema
 PROCEDURE IsSchema(poRef, pcSchema)
	 *
	 pcSchema = LOWER(pcSchema)
	 
	 * If object implements Is() method, used it
	 IF PEMSTATUS(poRef, "Is", 5)
	  RETURN poRef.Is(pcSchema)
	 ENDIF
	 
	 * Create an instance of the given schema
	 LOCAL oBase
	 oBase = JSONObject("schema:" + pcSchema)
	 
	 * Verify that the passed objects implements all schema's proporties
	 LOCAL ARRAY aProps[1]
	 LOCAL nCount, i, cProp, lIsValid
	 lIsValid = .T.
	 nCount = AMEMBERS(aProps, poRef, 0)
	 FOR i = 1 TO nCount
	  cProp = aProps[i]
	  IF (NOT PEMSTATUS(poRef, cProp, 5)) OR ;
	     (TYPE("poRef." + cProp) = TYPE("oBase." + cProp))
	   lIsValid = .F.
	   EXIT  
	  ENDIF
	 ENDFOR
	 
	 RETURN lIsValid
	 *
 ENDPROC
 
 * isArray
 * Check if the passed JSON string corresponds to an array
 PROCEDURE isArray(pcString)
  RETURN VARTYPE(pcString)="C" AND LEFT(pcString,1)="[" AND RIGHT(pcString,1)="]"
 ENDPROC

 * isObject
 * Check if the passed JSON string corresponds to an object
 PROCEDURE isObject(pcString)
  RETURN VARTYPE(pcString)="C" AND LEFT(pcString,1)="{" AND RIGHT(pcString,1)="}"
 ENDPROC
 
 
 *******************************************
 **      S U P P O R T   M E T H O D S
 *******************************************

 HIDDEN PROCEDURE _encodeValue(puValue, pnArraySize)
  *
  EXTERNAL ARRAY puValue
  EXTERNAL ARRAY RTRIMX
  
  LOCAL lIsArray, cType, cJSONValue
  *lIsArray = (TYPE("puValue",1) = "A")
  lIsArray = (TYPE("ALEN(puValue)") = "N")
  cType = VARTYPE(puValue)
  cJSONValue = "null"
  DO CASE
     CASE lIsArray        && Array value
          cJSONValue = "["
          LOCAL i,nSize
          IF PCOUNT() = 2
           nSize = pnArraySize
          ELSE
           nSize = ALEN(puValue,1)
          ENDIF
          FOR i = 1 TO nSize
           cJSONValue = cJSONValue + IIF(i>1,",","") + THIS._encodeValue(puValue[i])
          ENDFOR
          cJSONValue = cJSONValue + "]"
     
     CASE cType $ "CM"    && string/char value
          cJSONValue = THIS.stringDelimitator + THIS._encodeString(puValue) + THIS.stringDelimitator
          
     CASE cType $ "NIYF"   && Numeric value
          IF puValue = INT(puValue)
           cJSONValue = ALLTRIM(STR(puValue))
          ELSE
           cJSONValue = CHRTRAN(RTRIMX(RTRIMX(TRANSFORM(puValue), "0"), SET("POINT")),SET("POINT"), ".")  && JuanPa / Rafel Cano, Abril 13 2012
          ENDIF
                    
     CASE cType = "L"     && boolean value
          cJSONValue = IIF(puValue,"true","false")
          
     CASE cType = "D"     && Date value (foxpro only)
          cJSONValue = [@] + DTOS(puValue)
          
     CASE cType = "T"     && Datetime value (foxpro only)
          cJSONValue = [@] + TTOC(puValue,1)
          
     CASE cType = "O"     && Object value
          DO CASE
             CASE THIS._IsCollection(puValue)
		          LOCAL ARRAY aItems[MAX(puValue.Count,1)]
		          LOCAL i
		          FOR i = 1 TO puValue.Count
		           aItems[i] = puValue.Item[i]
		          ENDFOR
		          cJSONValue = THIS._encodeValue(@aItems, puValue.Count)
		          RELEASE aItems
             
             CASE PEMSTATUS(puValue,"ToJSON",5)
                  cJSONValue = puValue.toJSON()

             OTHERWISE
		          cJSONValue = THIS.Encode(puValue)             
          ENDCASE
          
     OTHERWISE            && unknown type. Handle it as a string value
          cJSONValue = TRANSFORM(puValue,"")
  ENDCASE

  RETURN cJSONValue
  *
 ENDPROC 
 
 HIDDEN PROCEDURE _Split(pcJSON)
	 *
	 LOCAL nBlockCount,cObj,lOpenQuote,cChar
	 nBlockCount = 0  
	 cObj = pcJSON
	 lOpenQuote = .F.
	 FOR j = 1 TO LEN(cObj)
	   cChar = SUBSTR(cObj, j, 1)
	   DO CASE
	      CASE cChar $ "[{"
	           nBlockCount = nBlockCount + 1
	   
	      CASE cChar $ "]}"
	           nBlockCount = nBLockCount - 1

	      CASE cChar $ THIS.stringDelimitator
	           IF lOpenQuote
	            nBlockCount = nBLockCount - 1
	           ELSE
	            nBlockCount = nBlockCount + 1 
	           ENDIF
	           lOpenQuote = !lOpenQuote
	           
	      CASE cChar = "," AND nBlockCount = 0
	           cObj = STUFF(cObj,j,1,CHR(254))
	   ENDCASE
	 ENDFOR   
	 
	 LOCAL ARRAY aObjects[1]
	 LOCAL nCount, i, oResult
	 oResult = CREATEOBJECT("Collection")
	 nCount = ALINES(aObjects, STRT(cObj,CHR(254),CRLF))
	 FOR i = 1 TO nCount
	  oResult.add(aObjects[i])
	 ENDFOR
	 
	 RETURN oResult
	 *
 ENDPROC
 
 HIDDEN PROCEDURE _isCollection(poObj)
  RETURN VARTYPE(poObj)="O" AND PEMSTATUS(poObj,"Count",5) AND PEMSTATUS(poObj,"Item",5)
 ENDPROC

 HIDDEN PROCEDURE _encodeString(pcString)
  pcString = STRT(pcString, CHR(13), "%CR%")
  pcString = STRT(pcString, CHR(10), "%LF%")  
  pcString = STRT(pcString, CHR(9), [%TAB%])
  pcString = STRT(pcString, ['], [%SINGLEQUOTE%])
  pcString = STRT(pcString, ["], [%DOUBLEQUOTE%])
  RETURN pcString
 ENDPROC
 
 HIDDEN PROCEDURE _decodeString(pcString)
  pcString = STRT(pcString, [%CR%], CHR(13))
  pcString = STRT(pcString, [%LF%], CHR(10))
  pcString = STRT(pcString, [%TAB%], CHR(9))
  pcString = STRT(pcString, [%SINGLEQUOTE%], ['])
  pcString = STRT(pcString, [%DOUBLEQUOTE%], ["])
  RETURN pcString
 ENDPROC
 *
ENDDEFINE



* JSONObject
* Helper class to create JSON-friendly objects
*
DEFINE CLASS JSONObject AS Custom
 *
 Buff = NULL
 Schema = ""
 Url = ""
 
 * Class constructor. If a JSON string is passed, it recreate
 * the object from it automatically
 PROCEDURE Init(pcJSON, puSource)
  *
  #IF VERSION(5) >= 800
   THIS.Buff = CREATEOBJECT("Empty")
  #ELSE
   THIS.Buff = CREATEOBJECT("JSONEmpty")
  #ENDIF
  
  * If no JSON string passed, ends here
  IF VARTYPE(pcJSON) <> "C"
   RETURN
  ENDIF
  
  DO CASE
		  * If a schema was indicated, create the object from the 
		  * given schema; otherwise, create the object from the
		  * JSON string passed
     CASE LEFT(pcJSON,7) == "schema:"
		  LOCAL cSchema
		  cSchema = LOWER(SUBSTR(pcJSON,8))
		  IF JSON.Schemas.getKey(cSchema) > 0
		   THIS.parseFromSchema(cSchema)
		  ELSE
		   #IF NOT "06.00" $ VERSION()
		    THROW "qdfoxJSON: Schema " + cSchema + " has not been declared"
		   #ELSE
		    RETURN NULL
		   #ENDIF
		  ENDIF
		  
		  
		  * If we received and URL, get the response and parse it
     CASE LEFT(pcJSON,4) == "url:"
          THIS.parseFromURL( SUBSTR(pcJSON,5) )
          
          
          * Process a normal JSON string
     OTHERWISE
          THIS.Parse(pcJSON)
  ENDCASE
  
  * If a data source was passed, import it 
  IF VARTYPE(puSource) $ "OC"
    THIS.Import(puSource)
  ENDIF
  *
 ENDPROC
 
 
 * THIS Accessor
 * Returns the appropiate reference base on the requested member
 PROCEDURE THIS_Access(cMember)
  IF LOWER(cMember)<>"buff" AND PEMSTATUS(THIS.Buff, cMember, 5)
   RETURN THIS.Buff
  ELSE
   RETURN THIS
  ENDIF
 ENDPROC

 
 * Add
 * Add a new property to the object
 PROCEDURE Add(pcProp, puValue)
  EXTERNAL ARRAY puValue
  DO CASE
     CASE (TYPE("ALEN(puValue)") = "N")  && TYPE("puValue",1) = "A"
          LOCAL oArray,i
          oArray = THIS.addArray(pcProp)
          FOR i = 1 TO ALEN(puValue,1)
           oArray.Add(puValue[i])
          ENDFOR
          RETURN oArray
     
     CASE JSON.isObject(puValue)
          ADDPROPERTY(THIS.Buff,pcProp,JSONObject(puValue))
          RETURN THIS.Buff.&pcProp
     
     OTHERWISE
          ADDPROPERTY(THIS.Buff, pcProp, puValue)
  ENDCASE
 ENDPROC
 
 * addArray
 * Add a new array property to the object
 PROCEDURE addArray(pcProp, pcValues)
  IF VARTYPE(pcValues) <> "C"
   ADDPROPERTY(THIS.Buff, pcProp, CREATEOBJECT("Collection"))
  ELSE
   ADDPROPERTY(THIS.Buff, pcProp, JSONDecode("[" + pcValues + "]"))
  ENDIF
  RETURN THIS.Buff.&pcProp
 ENDPROC
 
 * ToJSON
 * Return a JSON string representing the object data
 PROCEDURE ToJSON
  RETURN JSON.Encode(THIS.Buff)
 ENDPROC
 
 * Parse
 * Take a JSON string and recover the object data from it
 PROCEDURE Parse(pcJSON)
  THIS.Buff = JSON.Parse(pcJSON)
  IF PEMSTATUS(THIS.Buff,"JSONSchema",5)
   THIS.Schema = THIS.Buff.JSONSchema
  ENDIF
 ENDPROC
 
 * parseFromSchema
 * Create and empty object from a declared schema
 PROCEDURE parseFromSchema(pcSchema)
  pcSchema = LOWER(pcSchema)
  THIS.Buff = JSON.Parse( JSON.Schemas.Item[pcSchema] )
  ADDPROPERTY(THIS.Buff,"JSONSchema",pcSchema)
  THIS.Schema = pcSchema
 ENDPROC
 
 * parseFromURL
 PROCEDURE parseFromURL(pcURL)
  THIS.Url = pcUrl
  LOCAL cJSONString
  cJSONString = GetURL(pcURL)
  THIS.Buff = JSON.Parse(cJSONString)
 ENDPROC
 
 * Import
 * Import object's properties from an object or alias
 PROCEDURE Import(puSource)
  DO CASE
     CASE VARTYPE(puSource) = "O"  && Object
          LOCAL ARRAY aProps[1]
          LOCAL nCount, i, cProp
          nCount = AMEMBERS(puSource,0)
          FOR i = 1 TO nCount
           cProp = aProps[i]
           IF PEMSTATUS(THIS.Buff,cProp,5)
            STORE EVALUATE("puSource." + cProp) TO ("THIS.Buff." + cProp)
           ENDIF
          ENDFOR
     
     CASE VARTYPE(puSource) = "C" AND USED(puSource) && Alias
          LOCAL i,cProp
          FOR i = 1 TO FCOUNT(puSource)
           cProp = FIELD(i, puSource)
           IF PEMSTATUS(THIS.Buff,cProp,5)
            STORE EVALUATE("puSource." + cProp) TO ("THIS.Buff." + cProp)
           ENDIF
          ENDFOR
  ENDCASE
 ENDPROC
 
 
 * Export
 * Export object's properties value to a given object or alias
 PROCEDURE Export(puTarget)
  DO CASE
     CASE VARTYPE(puTarget) = "O"  && Object
          LOCAL ARRAY aProps[1]
          LOCAL nCount, i, cProp
          nCount = AMEMBERS(puTarget,0)
          FOR i = 1 TO nCount
           cProp = aProps[i]
           IF PEMSTATUS(THIS.Buff,cProp,5)
            STORE EVALUATE("THIS.Buff." + cProp) TO ("puTarget." + cProp)
           ENDIF
          ENDFOR
     
     CASE VARTYPE(puTarget) = "C" AND USED(puTarget) && Alias
          LOCAL i,cProp
          SELECT (puTarget)
          FOR i = 1 TO FCOUNT()
           cProp = FIELD(i)
           IF PEMSTATUS(THIS.Buff,cProp,5)
            REPLACE (cProp) WITH EVALUATE("THIS.Buff." + cProp)
           ENDIF
          ENDFOR
  ENDCASE
 ENDPROC
 
 
 * Is
 * Check if the object implements the given schema
 PROCEDURE Is(pcSchema)
  RETURN (THIS.Schema == LOWER(pcSchema))
 ENDPROC
 
 * Clone
 * Crea una copia del objeto y la devuelve
 *
 PROCEDURE Clone
  RETURN JSONObject(THIS.ToJSON())
 ENDPROC
 *
ENDDEFINE


* JSONArray (Class)
* Represents an array
DEFINE CLASS JSONArray AS Collection
 *
 Lines = 0
 Columns = 0
 
 PROCEDURE Init(paArray)
  DO CASE 
     CASE PCOUNT() = 0
          THIS.Lines = 0
          THIS.Columns = 1
     
     CASE TYPE("ALEN(paArray)")="N"  && TYPE("paArray",1) = "A"
          LOCAL uItem
          THIS.Lines = ALEN(paArray,1)
          THIS.Columns = ALEN(paArray,2)
		  FOR EACH uItem IN paArray
		   THIS.Add(uItem)
		  ENDFOR
		  
	 CASE THIS._isArray(paArray)
	      LOCAL oItems, uItem
	      oItems = JSON.decodeArray(paArray)
	      THIS.Lines = oItems.Count
	      THIS.Columns = 1
	      FOR EACH uItem IN oItems
	       THIS.Add(uItem)
	      ENDFOR
	      
	 CASE THIS._isCollection(paArray)
	      LOCAL uItem
	      THIS.Lines = paArray.Count
	      THIS.Columns = 1
	      FOR EACH uItem IN paArray
	       THIS.Add(uItem)
	      ENDFOR
  ENDCASE
 ENDPROC
 
 PROCEDURE ToJSON()
  LOCAL ARRAY aContent[1]
  THIS.ToArray(@aContent)
  RETURN JSON.encodeArray(@aContent)
 ENDPROC
 
 PROCEDURE ToArray(paArray)
  LOCAL nRows,nCols
  nRows = IIF(THIS.Lines > 0, THIS.Lines, THIS.Count)
  nCols = IIF(THIS.Columns > 0, THIS.Columns, 1)
  DIMENSION paArray[nRows,nCols]
  LOCAL uItem, i
  FOR i = 1 TO THIS.COunt
   paArray[i] = THIS.Item[i]
  ENDFOR
  RETURN THIS.Count
 ENDPROC
 
 HIDDEN PROCEDURE _isArray(puValue)
  RETURN (VARTYPE(puValue)="C" AND LEFT(puValue,1) = "[" AND RIGHT(puValue,1)="]")
 ENDPROC
 
 HIDDEN PROCEDURE _isCollection(puValue)
  RETURN (VARTYPE(puValue) = "O" AND PEMSTATUS(puValue,"BaseClass",5) AND LOWER(puValue.baseClass == "collection"))
 ENDPROC
 
 *
ENDDEFINE





*******************************************
** 
**       O L D   F U N C T I O N S
**
**   (For compatibility with verson 1.0)
**
*******************************************

PROCEDURE JSONEncode(poObj)
 RETURN JSON.Encode(poObj)
ENDPROC

PROCEDURE JSONEncodeCursor(pcAlias)
 IF PCOUNT() = 1
  RETURN JSON.Encode(pcAlias)
 ELSE
  RETURN JSON.Encode()
 ENDIF
ENDPROC

PROCEDURE JSONDecodeCursor(pcJSONString, pcAlias)
 IF PCOUNT() = 2
  RETURN JSON.parseCursor(pcJSONString, pcAlias)
 ELSE
  RETURN JSON.parseCursor(pcJSONString)
 ENDIF 
ENDPROC

PROCEDURE JSONDecode(pcJSON)
 RETURN JSON.Parse(pcJSON)
ENDPROC

PROCEDURE JSONDeclareSchema(pcNAme, pcSchema)
 RETURN JSON.declareSchema(pcName, pcSchema)
ENDPROC

PROCEDURE JSONIsSchema(poRef, pcSchema)
 RETURN JSON.isSchema(poRef, pcSchema)
ENDPROC




*******************************************
** 
**    S U P P O R T   F U N C T I O N S
**
*******************************************

*************************************************
**
** GETURL.PRG
** Returns the contains of any given URL
**
** Version: 1.0
**
** Author: Victor Espina (vespinas@cantv.net)
**         Walter Valle (wvalle@develcomp.com)
**         (based on original source code from Pablo Almunia)
*
** Date: August 20, 2003
**
**
** Syntax:
** cData = GetURL(pcURL[,plVerbose])
**
** Where:
** cData	 Contents (text or binary) of requested URL.
** pcURL	 URL of the requested resource or file. If an
**           error occurs, a empty string will be returned.
** plVerbose Optional. If setted to True, progress info
**			 will be shown.
**
** Example:
** cHTML=GetURL("http://www.portalfox.com")
**
**************************************************
PROCEDURE GetURL
LPARAMETER pcURL,plVerbose
 *
 *-- Se definen las funciones API necesarias
 *
 #DEFINE INTERNET_OPEN_TYPE_PRECONFIG     0
 DECLARE LONG GetLastError IN WIN32API
 DECLARE INTEGER InternetCloseHandle IN "wininet.dll" ;
	LONG hInet
 DECLARE LONG InternetOpen IN "wininet.dll" ;
  STRING   lpszAgent, ;
  LONG     dwAccessType, ;
  STRING   lpszProxyName, ;
  STRING   lpszProxyBypass, ;
  LONG     dwFlags
 DECLARE LONG InternetOpenUrl IN "wininet.dll" ;
    LONG    hInet, ;
 	STRING  lpszUrl, ;
	STRING  lpszHeaders, ;
    LONG    dwHeadersLength, ;
    LONG    dwFlags, ;
    LONG    dwContext
 DECLARE LONG InternetReadFile IN "wininet.dll" ;
	LONG     hFtpSession, ;
	STRING  @lpBuffer, ;
	LONG     dwNumberOfBytesToRead, ;
	LONG    @lpNumberOfBytesRead
	
	
 *-- Se establece la conexión con internet
 *
 IF plVerbose
  WAIT "Opening Internet connection..." WINDOW NOWAIT
 ENDIF
 
 LOCAL nInetHnd
 nInetHnd = InternetOpen("GETURL",INTERNET_OPEN_TYPE_PRECONFIG,"","",0)
 IF nInetHnd = 0
  RETURN ""
 ENDIF
 
 
 *-- Se establece la conexión con el recurso
 *
 IF plVerbose
  WAIT "Opening connection to URL..." WINDOW NOWAIT
 ENDIF
 
 LOCAL nURLHnd
 nURLHnd = InternetOpenUrl(nInetHnd,pcURL,NULL,0,0,0)
 IF nURLHnd = 0
  InternetCloseHandle( nInetHnd )
  RETURN ""
 ENDIF


 *-- Se lee el contenido del recurso
 *
 LOCAL cURLData,cBuffer,nBytesReceived,nBufferSize
 cURLData=""
 cBuffer=""
 nBytesReceived=0
 nBufferSize=0

 DO WHILE .T.
  *
  *-- Se inicializa el buffer de lectura (bloques de 2 Kb)
  cBuffer=REPLICATE(CHR(0),2048)
  
  *-- Se lee el siguiente bloque
  InternetReadFile(nURLHnd,@cBuffer,LEN(cBuffer),@nBufferSize)
  IF nBufferSize = 0
   EXIT
  ENDIF
  
  *-- Se acumula el bloque en el buffer de datos
  cURLData=cURLData + SUBSTR(cBuffer,1,nBufferSize)
  nBytesReceived=nBytesReceived + nBufferSize
  
  IF plVerbose
   WAIT WINDOW ALLTRIM(TRANSFORM(INT(nBytesReceived / 1024),"999,999")) + " Kb received..." NOWAIT
  ENDIF
  *
 ENDDO
 IF plVerbose
  WAIT CLEAR
 ENDIF

 
 *-- Se cierra la conexión a Internet
 *
 InternetCloseHandle( nInetHnd )

 *-- Se devuelve el contenido del URL
 *
 RETURN cURLData
 *
ENDPROC




#IF VERSION(5) <= 600

* Collection (Class)
* Implementacion aproximada de la clase Collection de VFP8+
*
* Autor: Victor Espina
* Fecha: Octubre 2012
*
DEFINE CLASS Collection AS Custom

 DIMEN Keys[1]
 DIMEN Items[1]
 DIMEN Item[1]
 Count = 0
 
 PROCEDURE Init(pnCapacity)
  IF PCOUNT() = 0
   pnCapacity = 0
  ENDIF
  DIMEN THIS.Items[MAX(1,pnCapacity)]
  DIMEN THIS.Keys[MAX(1,pnCapacity)]
  THIS.Count = pnCapacity
 ENDPROC
  
 PROCEDURE Items_Access(nIndex1,nIndex2)
  IF VARTYPE(nIndex1) = "N"
   RETURN THIS.Items[nIndex1]
  ENDIF
  LOCAL i
  FOR i = 1 TO THIS.Count
   IF THIS.Keys[i] == nIndex1
    RETURN THIS.Items[i]
   ENDIF
  ENDFOR
 ENDPROC

 PROCEDURE Items_Assign(cNewVal,nIndex1,nIndex2)
  IF VARTYPE(nIndex1) = "N"
   THIS.Items[nIndex1] = m.cNewVal
  ELSE
   LOCAL i
   FOR i = 1 TO THIS.Count
    IF THIS.Keys[i] == nIndex1
     THIS.Items[i] = m.cNewVal
     EXIT
    ENDIF
   ENDFOR
  ENDIF 
 ENDPROC
 
 PROCEDURE Item_Access(nIndex1, nIndex2)
  RETURN THIS.Items[nIndex1]
 ENDPROC
 
 PROCEDURE Item_Assign(cNewVal, nIndex1, nIndex2)
  THIS.Items[nIndex1] = cNewVal
 ENDPROC


 PROCEDURE Clear
  DIMEN THIS.Items[1]
  DIMEN THIS.Keys[1]
  THIS.Count = 0
 ENDPROC
 
 PROCEDURE Add(puValue, pcKey)
  IF !EMPTY(pcKey) AND THIS.getKey(pcKey) > 0
   RETURN .F.
  ENDIF
  THIS.Count = THIS.Count + 1
  IF ALEN(THIS.Items,1) < THIS.Count
   DIMEN THIS.Items[THIS.Count]
   DIMEN THIS.Keys[THIS.Count]
  ENDIF
  THIS.Items[THIS.Count] = puValue
  THIS.Keys[THIS.Count] = IIF(EMPTY(pcKey),"",pcKey)
 ENDPROC
 
 PROCEDURE Remove(puKeyOrIndex)
  IF VARTYPE(puKeyOrIndex)="C"
   puKeyOrIndex = THIS.getKey(puKeyOrIndex)
  ENDIF
  LOCAL i
  FOR i = puKeyOrIndex TO THIS.Count - 1
   THIS.Items[i] = THIS.Items[i + 1]
   THIS.Keys[i] = THIS.Keys[i + 1]
  ENDFOR
  THIS.Items[THIS.Count] = NULL
  THIS.Keys[THIS.Count] = NULL
  THIS.Count = THIS.Count - 1
 ENDPROC

 PROCEDURE getKey(puKeyOrIndex)
  LOCAL i,uResult
  IF VARTYPE(puKeyOrIndex)="N"
   uResult = THIS.Keys[puKeyOrIndex]
  ELSE
   uResult = 0
   FOR i = 1 TO THIS.Count
    IF THIS.Keys[i] == puKeyOrIndex
     uResult = i
     EXIT
    ENDIF
   ENDFOR
  ENDIF
  RETURN uResult  
 ENDPROC
   
ENDDEFINE


* ADDPROPERTY
* Simula la funcion ADDPROPERTY existente en VFP9
*
PROCEDURE AddProperty(poObject, pcProperty, puValue)
 poObject.addProperty(pcProperty, puValue)
ENDPROC


* JSONEmpy (Class)
* Simula una clase Empty para versiones de VFP anteriores a la 9.00
*
DEFINE CLASS JSONEmpty AS Custom
 _customPropList = ""
 
 PROCEDURE addProperty(pcProp, puValue)
  DODEFAULT(pcProp, puValue)
  THIS._customPropList = THIS._customPropList + "[" + LOWER(pcProp) + "]"
 ENDPROC
 
 PROCEDURE _isProp(pcProp)
  RETURN (AT("[" + LOWER(pcProp) + "]", THIS._customPropList) <> 0)
 ENDPROC
 
 PROCEDURE _setPropValue(pcProp, puValue)
  IF THIS._isProp(pcProp)
   STORE puValue TO ("THIS." + pcProp)
  ENDIF
 ENDPROC
ENDDEFINE


* RTRIMX
* Implementacion de la forma extendida de RTRIM() disponible en VFP9
*
PROCEDURE RTRIMX(pcString, pcCharToTrim)
 LOCAL i
 i = LEN(pcString)
 DO WHILE SUBS(pcString, i, 1) = pcCharToTrim
  i = i - 1
  pcString = LEFT(pcString, i)
 ENDDO
 RETURN pcString
ENDPROC

#ENDIF