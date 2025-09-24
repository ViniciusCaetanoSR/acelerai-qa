/**
 * @description       :
 * @author            : Vinícius Caetano
 * @group             :
 * @last modified on  : 31-03-2025
 * @last modified by  : Vinícius Caetano
**/
public with sharing class OpportunityTriggerHandler {
    public static void onBeforeInsert(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap, List<Opportunity> newList, List<Opportunity> oldList) {
        OpportunityService.validatePhoneNumber(newList);
        OpportunityService.handleBeforeClone(newList);
    }

    public static void onBeforeUpdate(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap, List<Opportunity> newList, List<Opportunity> oldList) {
        OpportunityService.validatePhoneNumber(newList);
        OpportunityService.validateOpportunityStageChangeGanho(newList, oldMap);
        OpportunityService.sendEmailProductInactive(newList, oldMap);
    }

    public static void onAfterInsert(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap, List<Opportunity> newList, List<Opportunity> oldList) {
        OpportunityService.handleBeforeCloneContact(newList);
        OpportunityService.updateAccountDates(newList);
        OpportunityService.setContactIdWhenEmpty(newList);
    }

    public static void onAfterUpdate(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap, List<Opportunity> newList, List<Opportunity> oldList) {
        OpportunityService.updateAccountDates(newList);
        OpportunityService.opportunityMetaIntegration(newList, oldMap);
        OpportunityService.handleOpportunityChanges(newList, oldMap);
    }
}