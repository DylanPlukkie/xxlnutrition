/**
 * @description REST API endpoint for upserting Contact records from Exact integration
 * @author Dylan Pluk
 * @date 2024-12-04
 */
@RestResource(urlMapping='/exact/contact/*')
global with sharing class ExactContactRestService {
    
    /**
     * @description Upserts a Contact based on Exact ID from the request payload
     * @return ExactIntegrationResponse containing success status, message, and Contact ID
     */
    @HttpPatch
    global static ExactIntegrationResponse upsertContact() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        
        // Initialize logger
        ExactLogger logger = new ExactLogger('ExactContactRestService', 'upsertContact');
        logger.setEndpoint(request.requestURI)
               .setRequest(ExactLogger.formatRestRequest(request))
               .logRequest();
        
        try {
            // Deserialize the JSON request body into ContactRequest object
            ExactContactRequest contactRequest = (ExactContactRequest) JSON.deserialize(
                request.requestBody.toString(), 
                ExactContactRequest.class
            );
            
            // Validate that Exact ID is provided
            if (String.isBlank(contactRequest.ExactId)) {
                return createErrorResponse(response, 400, 'Exact ID is required', logger);
            }
            
            // Process the contact upsert through service layer
            ExactContactService service = new ExactContactService();
            Contact upsertedContact = service.upsertContactByExactId(contactRequest);
            
            // Set success response
            response.statusCode = 200;
            ExactIntegrationResponse integrationResponse = new ExactIntegrationResponse(true, 'Contact processed successfully', upsertedContact.Id);
            
            // Log success with response details
            logger.setRecordId(upsertedContact.Id)
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