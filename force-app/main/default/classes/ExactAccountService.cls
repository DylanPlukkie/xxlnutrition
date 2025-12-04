/**
 * @description Service class for handling Account upsert operations from Exact integration
 * @author Dylan Pluk
 * @date 2024-12-04
 */
public with sharing class ExactAccountService {
    
    /**
     * @description Upserts an Account based on Exact ID
     * If Account exists with the given Exact ID, it will be updated
     * If Account does not exist, a new Account and related Exact_Account_Id__c record will be created
     * @param request ExactAccountRequest containing account data from Exact
     * @return Account The upserted Account record
     * @throws ExactIntegrationException if DML operations fail
     */
    public Account upsertAccountByExactId(ExactAccountRequest request) {
        Account existingAccount = findAccountByExactId(request.ExactId);
        
        if (existingAccount != null) {
            return updateExistingAccount(existingAccount, request);
        } else {
            return createNewAccount(request);
        }
    }
    
    /**
     * @description Finds an Account by querying the Exact_Account_Id__c child object
     * @param exactId The Exact ID to search for
     * @return Account The found Account record, or null if not found
     */
    private Account findAccountByExactId(String exactId) {
        List<Exact_Account_Id__c> exactAccountIds = [
            SELECT Id, Account__c, Account__r.Id, Account__r.Name
            FROM Exact_Account_Id__c
            WHERE Exact_Id__c = :exactId
            LIMIT 1
        ];
        
        return exactAccountIds.isEmpty() ? null : exactAccountIds[0].Account__r;
    }
    
    /**
     * @description Updates an existing Account with data from the request
     * @param existingAccount The Account record to update
     * @param request ExactAccountRequest containing the new data
     * @return Account The updated Account record
     * @throws ExactIntegrationException if the update operation fails
     */
    private Account updateExistingAccount(Account existingAccount, ExactAccountRequest request) {
        mapRequestToAccount(existingAccount, request);
        
        try {
            update existingAccount;
            return existingAccount;
        } catch (DmlException e) {
            throw new ExactIntegrationException('Failed to update account: ' + e.getMessage());
        }
    }
    
    /**
     * @description Creates a new Account and related Exact_Account_Id__c record
     * Uses a savepoint to ensure both records are created atomically
     * @param request ExactAccountRequest containing the account data
     * @return Account The newly created Account record
     * @throws ExactIntegrationException if the create operation fails
     */
    private Account createNewAccount(ExactAccountRequest request) {
        Account newAccount = new Account();
        mapRequestToAccount(newAccount, request);
        
        Savepoint sp = Database.setSavepoint();
        
        try {
            // Insert the Account record
            insert newAccount;
            
            // Create related Exact_Account_Id__c record to store the Exact ID
            Exact_Account_Id__c exactAccountId = new Exact_Account_Id__c(
                Account__c = newAccount.Id,
                Exact_Id__c = request.ExactId
            );
            insert exactAccountId;
            
            return newAccount;
        } catch (Exception e) {
            // Rollback both operations if either fails
            Database.rollback(sp);
            throw new ExactIntegrationException('Failed to create account: ' + e.getMessage());
        }
    }
    
    /**
     * @description Maps data from ExactAccountRequest to Account record
     * @param acc The Account record to populate
     * @param request ExactAccountRequest containing the source data
     */
    private void mapRequestToAccount(Account acc, ExactAccountRequest request) {
        acc.Name = request.Name;
        acc.exactStatus__c = request.ExactStatus;
        acc.COCNumber__c = request.COCNumber;
        acc.VATNumber__c = request.VATNumber;
        acc.BillingStreet = request.BillingStreet;
        acc.BillingCity = request.BillingCity;
        acc.BillingState = request.BillingState;
        acc.BillingPostalCode = request.BillingPostalCode;
        acc.BillingCountry = request.BillingCountry;
        acc.ShippingStreet = request.ShippingStreet;
        acc.ShippingCity = request.ShippingCity;
        acc.ShippingState = request.ShippingState;
        acc.ShippingPostalCode = request.ShippingPostalCode;
        acc.ShippingCountry = request.ShippingCountry;
    }
}