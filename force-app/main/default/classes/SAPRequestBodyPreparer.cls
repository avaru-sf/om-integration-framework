// Example class to prepare request body for SAP
public with sharing class SAPRequestBodyPreparer implements IRequestBodyPreparer, IDataValidator {
    
    public Map<String, Object> prepareRequestBody(Map<String, Object> data) {
        
        Map<String, Object> sapServiceOrder = new Map<String, Object>();
        sapServiceOrder.put('sapDataField', data.get('sapDataField'));
        sapServiceOrder.put('sapCommonDataField', data.get('commonDataName'));
        
        return sapServiceOrder;
    }

    public List<String> validateData(Map<String, Object> data) {
        
        List<String> errors = new List<String>();

        if(data.get('sapDataField') == null){
            errors.add('Missing sapDataField.');
        }

        return errors;
    }

}