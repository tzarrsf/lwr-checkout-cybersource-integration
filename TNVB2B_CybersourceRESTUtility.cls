/**
 * @description       :
 * @author            : Tom Zarr by way of a generous partner
 * @group             :
 * @last modified on  : 11-20-2023
 * @last modified by  : Tom Zarr by way of a generous partner
 * Modifications Log
 * Ver   Date         Author                                    Modification
 * 1.0   08-28-2020   Tom Zarr by way of a generous partner     Initial Version
 *
 /* Tom Zarr by way of a generous partner   01-18-2021 */

public class TNVB2B_CybersourceRESTUtility {

    public static String HOST ='HOST';
    public static String MERCHANT_ID='MERCHANT_ID';
    public static String KEY_ID='KEY_ID';
    public static String PRIVATE_KEY='PRIVATE_KEY';
    public static String microURL='microURL';
    public static String paymentURL='Test';
    public static String transactionURL='transactionURL';
    public static String merchantName='merchantName';
    public String DATETIME_STRING1='';

    //Origin of the B2B Storefront
    public static final String ORIGIN = System.Label.TNV_B2B_OrgUrl;

    public static String DATETIME_STRING, DIGEST_STRING;

    //Generates a temporary Key for the Microflex Form
    @auraEnabled
    public static String generateKey(string sObjectName, string recordId) {
        try {
            if(sObjectName.toLowerCase() == 'quote'){
                SBQQ__Quote__c quote = [SELECT Id, CurrencyIsoCode, TNV_SFB_Legal_Entity__r.TNV_LE_Code__c FROM SBQQ__Quote__c WHERE Id=:recordId];
                getCYBSConfiguration(quote.TNV_SFB_Legal_Entity__r.TNV_LE_Code__c, quote.CurrencyIsoCode);
            }
            if(sObjectName.toLowerCase() == 'order'){
                Order order = [SELECT Id, CurrencyIsoCode, TNV_Legal_Entity__r.TNV_LE_Code__c FROM Order WHERE Id=:recordId];
                getCYBSConfiguration(order.TNV_Legal_Entity__r.TNV_LE_Code__c, order.CurrencyIsoCode);
            }
            if(sObjectName.toLowerCase() == 'invoice'){
                blng__Invoice__c invoice = [SELECT Id, CurrencyIsoCode, TNV_Legal_Entity__r.TNV_LE_Code__c FROM blng__Invoice__c WHERE Id=:recordId];
                getCYBSConfiguration(invoice.TNV_Legal_Entity__r.TNV_LE_Code__c, invoice.CurrencyIsoCode);
            }
            if(sObjectName.toLowerCase() == 'contract'){
                Contract contract = [SELECT Id, CurrencyIsoCode, TNV_SFB_Legal_Entity__r.TNV_LE_Code__c FROM Contract WHERE Id=:recordId];
                getCYBSConfiguration(contract.TNV_SFB_Legal_Entity__r.TNV_LE_Code__c, contract.CurrencyIsoCode);
            }

            //String reqTarget = '/flex/v1/keys?format=JWT';
            String reqBody = '{"encryptionType":"RsaOaep256", "targetOrigin":"' + ORIGIN + '"}';
            HttpRequest req = generatePostRequest(microURL, reqBody);

            Http http = new Http();
            string respBody;
            if(!Test.isRunningTest()){
                HttpResponse res = http.send(req);
                respBody = res.getBody();
            }
            else{
                respBody ='{"keyId":"00000400"}';
            }

            //return res.getBody();
            return respBody;
        } catch(Exception e) {
            System.debug( e );
            return e.getMessage();
        }
    }

