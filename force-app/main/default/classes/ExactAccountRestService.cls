/**
 * @description REST API endpoint for upserting Account records from Exact integration
 * @author Dylan Pluk
 * @date 2024-12-04
 */
@RestResource(urlMapping='/exact/account/*')
global with sharing class ExactAccountRestService {
    
    /**
     * @description Upserts an Account based on Exact ID from the request payload
     * @return ExactIntegrationResponse containing success status, message, and Account ID
     */
    @HttpPatch
    global static ExactIntegrationResponse upsertAccount() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        
        // Initialize logger
        ExactLogger logger = new ExactLogger('ExactAccountRestService', 'upsertAccount');
        logger.setEndpoint(request.requestURI)
               .setRequest(ExactLogger.formatRestRequest(request))
               .logRequest();
        
        try {
            // Deserialize the JSON request body into AccountRequest object
            ExactAccountRequest accountRequest = (ExactAccountRequest) JSON.deserialize(
                request.requestBody.toString(), 
                ExactAccountRequest.class
            );
            
            // Validate that Exact ID is provided
            if (String.isBlank(accountRequest.ExactId)) {
                return createErrorResponse(response, 400, 'Exact ID is required', logger);
            }
            
            // Process the account upsert through service layer
            ExactAccountService service = new ExactAccountService();
            Account upsertedAccount = service.upsertAccountByExactId(accountRequest);
            
            // Set success response
            response.statusCode = 200;
            ExactIntegrationResponse integrationResponse = new ExactIntegrationResponse(true, 'Account processed successfully', upsertedAccount.Id);
            
            // Log success with response details
            logger.setRecordId(upsertedAccount.Id)
                   .setResponse(formatResponseForLogging(response.statusCode, integrationResponse))
                   .logSuccess();
            
            return integrationResponse;
            
        } catch (ExactIntegrationException e) {
            // Handle domain-specific exceptions (validation errors, business logic failures)
            logger.setError(e).logError();
            return createErrorResponse(response, 400, e.getMessage(), logger);
        } catch (Exception e) {
            // Handle unexpected exceptions
            logger.setError(e).logError();
            return createErrorResponse(response, 500, 'Internal server error: ' + e.getMessage(), logger);
        }
    }
    
    /**
     * @description Creates a standardized error response
     * @param response The RestResponse object to set the status code
     * @param statusCode HTTP status code for the error
     * @param message Error message to return
     * @param logger The logger instance for logging the response
     * @return ExactIntegrationResponse with error details
     */
    private static ExactIntegrationResponse createErrorResponse(RestResponse response, Integer statusCode, String message, ExactLogger logger) {
        response.statusCode = statusCode;
        ExactIntegrationResponse integrationResponse = new ExactIntegrationResponse(false, message, null);
        logger.setResponse(formatResponseForLogging(statusCode, integrationResponse));
        return integrationResponse;
    }
    
    /**
     * @description Formats the response object for logging
     * @param statusCode HTTP status code
     * @param integrationResponse The ExactIntegrationResponse object
     * @return Formatted string containing status code and response body
     */
    global static String formatResponseForLogging(Integer statusCode, ExactIntegrationResponse integrationResponse) {
        String formatted = 'Status Code: ' + statusCode + '\n';
        formatted += 'Body:\n';
        formatted += JSON.serializePretty(integrationResponse);
        return formatted;
    }
}