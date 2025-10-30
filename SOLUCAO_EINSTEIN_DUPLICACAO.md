# Solução: Evitar Duplicação de Eventos pelo Einstein Activity Capture

## 📋 Problema
Quando eventos são criados no Microsoft Teams/Outlook via integração Salesforce, o **Einstein Activity Capture** sincroniza esses eventos de volta para o Salesforce, criando duplicatas.

## ✅ Solução Implementada

A solução cria os eventos em um **calendário secundário dedicado** chamado "Salesforce" no Teams/Outlook do usuário. O Einstein Activity Capture sincroniza apenas o calendário padrão, portanto eventos neste calendário secundário não serão duplicados.

### Componentes Criados

1. **TeamsCalendarHelper.cls** - Helper para gerenciar o calendário dedicado
2. **TeamsCalendarHelperTest.cls** - Testes unitários
3. Modificações em **TeamsIntegrationService.cls** - Uso do calendário dedicado

### Fluxo da Solução

```
1. Evento criado no Salesforce
   ↓
2. TeamsCalendarHelper.getOrCreateSalesforceCalendar()
   - Verifica se User.TeamsCalendarId__c existe
   - Se não: GET /me/calendars (busca calendário 'Salesforce')
   - Se não encontrado: POST /me/calendars (cria calendário 'Salesforce')
   - Salva calendarId em User.TeamsCalendarId__c
   ↓
3. POST /me/calendars/{calendarId}/events
   - Cria evento no calendário 'Salesforce' (não no padrão)
   ↓
4. Einstein NÃO sincroniza (calendário secundário)
   ✓ Sem duplicação!
```

## 🔧 Configuração Necessária

### 1. Criar Campo Personalizado no User

No Salesforce Setup:
1. **Setup** → **Object Manager** → **User**
2. **Fields & Relationships** → **New**
3. Configure:
   - **Label**: `Teams Calendar Id`
   - **API Name**: `TeamsCalendarId__c`
   - **Data Type**: `Text (255)`
   - **Description**: `ID do calendário dedicado 'Salesforce' no Microsoft Teams/Outlook`

### 2. Permissões e Scopes

Garanta que o token OAuth do usuário tem os scopes:
- ✅ `Calendars.ReadWrite` (delegated)
- ✅ `OnlineMeetings.ReadWrite` (delegated)

### 3. Consentimento do Usuário

Os usuários precisam conceder consentimento novamente se o scope `Calendars.ReadWrite` for novo. Eles podem fazer isso através do fluxo de OAuth existente no sistema.

## 📊 Comportamento Esperado

### Para o Organizador (Owner do Evento)
- ✅ Evento criado no calendário "Salesforce" no Teams/Outlook
- ✅ Evento visível no Outlook/Teams (em calendário secundário)
- ✅ Link de reunião funcional
- ✅ Einstein **NÃO** sincroniza de volta para Salesforce
- ✅ Sem duplicação!

### Para os Participantes
- ✅ Recebem convite normalmente
- ✅ Evento aparece no calendário padrão deles (como convidados)
- ✅ Podem aceitar/recusar normalmente
- ✅ Einstein dos participantes funciona normalmente (se eles tiverem)

## 🧪 Testes

### Testes Unitários
```bash
# Testar helper de calendário
sfdx force:apex:test:run --class-names TeamsCalendarHelperTest --result-format human --synchronous

# Testar integração completa
sfdx force:apex:test:run --class-names TeamsIntegrationServiceTest --result-format human --synchronous

# Testar serviço de eventos
sfdx force:apex:test:run --class-names EventServiceTest --result-format human --synchronous
```

### Teste Manual em Sandbox

1. **Preparação**
   - Deploy das classes e criar campo `User.TeamsCalendarId__c`
   - Usuário com consentimento Teams ativo

2. **Criar Evento**
   - Criar Event no Salesforce via UI
   - Aguardar processamento assíncrono

3. **Validações**
   - ✅ No **Outlook/Teams do organizador**:
     - Evento aparece no calendário "Salesforce" (secundário)
     - Link de reunião está presente
   - ✅ No **Salesforce**:
     - Apenas 1 Event existe (sem duplicação)
     - Campo `TeamsEventId__c` preenchido
     - Campo `TeamsJoinURL__c` preenchido
   - ✅ No **User**:
     - Campo `TeamsCalendarId__c` preenchido
   - ✅ **Participantes**:
     - Receberam convite por email
     - Evento aparece no calendário deles

