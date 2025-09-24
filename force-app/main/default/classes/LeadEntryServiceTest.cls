@isTest
public with sharing class LeadEntryServiceTest {
   
    @isTest
    static void testProcessLeads(){
        List<Map<String, String>> leadsData = new List<Map<String, String>>();

        for(Integer i = 0; i < 5; i++){
            Map<String, String> rowLeads = new Map<String,String>();
            rowLeads.put('Name', 'João' + i);
            rowLeads.put('Email', 'joao' + i + '@performance.br');
            rowLeads.put('Phone', '5198161794' + i);

            leadsData.add(rowLeads);
        }

        Test.startTest();
        List<LeadEntry__c> result = LeadEntryService.processLeads(leadsData);
        Test.stopTest();

        System.assertEquals(5, result.size(), 'Não processou os 5 LeadEntry__c');

        for (LeadEntry__c entry : result) {
            System.assertNotEquals(null, entry.Name, 'O nome está nulo');
            System.assertNotEquals(null, entry.Email__c, 'O email está nulo');
            System.assertNotEquals(null, entry.Phone__c, 'O telefone está nulo');
        }

        List<LeadEntry__c> inserted = [SELECT Id, Name, Email__c FROM LeadEntry__c];
        System.assertEquals(5, inserted.size(), 'Não inseriu 5 registros');
    }

    @isTest
    static void testProcessLeadsWithEmptyList() {
        List<Map<String, String>> emptyLeadsData = new List<Map<String, String>>();
        
        Test.startTest();
        List<LeadEntry__c> result = LeadEntryService.processLeads(emptyLeadsData);
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Não retornou uma lista vazia como deveria');
    }

    @isTest
    static void testImportLeads(){
      List<LeadEntry__c> leadsToImport = new List<LeadEntry__c>();

        for(Integer i = 0; i < 2; i++){
            LeadEntry__c leadEntry = new LeadEntry__c (
                Name = 'Lead' + i,
                Email__c = 'lead' + i + '@performance.br.58',
                Phone__c = '5198161794' + i
            );

            leadsToImport.add(leadEntry);
        }

        Test.startTest();
        LeadEntryService.importLeads(leadsToImport);
        Test.stopTest();

        List<LeadEntry__c> insertedLeadEntries = [SELECT Id, Email__c FROM LeadEntry__c WHERE Email__c LIKE '%@performance.br.58'];

        System.assertEquals(2, insertedLeadEntries.size(), 'não inseriu 2 lead entry');        
    }

    @isTest
    static void testCreateLeadsFromEntries(){
        List<LeadEntry__c> entries = new List<LeadEntry__c>();

        for(Integer i = 0; i < 2; i++){
            LeadEntry__c leadEntry = new LeadEntry__c (
                Name = 'Lead' + i,
                Email__c = 'lead' + i + '@performance.br.59',
                Phone__c = '5198161794' + i
            );

            entries.add(leadEntry);
        }
        
        LeadEntryService service = new LeadEntryService();

        Test.startTest();
        service.createLeadsFromEntries(entries);
        Test.stopTest();

        List<Lead> insertedLeads = [SELECT Id, Email FROM Lead WHERE Email LIKE '%@performance.br.59'];
        System.assertEquals(2, insertedLeads.size(), 'Não inseriu 2 leads'); 
    }  

    @isTest
    static void testCreateLeadsFromEntriesWithEmptyList() {
        List<LeadEntry__c> emptyLeadsData = new List<LeadEntry__c>();
        
        LeadEntryService service = new LeadEntryService();

        Test.startTest();
        service.createLeadsFromEntries(emptyLeadsData);
        Test.stopTest();
        
        List<Lead> insertedLeads = [SELECT Id, Email FROM Lead];
        System.assertEquals(0, insertedLeads.size(), 'Não retornou uma lista vazia como deveria'); 
    }
}