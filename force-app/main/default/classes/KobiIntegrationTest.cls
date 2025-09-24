@isTest
public class KobiIntegrationTest {

    @isTest
    static void callingKobiIntegrationSuccess() {

        User kobiUser = [SELECT Id, Alias FROM USER
        WHERE Alias = 'kobi'
        LIMIT 1];

        if(kobiUser == null) {
            System.assert(false, 'User Kobi não encontrado.');
        }

        List<Lead> testLeads = new List<Lead>();
        
        Lead leadKobi = new Lead(
            FirstName = 'Lead',
            LastName = 'Test',
            Company = 'TestCompany',
            OwnerId = kobiUser.Id);
            
        Lead leadOther = new Lead(
            FirstName = 'Lead',
            LastName = 'Test',
            Company = 'TestCompany',
            OwnerId = UserInfo.getUserId());
            
        testLeads.add(leadKobi);
        testLeads.add(leadOther);
        
        Test.startTest();
        try{
            insert testLeads;
            KobiIntegration.callKobiIntegration(testLeads);

            } catch (Exception e) {
                System.debug('Erro na chamada (testSuccess): ' + e.getMessage());
                System.assert(false, 'Erro na chamada da integração: ' + e.getMessage());
        }
        Test.stopTest();

        List<Lead> kobiLeads = [SELECT Id FROM Lead WHERE OwnerId = :kobiUser.Id];
        System.assertEquals(1, kobiLeads.size());
        System.debug('O Id de kobiLeads é (testSuccess): ' + kobiLeads[0].Id);
    }

    @isTest
    static void callingKobiIntegrationNoLeads() {
        List<Lead> emptyLeads = new List<Lead>();

        try {
        Test.startTest();
        KobiIntegration.callKobiIntegration(emptyLeads);
        Test.stopTest();           
        
        } catch (Exception e) {
            System.assertEquals('Nenhum lead encontrado', e.getMessage());
        }
    }

    @isTest
    static void callingKobiIntegrationNoUser() {

        List<Lead> leadsList = new List<Lead>();

        Lead leadOther = new Lead(
            FirstName = 'Lead',
            LastName = 'Test',
            Company = 'TestCompany',
            OwnerId = UserInfo.getUserId());

        leadsList.add(leadOther);

        try {
        Test.startTest();
        KobiIntegration.callKobiIntegration(leadsList);
        Test.stopTest();           
        
        } catch (Exception e) {
            System.assertEquals('Usuário Kobi não foi encontrado.', e.getMessage());
        }
    }
}