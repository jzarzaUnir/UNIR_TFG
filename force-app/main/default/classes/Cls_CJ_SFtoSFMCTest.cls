@isTest
public with sharing class Cls_CJ_SFtoSFMCTest{

    private final static String MULESOFT_URL ='AST_SFtoSFMC';

    private static String body ='{"EventDefinitionKey": "APIEvent-200000d-2321-1fffff-vvv-441231", "members": [{"ContactKey": "29999","data": {"Task:Account:Id": "29999","Task:Account:Email":"test@test.com","Task:Account:FirstName": "Test","Task:Account:LastName": "Journey","Task:Account:LenguajePreferencia_c": "English"}}]}';

    
    @isTest
    static void sendRequestTest(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        Cls_CJ_SFtoSFMC.sendRequest('Brevo_Email', body);
        Test.stopTest();

        System.assertNotEquals(body, '', 'Body should not be empty.');
 
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"requestId": "7c63213cggh-fffff-uuid-v3x1-bb7ui990", "count": 1, "notQueuedCount": 0, "members": [{"contactKey": "id1","eventInstanceId": "ccccc-444-1213-5555-ggggh8887876"}]}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    
    }

}