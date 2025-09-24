public class KobiIntegration {

    @InvocableMethod(label='Kobi Integration' description='Class responsible for calling the Kobi Integration')
    public static void callKobiIntegration(List<Lead> leadsList) {

        if (leadsList == null || leadsList.isEmpty()) {
            System.debug('Nenhum lead encontrado');
            return;
        }

        List<User> user = [SELECT Id, Alias FROM USER
        WHERE Alias = 'kobi'
        LIMIT 1];

        if (!user.isEmpty()){
            try {

                List<Lead> kobiLeads = new List<Lead>();

                for (Lead lead : leadsList){ 
                    if (lead.OwnerId == user[0].Id) {
                        System.debug('Owner Id: ' + lead.OwnerId);
                        System.debug('User Id: ' + user[0].Id);

                        kobiLeads.add(lead);
                    }
                }

                if (!kobiLeads.isEmpty()){
                    IntegrationService.sendDataKobiWrapper(kobiLeads);
                }
                
            } catch (Exception e){
                System.debug('Erro ao enviar os dados para a Kobi: ' + e.getMessage());
                return;
            }
        } else {
            System.debug('Usuário Kobi não foi encontrado.');
        }
        
    }
}