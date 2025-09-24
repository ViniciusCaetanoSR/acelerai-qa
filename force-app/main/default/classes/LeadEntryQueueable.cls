public without sharing class LeadEntryQueueable implements Queueable {
    @TestVisible private List<Lead> leadsToInsert;
    @TestVisible private List<LeadEntry__c> entriesInOrder;

    public LeadEntryQueueable(List<Lead> leadsToInsert, List<LeadEntry__c> entriesInOrder) {
        this.leadsToInsert = leadsToInsert;
        this.entriesInOrder = entriesInOrder;
    }

    public void execute(QueueableContext context) {
        List<LeadEntry__c> entriesToUpdate = new List<LeadEntry__c>();
        try {
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, leadsToInsert);
            Database.SaveResult[] results = Database.insert(decision.getRecords(), false);
            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult sr = results[i];
                LeadEntry__c entry = entriesInOrder[i];
                if (sr.isSuccess()) {
                    entry.Lead__c = sr.getId();
                    entriesToUpdate.add(entry);
                } else {
                    LoggerUtility.createLog(
                        'Failed to create Lead for LeadEntry__c ID: ' + entry.Id + ': ' + sr.getErrors()[0].getMessage(),
                        'LeadEntryQueueable.execute'
                    );
                }
            }

            if (!entriesToUpdate.isEmpty()) {
                Database.SaveResult[] updateResults = Database.update(entriesToUpdate, false);
                for (Integer j = 0; j < updateResults.size(); j++) {
                    Database.SaveResult ur = updateResults[j];
                    if (!ur.isSuccess()) {
                        LoggerUtility.createLog(
                            'Failed to update LeadEntry__c ID: ' + entriesToUpdate[j].Id + ': ' + ur.getErrors()[0].getMessage(),
                            'LeadEntryQueueable.execute'
                        );
                    }
                }
            }
        } catch (Exception e) {
            LoggerUtility.createLogException(e, null, 'LeadEntryQueueable.execute');
        }
    }
}