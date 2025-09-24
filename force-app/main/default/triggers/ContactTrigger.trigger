trigger ContactTrigger on Contact (before insert, before update) {

    if (Trigger.isBefore) {

        if (Trigger.isInsert)
            ContactTriggerHandler.onBeforeInsert(Trigger.newMap, Trigger.oldMap, Trigger.new, Trigger.old);

        if (Trigger.isUpdate)
            ContactTriggerHandler.onBeforeUpdate(Trigger.newMap, Trigger.oldMap, Trigger.new, Trigger.old);

    }
}