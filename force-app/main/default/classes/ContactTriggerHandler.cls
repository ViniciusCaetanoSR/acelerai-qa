public with sharing class ContactTriggerHandler {

    public static void onBeforeInsert(Map<Id, Contact> newMap, Map<Id, Contact> oldMap, List<Contact> newList, List<Contact> oldList) {
        ContactService.validatePhoneAndFormatPhone(newList);
    }

    public static void onBeforeUpdate(Map<Id, Contact> newMap, Map<Id, Contact> oldMap, List<Contact> newList, List<Contact> oldList) {
        ContactService.validatePhoneAndFormatPhone(newList);
    }
}