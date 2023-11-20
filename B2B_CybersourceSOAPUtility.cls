/**
 * @description       :
 * @author            : Tom Zarr by way of a generous partner
 * @group             :
 * @last modified on  : 11-20-2023
 * @last modified by  : Tom Zarr by way of a generous partner
 * Modifications Log
 * Ver   Date           Author                                  Modification
 * 1.0   08-28-2020     Tom Zarr by way of a generous partner   Initial Version
 *
 /* Tom Zarr by way of a generous partner 01-18-2021 */
public class B2B_CybersourceSOAPUtility {

    public static String HOST ='HOST';
    public static String MERCHANT_ID='MERCHANT_ID';
    public static String KEY_ID='KEY_ID';
    public static String PRIVATE_KEY='PRIVATE_KEY';
    public static String microURL='microURL';
    public static String paymentURL='Test';
    public static String transactionURL='transactionURL';
    public static String DATETIME_STRING, DIGEST_STRING;

    //this method returns default contact point address of current logged in user
    public static Map<String, String> getActiveDefaultAddress(commercepayments.AddressRequest address){

        USER cUser = [SELECT Id, Contact.FirstName, Contact.LastName, Contact.Phone, Email, AccountId FROM User WHERE Id=:UserInfo.getUserId() LIMIT 1];

        Map<String, String> params = new Map<String, String>();
        datetime dt = datetime.now();
        System.debug('_____address_____'+address);
        params.put('mRefernceCode',String.valueOf(dt.gettime()));
        params.put('firstName',cUser.Contact.FirstName);
        params.put('lastName',cUser.Contact.LastName);
        params.put('lastName',cUser.Contact.Phone);

        params.put('street',address.Street);
        params.put('city',address.City);
        params.put('state',address.State);
        params.put('postalCode',address.PostalCode);
        params.put('country',address.Country);
        params.put('email',cUser.Email);

        return params;
    }

    public static String SoapXMLTOAuthorize(CommercePayments.AuthorizationRequest authReq) {

        String currencyIso = authReq.currencyIsoCode;
         if(currencyIso == null) {
            currencyIso = UserInfo.getDefaultCurrency();
        }
        commercepayments.AuthApiPaymentMethodRequest paymentMethod = authReq.paymentMethod;
        commercepayments.AddressRequest address = paymentMethod.address;

        System.debug('_________authReq________'+authReq);
        Map<String, String> params = getActiveDefaultAddress(address);

        Map<String, Object> listJson = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(paymentMethod));
        Map<String, Object> cardObject = (Map<String, Object>) listJson.get('cardPaymentMethod');
        System.debug('card Number ' + cardObject.get('cardNumber'));
        System.debug('card cvv ' + cardObject.get('cvv')); // Card Name
        System.debug('card expiryMonth ' + cardObject.get('expiryMonth'));
        System.debug('card expiryYear ' + cardObject.get('expiryYear'));

        string strxml ='';
        strxml +=  '<?xml version="1.0" encoding="UTF-8"?>';
        strxml +=  '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">';
        strxml +=  '<soapenv:Header>';
        strxml +=  '  <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">';
        strxml +=  '   <wsse:UsernameToken>';
        strxml +=  '     <wsse:Username>{!$Credential.Username}</wsse:Username>';
        strxml +=  '     <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">{!$Credential.Password}</wsse:Password>';
        strxml +=  '   </wsse:UsernameToken>';
        strxml +=  ' </wsse:Security>';
        strxml +=  ' </soapenv:Header>';
        strxml +=  '<soapenv:Body>';
        strxml +=  '  <requestMessage xmlns="urn:schemas-cybersource-com:transaction-data-1.129">';
        strxml +=  '    <merchantID>{!$Credential.Username}</merchantID>';
        strxml +=  '   <merchantReferenceCode>'+ params.get('mRefernceCode') +'</merchantReferenceCode>';
        strxml +=  '  <billTo>';
        strxml +=  '  <firstName>'+params.get('firstName')+'</firstName>';
        strxml +=  '  <lastName>'+params.get('lastName')+'</lastName>';
        strxml +=  ' <street1>'+params.get('street')+'</street1>';
        strxml +=  '  <city>'+params.get('city')+'</city>';
        strxml +=  '  <state>'+params.get('state')+'</state>';
        strxml +=  '  <postalCode>'+params.get('postalCode')+'</postalCode>';
        strxml +=  ' <country>'+params.get('country')+'</country>';
        strxml +=  '  <email>'+params.get('email')+'</email>';
        strxml +=  '</billTo>';

