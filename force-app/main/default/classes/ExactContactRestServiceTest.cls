/**
 * @description Test class for ExactContactRestService
 * Tests all scenarios for Contact upsert via REST API including success and error cases
 * @author Dylan Pluk
 * @date 2024-12-04
 */
@IsTest
private class ExactContactRestServiceTest {
    
    /**
     * @description Setup method to create test data used across multiple test methods
     * Creates an Account with associated Exact_Account_Id__c record
     */
    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Exact_Account_Id__c exactAccountId = new Exact_Account_Id__c(
            Account__c = testAccount.Id,
            Exact_Id__c = '114'
        );
        insert exactAccountId;
    }
    
    /**
     * @description Tests creating a new Contact when Exact ID doesn't exist
     * Verifies that Contact is created correctly and linked to the right Account
     */
    @IsTest
    static void testCreateNewContact() {
        String requestBody = '{'
            + '"ExactId": "CONT123",'
            + '"AccountExactId": "114",'
            + '"FirstName": "Pietje",'
            + '"LastName": "Achternaam",'
            + '"Email": "Pietje@test.com",'
            + '"MobilePhone": "0655555555",'
            + '"OtherPhone": "010555555"'
            + '}';
        
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/exact/contact/';
        request.httpMethod = 'PATCH';
        request.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        ExactIntegrationResponse response = ExactContactRestService.upsertContact();
        Test.stopTest();
        
        // Assert success response
        System.assertEquals(true, response.Success, 'Response should be successful');
        System.assertNotEquals(null, response.RecordId, 'Contact ID should be returned');
        
        // Verify Contact was created with correct data
        Contact createdContact = [
            SELECT Id, FirstName, LastName, Email, MobilePhone, OtherPhone, AccountId, exactId__c 
            FROM Contact 
            WHERE Id = :response.RecordId
        ];
        System.assertEquals('Pietje', createdContact.FirstName);
        System.assertEquals('Achternaam', createdContact.LastName);
        System.assertEquals('Pietje@test.com', createdContact.Email);
        System.assertEquals('0655555555', createdContact.MobilePhone);
        System.assertEquals('010555555', createdContact.OtherPhone);
        System.assertEquals('CONT123', createdContact.exactId__c);
        System.assertNotEquals(null, createdContact.AccountId, 'Contact should be linked to account');
    }
    
    /**
     * @description Tests updating an existing Contact when Exact ID already exists
     * Verifies that the same Contact is updated, not a new one created
     */
    @IsTest
    static void testUpdateExistingContact() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Setup existing contact
        Contact testContact = new Contact(
            FirstName = 'Original',
            LastName = 'Name',
            Email = 'original@test.com',
            exactId__c = 'CONT123',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        String requestBody = '{'
            + '"ExactId": "CONT123",'
            + '"AccountExactId": "114",'
            + '"FirstName": "Updated",'
            + '"LastName": "UpdatedName",'
            + '"Email": "updated@test.com",'
            + '"MobilePhone": "0611111111",'
            + '"OtherPhone": "010111111"'
            + '}';
        
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/exact/contact/';
        request.httpMethod = 'PATCH';
        request.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        ExactIntegrationResponse response = ExactContactRestService.upsertContact();
        Test.stopTest();
        
        // Assert success and same Contact ID is returned
        System.assertEquals(true, response.Success, 'Response should be successful');
        System.assertEquals(testContact.Id, response.RecordId, 'Should return existing contact ID');
        
        // Verify Contact was updated with new data
        Contact updatedContact = [
            SELECT FirstName, LastName, Email, MobilePhone, OtherPhone 
            FROM Contact 
            WHERE Id = :testContact.Id
        ];
        System.assertEquals('Updated', updatedContact.FirstName);
        System.assertEquals('UpdatedName', updatedContact.LastName);
        System.assertEquals('updated@test.com', updatedContact.Email);
        System.assertEquals('0611111111', updatedContact.MobilePhone);
        System.assertEquals('010111111', updatedContact.OtherPhone);
    }
    
    /**
     * @description Tests error handling when required Exact ID is missing
     * Verifies that appropriate error response is returned
     */
    @IsTest
    static void testMissingExactId() {
        String requestBody = '{'
            + '"AccountExactId": "114",'
            + '"FirstName": "Pietje",'
            + '"LastName": "Achternaam"'
            + '}';
        
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/exact/contact/';
        request.httpMethod = 'PATCH';
        request.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        ExactIntegrationResponse response = ExactContactRestService.upsertContact();
        Test.stopTest();
        
        // Assert error response
        System.assertEquals(false, response.Success, 'Response should indicate failure');
        System.assertEquals(400, RestContext.response.statusCode, 'Should return 400 status code');
        System.assert(response.Message.contains('Exact ID is required'));
    }
    
    /**
     * @description Tests error handling when AccountExactId references non-existent Account
     * Verifies that appropriate error is thrown and returned
     */
    @IsTest
    static void testInvalidAccountExactId() {
        String requestBody = '{'
            + '"ExactId": "CONT123",'
            + '"AccountExactId": "INVALID999",'
            + '"FirstName": "Pietje",'
            + '"LastName": "Achternaam"'
            + '}';
        
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/exact/contact/';
        request.httpMethod = 'PATCH';
        request.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        ExactIntegrationResponse response = ExactContactRestService.upsertContact();
        Test.stopTest();
        
        // Assert error response
        System.assertEquals(false, response.Success, 'Response should indicate failure');
        System.assert(response.Message.contains('Account with Exact ID'));
    }
    
    /**
     * @description Tests creating a Contact without linking to an Account
     * Verifies that Contact can be created successfully with null AccountId
     */
    @IsTest
    static void testCreateContactWithoutAccount() {
        String requestBody = '{'
            + '"ExactId": "CONT123",'
            + '"FirstName": "Pietje",'
            + '"LastName": "Achternaam",'
            + '"Email": "Pietje@test.com"'
            + '}';
        
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/exact/contact/';
        request.httpMethod = 'PATCH';
        request.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        ExactIntegrationResponse response = ExactContactRestService.upsertContact();
        Test.stopTest();
        
        // Assert success
        System.assertEquals(true, response.Success, 'Response should be successful');
        
        // Verify Contact was created without Account link
        Contact createdContact = [SELECT AccountId FROM Contact WHERE Id = :response.RecordId];
        System.assertEquals(null, createdContact.AccountId, 'Contact should not be linked to an account');
    }
}