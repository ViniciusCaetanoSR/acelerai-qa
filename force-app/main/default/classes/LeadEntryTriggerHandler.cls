/**
 * @description       : Handler class for LeadEntry__c trigger to manage lead creation and updates.
 * @author            : Vinícius Caetano
 * @last modified on  : 20-05-2025
 * @last modified by  : Vinícius Caetano
 **/
public with sharing class LeadEntryTriggerHandler {
    private static final LeadEntryService leadService = new LeadEntryService();

    public static void onBeforeInsert(List<LeadEntry__c> newRecords) {
    }

    public static void onBeforeUpdate(List<LeadEntry__c> newRecords, Map<Id, LeadEntry__c> oldMap) {
    }

    public static void onAfterInsert(List<LeadEntry__c> newRecords) {
        leadService.createLeadsFromEntries(newRecords);
    }

    public static void onAfterUpdate(List<LeadEntry__c> newRecords, Map<Id, LeadEntry__c> oldMap) {
    }
}