/**
 * @description Test class for ExactLogger
 * Verifies Exact-specific logging scenarios
 * @author Dylan Pluk
 * @date 2024-12-04
 */
@IsTest
private class ExactLoggerTest {
    
    /**
     * @description Tests logging a successful HTTP request
     */
    @IsTest
    static void testLogRequest() {
        ExactLogger logger = new ExactLogger('ExactAccountRestService', 'upsertAccount');
        
        Test.startTest();
        logger.setEndpoint('/services/apexrest/exact/account/')
               .setRequest('{"ExactId": "114", "Name": "Test"}')
               .logRequest();
        Test.stopTest();
        
        List<Automation_Log__c> logs = [
            SELECT Type__c, Apex_Class_Flow_Name__c, Apex_Function_Flow_Element__c, 
                   HTTP_Endpoint__c, HTTP_Request__c, Name
            FROM Automation_Log__c
        ];
        
        System.assertEquals(1, logs.size(), 'One log should be created');
        System.assertEquals('Apex Class', logs[0].Type__c);
        System.assertEquals('ExactAccountRestService', logs[0].Apex_Class_Flow_Name__c);
        System.assertEquals('upsertAccount', logs[0].Apex_Function_Flow_Element__c);
        System.assertEquals('/services/apexrest/exact/account/', logs[0].HTTP_Endpoint__c);
        System.assert(logs[0].HTTP_Request__c.contains('ExactId'));
        System.assert(logs[0].Name.contains('Request'));
    }
    
    /**
     * @description Tests logging a successful operation with record ID
     */
    @IsTest
    static void testLogSuccess() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        ExactLogger logger = new ExactLogger('ExactAccountService', 'upsertAccountByExactId');
        
        Test.startTest();
        logger.setRecordId(testAccount.Id)
               .setRequest('{"ExactId": "114"}')
               .setResponse('{"Success": true, "RecordId": "' + testAccount.Id + '"}')
               .logSuccess();
        Test.stopTest();
        
        List<Automation_Log__c> logs = [
            SELECT Triggering_Record_Id__c, HTTP_Request__c, HTTP_Response__c, Name
            FROM Automation_Log__c
        ];
        
        System.assertEquals(1, logs.size());
        System.assertEquals(testAccount.Id, logs[0].Triggering_Record_Id__c);
        System.assert(logs[0].Name.contains('Success'));
        System.assertNotEquals(null, logs[0].HTTP_Response__c);
    }
    
    /**
     * @description Tests logging an error with exception details
     */
    @IsTest
    static void testLogError() {
        ExactLogger logger = new ExactLogger('ExactAccountService', 'createNewAccount');
        
        Exception testException;
        try {
            Account acc = new Account();
            insert acc;
        } catch (Exception ex) {
            testException = ex;
        }
        
        Test.startTest();
        logger.setError(testException)
               .setRequest('{"ExactId": "114"}')
               .logError();
        Test.stopTest();
        
        List<Automation_Log__c> logs = [
            SELECT Error_Message__c, Stack_Trace__c, Name
            FROM Automation_Log__c
        ];
        
        System.assertEquals(1, logs.size());
        System.assertNotEquals(null, logs[0].Error_Message__c);
        System.assertNotEquals(null, logs[0].Stack_Trace__c);
        System.assert(logs[0].Name.contains('Error'));
    }
    
    /**
     * @description Tests method chaining functionality
     */
    @IsTest
    static void testMethodChaining() {
        Test.startTest();
        new ExactLogger('TestClass', 'testMethod')
            .setEndpoint('/test/endpoint')
            .setRequest('test request')
            .setResponse('test response')
            .setRecordId('001000000000000')
            .logSuccess();
        Test.stopTest();
        
        List<Automation_Log__c> logs = [SELECT Id FROM Automation_Log__c];
        System.assertEquals(1, logs.size(), 'Method chaining should work correctly');
    }
    
    /**
     * @description Tests formatting of RestRequest
     */
    @IsTest
    static void testFormatRestRequest() {
        RestRequest request = new RestRequest();
        request.httpMethod = 'PATCH';
        request.requestURI = '/services/apexrest/exact/account/';
        request.requestBody = Blob.valueOf('{"ExactId": "114"}');
        request.addHeader('Content-Type', 'application/json');
        request.addHeader('Authorization', 'Bearer token');
        
        Test.startTest();
        String formatted = ExactLogger.formatRestRequest(request);
        Test.stopTest();
        
        System.assert(formatted.contains('PATCH'));
        System.assert(formatted.contains('/services/apexrest/exact/account/'));
        System.assert(formatted.contains('Content-Type'));
        System.assert(formatted.contains('ExactId'));
    }
    
    /**
     * @description Tests formatting of RestResponse
     */
    @IsTest
    static void testFormatRestResponse() {
        RestResponse response = new RestResponse();
        response.statusCode = 200;
        response.responseBody = Blob.valueOf('{"Success": true}');
        response.addHeader('Content-Type', 'application/json');
        
        Test.startTest();
        String formatted = ExactLogger.formatRestResponse(response);
        Test.stopTest();
        
        System.assert(formatted.contains('200'));
        System.assert(formatted.contains('Success'));
        System.assert(formatted.contains('Content-Type'));
    }
}