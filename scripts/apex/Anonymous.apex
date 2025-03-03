//Call Integration Framework from Anonymous Apex

//1. ==> Invoke from apex:
String systemType = 'SAP';
String orchestrationItemId = 'a34ab0000000000AAA';
Map<String, Object> request = SystemIntegrationHelper.generateRequestBody(systemType, orchestrationItemId);
System.debug('output:: '+JSON.serialize(request));

//2. ==> Call Integration Framework from callbale interface:
IntegrationProcedureUtility util = new IntegrationProcedureUtility();
Map<String, Object> input = new Map<String, Object>{
    'systemType' => 'SAP',
    'OrchestrationItemId' => 'a34ab0000000000AAA'
};

Map<String, Object> args = new Map<String, Object> {
    'input' => input,
    'output' => new Map<String, Object>(),
    'options' => new Map<String, Object>()
};

try{
    util.call('getRequestBody', args);
    Map<String, Object> request = (Map<String, Object>)args.get('output');
    System.debug('output:: '+JSON.serialize(request));
}catch(Exception e){
    System.debug('Exception type caught: ' + e.getTypeName());    
    System.debug('Message: ' + e.getMessage());    
    System.debug('Cause: ' + e.getCause());
    System.debug('Line number: ' + e.getLineNumber());    
    System.debug('Stack trace: ' + e.getStackTraceString());
}