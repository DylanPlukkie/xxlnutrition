/**
 * @description Exact-specific logging wrapper that uses AutomationLogHandler
 * Provides convenience methods for logging REST API operations in Exact integration
 * @author Dylan Pluk
 * @date 2024-12-04
 */
public class ExactLogger {
    
    private AutomationLogHandler.LogBuilder logBuilder;
    
    /**
     * @description Constructor to initialize the logger for an Exact integration class
     * @param className Name of the Apex class where logging occurs
     * @param functionName Name of the method/function where logging occurs
     */
    public ExactLogger(String className, String functionName) {
        this.logBuilder = new AutomationLogHandler.LogBuilder('Apex Class', className)
            .setFunction(functionName);
    }
    
    /**
     * @description Sets the HTTP endpoint being called
     * @param endpoint The REST endpoint URL
     * @return ExactLogger instance for method chaining
     */
    public ExactLogger setEndpoint(String endpoint) {
        this.logBuilder.setEndpoint(endpoint);
        return this;
    }
    
    /**
     * @description Sets the HTTP request details (headers and body)
     * @param request The full HTTP request including headers and body
     * @return ExactLogger instance for method chaining
     */
    public ExactLogger setRequest(String request) {
        this.logBuilder.setRequest(request);
        return this;
    }
    
    /**
     * @description Sets the HTTP response details (headers and body)
     * @param response The full HTTP response including headers and body
     * @return ExactLogger instance for method chaining
     */
    public ExactLogger setResponse(String response) {
        this.logBuilder.setResponse(response);
        return this;
    }
    
    /**
     * @description Sets the triggering record ID
     * @param recordId The Salesforce record ID that triggered the operation or was created
     * @return ExactLogger instance for method chaining
     */
    public ExactLogger setRecordId(String recordId) {
        this.logBuilder.setRecordId(recordId);
        return this;
    }
    
    /**
     * @description Sets error details from an exception
     * @param ex The exception that occurred
     * @return ExactLogger instance for method chaining
     */
    public ExactLogger setError(Exception ex) {
        this.logBuilder.setError(ex);
        return this;
    }
    
    /**
     * @description Logs an incoming HTTP request
     * Should be called at the start of REST endpoint methods
     */
    public void logRequest() {
        this.logBuilder.setLogNamePrefix('Request').save();
    }
    
    /**
     * @description Logs a successful operation
     * Should be called after successful processing
     */
    public void logSuccess() {
        this.logBuilder.setLogNamePrefix('Success').save();
    }
    
    /**
     * @description Logs an error
     * Should be called in catch blocks
     */
    public void logError() {
        this.logBuilder.setLogNamePrefix('Error').save();
    }
    
    /**
     * @description Static helper method to format RestRequest for logging
     * @param request The RestRequest object
     * @return Formatted string containing headers and body
     */
    public static String formatRestRequest(RestRequest request) {
        String formatted = 'HTTP Method: ' + request.httpMethod + '\n';
        formatted += 'Endpoint: ' + request.requestURI + '\n';
        formatted += 'Headers:\n';
        
        if (request.headers != null) {
            for (String key : request.headers.keySet()) {
                formatted += '  ' + key + ': ' + request.headers.get(key) + '\n';
            }
        }
        
        formatted += '\nBody:\n';
        formatted += request.requestBody != null ? request.requestBody.toString() : 'null';
        
        return formatted;
    }
    
    /**
     * @description Static helper method to format RestResponse for logging
     * @param response The RestResponse object
     * @return Formatted string containing headers and body
     */
    public static String formatRestResponse(RestResponse response) {
        String formatted = 'Status Code: ' + response.statusCode + '\n';
        formatted += 'Headers:\n';
        
        if (response.headers != null) {
            for (String key : response.headers.keySet()) {
                formatted += '  ' + key + ': ' + response.headers.get(key) + '\n';
            }
        }
        
        formatted += '\nBody:\n';
        formatted += response.responseBody != null ? response.responseBody.toString() : 'null';
        
        return formatted;
    }
}