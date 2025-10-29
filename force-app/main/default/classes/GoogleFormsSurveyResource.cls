@RestResource(urlMapping='/forms/*')
global with sharing class GoogleFormsSurveyResource {

    @HttpPost
    global static String createCustomSurveyGoogleForms() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String retorno;

        if (req.requestBody == null || String.isBlank(req.requestBody.toString())) {
            res.statusCode = 400;
            return 'A requisição é inválida';
        }

        try {
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

            String surveyName = (String) payload.get('Name');
            List<Object> questionsResponsesList = (List<Object>) payload.get('questions');

            if (questionsResponsesList == null || questionsResponsesList.isEmpty()) {
                res.statusCode = 400;
                return 'É necessário enviar pelo menos uma pergunta e uma resposta';
            }

            System.debug('Debug x: questionsResponsesList: ' + JSON.serialize(questionsResponsesList));

            String opportunityId;

            List<SurveyQuestionResponse__c> sqResponses = new List<SurveyQuestionResponse__c>();

            Survey__c newSurvey = buildSurvey(surveyName, null);
            insert newSurvey;

            for (Object qObj : questionsResponsesList) {
                Map<String, Object> q = (Map<String, Object>) qObj;

                String nameQuestion = (String) q.get('nameQuestionForms');
                Object resp = q.get('response');

                if (nameQuestion == 'Id Oportunidade') {
                    opportunityId = String.valueOf(resp);
                    newSurvey.OpportunityId__c = opportunityId;
                }

                sqResponses.add(buildSurveyQuestionResponse(newSurvey, surveyName, nameQuestion, String.valueOf(resp)));

            }

            update newSurvey;

            if (!sqResponses.isEmpty()) {
                insert sqResponses;
            }

            res.statusCode = 201;
            retorno = 'Created';

        } catch (Exception e) {
            res.statusCode = 500;
            retorno = 'Erro interno no servidor. Detalhes: ' + e.getMessage();
        }

        System.debug('Retorno: ' + retorno);
        return retorno;
    }

    private static SurveyQuestionResponse__c buildSurveyQuestionResponse(Survey__c survey, String surveyName, String nameQuestion, String responseValue) {
        SurveyQuestionResponse__c surveyQuestionResponse = new SurveyQuestionResponse__c();
        surveyQuestionResponse.Survey__c = survey.Id;
        surveyQuestionResponse.Name = surveyName;
        surveyQuestionResponse.Question__c = nameQuestion;
        surveyQuestionResponse.Response__c = responseValue;
        return surveyQuestionResponse;
    }

    private static Survey__c buildSurvey(String surveyName, String opportunityId){
        Survey__c survey = new Survey__c();
        survey.Name = surveyName;
        survey.OpportunityId__c = opportunityId;
        return survey;
    }
}