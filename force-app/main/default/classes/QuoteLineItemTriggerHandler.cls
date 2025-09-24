public class QuoteLineItemTriggerHandler {
    public void beforeInsert(List<QuoteLineItem> newItems) {
    }

    public void beforeUpdate(List<QuoteLineItem> newItems, Map<Id, QuoteLineItem> oldItemsMap) {
        Map<Id, QuoteLineItem> newMap = new Map<Id, QuoteLineItem>();
        for (QuoteLineItem qli : newItems) {
            newMap.put(qli.Id, qli);
        }
        QuoteLineItemService.detectModifiedQuantities(newMap, oldItemsMap);    
    }

    public void afterInsert(List<QuoteLineItem> newItems) {
        syncValorTotalMidia(newItems, null);
    }

    public void afterUpdate(List<QuoteLineItem> newItems, Map<Id, QuoteLineItem> oldItemsMap) {
        syncValorTotalMidia(newItems, oldItemsMap);
    }

    public void afterDelete(Map<Id, QuoteLineItem> oldItemsMap) {
        syncValorTotalMidia(null, oldItemsMap);
    }

    public void syncValorTotalMidia(List<QuoteLineItem> newItems, Map<Id, QuoteLineItem> oldItemsMap) {
        try {
            Id quoteId;
            
            if (newItems != null && !newItems.isEmpty()) {
                quoteId = newItems[0].QuoteId;  
            } else if (oldItemsMap != null && !oldItemsMap.isEmpty()) {
                quoteId = oldItemsMap.values()[0].QuoteId;  
            } else {
                return; 
            }

            List<QuoteLineItem> mediaItems = [
                SELECT TotalPrice
                FROM QuoteLineItem
                WHERE QuoteId = :quoteId AND ProductType__c = 'Mídia'
            ];

            Decimal totalMidia = 0;
            for (QuoteLineItem item : mediaItems) {
                totalMidia += item.TotalPrice;
            }

            Quote quoteToUpdate = new Quote(Id = quoteId);
            quoteToUpdate.ValorTotalMidia__c = totalMidia;
            update quoteToUpdate;

            System.debug('Total de mídia recalculado: ' + totalMidia);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception>> e.getMessage: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Exception>> e.getCause: ' + e.getCause());
            System.debug(LoggingLevel.ERROR, 'Exception>> e.getLineNumber: ' + e.getLineNumber());
            System.debug(LoggingLevel.ERROR, 'Exception>> e.getStackTraceString: ' + e.getStackTraceString());
        }
    }
}