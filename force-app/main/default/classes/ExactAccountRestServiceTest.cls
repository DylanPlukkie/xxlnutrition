/**
 * @description Test class for ExactAccountRestService
 * Tests all scenarios for Account upsert via REST API including success and error cases
 * @author Dylan Pluk
 * @date 2024-12-04
 */
@IsTest
private class ExactAccountRestServiceTest {
    
    /**
     * @description Tests creating a new Account when Exact ID doesn't exist
     * Verifies that Account and related Exact_Account_Id__c records are created correctly
     */
    @IsTest
    static void testCreateNewAccount() {
        String requestBody = '{'
            + '"ExactId": "114",'
            + '"Name": "APIUpserted 114",'
            + '"ExactStatus": "Status1",'
            + '"COCNumber": "Coc114",'
            + '"VATNumber": "Vat114",'
            + '"BillingStreet": "Citadel 28-3",'
            + '"BillingCity": "Veenendaal",'
            + '"BillingState": "Zuid-Holland",'
            + '"BillingPostalCode": "3905NK",'
            + '"BillingCountry": "The Netherlands",'
            + '"ShippingStreet": "Citadel 28-3",'
            + '"ShippingCity": "Veenendaal",'
            + '"ShippingState": "Zuid-Holland",'
            + '"ShippingPostalCode": "3905NK",'
            + '"ShippingCountry": "The Netherlands"'
            + '}';
        
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/exact/account/';
        request.httpMethod = 'PATCH';
        request.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        ExactIntegrationResponse response = ExactAccountRestService.upsertAccount();
        Test.stopTest();
        
        // Assert success response
        System.assertEquals(true, response.Success, 'Response should be successful');
        System.assertNotEquals(null, response.RecordId, 'Account ID should be returned');
        
        // Verify Account was created with correct data
        Account createdAccount = [SELECT Id, Name, exactStatus__c, COCNumber__c FROM Account WHERE Id = :response.RecordId];
        System.assertEquals('APIUpserted 114', createdAccount.Name);
        System.assertEquals('Status1', createdAccount.exactStatus__c);
        System.assertEquals('Coc114', createdAccount.COCNumber__c);
        
        // Verify Exact_Account_Id__c record was created
        List<Exact_Account_Id__c> exactIds = [SELECT Exact_Id__c FROM Exact_Account_Id__c WHERE Account__c = :createdAccount.Id];
        System.assertEquals(1, exactIds.size(), 'One Exact Account ID should be created');
        System.assertEquals('114', exactIds[0].Exact_Id__c);
    }
    
    /**
     * @description Tests updating an existing Account when Exact ID already exists
     * Verifies that the same Account is updated, not a new one created
     */
    @IsTest
    static void testUpdateExistingAccount() {
        // Setup existing account with Exact ID
        Account testAccount = new Account(Name = 'Original Account');
        insert testAccount;
        
        Exact_Account_Id__c exactId = new Exact_Account_Id__c(
            Account__c = testAccount.Id,
            Exact_Id__c = '114'
        );
        insert exactId;
        
        String requestBody = '{'
            + '"ExactId": "114",'
            + '"Name": "Updated Account 114",'
            + '"ExactStatus": "Status2",'
            + '"COCNumber": "Coc114Updated",'
            + '"VATNumber": "Vat114Updated"'
            + '}';
        
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/exact/account/';
        request.httpMethod = 'PATCH';
        request.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        ExactIntegrationResponse response = ExactAccountRestService.upsertAccount();
        Test.stopTest();
        
        // Assert success and same Account ID is returned
        System.assertEquals(true, response.Success, 'Response should be successful');
        System.assertEquals(testAccount.Id, response.RecordId, 'Should return existing account ID');
        
        // Verify Account was updated with new data
        Account updatedAccount = [SELECT Id, Name, exactStatus__c, COCNumber__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Updated Account 114', updatedAccount.Name);
        System.assertEquals('Status2', updatedAccount.exactStatus__c);
        System.assertEquals('Coc114Updated', updatedAccount.COCNumber__c);
    }
    
    /**
     * @description Tests error handling when required Exact ID is missing
     * Verifies that appropriate error response is returned
     */
    @IsTest
    static void testMissingExactId() {
        String requestBody = '{'
            + '"Name": "APIUpserted 114"'
            + '}';
        
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/exact/account/';
        request.httpMethod = 'PATCH';
        request.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        ExactIntegrationResponse response = ExactAccountRestService.upsertAccount();
        Test.stopTest();
        
        // Assert error response
        System.assertEquals(false, response.Success, 'Response should indicate failure');
        System.assertEquals(400, RestContext.response.statusCode, 'Should return 400 status code');
        System.assert(response.Message.contains('Exact ID is required'));
    }
    
    /**
     * @description Tests that an Account with multiple Exact IDs can be updated via any of its IDs
     * Verifies that the same Account is updated regardless of which Exact ID is used
     */
    @IsTest
    static void testMultipleExactIdsPerAccount() {
        // Setup account with multiple Exact IDs
        Account testAccount = new Account(Name = 'Multi Exact ID Account');
        insert testAccount;
        
        Exact_Account_Id__c exactId1 = new Exact_Account_Id__c(
            Account__c = testAccount.Id,
            Exact_Id__c = '114'
        );
        Exact_Account_Id__c exactId2 = new Exact_Account_Id__c(
            Account__c = testAccount.Id,
            Exact_Id__c = '115'
        );
        insert new List<Exact_Account_Id__c>{exactId1, exactId2};
        
        String requestBody = '{'
            + '"ExactId": "115",'
            + '"Name": "Updated via Second Exact ID"'
            + '}';
        
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/exact/account/';
        request.httpMethod = 'PATCH';
        request.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        ExactIntegrationResponse response = ExactAccountRestService.upsertAccount();
        Test.stopTest();
        
        // Assert same Account was updated
        System.assertEquals(true, response.Success);
        System.assertEquals(testAccount.Id, response.RecordId, 'Should update the same account');
        
        Account updatedAccount = [SELECT Name FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Updated via Second Exact ID', updatedAccount.Name);
    }
}