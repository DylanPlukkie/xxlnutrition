/**
 * @description Standardized response object for all Exact integration REST API endpoints
 * Provides consistent response structure across Account, Contact, and future integrations
 * @author Dylan Pluk
 * @date 2024-12-04
 */
global class ExactIntegrationResponse {
    /** @description Indicates if the operation was successful */
    public Boolean Success { get; set; }
    
    /** @description Message describing the result or error */
    public String Message { get; set; }
    
    /** @description Salesforce record ID of the created/updated record */
    public String RecordId { get; set; }
    
    /**
     * @description Constructor for creating a response object
     * @param success Boolean indicating operation success
     * @param message Descriptive message about the operation result
     * @param recordId Salesforce ID of the affected record (null if operation failed)
     */
    public ExactIntegrationResponse(Boolean success, String message, String recordId) {
        this.Success = success;
        this.Message = message;
        this.RecordId = recordId;
    }
}