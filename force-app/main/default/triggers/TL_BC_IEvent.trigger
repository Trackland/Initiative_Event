trigger TL_BC_IEvent on InitiativeEvent__c (before delete) {
  for (InitiativeEvent__c i : Trigger.old) TL_BC_IEvent_Actions.deleteGoogleEvent(i.GoogleEventId__c, i.GoogleCalendarId__c);
}