public without sharing class IntegrationService {

    public static String getBaseURL(String name) {
        ApiSettings__c settings = ApiSettings__c.getValues(name);
        System.debug('Retrieved settings: ' + settings);
        return settings.BaseUrl__c;
    }

    @future(callout=true)
    public static void sendDataKobi(String leadsJson) {

        List<Lead> leads = (List<Lead>) JSON.deserialize(leadsJson, List<Lead>.class);

        String endpoint;
        String requestBody;
        HttpRequest request;
        HttpResponse response;

        try {
            endpoint = getBaseURL('Kobi');
            System.debug('Endpoint URL: ' + endpoint);

            requestBody = KobiConstructRequestBody(leads);
            System.debug('Request Body: ' + requestBody);

            request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(requestBody);
            request.setTimeout(22000); 

            System.debug('Sending HTTP request: ' + request);
            response = new Http().send(request);
            System.debug('HTTP response: ' + response);

            if (response.getStatusCode() == 200) {
                System.debug('Response Status Code: ' + response.getStatusCode());
                System.debug('Integração bem-sucedida!');
            } else {
                System.debug('Response Status Code: ' + response.getStatusCode());
                System.debug('Response Body: ' + response.getBody());
                System.debug('Erro na integração: ' + response.getBody());
            }
        } catch (CalloutException e) {
            System.debug('CalloutException: ' + e.getMessage());
            System.debug('Erro na chamada HTTP: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            System.debug('Erro inesperado: ' + e.getMessage());
        }
    }
    
    private static String KobiConstructRequestBody(List<Lead> leads) {

        List<Map<String, Object>> leadsList = new List<Map<String, Object>>();
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        String name = '';
        
        requestBodyMap.put('accessToken', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOiIzMjNkNmJhYS00ZDc2LTQxNTYtOTFjZS0zZGExNjhkYmIyMWUiLCJlbWFpbCI6Im1hdGhldXMuYmFycm9zQGFjZWxlcmFpLmNvbS5iciIsImNyZWF0ZWRBdCI6IjIwMjQtMDctMjVUMjE6MzE6NTIuMDAwWiIsInVwZGF0ZWRBdCI6IjIwMjQtMDctMjVUMjE6MzE6NTIuMDAwWiIsImlhdCI6MTcyMjM0NjgyMiwic3ViIjoiMzIzZDZiYWEtNGQ3Ni00MTU2LTkxY2UtM2RhMTY4ZGJiMjFlIn0.yYkHYJ2kvdKCY0cci3okssCx5vSumlCSAsR5Xl3h0HA'); // Token de acesso
        requestBodyMap.put('userUid', '323d6baa-4d76-4156-91ce-3da168dbb21e');
        requestBodyMap.put('assistantUid', '29501b01-b99e-414c-94e9-31e8a65b854b');
        requestBodyMap.put('eventUid', '92343297423947329847234389234');
        requestBodyMap.put('connectorUid', 'add1ce28-7d1d-4911-a6cb-330b1c47aa7f');
        requestBodyMap.put('message', 'Bom dia, tudo bem? Esse é um teste');

        for (Lead lead : leads) {

            Map<String, Object> leadMap = new Map<String, Object>();
            Map<String, String> phoneMap = new Map<String, String>();

            name = String.isNotBlank(lead.FirstName) ? lead.FirstName : lead.LastName;

            leadMap.put('externalId', lead.Id);
            leadMap.put('name', name);
            phoneMap.put('countryCode', '55');
            phoneMap.put('number', removeCountryCode(lead.Phone));
            leadMap.put('phone', phoneMap);
            leadsList.add(leadMap);
        }
    
        requestBodyMap.put('leads', leadsList);
    
        String serializedRequestBody = JSON.serialize(requestBodyMap);
        System.debug('Constructed Request Body: ' + serializedRequestBody);
        return serializedRequestBody;
    }
    
    

    public static void sendDataKobiWrapper(List<Lead> leads) {
        String leadsJson = JSON.serialize(leads);
        sendDataKobi(leadsJson);
    }

    public static String removeCountryCode(String phoneNumber) {

        if (phoneNumber != null && phoneNumber.startsWith('+')) {
            phoneNumber = phoneNumber.substring(1);
        }

        return phoneNumber;
    }
}