//Example class to fetch data from SAP
public with sharing class SAPDataFetcher extends CommonDataFetcher {

    public override Map<String, Object> fetchData(String orchestrationItemId) {
        Map<String, Object> data = fetchCommonData(orchestrationItemId);
        data.put('sapDataField', 'sapDataFieldValue');//TODO: write your actual logic here
        return data;
    }
}