public abstract with sharing class CommonDataFetcher implements IDataFetcher {
    
    // Fetch common data that is shared across different systems, like FRL, Order, Order Members, Billing & Service Accounts etc.
    public Map<String, Object> fetchCommonData(String orchestrationItemId) {
        
        Map<String, Object> commonData = new Map<String, Object>();
        commonData.put('commonDataName', 'commonDataValue');//TODO: write your actual logic here
        return commonData;
    }
    
    // Each system will have its own way of fetching additional data
    public abstract Map<String, Object> fetchData(String orchestrationItemId);
}