public with sharing class DataFetcherFactory {

    public static IDataFetcher getFetcher(String systemType) {
        
        List<SystemIntegrationConfig__mdt> config = [SELECT DataFetcherClassName__c 
                                                    FROM SystemIntegrationConfig__mdt 
                                                    WHERE SystemType__c = :systemType 
                                                    LIMIT 1];

        if (!config.isEmpty()) {
            // Use Type.forName to dynamically instantiate the DataFetcher class
            IDataFetcher fetcher = (IDataFetcher) Type.forName(config[0].DataFetcherClassName__c).newInstance();
            return fetcher;
        } else {
            throw new CustomException('No valid data fetcher found for system: ' + systemType);
        }
    }

    public class CustomException extends Exception {}
}