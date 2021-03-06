/*
Copyright (c) 2011, salesforce.com, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com, Inc. nor the names of its contributors 
    may be used to endorse or promote products derived from this software 
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
OF THE POSSIBILITY OF SUCH DAMAGE.

*/

public with sharing class BracketsUserMatchJSONObjectHandler {
		
	public static final String matchKey = 'matchId';
	public static final String teamKey = 'teamId';
	public static final String userMatchPredictionKey = 'userPred';
	public static final String userTournamentKey = 'userTour';
	
	public List<Brackets_UserMatchPred__c> matchesPredictionList;
	
	/**
	*	Constructor
	*/
	public BracketsUserMatchJSONObjectHandler(){
		matchesPredictionList = new List<Brackets_UserMatchPred__c>();
	}
	
	/**
	*	Given an string with json, map this to a map of sObject.
	*	
	*	@param jsonString 		a string containing a json array
	*/
	public void processJSON( String jsonString){
		Brackets_UserMatchPred__c userMatchPrediction;
		String userMatchPredId;
		BracketsJSONObject bracketsjsonObjectChild;
		BracketsJSONObject bracketsjsonObject;
		try{
			bracketsjsonObject = new BracketsJSONObject(new BracketsJSONObject.JSONTokener(jsonString));
			for(String key : bracketsjsonObject.keys()){
				bracketsjsonObjectChild = bracketsjsonObject.getValue(key).obj;
				userMatchPrediction = createMatchPredictionSObject(bracketsjsonObjectChild);
				matchesPredictionList.add(userMatchPrediction);
			}
		}
		catch(BracketsJSONObject.JSONException e){
			throw (Exception)e;
		}
	}
	
	private Brackets_UserMatchPred__c createMatchPredictionSObject(BracketsJSONObject bracketsjsonObject){
		Brackets_UserMatchPred__c userMatchPrediction = new Brackets_UserMatchPred__c();
		String teamId = (String)bracketsjsonObject.get(teamKey);
		String matchId = (String)bracketsjsonObject.get(matchKey);
		String userTournamentId = (String)bracketsjsonObject.get(userTournamentKey);
		if(teamId != ''){
			userMatchPrediction.PredictedWinnerBrackets_Team__c = (Id)teamId;
		}
		userMatchPrediction.Brackets_Match__c = (Id)matchId;
		userMatchPrediction.Brackets_UserTournament__c = (Id)userTournamentId;
		return userMatchPrediction;
	}
	
	public static testMethod void testProcessJSON(){
		Brackets_Tournament__c tournament = BracketsTestUtilities.getNewStandardTournament();
		Brackets_Group__c groupp = BracketsTestUtilities.getGroup(tournament.Id);
		Brackets_Team__c teamA = BracketsTestUtilities.createTeam('A-Team');
		Brackets_Team__c teamB = BracketsTestUtilities.createTeam('B-Team');
		
		List<Brackets_Team__c> auxList = new List<Brackets_Team__c>();
		auxList.add( teamA );
		auxList.add( teamB );
		upsert auxList;
		
		Brackets_Round__c round = BracketsTestUtilities.createSimpleRound(tournament);
		Brackets_Match__c match = BracketsTestUtilities.createMatch( teamA,teamB,round, null); 
		Brackets_UserTournament__c userTournament = BracketsTestUtilities.createUserTournament(Userinfo.getUserId(), tournament.Id, groupp.Id);
		String jsonString = '{ "0" : { "matchId" : "'+match.Id+'" ,"userTour" : "'+userTournament.Id+'", "teamId" : "'+teamA.Id+'" , "userPred" : "" }}';
		
		BracketsUserMatchJSONObjectHandler handler = new BracketsUserMatchJSONObjectHandler();
		handler.processJSON(jsonString);
		System.assert(handler.matchesPredictionList.size() == 1,'Should have a user match prediction empty at least.');
		Brackets_UserMatchPred__c prediction = handler.matchesPredictionList.get(0);
		System.assert(	prediction.Brackets_Match__c == match.Id && 
						prediction.Brackets_UserTournament__c == userTournament.Id && 
						prediction.PredictedWinnerBrackets_Team__c == teamA.Id, 'This prediction should have a match '+match.Id+
						' ,an userTournament '+userTournament.Id+' and a predictedWinnerTeam '+ teamA.Id);
	}
	
	public static testMethod void testProcessWrongJSON(){
		String jsonString = ' "0" : { "matchId" : "" ,"userTour" : "", "teamId" : "" , "userPred" : "" }}';
		BracketsUserMatchJSONObjectHandler handler = new BracketsUserMatchJSONObjectHandler();
		try{
			handler.processJSON(jsonString);	
			System.assert(false,'This line shouldn\'t be executed');
		}catch(Exception e){
			System.assert(true,'An error should happen when parsing the JSON.');
		}
					
	}
}