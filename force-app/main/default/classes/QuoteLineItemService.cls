public without sharing class QuoteLineItemService {    
    private static Set<Id> quotesWithModifiedItems = new Set<Id>();

    @InvocableMethod(
        label='Clonar produtos da cotação Varejo'
        description='Método que serve para conseguir achar os produtos para clonar corretamente os produtos de cotação'
    )
    public static void populateQuoteLineItemsToClone(List<MediaSalesFlowInputs> mediaSalesFlowValues) {
        if (mediaSalesFlowValues.isEmpty() || mediaSalesFlowValues.get(0).quoteLinesToClone.isEmpty() || mediaSalesFlowValues.get(0).insertedQuotes.isEmpty())
            return;

        Map<Id, List<QuoteLineItem>> quoteLinesToCloneMap = new Map<Id, List<QuoteLineItem>>();

        for (QuoteLineItem currentProduct : mediaSalesFlowValues.get(0).quoteLinesToClone) {
            if (!quoteLinesToCloneMap.containsKey(currentProduct.QuoteId))
                quoteLinesToCloneMap.put(currentProduct.QuoteId, new List<QuoteLineItem>());

            quoteLinesToCloneMap.get(currentProduct.QuoteId).add(currentProduct);
        }

        List<QuoteLineItem> quoteProductsToClone = new List<QuoteLineItem>();

        for (Quote currentQuote : mediaSalesFlowValues.get(0).insertedQuotes) {
            if (String.isBlank(currentQuote.CotacaoClonadaId__c) || !quoteLinesToCloneMap.containsKey(currentQuote.CotacaoClonadaId__c)) {
                System.debug('CotacaoClonadaId__c não encontrado ou acessível: ' + currentQuote.CotacaoClonadaId__c);
                continue;
            }

            List<QuoteLineItem> quoteLinesToClone = quoteLinesToCloneMap.get(currentQuote.CotacaoClonadaId__c);

            if (quoteLinesToClone == null || quoteLinesToClone.isEmpty())
                continue;

            for (QuoteLineItem currentProduct : quoteLinesToClone) {
                QuoteLineItem newClone = currentProduct.clone(false, false, false, false);
                newClone.QuoteId = currentQuote.Id;
                quoteProductsToClone.add(newClone);
            }
        }

        if (!quoteProductsToClone.isEmpty()) {
            try {
                insert quoteProductsToClone;
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, 'Exception>> e.getMessage: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'Exception>>  e.getCause: ' + e.getCause());
                System.debug(LoggingLevel.ERROR, 'Exception>>  e.getLineNumber: ' + e.getLineNumber());
                System.debug(LoggingLevel.ERROR, 'Exception>>  e.getStackTraceString: ' + e.getStackTraceString());
            }
        }
    }

    public class MediaSalesFlowInputs {
        @InvocableVariable(required=true)
        public List<QuoteLineItem> quoteLinesToClone;

        @InvocableVariable(required=true)
        public List<Quote> insertedQuotes;
    }

    public static void detectModifiedQuantities(Map<Id, QuoteLineItem> newMap, Map<Id, QuoteLineItem> oldMap) {
        System.debug('Chamou o detectModifiedQuantities()');    

        for (Id qliId : newMap.keySet()) {
            QuoteLineItem newQLI = newMap.get(qliId);
            QuoteLineItem oldQLI = oldMap.get(qliId);

            if (newQLI != null && oldQLI != null && newQLI.Quantity != oldQLI.Quantity) {
                System.debug('A quantidade está sendo alterada, segundo o detectModifiedQuantities()');    

                quotesWithModifiedItems.add(newQLI.QuoteId);
            }
        }
    }

    public static Boolean wasQuoteModified(Id quoteId) {
        System.debug('retorno: ' + quotesWithModifiedItems.contains(quoteId));    

        return quotesWithModifiedItems.contains(quoteId);
    }
}