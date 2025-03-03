
# Salesforce Apex Framework for Order Management Integration

**Document Version**: 1.0
**Date**: Friday, February 21
**Author**: [Axaykumar Varu](https://quip.com/dSMAEAWUhmk)

## Overview

The Salesforce Apex Framework for Order Management Integration is designed to streamline point-to-point (P2P) integrations by providing a modular, extensible architecture for preparing request bodies tailored to different external systems. The framework eliminates repetitive data fetching logic and supports dynamic configuration of integration components via custom metadata, enabling seamless scalability for multiple downstream fulfilment systems (e.g., SAP/Nokia etc).

### Objectives

* **Modularity**: Separate concerns of data fetching, validation, and request body preparation into reusable components.
* **Extensibility**: Allow easy addition of new integrations without modifying core logic, using factory patterns and metadata-driven configuration.
* **Reusability**: Reduce code duplication by centralising common data fetching and orchestration logic.
* **Flexibility**: Support diverse request body formats and validation rules specific to each external system.

### Scope

This framework supports:

* Fetching data from Salesforce objects based on an `orchestrationItemId`.
* Validating fetched data (optional, system-specific).
* Preparing system-specific request bodies for integration.
* Integration with Salesforce features like OmniStudio Integration Procedures via the Callable interface or call directly from Apex.

## Architecture

The framework follows a layered architecture:

1. **Interfaces**: Define contracts for data fetching, validation, and request body preparation.
2. **Abstract Layer**: Provides reusable logic for common data fetching.
3. **Factories**: Dynamically instantiate system-specific implementations using metadata.
4. **Helper Layer**: Orchestrates the integration workflow.
5. **Utility Layer**: Integrates with Salesforce features (e.g., Integration Procedures).
6. **Implementation Layer**: Contains system-specific logic (e.g., SAP integration).

### Class Diagram

[Image: Image.jpg]
### Key Design Principles

* **Interface Segregation**: Separate interfaces (IDataFetcher, IDataValidator, IRequestBodyPreparer) ensure classes implement only necessary methods.
* **Factory Pattern**: DataFetcherFactory and RequestBodyPreparerFactory use metadata to instantiate classes dynamically.
* **Single Responsibility**: Each class has a distinct role (e.g., fetching, validating, preparing).
* **Dependency Inversion**: High-level modules (SystemIntegrationHelper) depend on abstractions (interfaces), not concrete implementations.

## Components

### Interfaces

#### IDataFetcher

**Purpose**: Defines the interface for fetching data from Salesforce objects.
**Method**:

* **Input**: orchestrationItemId (`String`) - Identifier for the orchestration item.
* **Output**: `Map<String, Object>` - Key-value pairs where the key is the data name and the value is the data (of any type).

```
Map<String, Object> fetchData(String orchestrationItemId);
```

#### IDataValidator

**Purpose**: Defines the interface for validating fetched data.
**Method**:

* **Input**: data (`Map<String, Object>`) - Data to validate.
* **Output**:  `List<String>` - List of validation error messages (empty if no errors).

```
List<String> validateData(Map<String, Object> data);
```

#### IRequestBodyPreparer

**Purpose**: Defines the interface for validating fetched data.
**Method:**

* **Input**: data (`Map<String, Object>`) - Fetched data.
* **Output**: `Map<String, Object>` - Prepared request body.

#### Callable (Salesforce Interface)

**Purpose**: Out-of-the-box Salesforce interface for integration procedures.
**Method:** 

```
`Object call(String action, Map<String, Object> args);`
```

### Abstract Class

#### CommonDataFetcher

**Purpose**: Provides a base implementation for data fetching with shared logic.
**Implements**: `IDataFetcher`
**Methods:**

1. **Abstract**

```
 Map<String, Object> fetchData(String orchestrationItemId);
```

1. **Concrete**
    1. Fetches common data (e.g., account details, order info) using `orchestrationItemId`.
    2.  Returns a `Map<String, Object>` with common data.

```
 Map<String, Object> fetchCommonData(String orchestrationItemId);
```

### Factory Classes

#### DataFetcherFactory

**Purpose**: Instantiates system-specific `IDataFetcher` implementations.
**Methods:**

```
public static IDataFetcher getFetcher(String systemType) {
    // Query SystemIntegrationConfig__mdt for DataFetcherClassName__c
    // Return instance of the class (e.g., SAPDataFetcher)
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
```

**Metadata**: Uses `SystemIntegrationConfig__mdt` (e.g., `DataFetcherClassName__c`).

#### RequestBodyPreparerFactory

**Purpose**: Instantiates system-specific `IRequestBodyPreparer` implementations.
**Methods:**

```
public static IRequestBodyPreparer getPreparer(String systemType) {
    // Query SystemIntegrationConfig__mdt for RequestBodyPreparerClassName__c
    // Return instance of the class (e.g., SAPRequestBodyPreparer)
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
```

**Metadata**: Uses `SystemIntegrationConfig__mdt` (e.g., `RequestBodyPreparerClassName__c`).

### Helper Class

#### SystemIntegrationHelper

**Purpose**: Orchestrates the integration process.
**Method**:

```
public static Map<String, Object> generateRequestBody(String systemType, String orchestrationItemId) {
    
   IDataFetcher dataFetcher = DataFetcherFactory.getFetcher(systemType);
    Map<String, Object> data = dataFetcher.fetchData(orchestrationItemId);
    IRequestBodyPreparer preparer = RequestBodyPreparerFactory.getPreparer(systemType);
    List<String> validationErrors = new List<String>();
    
    if (preparer instanceof IDataValidator) {
        validationErrors = ((IDataValidator) preparer).validateData(data);
    }
    
    Map<String, Object> requestBody = preparer.prepareRequestBody(data);
    Map<String, Object> response = new Map<String, Object>();
    response.put('requestBody', requestBody);
    response.put('validationErrors', validationErrors);
    response.put('hasErrors', !validationErrors.isEmpty());
    
    return response;
}
```

**Output**: A `Map<String, Object>` with `requestBody`, `validationErrors`, and `hasErrors`.

### Utility Classes

#### IntegrationProcedureUtility

**Purpose**: Provides an entry point for Salesforce Integration Procedures.
**Implements**: Callable
**Method**:

```
public Object call(String action, Map<String, Object> args) {

    Map<String, Object> input = (Map<String, Object>) args.get('input');
    String systemType = (String) input.get('systemType');
    String orchestrationItemId = (String) input.get('orchestrationItemId');
    return SystemIntegrationHelper.generateRequestBody(systemType, orchestrationItemId);
}
```

### Implementation Classes (Example: SAP Integration)

#### SAPDataFetcher

**Purpose**: Fetches SAP-specific data.
**Extends**: `CommonDataFetcher`
**Method**:

```
public override Map<String, Object> fetchData(String orchestrationItemId) {
    Map<String, Object> commonData = fetchCommonData(orchestrationItemId);
    // Add SAP-specific data fetching logic
    commonData.put('sapSpecificField', 'someValue');
    return commonData;
}
```

#### SAPRequestBodyPreparer

**Purpose**: Prepares and validates the request body for SAP integration.
**Extends**: `IRequestBodyPreparer`, `IDataValidator`
**Methods**:


1. SAP Request Body Preparer

```
public Map<String, Object> prepareRequestBody(Map<String, Object> data) {
    
    Map<String, Object> requestBody = new Map<String, Object>();
    // SAP-specific request body preparation
    requestBody.put('sapField', data.get('sapSpecificField'));
    return requestBody;
}
```

1. SAP Data validation

```
public List<String> validateData(Map<String, Object> data) {
    
    List<String> errors = new List<String>();
    if (!data.containsKey('sapSpecificField')) {
        errors.add('Missing sapSpecificField');
    }
    
    return errors;
}
```

### Custom Metadata

#### SystemIntegrationConfig__mdt

**Purpose**: Stores configuration for system-specific implementations.
**Fields**:

*  `SystemType__c`: Unique identifier for the system (e.g., 'SAP').
*  `DataFetcherClassName__c`: Apex class name for `IDataFetcher` (e.g., '`SAPDataFetcher`').
*  `RequestBodyPreparerClassName__c`: Apex class name for `IRequestBodyPreparer` (e.g., `SAPRequestBodyPreparer`).

**Example Record**:

|Field	|Value	|
|---	|---	|
|SystemType__c	|SAP	|
|DataFetcherClassName__c	|SAPDataFetcher	|
|RequestBodyPreparerClassName__c	|SAPRequestBodyPreparer	|

## Usage Examples

### Apex Invocation

```

String systemType = 'SAP';
String orchestrationItemId = 'a34ab0000000000AAA';
Map<String, Object> response = SystemIntegrationHelper.generateRequestBody(systemType, orchestrationItemId);
System.debug('response: '+JSON.serialize(response));

```

### Integration Procedure invocation

**Remote Action**: Use `IntegrationProcedureUtility` as the Apex class in the Integration Procedure.
**Input Map**:

```
{
  "input": {
    "systemType": "SAP",
    "orchestrationItemId": "a34bW0000009hHSQAY"
  },
  "output": {},
  "options": {}
}
```

## Extensibility

To add a new integration (e.g., 'Nokia'):

1. Create `NokiaDataFetcher` extending `CommonDataFetcher`.
2. Create `NokiaRequestBodyPreparer` implementing `IRequestBodyPreparer` (and optionally `IDataValidator`).
3. Add a record to `SystemIntegrationConfig__mdt`: 

 

> SystemType__c: Nokia
 DataFetcherClassName__c: NokiaDataFetcher
 RequestBodyPreparerClassName__c: NokiaRequestBodyPreparer

 

1. Invoke via `SystemIntegrationHelper.generateRequestBody('Nokia', orchestrationItemId)`.

## Assumptions and Constraints

### Assumptions

*  `SystemIntegrationConfig__mdt` is populated with valid class names & System Type.

### Constraints

* Classes must be global or public for factory instantiation.
* Validation is optional and depends on `IDataValidator` implementation.
* Can’t accepts any other input apart from Orchestration Item Id & System Type.

## Future Enhancements

* Include logging mechanisms for debugging.
* Provide mechanism to pass additional information to framework from the caller.

## Resources

### Class Diagram UML

Copy below UML metadata and Paste it to https://editor.plantuml.com/ to customise the class diagram for your requirement.

```
@startuml
!theme mars
' Skin parameters for better readability
skinparam monochrome true
skinparam classAttributeIconSize 0
skinparam padding 2

' Interfaces
package "Interfaces" {
  interface IDataFetcher {
    +fetchData(orchestrationItemId: String): Map<String, Object>
  }

  interface IDataValidator {
    +validateData(data: Map<String, Object>): List<String>
  }

  interface IRequestBodyPreparer {
    +prepareRequestBody(data: Map<String, Object>): Map<String, Object>
  }

  interface Callable {
    +call(action: String, args: Map<String, Object>): Object
  }
}

' Abstract Class
package "Abstract Class" {
  abstract class CommonDataFetcher {
    +{abstract} fetchData(orchestrationItemId: String): Map<String, Object>
    +fetchCommonData(orchestrationItemId: String): Map<String, Object>
  }
}

' Factory Classes
package "Factory Classes" {
  class RequestBodyPreparerFactory {
    +{static} getPreparer(systemType: String): IRequestBodyPreparer
  }

  class DataFetcherFactory {
    +{static} getFetcher(systemType: String): IDataFetcher
  }
}

' Helper Classes
package "Helper Classes" {
  class SystemIntegrationHelper {
    +{static} generateRequestBody(systemType: String, orchestrationItemId: String): Map<String, Object>
  }
}

' Utility Classes
package "Utility Classes" {
  class IntegrationProcedureUtility {
    +call(action: String, args: Map<String, Object>): Object
  }
}

' Implementation Classes (e.g., SAP Integration)
package "Implementation Classes" {
  class SAPDataFetcher {
    +fetchData(orchestrationItemId: String): Map<String, Object>
  }

  class SAPRequestBodyPreparer {
    +prepareRequestBody(data: Map<String, Object>): Map<String, Object>
    +validateData(data: Map<String, Object>): List<String>
  }
}

' Relationships
' Interface Implementations
IDataFetcher <|.. CommonDataFetcher
CommonDataFetcher <|-- SAPDataFetcher
IRequestBodyPreparer <|.. SAPRequestBodyPreparer
IDataValidator <|.. SAPRequestBodyPreparer
Callable <|.. IntegrationProcedureUtility

' Dependencies and Associations
DataFetcherFactory --> IDataFetcher : produces
RequestBodyPreparerFactory --> IRequestBodyPreparer : produces
SystemIntegrationHelper --> DataFetcherFactory : uses
SystemIntegrationHelper --> RequestBodyPreparerFactory : uses
IntegrationProcedureUtility --> SystemIntegrationHelper : delegates to
SAPDataFetcher --> CommonDataFetcher : calls fetchCommonData()

' Notes for Context
note right of RequestBodyPreparerFactory
  Uses SystemIntegrationConfig__mdt
  to instantiate preparer classes
end note

note right of DataFetcherFactory
  Uses SystemIntegrationConfig__mdt
  to instantiate fetcher classes
end note

note right of SystemIntegrationHelper
  Orchestrates:
  1. Fetch data via IDataFetcher
  2. Validate via IDataValidator (if applicable)
  3. Prepare request via IRequestBodyPreparer
end note

note right of IntegrationProcedureUtility
  Entry point for integration procedure,
  leverages SystemIntegrationHelper
end note

note right of SAPDataFetcher
  Extends CommonDataFetcher,
  customizes data fetching for SAP
end note

note right of SAPRequestBodyPreparer
  Prepares SAP-specific request body,
  validates data as needed
end note
@enduml
```

### Code Repository

