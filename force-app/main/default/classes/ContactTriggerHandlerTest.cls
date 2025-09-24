@isTest
public with sharing class ContactTriggerHandlerTest {

    @TestSetup
    static void makeData(){
        Account account = VirtualTestData.createAccount('Conta Teste');
        insert account;        
    }

    //Teste de telefone com o format válido
    @isTest
    private static void onBeforeInsertUpdateFormatarTelefoneValido () {
        Account account = [SELECT Id FROM ACCOUNT Limit 1];
        Contact contato = VirtualTestData.createContact('Contato Teste', account.Id, 'barbara@gmail.com', '+5551985866585');
    
        Test.startTest();
            insert contato;
        Test.stopTest();   

        String phonePattern = '^\\+[0-9]{2}[0-9]{2}[0-9]{8,9}$';
        System.assertEquals(true, Pattern.matches(phonePattern, contato.Phone), 'Telefone não foi formatado corretamente');
    }

    //Teste de telefone com o formato inválido: sem DDD e sem DDI
    @isTest
    private static void onBeforeInsertUpdateFormatarTelefoneSemDDD () {
        Account conta = [SELECT Id FROM ACCOUNT Limit 1];
        Contact contato = VirtualTestData.createContact('Contato Teste', conta.Id, 'barbara@gmail.com', '+5551985866585');    
        insert contato;

        Test.startTest();
            try {
                contato.Phone = '981617944';
                update contato;
            } catch (DmlException e) {
                System.assertEquals('Número sem DDD', e.getDmlMessage(0));
            }
        Test.stopTest();
    }

    //Teste de telefone com o formato do DDD inválido
    @isTest
    private static void onBeforeInsertUpdateFormatarTelefoneDDDerrado () {
        Account conta = [SELECT Id FROM ACCOUNT Limit 1];
        Contact contato = VirtualTestData.createContact('Contato Teste', conta.Id, 'barbara@gmail.com', '20981617944');   
        
        Test.startTest();
            try {
                insert contato;
            } catch (DmlException e) {
                System.assertEquals('DDD Inválido', e.getDmlMessage(0));
            }
        Test.stopTest();
    }
}