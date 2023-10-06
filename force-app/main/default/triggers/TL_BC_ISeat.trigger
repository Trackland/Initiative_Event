trigger TL_BC_ISeat on InitiativeSeat__c (after insert) {
  TL_BC_ISeat.triggerISeat(Trigger.new, Trigger.oldMap);
}