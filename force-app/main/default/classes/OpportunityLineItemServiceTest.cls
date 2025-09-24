@isTest
public with sharing class OpportunityLineItemServiceTest {

    @TestSetup
    static void makeData() {
        Account acc = new Account(
            Name = 'Test Account',
            CNPJ__c = '42113212000125',
            BillingStreet = 'Rua das Flores, 123',
            BillingCity = 'São Paulo',
            BillingState = 'SP',
            BillingPostalCode = '01001-000',
            BillingCountry = 'Brasil',
            CompanyName__c = 'Test Account 1'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            Telefone__c = '5551981617948',
            Segmento__c = 'Aplicativos',
            Tipo_de_cliente__c = 'Cliente Final',
            CloseDate = Date.today().addDays(5),
            StageName = 'Qualificação',
            HaveCurrentlyAgency__c = 'Não',
            Ja_foi_anunciante__c = 'Não',
            MonthlyInvestmentMedia_Content__c = 'Não Invisto',
            PaymentLink_sendingDate__c = Date.today(),
            Pol_tica_Comercial__c = '1 mês a mais de direito de imagem',
            QuandoPretendeAnunciar__c = 'Imediatamente',
            SaleType__c = 'Cliente novo',
            //Tipo_de_cliente__c = clientType, 
            Veiculacao__c = 'Mídia On',
            WhatsYourInstagram__c = '@_teste',
            WhatsYourRole__c = 'Gerente',
            StateYourCompany__c = 'AC',
            ClientsObjectiveWithAcelerai__c = 'Campanha Institucional'
        );
        insert opp;

        Product2 product = new Product2(
            Name = 'Test Product',
            Tipo__c = 'Direito de Uso',
            IsActive = true
        );
        insert product;

        Id standardPricebookId = Test.getStandardPricebookId();

        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPricebookEntry;

        Quote qte = new Quote(
            OpportunityId = opp.Id,
            Name = 'New Quote',
            Status = 'AGUARDANDO_ACEITE',
            Pricebook2Id = standardPricebookId 
        );
        insert qte;

        QuoteLineItem qteLI1 = new QuoteLineItem(
            QuoteId = qte.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Product2Id = product.Id,
            Quantity = 2,
            UnitPrice = 1000
        );
        insert qteLI1;

        QuoteLineItem qteLI2 = new QuoteLineItem(
            QuoteId = qte.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Product2Id = product.Id,
            Quantity = 3,
            UnitPrice = 1000
        );
        insert qteLI2;
    }

    /*@isTest
    static void testInsertOrUpdateOpportunityLineItemsFromQuote() {
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        Set<Id> opportunityIds = new Set<Id>{ testOpportunity.Id };

        PricebookEntry testPricebookEntry = [SELECT Id FROM PricebookEntry LIMIT 1];

        List<QuoteLineItem> quoteProducts = [SELECT Id, Quantity, Quote.OpportunityId, UnitPrice, Product2Id, PricebookEntryId FROM QuoteLineItem WHERE Quantity IN (2, 3) LIMIT 2];
        //Quote testQuote = [SELECT Id FROM Quote LIMIT 1];    

        List<OpportunityLineItem> opportunityProducts = new List<OpportunityLineItem>();

        Test.startTest();
        OpportunityLineItemService.insertOrUpdateOpportunityLineItemsFromQuote(opportunityProducts, quoteProducts, opportunityIds);
        Test.stopTest();

        List<OpportunityLineItem> insertedOpportunityLineItems = [
            SELECT Id, Quantity, UnitPrice, OpportunityId
            FROM OpportunityLineItem
            WHERE OpportunityId = :testOpportunity.Id
        ];

        System.assertEquals(1, insertedOpportunityLineItems.size(), 'Deveria ter 1 OpportunityLineItem inserido');
        System.assertEquals(5, insertedOpportunityLineItems[0].Quantity, 'A quantidade deve ser a soma das quantidades dos QuoteLineItems');

        Opportunity updatedOpportunity = [
            SELECT Id, StageName
            FROM Opportunity
            WHERE Id = :testOpportunity.Id
        ];
        System.assertEquals('Em Negociação', updatedOpportunity.StageName, 'O estágio da Opportunity deveria ser "Em Negociação".');
    }

    @isTest
    static void testUpdateExistingOpp(){
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        Set<Id> opportunityIds = new Set<Id>{ testOpportunity.Id };

        PricebookEntry testPricebookEntry = [SELECT Id FROM PricebookEntry LIMIT 1];
        //QuoteLineItem qteLI2 = [SELECT Id, Quantity, Quote.OpportunityId, UnitPrice, Product2Id, PricebookEntryId FROM QuoteLineItem WHERE Quantity = 3 LIMIT 1];
        List<QuoteLineItem> quoteProducts = [SELECT Id, Quantity, Quote.OpportunityId, UnitPrice, Product2Id, PricebookEntryId FROM QuoteLineItem WHERE Quantity IN (2, 3) LIMIT 2];
        System.debug('quoteProducts : ' + quoteProducts);
        List<OpportunityLineItem> opportunityProducts = new List<OpportunityLineItem>();

        OpportunityLineItem existingOpportunityLineItem = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = testPricebookEntry.Id
        );
        insert existingOpportunityLineItem;

        opportunityProducts.add(existingOpportunityLineItem);

        Test.startTest();
        OpportunityLineItemService.insertOrUpdateOpportunityLineItemsFromQuote(opportunityProducts, quoteProducts, opportunityIds);
        Test.stopTest();

        List<OpportunityLineItem> updatedOpportunityLineItems = [
            SELECT Id, Quantity
            FROM OpportunityLineItem
            WHERE Id = :existingOpportunityLineItem.Id
        ];

        System.assertEquals(1.00, updatedOpportunityLineItems[0].Quantity, 'A quantidade do OpportunityLineItem existente deveria ser atualizada.');
    }*/
}