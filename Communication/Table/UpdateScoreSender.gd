extends Node

#
# Broadcasts changes in any GameScore via the CommunicationServer.
#


func _ready():
	GameSystem.connect("score_changed", self, "_on_score_changed")


func _on_score_changed(score: GameScore):
	send_score_value(score.id, score.get_value())


func send_score_value(score_id, value):
	var message = {
		"keyword": "SCORE_UPDATE",
		"score_id": score_id,
		"value": value
	}
	
	CommunicationServer.broadcast(message)
