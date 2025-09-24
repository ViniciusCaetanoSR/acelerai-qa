public without sharing class QuoteService {
    private static Map<String, Schema.RecordTypeInfo> opportunityRecordTypesMap = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();

    public static void syncQuoteWithOpportunity(Map<Id, Quote> newMap, Map<Id, Quote> oldMap) {
        System.debug('syncQuoteWithOpportunity,oldMap: ' + oldMap);    
        Set<Id> quoteIds = new Set<Id>();
        Set<Id> opportunityIds = populateOppIdsSetWithQuoteOpportunity(newMap.values());

        // /////////////////////////
        // List<Quote> oldQuotesIdsList = new List<Quote>();

        // for (Quote currentQuote : newMap.values()) {
        //     Quote oldQuoteId = oldMap.get(currentQuote.Id); //pega a old quote
        //     oldQuotesIdsList.add(oldQuoteId);           
        // }
        // System.debug('oldQuotesIdsList: ' + oldQuotesIdsList);
        
        // if(!oldQuotesIdsList.isEmpty()){ //pega o qli a partir da oldquote
        //     List<QuoteLineItem> qliFromOldQuote = [SELECT Id, Quantity, UnitPrice, QuoteId, Product2Id FROM QuoteLineItem WHERE QuoteId IN :oldQuotesIdsList];    
        //     System.debug('qliFromOldQuote: ' + qliFromOldQuote);
        
        //     List<QuoteLineItem> qliFromNewQuote = [SELECT Id, Quantity, UnitPrice, QuoteId, Product2Id FROM QuoteLineItem WHERE QuoteId IN :newMap.keySet()];
        //     System.debug('qliFromNewQuote: ' + qliFromNewQuote); //fazer o mesmo com o new quopte

        //     Map<Id, Map<Id, QuoteLineItem>> oldQLIsByProduct = new Map<Id, Map<Id, QuoteLineItem>>(); //armazenar o id da quote e um map de id e qli
        //     Map<Id, Map<Id, QuoteLineItem>> newQLIsByProduct = new Map<Id, Map<Id, QuoteLineItem>>();

        //     for(QuoteLineItem qli : qliFromOldQuote){
        //         if(!oldQLIsByProduct.containsKey(qli.QuoteId)){
        //             oldQLIsByProduct.put(qli.QuoteId, new Map<Id, QuoteLineItem>());
        //         }
        //         oldQLIsByProduct.get(qli.QuoteId).put(qli.Product2Id, qli); //armazenamos o oppLineItem e o qteLineItem
        //     }

        //     for(QuoteLineItem qli : qliFromNewQuote){ //pra cada qli do newMap
        //         if(!newQLIsByProduct.containsKey(qli.QuoteId)){
        //             newQLIsByProduct.put(qli.QuoteId, new Map<Id, QuoteLineItem>());
        //         }
        //         newQLIsByProduct.get(qli.QuoteId).put(qli.Product2Id, qli); //armazenamos o oppLineItem e o qteLineItem            
        //     }

        //     for(Id quoteId : newMap.keySet()){ //pra cada cot do new map
        //         if (newQLIsByProduct.containsKey(quoteId)){ //se a chave do map de newQLI existir
        //             System.debug('Está sendo atualizada | quoteId: ' + quoteId);
        //             Map<Id, QuoteLineItem> newProductsMap = newQLIsByProduct.get(quoteId); 
        //             System.debug('newProductsMap: ' + newProductsMap);

        //             Map<Id, QuoteLineItem> oldProductsMap = oldQLIsByProduct.get(quoteId);
        //             System.debug('oldProductsMap: ' + oldProductsMap);

                   
        //             if(oldProductsMap != null){
        //                 for(Id productId : newProductsMap.keySet()){
        //                     QuoteLineItem newQLI = newProductsMap.get(productId);
        //                     System.debug('newQLI: ' + newQLI);

        //                     QuoteLineItem oldQLI = oldProductsMap.get(productId);
        //                     System.debug('oldQLI: ' + oldQLI);

        //                     if(oldQLI != null){
        //                         if(oldQLI.Quantity != newQLI.Quantity) {
        //                             hasModifiedItems = true;
        //                             System.debug('Item modificado - Product: ' + productId);
        //                         }
        //                     }
        //                 }
        //             }
        //         }
        //     }
        // }
        //////////////////////////////////////
        Map<Id, Opportunity> quoteOppsMap = new Map<Id, Opportunity>([SELECT Id, Name, RecordTypeId FROM Opportunity WHERE Id IN :opportunityIds]);
        opportunityIds = new Set<Id>();

        for (Quote currentQuote : newMap.values()) {

            if (quoteOppsMap.get(currentQuote.OpportunityId).RecordTypeId == opportunityRecordTypesMap.get('MidiasVendas').getRecordTypeId())
                continue;

            Quote oldQuoteValue = oldMap.get(currentQuote.Id);

            Boolean quoteStatusChangedToPaymentDone = (currentQuote.Status.equals('PAGAMENTO_REALIZADO')) && currentQuote.Status != oldQuoteValue.Status;
            Boolean quoteFuturePaymentChangedToTrue = currentQuote.PagamentoFuturo__c != oldQuoteValue.PagamentoFuturo__c && currentQuote.PagamentoFuturo__c;

            if (quoteStatusChangedToPaymentDone && !currentQuote.Sincronizado__c) {
                currentQuote.Status = 'FINALIZADA';
                currentQuote.Sincronizado__c = true;
            }

            Boolean paymentDoneAndFuturePayment = quoteStatusChangedToPaymentDone && oldQuoteValue.PagamentoFuturo__c;
            Boolean paymentDoneAndFutureSale = quoteStatusChangedToPaymentDone && oldQuoteValue.VendaFutura__c;
            Boolean FuturePaymentChangedToTrueAndNotSynced = quoteFuturePaymentChangedToTrue && !oldQuoteValue.Sincronizado__c;
      
            if (quoteStatusChangedToPaymentDone || oldQuoteValue.PagamentoFuturo__c || paymentDoneAndFuturePayment || paymentDoneAndFutureSale || FuturePaymentChangedToTrueAndNotSynced) {

                quoteIds.add(oldQuoteValue.Id);
                opportunityIds.add(oldQuoteValue.OpportunityId);            
            } 
            
            Boolean hasModifiedItems = QuoteLineItemService.wasQuoteModified(currentQuote.Id);
            System.debug('hasModifiedItems ? ' + hasModifiedItems);   
            Boolean isEligibleForUpdate = (currentQuote.Sincronizado__c &&
            (currentQuote.PagamentoFuturo__c || currentQuote.VendaFutura__c)) || currentQuote.Sincronizado__c;
            System.debug('isEligibleForUpdate ? ' + isEligibleForUpdate);   

            if (hasModifiedItems && isEligibleForUpdate) {
                quoteIds.add(oldQuoteValue.Id);
                opportunityIds.add(oldQuoteValue.OpportunityId);
            }
        }

        try {
            OpportunityLineItemService.insertOrUpdateOpportunityLineItemsFromQuote(
                OpportunityLineItemSelector.selectByOpportunityId(opportunityIds),
                QuoteLineItemSelector.selectByQuoteId(quoteIds),
                opportunityIds
            );
            System.debug(' O syncQuoteWithOpportunity() da QuoteService chamou o OpportunityLineItemService.insertOrUpdateOpportunityLineItemsFromQuote com esses parâmetros: (' +  OpportunityLineItemSelector.selectByOpportunityId(opportunityIds) + ' , ' + QuoteLineItemSelector.selectByQuoteId(quoteIds) + ' , ' + opportunityIds + ')');

        } catch (Exception e){
            System.debug(' Exception no syncQuoteWithOpportunity: ' + e.getMessage());
            Throw e;
        }  
    }

    public static void deleteRemovedLineItemsAndUpdateOpportunityProducts(Map<Id, Quote> newMap, Map<Id, Quote> oldMap) {
        Set<Id> opportunityIds = populateOppIdsSetWithQuoteOpportunity(newMap.values());
        System.debug('Chamou o deleteRemovedLineItemsAndUpdateOpportunityProducts() da QuoteService');

        Map<Id, Opportunity> quoteOppsMap = new Map<Id, Opportunity>([SELECT Id, Name, RecordTypeId FROM Opportunity WHERE Id IN :opportunityIds]);

        opportunityIds = new Set<Id>();

        for (Quote currentQuote : newMap.values()) {
            if (quoteOppsMap.get(currentQuote.OpportunityId).RecordTypeId == opportunityRecordTypesMap.get('MidiasVendas').getRecordTypeId())
                continue;

            Quote oldQuoteValue = oldMap.get(currentQuote.Id);

            Boolean quoteDesynchronized = currentQuote.Sincronizado__c != oldMap.get(currentQuote.Id).Sincronizado__c && !currentQuote.Sincronizado__c;

            Boolean quoteFuturePaymentChangedToFalse = currentQuote.PagamentoFuturo__c != oldQuoteValue.PagamentoFuturo__c && !currentQuote.PagamentoFuturo__c;

            if ((quoteDesynchronized && !currentQuote.PagamentoFuturo__c) || (quoteFuturePaymentChangedToFalse && !currentQuote.Sincronizado__c))
                opportunityIds.add(currentQuote.OpportunityId);
        }

        List<OpportunityLineItem> opportunityProductsToDelete = OpportunityLineItemSelector.selectByOpportunityId(opportunityIds);

        if (!opportunityProductsToDelete.isEmpty()) {
            delete opportunityProductsToDelete;
        }

        OpportunityLineItemService.insertOrUpdateOpportunityLineItemsFromQuote(
            new List<OpportunityLineItem>(),
            QuoteLineItemSelector.selectByOpportunityIdAndSynchronizedOrFuturePayment(opportunityIds, true, true),
            opportunityIds
        );
        System.debug(' O deleteRemovedLineItemsAndUpdateOpportunityProducts() da QuoteService chamou o OpportunityLineItemService.insertOrUpdateOpportunityLineItemsFromQuote com esses parâmetros: ( new List<OpportunityLineItem>' +  ' , ' + QuoteLineItemSelector.selectByOpportunityIdAndSynchronizedOrFuturePayment(opportunityIds, true, true) + ' , ' + opportunityIds + ')');

    }

    @InvocableMethod(label='Sincronizar cotação com oportunidade' description='Método criado para sincronizar a cotação com a oportunidade vinculada a ela')
    public static void syncQuoteWithOpportunity(List<Quote> flowQuotes) {
        if (flowQuotes.isEmpty() || flowQuotes.get(0).PagamentoFuturo__c)
            return;

        Set<Id> quoteIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();

        for (Quote currentQuote : flowQuotes) {
            quoteIds.add(currentQuote.Id);
            opportunityIds.add(currentQuote.OpportunityId);
        }

        OpportunityLineItemService.insertOrUpdateOpportunityLineItemsFromQuote(
            OpportunityLineItemSelector.selectByOpportunityId(opportunityIds),
            QuoteLineItemSelector.selectByQuoteId(quoteIds),
            opportunityIds
        );
    }

    private static Set<Id> populateOppIdsSetWithQuoteOpportunity(List<Quote> quotesToProcess) {
        Set<Id> opportunityIds = new Set<Id>();

        for (Quote currentQuote : quotesToProcess) {
            opportunityIds.add(currentQuote.OpportunityId);
        }

        return opportunityIds;
    }

    public static void nullFieldCanceledQuote(Map<Id, Quote> quoteMap) {
        List<QuoteLineItem> quoteLineItemList = new List<QuoteLineItem>();
        quoteLineItemList = [SELECT Id, QuoteId, UnitPrice FROM QUOTELINEITEM WHERE QuoteId IN :quoteMap.keySet()];

        List<RelatedListDefinition> quoteLineItemRelatedList = [
            SELECT Id, DurableId, Label, RelatedListName
            FROM RelatedListDefinition
            WHERE ParentEntityDefinitionId = 'Quote' AND RelatedListName = 'QuoteLineItems'
            LIMIT 1
        ];
        //System.debug('O quoteLineItem related list é: ' + quoteLineItemRelatedList);

        for (Quote cot : quoteMap.values()) {
            if (cot.Status == 'Cancelada') {
                cot.Valor_Final__c = null;
                cot.PagamentoFuturo__c = false;
                cot.VendaFutura__c = false;
                cot.DataVendaFutura__c = null;
                cot.DataPagamentoFuturo__c = null;
            }
        }
    }

    public static void syncValorFinalMidia(List<Quote> newQuotes, Map<Id, Quote> oldQuotesMap) {
        try {
            Id opportunityId;

            if (newQuotes != null && !newQuotes.isEmpty()) {
                opportunityId = newQuotes[0].OpportunityId;
            } else if (oldQuotesMap != null && !oldQuotesMap.isEmpty()) {
                opportunityId = oldQuotesMap.values()[0].OpportunityId;
            } else {
                return;
            }

            List<Quote> quotes = [
                SELECT Id, ValorTotalMidia__c, Name
                FROM Quote
                WHERE OpportunityId = :opportunityId AND (PagamentoFuturo__c = TRUE OR Sincronizado__c = TRUE)
            ];

            Decimal valorFinalMidia = 0;
            for (Quote quote : quotes) {
                valorFinalMidia += quote.ValorTotalMidia__c != null ? quote.ValorTotalMidia__c : 0;
                System.debug('Quote Name e ValorTotalMidia__c:' + quote.name + ' | ' + quote.ValorTotalMidia__c);
            }

            Opportunity opportunity = new Opportunity(Id = opportunityId);
            opportunity.ValorFinalMidia__c = valorFinalMidia;
            update opportunity;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception>> e.getMessage: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Exception>> e.getCause: ' + e.getCause());
            System.debug(LoggingLevel.ERROR, 'Exception>> e.getLineNumber: ' + e.getLineNumber());
            System.debug(LoggingLevel.ERROR, 'Exception>> e.getStackTraceString: ' + e.getStackTraceString());
        }
    }

    private static Map<String, QuoteLineItem> createItemMap(List<QuoteLineItem> items) {
        Map<String, QuoteLineItem> itemMap = new Map<String, QuoteLineItem>();
        for (QuoteLineItem qli : items) {
            itemMap.put(qli.Product2Id + '_' + qli.PricebookEntryId + '_' + qli.UnitPrice, qli);
        }
        return itemMap;
    }
}