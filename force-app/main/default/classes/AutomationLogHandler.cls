/**
 * @description Generic handler for creating and managing Automation_Log__c records
 * Can be used by any Apex class (flows, batch jobs, integrations, etc.)
 * Provides both single and bulk logging capabilities
 * @author Dylan Pluk
 * @date 2024-12-04
 */
public class AutomationLogHandler {
    
    private static final Integer MAX_FIELD_LENGTH = 131072; // Long Text Area limit
    
    /**
     * @description Builder class for constructing log entries
     * Provides a fluent API for setting log properties
     */
    public class LogBuilder {
        private Automation_Log__c log;
        
        /**
         * @description Constructor initializes a new log record
         * @param type Type of automation (e.g., 'Apex Class', 'Flow', 'Batch Job')
         * @param name Name of the class, flow, or process
         */
        public LogBuilder(String type, String name) {
            this.log = new Automation_Log__c();
            this.log.Type__c = type;
            this.log.Apex_Class_Flow_Name__c = name;
            this.log.Name = generateLogName(name);
        }
        
        /**
         * @description Sets the function or element name
         * @param functionName Name of the method, function, or flow element
         * @return LogBuilder instance for method chaining
         */
        public LogBuilder setFunction(String functionName) {
            this.log.Apex_Function_Flow_Element__c = functionName;
            return this;
        }
        
        /**
         * @description Sets the HTTP endpoint
         * @param endpoint The REST endpoint URL
         * @return LogBuilder instance for method chaining
         */
        public LogBuilder setEndpoint(String endpoint) {
            this.log.HTTP_Endpoint__c = endpoint;
            return this;
        }
        
        /**
         * @description Sets the HTTP request details
         * @param request The full HTTP request including headers and body
         * @return LogBuilder instance for method chaining
         */
        public LogBuilder setRequest(String request) {
            this.log.HTTP_Request__c = truncateField(request);
            return this;
        }
        
        /**
         * @description Sets the HTTP response details
         * @param response The full HTTP response including headers and body
         * @return LogBuilder instance for method chaining
         */
        public LogBuilder setResponse(String response) {
            this.log.HTTP_Response__c = truncateField(response);
            return this;
        }
        
        /**
         * @description Sets the triggering or created record ID
         * @param recordId The Salesforce record ID
         * @return LogBuilder instance for method chaining
         */
        public LogBuilder setRecordId(String recordId) {
            this.log.Triggering_Record_Id__c = recordId;
            return this;
        }
        
        /**
         * @description Sets error details from an exception
         * @param ex The exception that occurred
         * @return LogBuilder instance for method chaining
         */
        public LogBuilder setError(Exception ex) {
            this.log.Error_Message__c = truncateField(ex.getMessage());
            this.log.Stack_Trace__c = truncateField(ex.getStackTraceString());
            return this;
        }
        
        /**
         * @description Sets a custom error message
         * @param errorMessage The error message
         * @return LogBuilder instance for method chaining
         */
        public LogBuilder setErrorMessage(String errorMessage) {
            this.log.Error_Message__c = truncateField(errorMessage);
            return this;
        }
        
        /**
         * @description Sets a custom stack trace
         * @param stackTrace The stack trace string
         * @return LogBuilder instance for method chaining
         */
        public LogBuilder setStackTrace(String stackTrace) {
            this.log.Stack_Trace__c = truncateField(stackTrace);
            return this;
        }
        
        /**
         * @description Updates the log name with a specific prefix (Request, Success, Error)
         * @param prefix The prefix to add to the log name
         * @return LogBuilder instance for method chaining
         */
        public LogBuilder setLogNamePrefix(String prefix) {
            this.log.Name = prefix + ' - ' + this.log.Apex_Class_Flow_Name__c + ' - ' + 
                           System.now().format('yyyy-MM-dd HH:mm:ss');
            return this;
        }
        
        /**
         * @description Builds and returns the Automation_Log__c record without inserting
         * @return Automation_Log__c The constructed log record
         */
        public Automation_Log__c build() {
            return this.log;
        }
        
        /**
         * @description Builds and inserts the log record
         * @return Boolean True if insert was successful, false otherwise
         */
        public Boolean save() {
            return AutomationLogHandler.insertLog(this.log);
        }
        
        /**
         * @description Builds and inserts the log record asynchronously
         */
        public void saveAsync() {
            AutomationLogHandler.insertLogAsync(this.log);
        }
    }
    
    /**
     * @description Inserts a single log record synchronously
     * Uses allOrNone=false to prevent logging failures from affecting the main transaction
     * @param log The Automation_Log__c record to insert
     * @return Boolean True if insert was successful, false otherwise
     */
    public static Boolean insertLog(Automation_Log__c log) {
        try {
            Database.SaveResult result = Database.insert(log, false);
            if (!result.isSuccess()) {
                logDatabaseErrors(result.getErrors());
                return false;
            }
            return true;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Failed to insert Automation_Log__c: ' + ex.getMessage());
            return false;
        }
    }
    
    /**
     * @description Inserts multiple log records synchronously
     * Uses allOrNone=false to prevent logging failures from affecting the main transaction
     * @param logs List of Automation_Log__c records to insert
     * @return List<Boolean> List indicating success/failure for each record
     */
    public static List<Boolean> insertLogs(List<Automation_Log__c> logs) {
        List<Boolean> results = new List<Boolean>();
        
        try {
            List<Database.SaveResult> saveResults = Database.insert(logs, false);
            
            for (Database.SaveResult result : saveResults) {
                if (!result.isSuccess()) {
                    logDatabaseErrors(result.getErrors());
                    results.add(false);
                } else {
                    results.add(true);
                }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Failed to insert Automation_Log__c records: ' + ex.getMessage());
            for (Integer i = 0; i < logs.size(); i++) {
                results.add(false);
            }
        }
        
        return results;
    }
    
    /**
     * @description Inserts a single log record asynchronously using future method
     * @param log The Automation_Log__c record to insert
     */
    public static void insertLogAsync(Automation_Log__c log) {
        if (!System.isFuture() && !System.isBatch() && !System.isQueueable()) {
            String serializedLog = JSON.serialize(log);
            insertLogFuture(serializedLog);
        } else {
            // If already in async context, insert synchronously
            insertLog(log);
        }
    }
    
    /**
     * @description Future method to insert log asynchronously
     * @param serializedLog JSON serialized Automation_Log__c record
     */
    @future
    private static void insertLogFuture(String serializedLog) {
        try {
            Automation_Log__c log = (Automation_Log__c) JSON.deserialize(serializedLog, Automation_Log__c.class);
            insertLog(log);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Failed to insert async Automation_Log__c: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Truncates a string to fit within field limits
     * @param value The string to truncate
     * @return Truncated string or original if within limit
     */
    private static String truncateField(String value) {
        if (String.isBlank(value)) {
            return value;
        }
        return value.length() > MAX_FIELD_LENGTH ? value.substring(0, MAX_FIELD_LENGTH) : value;
    }
    
    /**
     * @description Generates a standardized log name with timestamp
     * @param baseName The base name for the log
     * @return Formatted log name
     */
    private static String generateLogName(String baseName) {
        return baseName + ' - ' + System.now().format('yyyy-MM-dd HH:mm:ss');
    }
    
    /**
     * @description Logs database errors to debug log
     * @param errors List of database errors
     */
    private static void logDatabaseErrors(List<Database.Error> errors) {
        for (Database.Error error : errors) {
            System.debug(LoggingLevel.ERROR, 'Database Error: ' + error.getMessage() + 
                        ' [Fields: ' + error.getFields() + ']');
        }
    }
}