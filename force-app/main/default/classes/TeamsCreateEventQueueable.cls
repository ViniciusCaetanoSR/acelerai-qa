/**
 * Antiga TeamsEventCalloutQueueable
 */
public class TeamsCreateEventQueueable implements Queueable, Database.AllowsCallouts {
    private Id eventId;
    private String accessToken;

    public TeamsCreateEventQueueable(Id evId, String token) {
        this.eventId = evId;
        this.accessToken = token;
    }

    public void execute(QueueableContext qc) {
        System.debug('~~ START > TeamsCreateEventQueueable');
        try{
            Event event = [
                SELECT Id, Subject, OwnerId, StartDateTime, EndDateTime, TeamsEventId__c, TeamsJoinURL__c, TeamsOnlineMeetingId__c, TeamsMeetingId__c, ProcessedByTeams__c FROM Event 
                WHERE Id = :eventId LIMIT 1
            ];
            
            // ✅ VERIFICAÇÃO CRÍTICA - Evita duplicação
            if (String.isNotBlank(event.TeamsEventId__c)) {
                System.debug('~~ SKIP > Evento já possui TeamsEventId: ' + event.TeamsEventId__c);
                return;
            }
            
            // ✅ MARCAR COMO EM PROCESSAMENTO ANTES DA API
            event.ProcessedByTeams__c = true;
            update event;
            
            TeamsIntegrationService.createTeamsEvent(event, accessToken);
        } catch (Exception e){
            System.debug('~~ END [EXCEPTION] > TeamsCreateEventQueueable: '+ e.getMessage());
            
            // ✅ REVERTER ProcessedByTeams__c em caso de erro
            try {
                Event eventToRevert = [SELECT Id FROM Event WHERE Id = :eventId LIMIT 1];
                eventToRevert.ProcessedByTeams__c = false;
                update eventToRevert;
            } catch (Exception ex) {
                System.debug('Erro ao reverter ProcessedByTeams__c: ' + ex.getMessage());
            }
        }
    }
}