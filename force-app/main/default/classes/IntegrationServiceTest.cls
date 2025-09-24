@isTest
private class IntegrationServiceTest {

    @testSetup
    static void setup() {
        // Configurar dados de teste para ApiSettings__c
        ApiSettings__c settings = new ApiSettings__c();
        settings.Name = 'Kobi';
        settings.BaseUrl__c = 'https://api.kobi.com/v1/leads';
        insert settings;

        // Configurar dados de teste para Lead
        Lead lead1 = new Lead(FirstName = 'John', LastName = 'Doe', Phone = '123456789', Company = 'Test Company');
        Lead lead2 = new Lead(FirstName = 'Jane', LastName = 'Smith', Phone = '987654321', Company = 'Test Company');
        insert new List<Lead>{lead1, lead2};
    }

    @isTest
    static void testSendDataKobiSuccess() {
        // Simular resposta de sucesso
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody('{"message": "Integração bem-sucedida!"}');
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(response));

        List<Lead> leads = [SELECT Id, FirstName, Name, LastName, Phone, Company FROM Lead];
        String leadsJson = JSON.serialize(leads);
        IntegrationService.sendDataKobi(leadsJson);

        System.assertEquals(200, response.getStatusCode());        
    }

    @isTest
    static void testSendDataKobiError() {
        // Simular resposta de erro
        HttpResponse response = new HttpResponse();
        response.setStatusCode(400);
        response.setBody('{"message": "Erro na integração"}');
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(response));

        List<Lead> leads = [SELECT Id, FirstName, LastName, Name, Phone, Company FROM Lead];
        String leadsJson = JSON.serialize(leads);
        IntegrationService.sendDataKobi(leadsJson);

        System.assertEquals(400, response.getStatusCode());     
    }

    @isTest
    static void testSendDataKobiCalloutException() {
        // Simular exceção de chamada HTTP
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(null, true));

        List<Lead> leads = [SELECT Id, FirstName, LastName, Name, Phone, Company FROM Lead];
        String leadsJson = JSON.serialize(leads);

        try {
            IntegrationService.sendDataKobi(leadsJson);

        } catch (CalloutException e) {
            System.assertEquals('{"message": "Erro na chamada HTTP"}', e.getMessage());
        }         
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse response;
        private Boolean throwException;

        public MockHttpResponseGenerator(HttpResponse response, Boolean throwException) {
            this.response = response;
            this.throwException = throwException;
        }

        public MockHttpResponseGenerator(HttpResponse response) {
            this(response, false);
        }

        public HttpResponse respond(HttpRequest req) {
            if (throwException) {
                throw new CalloutException('Simulated callout exception');
            }
            return response;
        }
    }
}