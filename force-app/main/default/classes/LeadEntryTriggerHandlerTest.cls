@isTest
public class LeadEntryTriggerHandlerTest {

    @isTest
    static void testOnAfterInsert() {
        List<LeadEntry__c> entries = new List<LeadEntry__c>();

        entries.add(new LeadEntry__c(
            Name = 'João 1',
            Email__c = 'joao1@joaoperformance.com',
            Phone__c = '51981617948'
        ));

        entries.add(new LeadEntry__c(
            Name = 'João 2',
            Email__c = 'joao2@joaoperformance.com',
            Phone__c = '51981617949'
        ));

        Test.startTest();
        insert entries; 
        Test.stopTest();

        List<Lead> createdLeads = [
            SELECT Id, Email FROM Lead
            WHERE Email IN ('joao1@joaoperformance.com', 'joao2@joaoperformance.com')
        ];

        System.assertEquals(2, createdLeads.size(), 'Deveria ter criado 2 leads ');
    }
}