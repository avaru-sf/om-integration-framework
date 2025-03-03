global with sharing class IntegrationProcedureUtility implements Callable {
    
    global Object call(String action, Map<String, Object> args) {
        
        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');
        
        if(action == 'getRequestBody'){
            getRequestBody(input, output, options);
            return true;
        }

        return false;
    }
    
    private static Map<String, Object> getRequestBody(Map<String,Object> input, Map<String,Object> output, Map<String,Object> options){
        
        String systemType = String.valueOf(input.get('systemType'));
        String orchestrationItemId = String.valueOf(input.get('OrchestrationItemId'));

        Map<String, Object> response = SystemIntegrationHelper.generateRequestBody(systemType, orchestrationItemId);
        output.put('response', response);
        return response;
    }
}