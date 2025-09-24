global class LeadBatchDelete implements Database.Batchable<SObject> {

    // Definir a consulta que retorna os leads a serem deletados
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id FROM Lead WHERE Status != 'Histórico'
        ]);
    }

    // Processa cada lote de registros
    global void execute(Database.BatchableContext bc, List<Lead> scope) {
        try {
            // Deleta o lote de leads
            delete scope;
        } catch (Exception e) {
            System.debug('Erro ao deletar leads: ' + e.getMessage());
        }
    }

    // Finalização após o processamento de todos os lotes
    global void finish(Database.BatchableContext bc) {
        System.debug('Leads deletados com sucesso.');
    }
}