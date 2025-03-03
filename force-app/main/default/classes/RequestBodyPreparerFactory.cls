public with sharing class RequestBodyPreparerFactory {

    public static IRequestBodyPreparer getPreparer(String systemType) {

        List<SystemIntegrationConfig__mdt> config = [SELECT RequestBodyPreparerClassName__c 
                                                    FROM SystemIntegrationConfig__mdt 
                                                    WHERE SystemType__c = :systemType 
                                                    LIMIT 1];

        if (!config.isEmpty()) {
            // Use Type.forName to dynamically instantiate the RequestBodyPreparer class
            IRequestBodyPreparer preparer = (IRequestBodyPreparer) Type.forName(config[0].RequestBodyPreparerClassName__c).newInstance();
            return preparer;
        } else {
            throw new CustomException('No valid request preparer found for system: ' + systemType);
        }
    }

    public class CustomException extends Exception {}
}