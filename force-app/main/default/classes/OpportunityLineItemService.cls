public with sharing class OpportunityLineItemService {

    private static List<String> stagesToIgnore = new List<String> {
        'Ganho Pagamento Futuro',
        'Ganho',
        'Closed Won',
        'Venda Futura',
        'Negociação Fechada'
    };

    public static OpportunityLineItem createOpportunityLineItem(Opportunity relatedOpportunity, PricebookEntry relatedPricebookEntry, QuoteLineItem quoteLineItem) {
        System.debug(' >> chamou o createOpportunityLineItem 1');     
        return new OpportunityLineItem(
            OpportunityId = relatedOpportunity != null ? relatedOpportunity.Id : quoteLineItem.Quote.OpportunityId, 
            Product2Id = relatedPricebookEntry != null ? relatedPricebookEntry.Product2Id : quoteLineItem.Product2Id, 
            PricebookEntryId = relatedPricebookEntry != null ? relatedPricebookEntry.Id : quoteLineItem.PricebookEntryId,
            Quantity = quoteLineItem == null ? 1 : quoteLineItem.Quantity,
            UnitPrice = relatedPricebookEntry != null ? relatedPricebookEntry.UnitPrice : quoteLineItem.UnitPrice
        );
    }

    public static OpportunityLineItem createOpportunityLineItem (Opportunity relatedOpportunity, PricebookEntry relatedPricebookEntry) {
        System.debug(' >> chamou o createOpportunityLineItem 2');
        return createOpportunityLineItem(relatedOpportunity, relatedPricebookEntry, null);
    }

    public static OpportunityLineItem createOpportunityLineItem(QuoteLineItem quoteLineItem) {
        System.debug(' >> chamou o createOpportunityLineItem 3');
        return createOpportunityLineItem(null, null, quoteLineItem);
    }  

    public static void insertOrUpdateOpportunityLineItemsFromQuote (List<OpportunityLineItem> opportunityProducts, List<QuoteLineItem> quoteProducts, Set<Id> opportunityIds) {
        System.debug(' Chamou o insertOrUpdateOpportunityLineItemsFromQuote() | quoteProducts: ' + quoteProducts);
        System.debug(' Chamou o insertOrUpdateOpportunityLineItemsFromQuote() | opportunityProducts: ' + opportunityProducts);

        Map<String, OpportunityLineItem> opportunityProductsToInsert = new Map<String, OpportunityLineItem> ();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        List<OpportunityLineItem> opportunityProductsToUpdate = new List<OpportunityLineItem>();
        List<String> relatedRecordIdsList = new List<String>();
        
        try{
            Map<String, List<QuoteLineItem>> quoteLineItemMap = populateQuoteLineItemMapWithProductIdAndUnitPriceKey(quoteProducts); 
            System.debug('*********quoteLineItemMap ficou assim: ' +  quoteLineItemMap);

            Map<String, OpportunityLineItem> oppLineItemMap = populateOppLineItemMapWithProductIdAndUnitPriceKey(opportunityProducts);

            for (String quoteLineItemKey : quoteLineItemMap.keySet()) {

                OpportunityLineItem oppLineItemWithKey = oppLineItemMap.get(quoteLineItemKey);
                List<QuoteLineItem> quotesLineItemWithKey = quoteLineItemMap.get(quoteLineItemKey);

                if (oppLineItemWithKey == null && !opportunityProductsToInsert.containsKey(quoteLineItemKey)) {
                    opportunityProductsToInsert.put(quoteLineItemKey, createOpportunityLineItem(quotesLineItemWithKey.get(0)));
                    System.debug(' Chamou o "insertOrUpdateOpportunityLineItemsFromQuote" opportunityProductsToInsert: ' + opportunityProductsToInsert);

                    if (quotesLineItemWithKey.size() > 1) {

                        for (Integer i = 1; i < quotesLineItemWithKey.size(); i++) {
                            opportunityProductsToInsert.get(quoteLineItemKey).Quantity += quotesLineItemWithKey.get(i).Quantity;
                        }
                    }
                } else if (oppLineItemWithKey != null){ //adicionei em 19 fev. 25

                    for (QuoteLineItem quoteLineItem : quotesLineItemWithKey){

                        if (oppLineItemWithKey.Quantity != quoteLineItem.Quantity) {
                            System.debug(' oppLineItemWithKey.Quantity e quoteLineItem.Quantity: ' + oppLineItemWithKey.Quantity + ' | ' + quoteLineItem.Quantity);

                            Decimal oldQuantity = oppLineItemWithKey.Quantity;
                            oppLineItemWithKey.Quantity = quoteLineItem.Quantity;

                            if (!opportunityProductsToUpdate.contains(oppLineItemWithKey)) {
                                opportunityProductsToUpdate.add(oppLineItemWithKey);
                            }
                        } else {
                            Decimal currentQuantity = oppLineItemWithKey.Quantity;

                            System.debug('O valor de quantidade não precisou ser atualizado: valor anterior = ' + currentQuantity + ', valor atual = ' + oppLineItemWithKey.Quantity);
                        }
                    }
                }
                
            }

            if (!opportunityProductsToInsert.values().isEmpty()) {
                for (OpportunityLineItem oli : opportunityProductsToInsert.values()) {
                    System.debug('OpportunityLineItem a ser inserido: ' + oli);
                }

                Set<Id> pbeIds = new Set<Id>();
                for (OpportunityLineItem oli : opportunityProductsToInsert.values()) {
                    pbeIds.add(oli.PricebookEntryId);
                }

                Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>([
                    SELECT Id, IsActive FROM PricebookEntry WHERE Id IN :pbeIds
                ]);

                List<PricebookEntry> pbesToUpdate = new List<PricebookEntry>();

                for (PricebookEntry pbe : pbeMap.values()) {
                    if (!pbe.IsActive) {
                        System.debug(' ** PricebookEntry ' + pbe.Id + ' está inativo - ativando temporariamente');

                        PricebookEntry pb = new PricebookEntry(Id = pbe.Id, IsActive = true);
                        pbesToUpdate.add(pb);
                    }
                }
                
                if (!pbesToUpdate.isEmpty()) {
                    update pbesToUpdate;
                    System.debug(' ** ' + pbesToUpdate.size() + ' PricebookEntries ativados temporariamente');
                }
                try {
                    insert opportunityProductsToInsert.values();                   
                   
                } catch (Exception e) {                    
                    System.debug(' ** Erro ocorrido na inserção/atualização de OppLineItems : ' + e.getMessage());
                }

                if(!pbesToUpdate.isEmpty()){
                    for (PricebookEntry pbe : pbesToUpdate){
                        pbe.IsActive = false;
                        System.debug(' ** Pricebook Entry desativado: ' + pbe);
                    }
                    update pbesToUpdate;
                }
            }
            System.debug('Há oppProducts para inserir? ' + opportunityProductsToInsert);

            if (!opportunityProductsToUpdate.isEmpty()) {
                update opportunityProductsToUpdate;
            }

            List<Opportunity> opportunities = [SELECT Id, StageName FROM Opportunity WHERE Id IN: opportunityIds];


            for (Opportunity currentOpportunity : opportunities) {

                if (stagesToIgnore.contains(currentOpportunity.StageName)) {
                    continue;
                }
                
                currentOpportunity.StageName = 'Em Negociação';

                opportunitiesToUpdate.add(currentOpportunity);
            }

            if (!opportunitiesToUpdate.isEmpty()) {
                System.debug('Tem oportunidades para atualizar?' + opportunitiesToUpdate);
                update opportunitiesToUpdate;
            }
        } catch (Exception e) {

            for (Opportunity opportunity : opportunitiesToUpdate) {
                relatedRecordIdsList.add(opportunity.Id);
            }

            String relatedRecordIdConcat = String.join(relatedRecordIdsList, ',');
            System.debug('Erro ao inserir/atualizar OpportunityLineItem. Mensagem: ' + e.getMessage());
            System.debug('Erro ao inserir/atualizar OpportunityLineItem. StackTrace: ' + e.getStackTraceString());
            
            LoggerUtility.createLogException(e, relatedRecordIdConcat, 'insertOrUpdateOpportunityLineItemsFromQuote');        
        }
    }

    private static Map<String, List<QuoteLineItem>> populateQuoteLineItemMapWithProductIdAndUnitPriceKey (List<QuoteLineItem> quoteProducts) {
        System.debug(' **************populateQuoteLineItemMapWithProductIdAndUnitPriceKey | quoteproducts: ' + quoteProducts);
        
        Map<String, List<QuoteLineItem>> quoteLineItemMap = new Map<String, List<QuoteLineItem>>();

        for (QuoteLineItem quoteLine : quoteProducts) {
            System.debug(' quoteLine.Product2Id :' + quoteLine.Product2Id + ' | quoteLine.UnitPrice: ' + quoteLine.UnitPrice);

            if (!quoteLineItemMap.containsKey(quoteLine.Product2Id + ' - ' + String.valueOf(quoteLine.UnitPrice)))
                quoteLineItemMap.put(quoteLine.Product2Id + ' - ' + String.valueOf(quoteLine.UnitPrice), new List<QuoteLineItem>());
                System.debug(' quoteLine.Product2Id :' + quoteLine.Product2Id + ' | quoteLine.UnitPrice: ' + quoteLine.UnitPrice);

            quoteLineItemMap.get(quoteLine.Product2Id + ' - ' + String.valueOf(quoteLine.UnitPrice)).add(quoteLine);
        }

        return quoteLineItemMap;
    }

    private static Map<String, OpportunityLineItem> populateOppLineItemMapWithProductIdAndUnitPriceKey (List<OpportunityLineItem> opportunityProducts) {
        System.debug(' Chamou o populateOppLineItemMapWithProductIdAndUnitPriceKey()');

        Map<String, OpportunityLineItem> oppLineItemMap = new Map<String, OpportunityLineItem> ();
        
        for (OpportunityLineItem oppLineItem : opportunityProducts) {
            if (!oppLineItemMap.containsKey(oppLineItem.Product2Id + ' - ' + String.valueOf(oppLineItem.UnitPrice))) 
                oppLineItemMap.put(oppLineItem.Product2Id + ' - ' + String.valueOf(oppLineItem.UnitPrice), oppLineItem);
        }

        return oppLineItemMap;
    }
}