    //Generates the POST /payments request for Cybersource
    public static HttpResponse buildPaymentRequest(String token, String recordId, string sObjectName, boolean isJWTToken) {

        if(sObjectName.toLowerCase() == 'quote'){
            SBQQ__Quote__c quote = [SELECT Id, CurrencyIsoCode, TNV_SFB_Legal_Entity__r.TNV_LE_Code__c FROM SBQQ__Quote__c WHERE Id=:recordId];
            getCYBSConfiguration(quote.TNV_SFB_Legal_Entity__r.TNV_LE_Code__c, quote.CurrencyIsoCode);
        }
        if(sObjectName.toLowerCase() == 'order'){
            Order order = [SELECT Id, CurrencyIsoCode, TNV_Legal_Entity__r.TNV_LE_Code__c FROM Order WHERE Id=:recordId];
            getCYBSConfiguration(order.TNV_Legal_Entity__r.TNV_LE_Code__c, order.CurrencyIsoCode);
        }
        if(sObjectName.toLowerCase() == 'invoice'){
            blng__Invoice__c invoice = [SELECT Id, CurrencyIsoCode, TNV_Legal_Entity__r.TNV_LE_Code__c FROM blng__Invoice__c WHERE Id=:recordId];
            getCYBSConfiguration(invoice.TNV_Legal_Entity__r.TNV_LE_Code__c, invoice.CurrencyIsoCode);  
        }
        if(sObjectName.toLowerCase() == 'contract'){
            Contract contract = [SELECT Id, CurrencyIsoCode, TNV_SFB_Legal_Entity__r.TNV_LE_Code__c FROM Contract WHERE Id=:recordId];
            getCYBSConfiguration(contract.TNV_SFB_Legal_Entity__r.TNV_LE_Code__c, contract.CurrencyIsoCode);
        }

        //String reqTarget = '/pts/v2/payments';
        HttpResponse res ;

        String reqBody = buildCaptureRestRequest(token, recordId, sObjectName, isJWTToken);

        System.debug('reqBody ' + reqBody);


        try{

        HttpRequest req = generatePostRequest(paymentURL, reqBody);

        Http http = new Http();

             if(!Test.isRunningTest()){
                 res = http.send(req);
             }
        }
        catch(Exception ex){
            System.debug('resMap ex' +ex);
        }
        return res;
    }

    //Generates the GET /payments request for Cybersource

    public static String getTransactionDetails(String paymentId) {
        String reqTarget = transactionURL + paymentId;
        HttpResponse res ;


        try{
            if(!Test.isRunningTest()){
                HttpRequest req = generateGetRequest(reqTarget);
                Http http = new Http();
                res = http.send(req);
                return res.getBody();
            }
            else{
                return '{ "clientReferenceInformation":{"code":"00000400"}, "id":"6213810968596822804006", "merchantId":"test", "orderInformation":{"amountDetails":{"authorizedAmount":"530.00", "currency":"EUR"}}, "paymentInformation":{"customer":{"customerId":"9909000331850373"},"card":{"suffix":"1111","prefix":"411111","expirationMonth":"03","expirationYear":"24","type":"001"}},"processorInformation":{"approvalCode":"831000","responseCode":"00"}}';       
            }
        }
        catch(Exception ex){
            System.debug('resMap ex' +ex);
        }
        return null;
    }

    // --- HTTP Request Helper Methods ---
    //
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

    private static HttpRequest generateGetRequest(String reqTarget) {
        HttpRequest req = generateRequestBase(reqTarget, 'GET');

        //GET requests
        String signatureString = generateSignature('get', reqTarget, '');

        req.setHeader('signature', signatureString);

        return req;
    }

    //Generates a base HTTP Request with common headers set (basic structure for GET and POST methods)
    private static HttpRequest generateRequestBase(String reqTarget, String reqMethod) {
        HttpRequest req = new HttpRequest();
        req.setMethod(reqMethod);
        req.setEndpoint('https://'+ HOST + reqTarget);
        req.setHeader('Host', HOST);
        req.setHeader('v-c-merchant-id', MERCHANT_ID);
        req.setHeader('Content-Type', 'application/json');

        setDateTimeString();
        System.debug('DATETIME_STRING ' +DATETIME_STRING);
        req.setHeader('Date', DATETIME_STRING);

        return req;
    }

    //Sets the DATETIME_STRING to the current time in RCF format
    private static void setDateTimeString() {
        DATETIME_STRING = String.valueOf(DateTime.now().formatGmt('EEE, dd MMM yyyy HH:mm:ss z'));
    }

