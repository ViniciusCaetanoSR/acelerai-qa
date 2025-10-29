@IsTest
private class GoogleFormsSurveyResourceTest {

    @IsTest
    static void testRequestWithoutBody() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = null;
        RestContext.request = req;
        RestContext.response = res;

        String result = GoogleFormsSurveyResource.createCustomSurveyGoogleForms();

        System.assertEquals('A requisição é inválida', result);
        System.assertEquals(400, res.statusCode);
    }

    @IsTest
    static void testRequestWithoutQuestions() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        String payload = '{"Name": "Pesquisa Teste", "questions": []}';

        req.requestBody = Blob.valueOf(payload);
        RestContext.request = req;
        RestContext.response = res;

        String result = GoogleFormsSurveyResource.createCustomSurveyGoogleForms();

        System.assertEquals('É necessário enviar pelo menos uma pergunta e uma resposta', result);
        System.assertEquals(400, res.statusCode);
    }

    @IsTest
    static void testValidRequest() {

        Account accountTest = VirtualTestData.createAccount('accountName');
        insert accountTest;

        Contact contactTest = VirtualTestData.createContact('lastName', accountTest.Id, 'test@example.com', '77673267632763');
        insert contactTest;

        Opportunity opportunity = VirtualTestData.createOpportunity(
            'opportunityName',
            accountTest.Id,
            '674867536768',
            'Financeiro',
            'clientType',
            Date.today().addDays(7),
            'Em Negociação'
        );
        opportunity.Tipo_de_Cliente__C = 'Cliente final';
        insert opportunity;

        String opportunityId = opportunity.Id;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        String payload = '{"Name": "Pesquisa Teste", "questions": [' +
                 '{"nameQuestionForms": "Id Oportunidade", "response": "'+ opportunityId +'"},' +
                 '{"nameQuestionForms": "Email", "response": "teste@iago.com"}]}';

        req.requestBody = Blob.valueOf(payload);
        RestContext.request = req;
        RestContext.response = res;

        String result = GoogleFormsSurveyResource.createCustomSurveyGoogleForms();

        System.assertEquals('Created', result);
        System.assertEquals(201, res.statusCode);

        List<Survey__c> surveys = [SELECT Id, Name, OpportunityId__c FROM Survey__c WHERE Name = 'Pesquisa Teste'];
        System.assertEquals(1, surveys.size());
        System.assertEquals(opportunityId, surveys[0].OpportunityId__c);

        List<SurveyQuestionResponse__c> responses = [SELECT Id, Question__c, Response__c FROM SurveyQuestionResponse__c WHERE Survey__c = :surveys[0].Id];
        System.assertEquals(2, responses.size());
    }

    @IsTest
    static void testMalformedJsonRequest() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        String payload = '{"Name": "Pesquisa Teste", "questions": [ {"nameQuestionForms": "Teste", "response": } ]}';

        req.requestBody = Blob.valueOf(payload);
        RestContext.request = req;
        RestContext.response = res;

        String result = GoogleFormsSurveyResource.createCustomSurveyGoogleForms();

        System.assert(result.contains('Erro interno no servidor'));
        System.assertEquals(500, res.statusCode);
    }
}