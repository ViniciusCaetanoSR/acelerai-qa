@isTest
public with sharing class LeadEntryQueueableTest {
    @TestSetup
    static void makeData(){        
        Lead lead = new Lead (
            LastName = 'LeadLuck',
            Email = 'lead@luck.com',
            Phone = '5551981617448'
        );
        insert lead;

        LeadEntry__c leadentry = new LeadEntry__c(
            Email__c = 'leadENTRY@luck.com',
            Phone__c = '5551981617448'
        );
        insert leadentry;
    }
    
    @isTest
    static void testeLeadEntryQueuable(){
        List<Lead> leadsToInsert = new List<Lead>();
        List<LeadEntry__c> entriesInOrder = new List<LeadEntry__c>();

        Lead lead = [SELECT Id From Lead WHERE Email LIKE '%@luck.com' LIMIT 1];
        leadsToInsert.add(lead);

        LeadEntry__c leadentry = [SELECT Id FROM LeadEntry__c WHERE Email__c LIKE '%@luck.com'];
        entriesInOrder.add(leadentry);

        LeadEntryQueueable leQueueable = new LeadEntryQueueable(leadsToInsert, entriesInOrder);
        System.assertEquals(leadsToInsert, leQueueable.leadsToInsert, 'A lista de leads nao foi construida');
        System.assertEquals(entriesInOrder, leQueueable.entriesInOrder, 'A lista de lead entries nao foi construida');
    }

    @isTest
    static void testExecute(){
        List<Lead> leadsToInsert = new List<Lead>();
        List<LeadEntry__c> entriesInOrder = new List<LeadEntry__c>();

        Lead lead = new Lead (
            Email = 'lead2@luck.com',
            LastName = 'LeadLuck2',
            Phone = '5551981617448'
        );
        leadsToInsert.add(lead);

        LeadEntry__c leadentry = new LeadEntry__c(
            Email__c = 'leadENTRY@luck.com',
            Phone__c = '5551981617448'
        );
        entriesInOrder.add(leadentry);
        insert entriesInOrder;
        
        Test.startTest();
        LeadEntryQueueable leQueueable = new LeadEntryQueueable(leadsToInsert, entriesInOrder);
        System.enqueueJob(leQueueable);
        Test.stopTest();

        List<Lead> insertedLeads = [SELECT Id FROM Lead WHERE Email = 'lead2@luck.com'];
        System.assertEquals(1, insertedLeads.size());

        List<LeadEntry__c> updatedLE = [SELECT Id, Lead__c FROM LeadEntry__c WHERE Lead__c = :insertedLeads[0].Id];
        System.assertEquals(1, updatedLE.size());
    }   
    
    /**
     * 
     * Ainda falta criar o teste de falha com criação de log para poder cobrir 75%, por enquanto só cobre 70%
     * 
     */
    // @IsTest
    // static void testExecute_Failure() {
    //     /*Lead invalidLead = new Lead(
    //         LastName = 'InvalidLead'
    //     );
    //     LeadEntry__c testEntry = [SELECT Id FROM LeadEntry__c LIMIT 1];*/

    //     Test.startTest();
    //     LeadEntryQueueable leQueueable = new LeadEntryQueueable(
    //         new List<Lead>(),
    //         new List<LeadEntry__c>()
    //     );
    //     System.enqueueJob(leQueueable);
    //     Test.stopTest();

    //     List<Log__c> logs = [SELECT Id, ErrorMessage__c FROM Log__c WHERE MethodName__c = 'LeadEntryQueueable.execute'];

    //     System.assertEquals(1, logs.size(), 'Nao criou o log');
    //     System.assert(logs[0].ErrorMessage__c.contains('Failed to create Lead'), 'A mensagem está errada');
    // }
}