    //Generates a Hash of the request body (Digest header)
    private static String generateDigest(String reqBody) {
        Blob digestHash = Crypto.generateDigest('SHA-256', Blob.valueOf(reqBody)); 
        String digestString = 'SHA-256=' + EncodingUtil.base64Encode(digestHash);

        return digestString;
    }
    //
    // --- HTTP Request Helper Methods ---

    // --- Signature Helper Methods ---
    //
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

    public static string buildCaptureRestRequest(String token, string recordId, string sObjectName, boolean isJWTToken){

        requestParams rp = new requestParams();

        if(sObjectName == 'Quote'){
            SBQQ__Quote__c currentQuote = [SELECT Id, Name, TNV_Billing_Contact__r.FirstName,TNV_Billing_Contact__r.LastName, TNV_Billing_Contact__r.Email, TNV_Billing_Contact__r.Phone, CurrencyIsoCode, TNV_First_Billing_Gross_Amount__c, 
                                TNV_Billing_Address__r.TNV_City__c, TNV_Billing_Address__r.TNV_State_Picklist__c, TNV_Billing_Address__r.TNV_Street_Address_1__c, TNV_Billing_Address__r.TNV_Country_BC_Pick__c, TNV_Billing_Address__r.TNV_Postal_Code__c from  SBQQ__Quote__c WHERE Id=:recordId];

            rp.firstName = currentQuote.TNV_Billing_Contact__r.FirstName;
            rp.lastName = currentQuote.TNV_Billing_Contact__r.LastName;
            rp.address1 = currentQuote.TNV_Billing_Address__r.TNV_Street_Address_1__c;
            rp.locality = currentQuote.TNV_Billing_Address__r.TNV_City__c;
            rp.administrativeArea = currentQuote.TNV_Billing_Address__r.TNV_State_Picklist__c;
            rp.postalCode = currentQuote.TNV_Billing_Address__r.TNV_Postal_Code__c;
            rp.country = currentQuote.TNV_Billing_Address__r.TNV_Country_BC_Pick__c;
            rp.email = currentQuote.TNV_Billing_Contact__r.Email;
            rp.phoneNumber = currentQuote.TNV_Billing_Contact__r.Phone;
            rp.totalAmount = string.valueOf(currentQuote.TNV_First_Billing_Gross_Amount__c);
            rp.userCurrency = currentQuote.CurrencyIsoCode;
            rp.recordName = currentQuote.Name;
        }

        if(sObjectName == 'Invoice'){
           blng__Invoice__c currentInvoice =  [SELECT Id, CurrencyIsoCode, Name, blng__Account__r.BillingCity, TNV_Billing_Contact__r.FirstName, blng__TotalAmount__c,
                                               TNV_Billing_Contact__r.LastName, TNV_Billing_Contact__r.Email, blng__Account__r.BillingStreet, TNV_Billing_Contact__r.Phone,
                                               TNV_Billing_Address__r.TNV_City__c, TNV_Billing_Address__r.TNV_State_Picklist__c, TNV_Billing_Address__r.TNV_Street_Address_1__c, TNV_Billing_Address__r.TNV_Country_BC_Pick__c, TNV_Billing_Address__r.TNV_Postal_Code__c,
                                               blng__Account__r.BillingState, blng__Account__r.BillingPostalCode, blng__Account__r.BillingCountry FROM blng__Invoice__c WHERE Id=:recordId LIMIT 1];

            rp.firstName = currentInvoice.TNV_Billing_Contact__r.FirstName;
            rp.lastName = currentInvoice.TNV_Billing_Contact__r.LastName;
            rp.address1 = currentInvoice.TNV_Billing_Address__r.TNV_Street_Address_1__c;
            rp.locality = currentInvoice.TNV_Billing_Address__r.TNV_City__c;
            rp.administrativeArea = currentInvoice.TNV_Billing_Address__r.TNV_State_Picklist__c;
            rp.postalCode = currentInvoice.TNV_Billing_Address__r.TNV_Postal_Code__c;
            rp.country = currentInvoice.TNV_Billing_Address__r.TNV_Country_BC_Pick__c;
            rp.email = currentInvoice.TNV_Billing_Contact__r.Email;
            rp.phoneNumber = currentInvoice.TNV_Billing_Contact__r.Phone;
            rp.totalAmount = string.valueOf(currentInvoice.blng__TotalAmount__c);
            rp.userCurrency = currentInvoice.CurrencyIsoCode;
            rp.recordName = currentInvoice.Name;
        }

        if(sObjectName == 'Order'){
            Order currentOrder = [SELECT Id, Name,TNV_Billing_Contact__r.FirstName,TNV_Billing_Contact__r.LastName, TNV_Billing_Contact__r.Email, TNV_Billing_Contact__r.Phone, OrderNumber, CurrencyIsoCode, TNV_First_Billing_Gross_Amount__c, 
                                TNV_Billing_Address__r.TNV_City__c, TNV_Billing_Address__r.TNV_State_Picklist__c, TNV_Billing_Address__r.TNV_Street_Address_1__c, TNV_Billing_Address__r.TNV_Country_BC_Pick__c, TNV_Billing_Address__r.TNV_Postal_Code__c FROM Order WHERE Id=:recordId LIMIT 1];

            rp.firstName = currentOrder.TNV_Billing_Contact__r.FirstName;
            rp.lastName = currentOrder.TNV_Billing_Contact__r.LastName;
            rp.address1 = currentOrder.TNV_Billing_Address__r.TNV_Street_Address_1__c;
            rp.locality = currentOrder.TNV_Billing_Address__r.TNV_City__c;
            rp.administrativeArea = currentOrder.TNV_Billing_Address__r.TNV_State_Picklist__c;
            rp.postalCode = currentOrder.TNV_Billing_Address__r.TNV_Postal_Code__c;
            rp.country = currentOrder.TNV_Billing_Address__r.TNV_Country_BC_Pick__c;
            rp.email = currentOrder.TNV_Billing_Contact__r.Email;
            rp.phoneNumber = currentOrder.TNV_Billing_Contact__r.Phone;
            rp.totalAmount = string.valueOf(currentOrder.TNV_First_Billing_Gross_Amount__c);
            rp.userCurrency = currentOrder.CurrencyIsoCode;
            rp.recordName = currentOrder.OrderNumber;

        }

        if(sObjectName == 'Contract'){
            Contract contract = [SELECT Id,TNV_Billing_Contact__r.FirstName, TNV_Billing_Contact__r.LastName, TNV_Billing_Contact__r.Email, TNV_Billing_Contact__r.Phone, ContractNumber, BillingStreet, CurrencyIsoCode,
                                 TNV_Billing_Address__r.TNV_City__c, TNV_Billing_Address__r.TNV_State_Picklist__c, TNV_Billing_Address__r.TNV_Street_Address_1__c, TNV_Billing_Address__r.TNV_Country_BC_Pick__c, TNV_Billing_Address__r.TNV_Postal_Code__c
                                 FROM Contract WHERE Id=:recordId];
            rp.firstName = contract.TNV_Billing_Contact__r.FirstName;
            rp.lastName = contract.TNV_Billing_Contact__r.LastName;
            rp.address1 = contract.TNV_Billing_Address__r.TNV_Street_Address_1__c;
            rp.locality = contract.TNV_Billing_Address__r.TNV_City__c;
            rp.administrativeArea = contract.TNV_Billing_Address__r.TNV_State_Picklist__c;
            rp.postalCode = contract.TNV_Billing_Address__r.TNV_Postal_Code__c;
            rp.country = contract.TNV_Billing_Address__r.TNV_Country_BC_Pick__c;
            rp.email = contract.TNV_Billing_Contact__r.Email;
            rp.phoneNumber = contract.TNV_Billing_Contact__r.Phone;
            rp.totalAmount = '0';
            rp.userCurrency = contract.CurrencyIsoCode;
            rp.recordName = contract.ContractNumber;
        }

        JSONGenerator jsGen = JSON.createGenerator(true);
        jsGen.writeStartObject();
        jsGen.writeFieldName('clientReferenceInformation');
        jsGen.writeStartObject();
        jsGen.writeStringField('code', rp.recordName);
        jsGen.writeEndObject();

        if(isJWTToken){
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
        //jsGen.writeStringField('totalAmount', '1500');
        if(rp.totalAmount != null){
            jsGen.writeStringField('totalAmount', rp.totalAmount);
        }

        //currency has to be dynamic , pick from the quote currency field
        if(rp.userCurrency != null){
            jsGen.writeStringField('currency', rp.userCurrency);
        }
        jsGen.writeEndObject();

        jsGen.writeFieldName('billTo');
        jsGen.writeStartObject();

        //TODO - Update Contact fields to be pulled from request
        if(rp.firstName != null){
            jsGen.writeStringField('firstName', rp.firstName);
        }
        if(rp.lastName != null){
            jsGen.writeStringField('lastName', rp.lastName);
        }
        if(rp.address1 != null){
            jsGen.writeStringField('address1', rp.address1);
        }
        if(rp.locality != null){
            jsGen.writeStringField('locality', rp.locality);
        }
        if(rp.administrativeArea != null){
            jsGen.writeStringField('administrativeArea', rp.administrativeArea);
        }
        if(rp.postalCode != null){
            jsGen.writeStringField('postalCode', rp.postalCode);
        }
        if(rp.country != null){
            jsGen.writeStringField('country', rp.country);
        }
        if(rp.email != null){
            jsGen.writeStringField('email', rp.email);
        }
        if(rp.phoneNumber != null){
            jsGen.writeStringField('phoneNumber', rp.phoneNumber);
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

    //
    // --- End of Signature Helper Methods ---

    public static void getCYBSConfiguration(string leCode, string currencyCode){
        try{
            TNVB2B_LE_Merchant_Mapping__mdt metaConfig = [SELECT Id, TNVB2B_CYBS_Merchant__r.Id, TNVB2B_CYBS_Merchant__r.Key_ID__c, TNVB2B_CYBS_Merchant__r.Private_Key__c, TNVB2B_CYBS_Merchant__r.Microflex_Key_Creation_URL__c,
                                                          TNVB2B_CYBS_Merchant__r.DeveloperName, TNVB2B_CYBS_Merchant__r.Environments_Request_URLs__c, TNVB2B_CYBS_Merchant__r.Payment_API_URL__c, TNVB2B_CYBS_Merchant__r.Transaction_API_URL__c
                                                          FROM TNVB2B_LE_Merchant_Mapping__mdt WHERE TNV_LE_Code__c =:leCode AND Currency__c=:currencyCode];
            if(metaConfig != null){
                HOST = metaConfig.TNVB2B_CYBS_Merchant__r.Environments_Request_URLs__c;
                MERCHANT_ID = metaConfig.TNVB2B_CYBS_Merchant__r.DeveloperName;
                KEY_ID = metaConfig.TNVB2B_CYBS_Merchant__r.Key_ID__c;
                PRIVATE_KEY = metaConfig.TNVB2B_CYBS_Merchant__r.Private_Key__c;
                microURL = metaConfig.TNVB2B_CYBS_Merchant__r.Microflex_Key_Creation_URL__c;
                paymentURL = metaConfig.TNVB2B_CYBS_Merchant__r.Payment_API_URL__c;
                transactionURL = metaConfig.TNVB2B_CYBS_Merchant__r.Transaction_API_URL__c;
                merchantName = metaConfig.TNVB2B_CYBS_Merchant__r.DeveloperName;
                System.debug('_______merchantName________'+merchantName);
            }
        }
        catch(Exception e){
            dcm_Logger.log(LoggingLevel.ERROR, e, 'CYBS Payment', 'getCYBSConfiguration', '', '', '', '','', 'getCYBSConfiguration', 'TNVB2B_CybersourceRESTUtility', 'getCYBSConfiguration');
        }
    }

    public class requestParams{
        public string firstName;
        public string lastName;
        public string address1;
        public string locality;
        public string administrativeArea;
        public string postalCode;
        public string country;
        public string email;
        public string phoneNumber;
        public string totalAmount;
        public string userCurrency;
        public string recordName;
    }
}