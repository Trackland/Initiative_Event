// Initiative__c init = [SELECT Id, ActiveMinimumToContinue__c, Day__c, Repeats__c, Frequency__c, MaxSeats__c, AddThreshhold__c, InactiveParticipants__c, Duration__c, StartTime__c, DaysToPause__c, EventCount__c, CurrentEvent__c, UseActiveMinimums__c, ActiveMinimumToStart__c, ActiveParticipants__c FROM Initiative__c WHERE Id = 'a07Hs0000185BURIA2'];
// InitiativeEvent__c initEvent  = [SELECT Id, MaxSeats__c, Seats__c, Initiative__c FROM InitiativeEvent__c WHERE Initiative__c = 'a07Hs0000185BURIA2'];
// TL_BC_AutomatedProcess.addInitiativeSeats(initEvent);
// TL_BC_AutomatedProcess.scheduleNextEvent(init);
// TL_BC_AutomatedProcess.checkCIH(new List<Ifnitiative__c>{init});
// GoogleCalendar__c calendar = [SELECT Id, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, Default__c, Description__c, GoogleId__c FROM GoogleCalendar__c WHERE Default__c = true];
// TL_BC_IEvent_Actions.updateAttendance(calendar.Id);

// TL_BC_ScheduledProcess.init('a07Hs0000185KFFIA2'); 
update GenericConnectorController.doRefreshTokenStatic();
// ya29.a0AfB_byBZ_T7rpptZqjXCg-ki-Z6BBFHrkYoBFk6ah1r2cxkzUk9gNSd29nZ4q_LIqVjOYGB1bro9ARKSZ6CVzk2nhMaQrE3vlexNK0L23NZ0Fzft9IwIp2sxqRoV1ZrXSlusKgETNIEUQpqC7PFbhRIRRWUk-DD6OcpdaCgYKAScSARMSFQGOcNnCIIw7S9D_TNuH4EIQ8xsM6Q0171
// 1//06mzZfbZtFZFrCgYIARAAGAYSNwF-L9IrOHP0h_TI71vlQpRVXM9IY9Z2dvlJIUXkNwRu8C9tT6OIWDF4wRQ4oyvApVcV8GKJjMY