4. **Aguardar Sync do Einstein**
   - Esperar 15-30 minutos
   - ✅ **Confirmar**: Nenhum evento duplicado foi criado no Salesforce

## 🔍 Debug e Troubleshooting

### Logs a Verificar

```apex
// Logs de criação de calendário
'~~ START > getOrCreateSalesforceCalendar'
'~~ TeamsCalendarId já existe: cal-xxx'
'~~ Calendário Salesforce encontrado: cal-xxx'
'~~ Calendário Salesforce criado: cal-xxx'

// Logs de criação de evento
'~~ START [CREATE TeamsEvent]'
'~~ Usando calendarId: cal-xxx'
'~~ Endpoint para criação: https://graph.microsoft.com/v1.0/me/calendars/cal-xxx/events'
```

### Problemas Comuns

**1. "Não foi possível obter calendarId"**
- Verificar token de acesso válido
- Verificar scope `Calendars.ReadWrite` no consentimento
- Verificar logs HTTP (status 401/403)

**2. "Evento criado mas Einstein ainda duplica"**
- Verificar que evento está realmente no calendário "Salesforce" (não "Calendar")
- Verificar configuração Einstein (pode estar sincronizando todos os calendários - raro)
- Verificar se usuário tem múltiplas mailboxes conectadas

**3. "Participantes não recebem convite"**
- Verificar campo Email dos participantes preenchido
- Verificar logs de montagem de `attendees`
- Verificar response da API do Teams

## 📝 Notas Importantes

1. **Calendário Padrão vs Secundário**
   - O calendário "Salesforce" é secundário
   - Eventos continuam visíveis no Outlook/Teams
   - Einstein sincroniza apenas calendário padrão (default calendar)

2. **Performance**
   - `User.TeamsCalendarId__c` é cacheado para evitar chamadas repetidas
   - Primeira criação faz 2 callouts (GET + POST calendars)
   - Criações subsequentes: apenas 1 callout (POST event)

3. **Compatibilidade**
   - Funciona com Outlook Web, Desktop e Mobile
   - Funciona com Teams Web, Desktop e Mobile
   - Participantes recebem convites normalmente

4. **Migração de Eventos Existentes**
   - Eventos criados antes desta mudança continuam no calendário padrão
   - Novos eventos serão criados no calendário "Salesforce"
   - Não é necessário migrar eventos antigos

## 🚀 Deployment

### Checklist de Deploy

- [ ] Criar campo `User.TeamsCalendarId__c` na org de destino
- [ ] Deploy classes Apex:
  - [ ] `TeamsCalendarHelper.cls`
  - [ ] `TeamsCalendarHelperTest.cls`
  - [ ] `TeamsIntegrationService.cls` (modificado)
  - [ ] `TeamsIntegrationServiceTest.cls` (modificado)
- [ ] Executar testes
- [ ] Teste manual com 1 usuário
- [ ] Monitorar logs por 24h
- [ ] Verificar ausência de duplicação Einstein
- [ ] Deploy para produção

### Query para Monitoramento

```sql
-- Verificar Users com calendarId configurado
SELECT Id, Name, Email, TeamsCalendarId__c, HasTeamsConsent__c
FROM User 
WHERE HasTeamsConsent__c = true 
AND TeamsCalendarId__c != null
ORDER BY CreatedDate DESC

-- Verificar eventos criados recentemente
SELECT Id, Subject, OwnerId, Owner.Name, TeamsEventId__c, 
       TeamsJoinURL__c, ProcessedByTeams__c, CreatedDate
FROM Event 
WHERE CreatedDate = TODAY 
AND ProcessedByTeams__c = true
ORDER BY CreatedDate DESC
```

## 📞 Suporte

Se houver problemas:
1. Verificar logs de debug Apex
2. Verificar Debug Logs do usuário específico
3. Consultar seção "Troubleshooting" acima
4. Revisar configuração Einstein Activity Capture
