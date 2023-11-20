/**
 * @description       :
 * @author            : Tom Zarr by way of a generous partner
 * @group             :
 * @last modified on  : 11-20-2023
 * @last modified by  : Tom Zarr by way of a generous partner
 * Modifications Log
 * Ver   Date         Author                                Modification
 * 1.0   08-28-2020   Tom Zarr by way of a generous partner Initial Version
 *
 /* Tom Zarr by way of a generous partner   01-18-2021 */
global class B2B_CYBSPaymentAdapter implements commercepayments.PaymentGatewayAdapter {

    private static final commercepayments.SalesforceResultCodeInfo RC_SUCCESS = toCodeInfo(commercepayments.SalesforceResultCode.Success);
    private static final commercepayments.SalesforceResultCodeInfo RC_DECLINE = toCodeInfo(commercepayments.SalesforceResultCode.Decline);
    private static final List<String> DECLINE_CODES = new List<String>{'card_declined', 'incorrect_cvc', 'expired_card',
     'authentication_required', 'card_not_supported', 'currency_not_supported', 'incorrect_number', 'incorrect_zip'};

    global B2B_CYBSPaymentAdapter() {
    }

    global commercepayments.GatewayResponse processRequest(commercepayments.paymentGatewayContext gatewayContext) {
        commercepayments.RequestType requestType = gatewayContext.getPaymentRequestType();
        commercepayments.PaymentGatewayRequest paymentRequest = gatewayContext.getPaymentRequest();
        commercepayments.GatewayResponse response;

        try {
            if (requestType == commercepayments.RequestType.Authorize) {
                response = createAuthResponse((commercepayments.AuthorizationRequest) paymentRequest);
            }
            /*
            else if (requestType == commercepayments.RequestType.Capture) {
                //response =  createCaptureResponse((commercepayments.CaptureRequest) paymentRequest);
            } else if (requestType == commercepayments.RequestType.Sale) {
                //response =  createSaleResponse((commercepayments.SaleRequest) paymentRequest);
            } else if (requestType == commercepayments.RequestType.ReferencedRefund) {
                //response = createRefundResponse((commercepayments.ReferencedRefundRequest) paymentRequest);
            } else if (requestType == commercepayments.RequestType.Tokenize) {
                //response = createTokenizeResponse((commercepayments.PaymentMethodTokenizationRequest) paymentRequest);
            }
            */
            return response;
        } catch (B2B_CYBSException e) {
             return new commercepayments.GatewayErrorResponse('400', e.getMessage());
        }
    }

    public commercepayments.GatewayResponse createAuthResponse(commercepayments.AuthorizationRequest authRequest) {
        // API: https://apitest.cybersource.com/pts/v2/payments/


        String v1Token = authRequest.additionalData.get('v1Token');
        String v2Token = authRequest.additionalData.get('v2Token');
        string token = v1Token + v2Token;
        String currencyIsoCodeLC = authRequest.currencyIsoCode.toLowercase();

        Map<String, String> params = new Map<String, String>();

        B2B_CybersourceSOAPUtility.getCYBSConfiguration('Trimble Europe B.V.',currencyIsoCodeLC);

        HttpRequest req = new HttpRequest();
        String reqBody = B2B_CybersourceSOAPUtility.buildCaptureRestRequest(token, true, authRequest);
        req = B2B_CybersourceSOAPUtility.generatePostRequest('/pts/v2/payments', reqBody);
        commercepayments.PaymentsHttp http = new commercepayments.PaymentsHttp();
        HttpResponse response = http.send(req);


        String body = response.getBody();
        Integer httpStatusCode = response.getStatusCode();
        System.debug(' CYBS results    ' + body);

        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(body);
        Map<String, Object> orderInfo = (Map<String, Object>) results.get('orderInformation');
        Map<String, Object> amountDetails = (Map<String, Object>) orderInfo.get('amountDetails');


        commercepayments.AuthorizationResponse authResponse = new commercepayments.AuthorizationResponse();

        authResponse.setGatewayDate(system.now());
        authResponse.setGatewayResultCode((String) results.get('status'));
        authResponse.setGatewayResultCodeDescription((string)results.get('status'));
        authResponse.setGatewayAuthCode((String) results.get('id')); 
        authResponse.setSalesforceResultCodeInfo(RC_SUCCESS);
        authResponse.setAmount(double.valueOf(amountDetails.get('authorizedAmount'))); 

        return authResponse;
    }

    private static commercepayments.SalesforceResultCodeInfo toCodeInfo(commercepayments.SalesforceResultCode code) {
        return new commercepayments.SalesforceResultCodeInfo(code);
    }
}