        strxml +=  ' <item id="0">';
        strxml +=  '   <unitPrice>'+authReq.amount +'</unitPrice>';
        /*strxml +=  '   <quantity>'+Integer.valueOf(cartItem.quantity)+'</quantity>'; */
        strxml +=  ' </item>';
        strxml +=  ' <purchaseTotals>';
        /*strxml +=  '   <currency>'+currencyIso+'</currency>';*/
        strxml +=  '   <currency>USD</currency>';
        strxml +=  ' </purchaseTotals>';
        System.debug('strxml ' + JSON.serialize(paymentMethod));
        System.debug('paymentMethod ' +paymentMethod);
        strxml +=  ' <card>';
        strxml +=  '   <accountNumber>'+cardObject.get('cardNumber')+'</accountNumber>';
        strxml +=  '  <expirationMonth>'+cardObject.get('expiryMonth')+'</expirationMonth>';
        strxml +=  '  <expirationYear>'+cardObject.get('expiryYear')+'</expirationYear>';
        strxml +=  '   <cardType>'+changeCardtype((String)cardObject.get('cardType'))+'</cardType>';
        strxml +=  '</card>';
        strxml +=  ' <ccAuthService run="true"/>';
        strxml +=  ' </requestMessage>';
        strxml +=  ' </soapenv:Body>';
        strxml +=  '</soapenv:Envelope>';
        System.debug('strxml ' +strxml);
        return strxml;
    }


    public static String SoapXMLTOAuthorizeByToken(CommercePayments.AuthorizationRequest authReq, string csToken){

        commercepayments.AuthApiPaymentMethodRequest paymentMethod = authReq.paymentMethod;
        commercepayments.AddressRequest address = paymentMethod.address;
        Map<String, String> params = getActiveDefaultAddress(address);

        integer i =0;
        string strxml ='';
        strxml +=  '<?xml version="1.0" encoding="UTF-8"?>';
        strxml +=  '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">';
        strxml +=  '<soapenv:Header>';
        strxml +=  '  <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">';
        strxml +=  '   <wsse:UsernameToken>';
        strxml +=  '     <wsse:Username>{!$Credential.Username}</wsse:Username>';
        strxml +=  '     <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">{!$Credential.Password}</wsse:Password>';
        strxml +=  '   </wsse:UsernameToken>';
        strxml +=  ' </wsse:Security>';
        strxml +=  ' </soapenv:Header>';
        strxml +=  '<soapenv:Body>';
        strxml +=  '  <requestMessage xmlns="urn:schemas-cybersource-com:transaction-data-1.129">';
        strxml +=  '    <merchantID>{!$Credential.Username}</merchantID>';
        strxml +=  '   <merchantReferenceCode>'+ params.get('mRefernceCode') +'</merchantReferenceCode>';
        strxml +=  '  <billTo>';
        strxml +=  '  <firstName>'+params.get('firstName')+'</firstName>';
        strxml +=  '  <lastName>'+params.get('lastName')+'</lastName>';
        strxml +=  ' <street1>'+params.get('street')+'</street1>';
        strxml +=  '  <city>'+params.get('city')+'</city>';
        strxml +=  '  <state>'+params.get('state')+'</state>';
        strxml +=  '  <postalCode>'+params.get('postalCode')+'</postalCode>';
        strxml +=  ' <country>'+params.get('country')+'</country>';
        strxml +=  '  <email>'+params.get('email')+'</email>';
        strxml +=  '</billTo>';
        strxml +=  ' <item id="0">';
        strxml +=  '   <unitPrice>'+authReq.amount +'</unitPrice>';
        strxml +=  ' </item>';
        strxml +=  ' <purchaseTotals>';
        strxml +=  '   <currency>USD</currency>';
        strxml +=  ' <grandTotalAmount>'+authReq.amount+'</grandTotalAmount>';
        strxml +=  ' </purchaseTotals>';
        strxml += '<recurringSubscriptionInfo>';
        strxml += '<subscriptionID>'+csToken+'</subscriptionID>';
        strxml += '</recurringSubscriptionInfo>';
        strxml +=   '<ccAuthService run="true"/>';
        strxml +='</requestMessage>';
        strxml += ' </soapenv:Body>';
        strxml += '</soapenv:Envelope>';
        return strxml;
    }

    //This method is used to parse XML response of Cyber Source
    public static Map<String , String> parseXML(DOM.XMLNode node , Map<String , String> cybsResultMap) {
        if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) {
            if(cybsResultMap.get(node.getName()) == null){
                cybsResultMap.put(node.getName() , node.getText());
            }
        }
        for (Dom.XMLNode child: node.getChildElements()) {
            parseXML(child , cybsResultMap);
        }

        return cybsResultMap;
    }

    public static String changeCardtype(String cardType){
        if(cardType=='Visa'){
            cardType='001';
        }
        else if(cardType=='MasterCard'){
            cardType='002';
        }
        else if(cardType=='AmericanExpress'){
            cardType='003';
        }
        else if(cardType=='Discover'){
            cardType='004';
        }
        else if(cardType=='DinersClub'){
            cardType='005';
        }
        else if(cardType=='JCB'){
            cardType='007';
        }

        return cardType;
    }


    public static string buildCaptureRestRequest(String token,  boolean isJWTToken, CommercePayments.AuthorizationRequest authReq){

        commercepayments.AuthApiPaymentMethodRequest paymentMethod = authReq.paymentMethod;
        commercepayments.AddressRequest address = paymentMethod.address;
        Map<String, String> params = getActiveDefaultAddress(address);

        JSONGenerator jsGen = JSON.createGenerator(true);
        jsGen.writeStartObject();
        jsGen.writeFieldName('clientReferenceInformation');
        jsGen.writeStartObject();
        jsGen.writeStringField('code', 'Commerce Checkout');
        jsGen.writeEndObject();

        if(isJWTToken) {
            jsGen.writeFieldName('processingInformation');
            jsGen.writeStartObject();
            jsGen.writeFieldName('actionList');
            jsGen.writeStartArray();
            jsGen.writeString('TOKEN_CREATE');
            jsGen.writeEndArray();
            jsGen.writeFieldName('actionTokenTypes');
            jsGen.writeStartArray();
            jsGen.writeString('customer');
            jsGen.writeEndArray();
            jsGen.writeEndObject();
        }

        jsGen.writeFieldName('orderInformation');
        jsGen.writeStartObject();
        jsGen.writeFieldName('amountDetails');
        jsGen.writeStartObject();
        jsGen.writeStringField('totalAmount', string.valueOf(authReq.amount));

        //currency has to be dynamic , pick from the quote currency field
        jsGen.writeStringField('currency', 'EUR');
        jsGen.writeEndObject();
        jsGen.writeFieldName('billTo');
        jsGen.writeStartObject();

        //TODO - Update Contact fields to be pulled from request
        if(params.get('firstName') != null){
            jsGen.writeStringField('firstName', params.get('firstName'));
        }
        if(params.get('lastName') != null){
            jsGen.writeStringField('lastName', params.get('lastName'));
        }
        if(params.get('street') != null){
            jsGen.writeStringField('address1', params.get('street'));
        }
        if(params.get('city') != null){
            jsGen.writeStringField('locality',params.get('city'));
        }
        if(params.get('state') != null){
            jsGen.writeStringField('administrativeArea', params.get('state'));
        }
        if(params.get('postalCode') != null){
            jsGen.writeStringField('postalCode', params.get('postalCode'));
        }
        if(params.get('country') != null){
            jsGen.writeStringField('country', params.get('country'));
        }
        if(params.get('email') != null){
            jsGen.writeStringField('email', params.get('email'));
        }
        if(params.get('phoneNumber') != null){
            jsGen.writeStringField('phoneNumber', params.get('phoneNumber'));
        }

        jsGen.writeEndObject();
        jsGen.writeEndObject();

        // No need to add "tokenInformation" for payment using token
        if(isJWTToken){
            jsGen.writeFieldName('tokenInformation');
            jsGen.writeStartObject();
            jsGen.writeStringField('transientTokenJwt', token);
            jsGen.writeEndObject();
        }

        if(!isJWTToken){
            jsGen.writeFieldName('paymentInformation');
            jsGen.writeStartObject();
            jsGen.writeFieldName('legacyToken');
            jsGen.writeStartObject();
            jsGen.writeStringField('id', token);
            jsGen.writeEndObject();
            jsGen.writeEndObject();
        }

        jsGen.writeEndObject();
        return jsGen.getAsString();
     }

    public static void getCYBSConfiguration(string legalEntity, string currencyCode){
        try{
            TNVB2B_LE_Merchant_Mapping__mdt metaConfig = [SELECT Id, TNVB2B_CYBS_Merchant__r.Id, TNVB2B_CYBS_Merchant__r.Key_ID__c, TNVB2B_CYBS_Merchant__r.Private_Key__c, TNVB2B_CYBS_Merchant__r.Microflex_Key_Creation_URL__c,
                                                          TNVB2B_CYBS_Merchant__r.DeveloperName, TNVB2B_CYBS_Merchant__r.Environments_Request_URLs__c, TNVB2B_CYBS_Merchant__r.Payment_API_URL__c, TNVB2B_CYBS_Merchant__r.Transaction_API_URL__c
                                                          FROM TNVB2B_LE_Merchant_Mapping__mdt WHERE Legal_Entity_Name__c =:legalEntity AND Currency__c=:currencyCode];

            if(metaConfig != null){
                HOST = metaConfig.TNVB2B_CYBS_Merchant__r.Environments_Request_URLs__c;
                MERCHANT_ID = metaConfig.TNVB2B_CYBS_Merchant__r.DeveloperName;
                KEY_ID = metaConfig.TNVB2B_CYBS_Merchant__r.Key_ID__c;
                PRIVATE_KEY = metaConfig.TNVB2B_CYBS_Merchant__r.Private_Key__c;
                microURL = metaConfig.TNVB2B_CYBS_Merchant__r.Microflex_Key_Creation_URL__c;
                paymentURL = metaConfig.TNVB2B_CYBS_Merchant__r.Payment_API_URL__c;
                transactionURL = metaConfig.TNVB2B_CYBS_Merchant__r.Transaction_API_URL__c;

            }
        }
        catch(Exception e){
            dcm_Logger.log(LoggingLevel.ERROR, e, 'CYBS Payment', 'getCYBSConfiguration', '', '', '', '','', 'getCYBSConfiguration', 'TNVB2B_CybersourceRESTUtility', 'getCYBSConfiguration');
        }
    }

    //Generates a POST request to the specified endpoint and sets the body
    public static HttpRequest generatePostRequest(String reqTarget, String reqBody) {
        HttpRequest req = generateRequestBase(reqTarget, 'POST');

        //POST requests
        String digestString = generateDigest(reqBody);
        String signatureString = generateSignature('post', reqTarget, digestString);
        req.setHeader('digest', digestString);
        req.setHeader('signature', signatureString);
        req.setBody(reqBody);
        return req;
    }

     //Generates a base HTTP Request with common headers set (basic structure for GET and POST methods)
    private static HttpRequest generateRequestBase(String reqTarget, String reqMethod) {
        HttpRequest req = new HttpRequest();
        req.setMethod(reqMethod);
        req.setEndpoint(reqTarget);
        //req.setEndpoint('https://'+ HOST + reqTarget);
        req.setHeader('Host', HOST);
        req.setHeader('v-c-merchant-id', MERCHANT_ID);
        req.setHeader('Content-Type', 'application/json');
        setDateTimeString();
        System.debug('DATETIME_STRING ' +DATETIME_STRING);
        req.setHeader('Date', DATETIME_STRING);
        return req;
    }

     //Generates a Hash of the request body (Digest header)
    private static String generateDigest(String reqBody) {
        Blob digestHash = Crypto.generateDigest('SHA-256', Blob.valueOf(reqBody));
        String digestString = 'SHA-256=' + EncodingUtil.base64Encode(digestHash);
        return digestString;
    }

    //Method wrapping helper methods to create and return the string that will be set for the Signature header
    private static String generateSignature(String reqType, String reqTarget, String digestString) {
        String signatureHeaders = generateSignatureHeaders(reqType, reqTarget, digestString);
        String signatureHash = generateSignatureHash(signatureHeaders);

        return generateSignatureString(reqType, signatureHash);
    }

    //Generates the (host date (request-target) digest v-c-merchant-id) string
    private static String generateSignatureHeaders(String reqType, String reqTarget, String digestString) {
        String headerFields = '';
        //Add host
        headerFields += ('host: ' + HOST + '\n');

        //Add date (for POST requests only)
        if(reqType == 'post') {
            headerFields += 'date: ' + DATETIME_STRING + '\n';
        }

        //Add (request-target)
        headerFields += ('(request-target): ' + reqType + ' ' + reqTarget + '\n');

        //Add digest (for POST requests only)
        if(reqType == 'post') {
            headerFields += ('digest: ' + digestString + '\n');
        }

        //Add v-c-merchant-id
        headerFields += ('v-c-merchant-id: ' + MERCHANT_ID);

        return headerFields;
    }

    //Sets the DATETIME_STRING to the current time in RCF format
    private static void setDateTimeString() {
        DATETIME_STRING = String.valueOf(DateTime.now().formatGmt('EEE, dd MMM yyyy HH:mm:ss z'));
    }

    //Creates a HmacSHA256 hash of the Signature Header/Value String
    private static String generateSignatureHash(String data) {        
        Blob hash = Crypto.generateMac('HmacSHA256', Blob.valueOf(data), EncodingUtil.base64Decode(PRIVATE_KEY));

        return EncodingUtil.base64Encode(hash);
    }

    //Creates the value to be attached to the Signature on the POST request
    private static String generateSignatureString(String reqType, String signatureHash) {
        String signatureString = '';

        signatureString += 'keyid="' + KEY_ID + '", ';
        signatureString += 'algorithm="HmacSHA256", ';
        signatureString += 'headers="host';

        //Add in 'date' for POST requests (seems to break GET requests)
        if(reqType == 'post') {
            signatureString += ' date';
        }

        signatureString += ' (request-target)';

        //Add in 'digest' for POST requests        
        if(reqType == 'post') {
            signatureString += ' digest';
        }

        signatureString += ' v-c-merchant-id", ';
        signatureString += 'signature="' + signatureHash + '"';

        return signatureString;
    }

}