/**
 * @description Test class for AutomationLogHandler
 * Verifies logging functionality for various scenarios and contexts
 * @author Dylan Pluk
 * @date 2024-12-04
 */
@IsTest
private class AutomationLogHandlerTest {
    
    /**
     * @description Tests basic log creation using LogBuilder
     */
    @IsTest
    static void testBasicLogCreation() {
        Test.startTest();
        AutomationLogHandler.LogBuilder builder = new AutomationLogHandler.LogBuilder('Apex Class', 'TestClass');
        Boolean result = builder.setFunction('testMethod')
                                 .setEndpoint('/test/endpoint')
                                 .setRequest('test request')
                                 .setResponse('test response')
                                 .setRecordId('001000000000000')
                                 .save();
        Test.stopTest();
        
        System.assertEquals(true, result, 'Log should be saved successfully');
        
        List<Automation_Log__c> logs = [
            SELECT Type__c, Apex_Class_Flow_Name__c, Apex_Function_Flow_Element__c,
                   HTTP_Endpoint__c, HTTP_Request__c, HTTP_Response__c, Triggering_Record_Id__c
            FROM Automation_Log__c
        ];
        
        System.assertEquals(1, logs.size());
        System.assertEquals('Apex Class', logs[0].Type__c);
        System.assertEquals('TestClass', logs[0].Apex_Class_Flow_Name__c);
        System.assertEquals('testMethod', logs[0].Apex_Function_Flow_Element__c);
        System.assertEquals('/test/endpoint', logs[0].HTTP_Endpoint__c);
        System.assertEquals('001000000000000', logs[0].Triggering_Record_Id__c);
    }
    
    /**
     * @description Tests logging with exception details
     */
    @IsTest
    static void testLogWithException() {
        Exception testException;
        try {
            Account acc = new Account();
            insert acc;
        } catch (Exception ex) {
            testException = ex;
        }
        
        Test.startTest();
        AutomationLogHandler.LogBuilder builder = new AutomationLogHandler.LogBuilder('Apex Class', 'ErrorTest');
        Boolean result = builder.setFunction('testError')
                                 .setError(testException)
                                 .setLogNamePrefix('Error')
                                 .save();
        Test.stopTest();
        
        System.assertEquals(true, result);
        
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
     * @description Tests bulk log insertion
     */
    @IsTest
    static void testBulkLogInsertion() {
        List<Automation_Log__c> logs = new List<Automation_Log__c>();
        
        for (Integer i = 0; i < 5; i++) {
            AutomationLogHandler.LogBuilder builder = new AutomationLogHandler.LogBuilder('Apex Class', 'BulkTest');
            logs.add(builder.setFunction('bulkMethod' + i)
                            .setRequest('request ' + i)
                            .build());
        }
        
        Test.startTest();
        List<Boolean> results = AutomationLogHandler.insertLogs(logs);
        Test.stopTest();
        
        System.assertEquals(5, results.size());
        for (Boolean result : results) {
            System.assertEquals(true, result, 'All logs should be inserted successfully');
        }
        
        List<Automation_Log__c> insertedLogs = [SELECT Id FROM Automation_Log__c];
        System.assertEquals(5, insertedLogs.size());
    }
    
    /**
     * @description Tests log name prefix functionality
     */
    @IsTest
    static void testLogNamePrefix() {
        Test.startTest();
        new AutomationLogHandler.LogBuilder('Apex Class', 'PrefixTest')
            .setLogNamePrefix('Request')
            .save();
        
        new AutomationLogHandler.LogBuilder('Apex Class', 'PrefixTest')
            .setLogNamePrefix('Success')
            .save();
        
        new AutomationLogHandler.LogBuilder('Apex Class', 'PrefixTest')
            .setLogNamePrefix('Error')
            .save();
        Test.stopTest();
        
        List<Automation_Log__c> logs = [SELECT Name FROM Automation_Log__c ORDER BY Name];
        
        System.assertEquals(3, logs.size());
        System.assert(logs[0].Name.contains('Error') || logs[0].Name.contains('Request') || logs[0].Name.contains('Success'));
    }
    
    /**
     * @description Tests field truncation for long values
     */
    @IsTest
    static void testFieldTruncation() {
        String longString = '';
        for (Integer i = 0; i < 140000; i++) {
            longString += 'x';
        }
        
        Test.startTest();
        new AutomationLogHandler.LogBuilder('Apex Class', 'TruncateTest')
            .setRequest(longString)
            .setResponse(longString)
            .setErrorMessage(longString)
            .save();
        Test.stopTest();
        
        List<Automation_Log__c> logs = [
            SELECT HTTP_Request__c, HTTP_Response__c, Error_Message__c
            FROM Automation_Log__c
        ];
        
        System.assertEquals(1, logs.size());
        System.assert(logs[0].HTTP_Request__c.length() <= 131072);
        System.assert(logs[0].HTTP_Response__c.length() <= 131072);
        System.assert(logs[0].Error_Message__c.length() <= 131072);
    }
    
    /**
     * @description Tests build method without saving
     */
    @IsTest
    static void testBuildWithoutSave() {
        Test.startTest();
        Automation_Log__c log = new AutomationLogHandler.LogBuilder('Flow', 'TestFlow')
            .setFunction('Screen1')
            .setRecordId('003000000000000')
            .build();
        Test.stopTest();
        
        System.assertNotEquals(null, log);
        System.assertEquals('Flow', log.Type__c);
        System.assertEquals('TestFlow', log.Apex_Class_Flow_Name__c);
        System.assertEquals('003000000000000', log.Triggering_Record_Id__c);
        
        List<Automation_Log__c> logs = [SELECT Id FROM Automation_Log__c];
        System.assertEquals(0, logs.size(), 'Log should not be saved when using build()');
    }
    
    /**
     * @description Tests different automation types (not just Apex Class)
     */
    @IsTest
    static void testDifferentAutomationTypes() {
        Test.startTest();
        new AutomationLogHandler.LogBuilder('Flow', 'MyFlow')
            .setFunction('DecisionElement1')
            .save();
        
        new AutomationLogHandler.LogBuilder('Batch Job', 'MyBatchJob')
            .setFunction('execute')
            .save();
        
        new AutomationLogHandler.LogBuilder('Scheduled Job', 'MyScheduledJob')
            .setFunction('execute')
            .save();
        Test.stopTest();
        
        List<Automation_Log__c> logs = [SELECT Type__c FROM Automation_Log__c];
        
        System.assertEquals(3, logs.size());
        Set<String> types = new Set<String>();
        for (Automation_Log__c log : logs) {
            types.add(log.Type__c);
        }
        System.assert(types.contains('Flow'));
        System.assert(types.contains('Batch Job'));
        System.assert(types.contains('Scheduled Job'));
    }
    
    /**
     * @description Tests custom error message and stack trace
     */
    @IsTest
    static void testCustomErrorDetails() {
        Test.startTest();
        new AutomationLogHandler.LogBuilder('Apex Class', 'CustomErrorTest')
            .setErrorMessage('Custom error occurred')
            .setStackTrace('Line 1: CustomClass.method()\nLine 2: Trigger.execute()')
            .save();
        Test.stopTest();
        
        List<Automation_Log__c> logs = [
            SELECT Error_Message__c, Stack_Trace__c
            FROM Automation_Log__c
        ];
        
        System.assertEquals(1, logs.size());
        System.assertEquals('Custom error occurred', logs[0].Error_Message__c);
        System.assert(logs[0].Stack_Trace__c.contains('CustomClass.method()'));
    }
}