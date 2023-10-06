// Initiative__c init = [SELECT Id, ActiveMinimumToContinue__c, Day__c, Repeats__c, Frequency__c, MaxSeats__c, AddThreshhold__c, InactiveParticipants__c, Duration__c, StartTime__c, DaysToPause__c, EventCount__c, CurrentEvent__c, UseActiveMinimums__c, ActiveMinimumToStart__c, ActiveParticipants__c FROM Initiative__c WHERE Id = 'a07Hs0000185BURIA2'];
// InitiativeEvent__c initEvent  = [SELECT Id, MaxSeats__c, Seats__c, Initiative__c, GoogleCalendarId__c, GoogleEventId__c FROM InitiativeEvent__c WHERE Initiative__c = 'a07Hs0000185KFFIA2'];
// TL_BC_AutomatedProcess.addInitiativeSeats(initEvent);
// TL_BC_AutomatedProcess.scheduleNextEvent(init);
// TL_BC_AutomatedProcess.checkCIH(new List<Ifnitiative__c>{init});
// GoogleCalendar__c calendar = [SELECT Id, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, Default__c, Description__c, GoogleId__c FROM GoogleCalendar__c WHERE Default__c = true];
// TL_BC_IEvent_Actions.updateAttendance(calendar.Id);

TL_BC_ScheduledProcess.init('a07Hs0000185KFFIA2'); 