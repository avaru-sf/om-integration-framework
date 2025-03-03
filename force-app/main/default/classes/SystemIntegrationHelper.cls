public with sharing class SystemIntegrationHelper {

    public static Map<String, Object> generateRequestBody(String systemType, String orchestrationItemId) {
        
        // Step 1: Fetch the relevant DataFetcher interface
        IDataFetcher dataFetcher = DataFetcherFactory.getFetcher(systemType);

        // Step 2: Fetch data from the orchestration item
        Map<String, Object> data = dataFetcher.fetchData(orchestrationItemId);
        
        // Step 3: Fetch the relevant RequestBodyPreparer interface
        IRequestBodyPreparer preparer = RequestBodyPreparerFactory.getPreparer(systemType);

        // Step 4: Validate the data (if RequestBodyPreparer for the system implements DataValidator interface)
        List<String> validationErrors = new List<String>();
        if (preparer instanceof IDataValidator) {
            validationErrors = ((IDataValidator) preparer).validateData(data);
        }

        // Step 5: Prepare the request body
        Map<String, Object> requestBody = preparer.prepareRequestBody(data);

        // Step 6: Package the request body and any validation errors in the response
        Map<String, Object> response = new Map<String, Object>();
        response.put('requestBody', requestBody);
        response.put('validationErrors', validationErrors);
        response.put('hasErrors', !validationErrors.isEmpty());

        return response;
    }
}