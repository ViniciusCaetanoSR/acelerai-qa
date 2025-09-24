/**
 * @description       : Service class to manage Lead creation from LeadEntry__c records.
 * @author            : Vinícius Caetano
 * @last modified on  : 21-05-2025
 * @last modified by  : Vinícius Caetano
 **/
public without sharing class LeadEntryService {
    @AuraEnabled
    public static List<LeadEntry__c> processLeads(List<Map<String, String>> leadsData) {
        System.debug('processLeads | input size: ' + (leadsData == null ? 0 : leadsData.size()));

        if (leadsData == null || leadsData.isEmpty()) {
            return new List<LeadEntry__c>();
        }

        List<LeadEntry__c> leadsToProcess = new List<LeadEntry__c>();
        Id partnerAccountId = getPartnerAccountId();
        System.debug('processLeads | partnerAccountId: ' + partnerAccountId);

        //Id defaultOwnerId = getDefaultOwnerId('Lead');
        //System.debug('processLeads | defaultOwnerId:  ' + defaultOwnerId);

        try {
            for (Map<String, String> row : leadsData) {
                System.debug('processLeads | row: ' + row);

                LeadEntry__c entry = new LeadEntry__c();
                entry.Name = row.get('Name') != null ? row.get('Name').trim() : null;
                entry.Email__c = row.get('Email') != null ? row.get('Email').trim() : null;
                entry.Phone__c = row.get('Phone') != null ? row.get('Phone').trim() : null;
                entry.PartnerAccount__c = partnerAccountId;
                //if (defaultOwnerId != null)
                    //entry.OwnerId = defaultOwnerId;

                leadsToProcess.add(entry);
            }
            System.debug('processLeads | prepared: ' + leadsToProcess.size());

            if (!leadsToProcess.isEmpty()) {
                Database.SaveResult[] srList = Database.insert(leadsToProcess, /* allOrNone = */ false);

                for (Integer i = 0; i < srList.size(); i++) {
                    if (!srList[i].isSuccess()) {
                        System.debug(LoggingLevel.ERROR, 'processLeads | DML error on row ' + i + ' | ' + srList[i].getErrors()[0].getMessage());
                    }
                }
            }
            return leadsToProcess;
        } catch (Exception e) {
            LoggerUtility.createLogException(e, null, 'LeadEntryService.processLeads');
            throw new AuraHandledException('Erro ao processar os leads: ' + e.getMessage());
        }
    }

    private static Id getPartnerAccountId() {
        System.debug('getPartnerAccountId');

        try {
            User u = [
                SELECT ContactId, AccountId
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            if (u.ContactId == null)
                return null;

            Account acc = [
                SELECT Id
                FROM Account
                WHERE Id = :u.AccountId AND IsPartner = TRUE
                LIMIT 1
            ];
            System.debug('getPartnerAccountId | acc: ' + acc);
            return acc == null ? null : acc.Id;
        } catch (Exception e) {
            LoggerUtility.createLogException(e, null, 'LeadEntryService.getPartnerAccountId');
            throw new AuraHandledException('Erro ao buscar Partner Account: ' + e.getMessage());
        }
    }

    private static Id getDefaultOwnerId(String objectName) {
        System.debug('getDefaultOwnerId | object: ' + objectName);

        Default_Object_Owner__mdt cfg = [
            SELECT OwnerId__c
            FROM Default_Object_Owner__mdt
            WHERE ObjectName__c = :objectName
            LIMIT 1
        ];
        Id ownerId = cfg != null && String.isNotBlank(cfg.OwnerId__c) ? Id.valueOf(cfg.OwnerId__c) : null;
        System.debug('getDefaultOwnerId | ownerId: ' + ownerId);
        return ownerId;
    }

    @AuraEnabled
    public static String importLeads(List<LeadEntry__c> leadsToImport) {
        System.debug('importLeads | input size: ' + (leadsToImport == null ? 0 : leadsToImport.size()));

        try {
            List<LeadEntry__c> news = new List<LeadEntry__c>();
            List<LeadEntry__c> upds = new List<LeadEntry__c>();

            for (LeadEntry__c le : leadsToImport) {
                if (le.Id == null)
                    news.add(le);
                else
                    upds.add(le);
            }
            System.debug('importLeads | new: ' + news.size() + ' | upd: ' + upds.size());

            if (!news.isEmpty()) {
                insert news;
                System.debug('importLeads | inserted: ' + news.size());
            }
            if (!upds.isEmpty()) {
                update upds;
                System.debug('importLeads | updated:  ' + upds.size());
            }
            return String.valueOf(leadsToImport);
        } catch (Exception e) {
            LoggerUtility.createLogException(e, null, 'LeadEntryService.importLeads');
            throw new AuraHandledException(e.getMessage());
        }
    }

    public void createLeadsFromEntries(List<LeadEntry__c> entries) {
        System.debug('createLeadsFromEntries | input size: ' + (entries == null ? 0 : entries.size()));
        if (entries == null || entries.isEmpty())
            return;

        Id ownerId = getDefaultOwnerId('Lead');
        Id partnerAccountId = [
                SELECT Contact.AccountId
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ]
            .Contact
            ?.AccountId;
        System.debug('createLeadsFromEntries | ownerId: ' + ownerId + ' | partnerAccountId: ' + partnerAccountId);

        List<Lead> leadsToInsert = new List<Lead>();
        List<LeadEntry__c> entriesInOrder = new List<LeadEntry__c>();
        List<LeadEntry__c> entriesNeedingUpdate = new List<LeadEntry__c>();

        for (LeadEntry__c e : entries) {
            if (String.isBlank(e.Email__c)) {
                System.debug('createLeadsFromEntries | skip (blank email) ' + e);
                continue;
            }
            entriesInOrder.add(new LeadEntry__c(Id = e.Id)); // clone for update

            if (partnerAccountId != null && e.PartnerAccount__c == null) {
                e.PartnerAccount__c = partnerAccountId;
                entriesNeedingUpdate.add(e);
            }

            leadsToInsert.add(
                new Lead(
                    LastName = e.Name,
                    Email = e.Email__c,
                    Phone = e.Phone__c,
                    PartnerAccount__c = e.PartnerAccount__c,
                    LeadSource = 'Aceleraí Performance',
                    OwnerId = ownerId
                )
            );
        }
        System.debug('createLeadsFromEntries | leadsToInsert: ' + leadsToInsert.size());

        if (leadsToInsert.isEmpty())
            return;

        try {
            System.enqueueJob(new LeadEntryQueueable(leadsToInsert, entriesInOrder));
        } catch (Exception e) {
            LoggerUtility.createLogException(e, null, 'LeadEntryService.createLeadsFromEntries');
        }
    }
}