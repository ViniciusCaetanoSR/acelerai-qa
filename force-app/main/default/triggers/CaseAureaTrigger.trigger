trigger CaseAureaTrigger on Case (after update, after insert, Before insert, Before update) {

    if (Trigger.isAfter) {
        
        List<Id> caseIds = new List<Id>();
        System.debug('caseIds na Trigger é:' + caseIds);

        for (Case caso : Trigger.new) {
            caseIds.add(caso.Id);
            
        }

        if(!caseIds.isEmpty()){
            IntegrationAureaService.buscarEnviarDados(caseIds);
            System.debug('[CaseAureaTrigger] o caso é: ' + Trigger.new[0]);
        } 

        // if(caseIds.size() > 0){            
        //  IntegrationAureaService.buscarEnviarDados(caseIds[0]);
        // }
    }
}