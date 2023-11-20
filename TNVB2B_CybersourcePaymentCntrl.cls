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

public without sharing class TNVB2B_CybersourcePaymentCntrl {


    @AuraEnabled
    public static Map<String, Object> getComponentSetup(String sObjectName, String recordId) {
        Map<String, Object> returnData = new Map<String, Object>();

        Map<String, Object> resMap = (Map<String, Object>)JSON.deserializeUntyped(TNVB2B_CybersourceRESTUtility.generateKey(sObjectName, recordId));
        System.debug('resMap ____ ' +resMap);

        try {
            returnData.put('keyId', String.valueOf(resMap.get('keyId')));
            returnData.put('jwk', String.valueOf(resMap));
        } catch(Exception e) {
            System.debug(e.getMessage());
            returnData.put('error', e.getMessage());
        }
        return returnData;
    }

    @AuraEnabled
    public static boolean isPaymentAuthorizationCheck(String sObjectName, String recordId){
        if(sObjectName.toLowerCase() =='quote'){
            String paymentStatus = [SELECT Id, TNV_Payment_Authorization_Status__c FROM SBQQ__Quote__c WHERE Id=:recordId].TNV_Payment_Authorization_Status__c;
            if(paymentStatus == 'Processed'){
                return false;
            }
        }
        if(sObjectName.toLowerCase() =='invoice'){
            String paymentStatus = [SELECT Id, TNV_Payment_Authorization_Status__c FROM blng__Invoice__c WHERE Id=:recordId].TNV_Payment_Authorization_Status__c;
            if(paymentStatus == 'Processed'){
                return false;
            }
        }
        if(sObjectName.toLowerCase() =='order'){
            String paymentStatus = [SELECT Id, TNV_Payment_Authorization_Status__c FROM Order WHERE Id=:recordId].TNV_Payment_Authorization_Status__c;
            if(paymentStatus == 'Processed'){
                return false;
            }
        }
        if(sObjectName.toLowerCase() =='contract'){
            String paymentStatus = [SELECT Id, TNV_Payment_Authorization_Status__c FROM Contract WHERE Id=:recordId].TNV_Payment_Authorization_Status__c;
            if(paymentStatus == 'Processed'){
                return false;
            }
        }
        return true;
    }

    @AuraEnabled
    public static String handlePostPayment(String token, String recordId, String orderId, String addressId,
    String expirationMonth, String expirationYear, String cardholderName,String cardholderNickName,String cardType, String sObjectName) {

         try{
            HttpResponse res = TNVB2B_CybersourceRESTUtility.buildPaymentRequest(token, recordId, sObjectName, true);
            String respBody;
            if(!Test.isRunningTest()){
               respBody = res.getBody();
               System.debug('______first payment Response______'+respBody);
            }
            else{
                respBody = '{"id":"6213810968596822804006","status": "AUTHORIZED"}';
            }
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(respBody);

            string respToken = (string)results.get('id');
            String respStatus = (string)results.get('status');
            if(respStatus != 'AUTHORIZED'){
                String paId = CreatePaymentAuthforFailedTransaction(results,sObjectName,recordId);
                return paId;
            }
            getTransactionDetails(respToken,recordId,cardholderName,cardholderNickName,cardType,sObjectName);
            return respBody;

        }
        catch(Exception e) {
            dcm_Logger.log(LoggingLevel.ERROR, e, 'CYBS Payment', 'handlePostPayment', '', '', '', '','', 'handlePostPayment', 'TNVB2B_CybersourcePaymentCntrl', 'handlePostPayment');
            return e.getMessage()+'__Error__';
        }
    }

    public static void getTransactionDetails(String paymentId,string recordId,
    string cardholderName,string cardholderNickName,String cardType, String sObjectName) {

        Datetime sysTime = System.now().addSeconds( 5 );
        String chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        TNVB2B_CybersourceScheduler obj = new TNVB2B_CybersourceScheduler();
        obj.paymentId = paymentId;
        obj.recordId = recordId;
        obj.cardholderName = cardholderName;
        obj.cardholderNickName = cardholderNickName;
        obj.cardType = cardType;
        obj.sObjectName = sObjectName;

        System.schedule( 'TNVB2B_CybersourceScheduler ' + sysTime, chronExpression,obj);
    }

     //this method is for getting list stored wallet of current user
    @AuraEnabled
    public static List<blng__PaymentMethod__c> getStoredWallet(String recordId, String sObjectName) {

        List<blng__PaymentMethod__c> myStoredWallet;

        if(sObjectName.toLowerCase()  =='quote'){
            String contactId = [SELECT Id, TNV_Billing_Contact__c from  SBQQ__Quote__c WHERE Id=:recordId].TNV_Billing_Contact__c;
                if(contactId != null){
                     myStoredWallet = new List<blng__PaymentMethod__c>([SELECT Id, blng__CardType__c,blng__CardNumber__c,Contact__c,blng__CardExpirationYear__c,
                                                                    Contact__r.Name,blng__CardExpirationMonth__c,blng__NickName__c,blng__Nameoncard__c FROM 
                                                                    blng__PaymentMethod__c WHERE Contact__c=:contactId AND blng__Active__c=true order by CreatedDate desc]);
                }
        }
        if(sObjectName.toLowerCase()  =='invoice'){
            String contactId = [SELECT Id, TNV_Billing_Contact__c FROM blng__Invoice__c WHERE Id=:recordId].TNV_Billing_Contact__c;
                if(contactId != null){
                     myStoredWallet = new List<blng__PaymentMethod__c>([SELECT Id, blng__CardType__c,blng__CardNumber__c,Contact__c,blng__CardExpirationYear__c,
                                                                Contact__r.Name,blng__CardExpirationMonth__c,blng__NickName__c,blng__Nameoncard__c FROM 
                                                                blng__PaymentMethod__c WHERE Contact__c=:contactId AND blng__Active__c=true order by CreatedDate desc]);
                }
           }

        //currently contact id is hard coded
        if(sObjectName.toLowerCase()  =='order'){
            String contactId = [SELECT Id, TNV_Billing_Contact__c FROM Order WHERE Id=:recordId].TNV_Billing_Contact__c;
            if(contactId != null){
                myStoredWallet = new List<blng__PaymentMethod__c>([SELECT Id, blng__CardType__c,blng__CardNumber__c,Contact__c,blng__CardExpirationYear__c,
                                                                Contact__r.Name,blng__CardExpirationMonth__c,blng__NickName__c,blng__Nameoncard__c FROM 
                                                                blng__PaymentMethod__c WHERE Contact__c=:contactId AND blng__Active__c=true order by CreatedDate desc]);
            }
        }
        //currently contact id is hard coded
        if(sObjectName.toLowerCase()  =='contract'){
            String contactId = [SELECT Id, TNV_Billing_Contact__c FROM Contract WHERE Id=:recordId].TNV_Billing_Contact__c;
            if(contactId != null){
                myStoredWallet = new List<blng__PaymentMethod__c>([SELECT Id, blng__CardType__c,blng__CardNumber__c,Contact__c,blng__CardExpirationYear__c,
                                                                Contact__r.Name,blng__CardExpirationMonth__c,blng__NickName__c,blng__Nameoncard__c FROM 
                                                                blng__PaymentMethod__c WHERE Contact__c=:contactId AND blng__Active__c=true order by CreatedDate desc]);
            }
        }

        return myStoredWallet;
    }

    @AuraEnabled
    public static string checkoutUsingStoredPayment(String storedPaymentId, String recordId, String sObjectName) {
        string accountId;

        String token = [SELECT Id, blng__PaymentGatewayToken__c FROM blng__PaymentMethod__c WHERE Id=:storedPaymentId].blng__PaymentGatewayToken__c;
        System.debug('_____token_____'+token);
        HttpResponse res = TNVB2B_CybersourceRESTUtility.buildPaymentRequest(token, recordId, sObjectName, false);
        String respBody;
        System.debug('_____respBody_____'+res);
        if(!Test.isRunningTest()){
           respBody = res.getBody();
        }
        else{
            respBody = '{ "clientReferenceInformation":{"code":"00000400"}, "id":"6213810968596822804006", "merchantId":"test", "orderInformation":{"amountDetails":{"authorizedAmount":"530.00", "currency":"EUR"}}, "paymentInformation":{"customer":{"customerId":"9909000331850373"},"card":{"suffix":"1111","prefix":"411111","expirationMonth":"03","expirationYear":"24","type":"001"}},"processorInformation":{"approvalCode":"831000","responseCode":"00"}}';       
        }
        //System.debug('_____respBody_____'+res.getBody());
        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(respBody);
        Map<String,Object> orderInformation = (Map<String,Object>)results.get('orderInformation');
        Map<String,Object> amountDetails = (Map<String,Object>)orderInformation.get('amountDetails');
        Map<String,Object> processorInformation = (Map<String,Object>)results.get('processorInformation');  

        PaymentAuthorization pa = new PaymentAuthorization();
        Decimal amount = decimal.valueOf((string)amountDetails.get('authorizedAmount'));
        string currencyCode;
        pa.Amount = amount;

        if(sObjectName.toLowerCase() =='quote'){
            SBQQ__Quote__c quote = [SELECT Id, currencyISOCode, SBQQ__Account__c FROM  SBQQ__Quote__c WHERE Id=:recordId];
            currencyCode = quote.currencyISOCode;
            accountId = quote.SBQQ__Account__c;
            pa.Quote__c = recordId;
        }
        if(sObjectName.toLowerCase() =='invoice'){
            blng__Invoice__c invoice = [SELECT Id, blng__Account__c,currencyISOCode FROM blng__Invoice__c WHERE Id=:recordId];
            currencyCode = invoice.currencyISOCode;
            accountId = invoice.blng__Account__c;
            pa.Invoice__c = recordId;
        }
        if(sObjectName.toLowerCase() =='order'){
            Order o = [SELECT Id, AccountId, CurrencyISOCode FROM Order WHERE Id=:recordId];
            currencyCode = o.currencyISOCode;
            accountId = o.AccountId;
            pa.Order__c = recordId;
        }
        if(sObjectName.toLowerCase() =='contract'){
            Contract cont = [SELECT Id, AccountId, CurrencyISOCode FROM Contract WHERE Id=:recordId];
            currencyCode = cont.currencyISOCode;
            accountId = cont.AccountId;
            pa.Contract__c = recordId;
        }

        //pa.Quote__c = recordId;
        pa.Payment_Method__c = storedPaymentId;
        pa.currencyISOCode = currencyCode;
        pa.status = 'Processed';
        pa.processingmode='External';
        pa.GatewayRefNumber = (string)results.get('id');
        pa.GatewayResultCode = (string)processorInformation.get('approvalCode');
        pa.Response_Code__c = (string)processorInformation.get('responseCode');
        //pa.Merchant_Name__c = (string)results.get('merchantId');
        pa.Merchant_Name__c = TNVB2B_CybersourceRESTUtility.merchantName;
        System.debug('_______merchantName________'+TNVB2B_CybersourceRESTUtility.merchantName);
        pa.AccountId = accountId;
        insert pa;

        if(sObjectName.toLowerCase() =='quote'){
            SBQQ__Quote__c quote = new SBQQ__Quote__c(Id=recordId);
            quote.TNV_Payment_Authorization_SFID__c = pa.Id;
            quote.TNV_Payment_Authorization_Status__c ='Processed';
            quote.TNV_Payment_Method__c = storedPaymentId;
            quote.TNV_CC_Auth_Approval_Timestamp__c = System.now();
            quote.TNV_CC_Auth_Status__c = 'Approved';
            update quote;
        }
        if(sObjectName.toLowerCase() =='invoice'){
             blng__Invoice__c invoice = [SELECT Id, blng__Order__c FROM blng__Invoice__c WHERE Id=:recordId];
                if(invoice.blng__Order__c != null){
                    order o = new order(Id=invoice.blng__Order__c);
                    o.TNV_Payment_Authorization_SFID__c = pa.Id;
                    o.TNV_Payment_Authorization_Status__c ='Processed';
                    o.TNV_Payment_Method__c = storedPaymentId;
                    update o;
                    pa.Order__c = invoice.blng__Order__c;
                    List<contract> contList = new List<Contract>([SELECT Id, SBQQ__Order__c FROM Contract WHERE SBQQ__Order__c=:o.Id]);
                    if(!contList.isEmpty()){
                        contract cont = contList[0];
                        cont.TNV_Payment_Authorization_SFID__c = pa.Id;
                        cont.TNV_Payment_Authorization_Status__c ='Processed';
                        cont.TNV_Payment_Method__c = storedPaymentId;
                        update cont;
                        pa.contract__c = cont.Id;
                    }
                }

                invoice.TNV_Payment_Authorization_SFID__c = pa.Id;
                invoice.TNV_Payment_Authorization_Status__c ='Processed';
                invoice.TNV_Payment_Method__c = storedPaymentId;
                update invoice;
                update pa;
        }
        if(sObjectName.toLowerCase() =='order'){
            Order o = new Order(Id=recordId);
            o.TNV_Payment_Authorization_SFID__c = pa.Id;
            o.TNV_Payment_Authorization_Status__c ='Processed';
            o.TNV_Payment_Method__c = storedPaymentId;
            update o;
        }
        if(sObjectName.toLowerCase() =='contract'){
            Contract contract = new Contract(Id=recordId);
            contract.TNV_Payment_Authorization_SFID__c = pa.Id;
            contract.TNV_Payment_Authorization_Status__c ='Processed';
            contract.TNV_Payment_Method__c = storedPaymentId;
            update contract;
        }

        return pa.Id;
    }

    @future(callout=true)
    public static void doInvoicePayment(string storedPaymentId, string recordId, string sObjectName){
        String paId = checkoutUsingStoredPayment(storedPaymentId, recordId, sObjectName);
    }

    @InvocableMethod
    public static void ProcessInvoices(List<Id> invoiceId)
    {
        System.debug('__________invoiceId__________'+invoiceId);
        try{
            String recordId = invoiceId[0];
            String storedPaymentId = [SELECT Id, TNV_Payment_Method__c FROM blng__Invoice__c WHERE Id=:recordId].TNV_Payment_Method__c;
            String sObjectName = 'Invoice';
            doInvoicePayment(storedPaymentId, recordId, sObjectName);
        }
        catch(Exception e){
            dcm_Logger.log(LoggingLevel.ERROR, e, 'CYBS Payment', 'handlePostPayment', '', '', '', '','', 'handlePostPayment', 'TNVB2B_CybersourcePaymentCntrl', 'handlePostPayment');
        }
    }

    public static string CreatePaymentAuthforFailedTransaction(Map<String,Object> cybsResponse, string sObjectName, string recordId){
        PaymentAuthorization pa = new PaymentAuthorization();

        try{
        String accountId, currencyCode;
        decimal amount;
        if(sObjectName.toLowerCase() =='quote'){
            SBQQ__Quote__c quote = [SELECT CurrencyISOCode, SBQQ__Account__c, TNV_First_Billing_Gross_Amount__c FROM SBQQ__Quote__c WHERE Id=:recordId];
            accountId = quote.SBQQ__Account__c;
            currencyCode = quote.CurrencyISOCode;
            amount = quote.TNV_First_Billing_Gross_Amount__c;
            pa.Quote__c = recordId;
        }
        if(sObjectName.toLowerCase() =='invoice'){
            blng__Invoice__c invoice = [SELECT CurrencyISOCode, blng__Account__c, blng__TotalAmount__c FROM blng__Invoice__c WHERE Id=:recordId];
            accountId = invoice.blng__Account__c;
            currencyCode = invoice.CurrencyISOCode;
            amount = invoice.blng__TotalAmount__c;
            pa.Invoice__c = recordId;
        }
        if(sObjectName.toLowerCase() =='order'){
            Order order = [SELECT AccountId,CurrencyISOCode, TNV_First_Billing_Gross_Amount__c FROM Order WHERE Id=:recordId];
            accountId = order.AccountId;
            currencyCode = order.CurrencyISOCode;
            amount = order.TNV_First_Billing_Gross_Amount__c;
            pa.Order__c = recordId;
        }
        if(sObjectName.toLowerCase() =='contract'){
            Contract contract = [SELECT AccountId, CurrencyISOCode FROM Contract WHERE Id=:recordId];
            accountId = contract.AccountId;
            amount = 1.00;
            currencyCode = contract.CurrencyISOCode;
            pa.Contract__c = recordId;
        }

        List<Object> errorDetail = (List<Object>)cybsResponse.get('details');
        Map<string, object> errorDetails = (Map<string, object>)errorDetail[0];
        pa.status = 'Failed';
        pa.CurrencyISOCode = currencyCode;
        pa.processingmode='External';
        pa.GatewayRefNumber = (string)cybsResponse.get('id');
        pa.GatewayResultCodeDescription = (string)cybsResponse.get('message');
        pa.GatewayRefDetails  = (string)errorDetails.get('field');
        pa.GatewayResultCode = (string)cybsResponse.get('status');
        pa.Response_Code__c = (string)cybsResponse.get('reason');
        pa.AccountId = accountId;
        pa.Amount = amount;
        pa.Merchant_Name__c = TNVB2B_CybersourceRESTUtility.merchantName;
        System.debug('_______merchantName________'+TNVB2B_CybersourceRESTUtility.merchantName);
        insert pa;

         if(sObjectName.toLowerCase() =='quote'){
            SBQQ__Quote__c quote = new SBQQ__Quote__c(Id=recordId);
            quote.TNV_Payment_Authorization_SFID__c = pa.Id;
            quote.TNV_Payment_Authorization_Status__c ='Failed';
            update quote;
        }
        if(sObjectName.toLowerCase() =='invoice'){
            blng__Invoice__c invoice = [SELECT Id, blng__Order__c FROM blng__Invoice__c WHERE Id=:recordId];
                if(invoice.blng__Order__c != null){
                    order o = new order(Id=invoice.blng__Order__c);
                    o.TNV_Payment_Authorization_SFID__c = pa.Id;
                    o.TNV_Payment_Authorization_Status__c ='Failed';
                    update o;
                    pa.Order__c = invoice.blng__Order__c;
                    List<contract> contList = new List<Contract>([SELECT Id, SBQQ__Order__c FROM Contract WHERE SBQQ__Order__c=:o.Id]);
                    if(!contList.isEmpty()){
                        contract cont = contList[0];
                        cont.TNV_Payment_Authorization_SFID__c = pa.Id;
                        cont.TNV_Payment_Authorization_Status__c ='Failed';
                        update cont;
                        pa.contract__c = cont.Id;
                    }
                }

                invoice.TNV_Payment_Authorization_SFID__c = pa.Id;
                invoice.TNV_Payment_Authorization_Status__c ='Failed';
                update invoice;
                update pa;
        }
        if(sObjectName.toLowerCase() =='order'){
            Order o = new Order(Id=recordId);
            o.TNV_Payment_Authorization_SFID__c = pa.Id;
            o.TNV_Payment_Authorization_Status__c ='Failed';
            update o;
        }
        if(sObjectName.toLowerCase() =='contract'){
            Contract contract = new Contract(Id=recordId);
            contract.TNV_Payment_Authorization_SFID__c = pa.Id;
            contract.TNV_Payment_Authorization_Status__c ='Failed';
            update contract;
        }
        }
        catch(Exception e){
            dcm_Logger.log(LoggingLevel.ERROR, e, 'CYBS Payment', 'CreatePaymentAuthforFailedTransaction', '', '', '', '','', 'CreatePaymentAuthforFailedTransaction', 'TNVB2B_CybersourcePaymentCntrl', 'handlePostPayment');
        }

        return pa.Id;
    }
}