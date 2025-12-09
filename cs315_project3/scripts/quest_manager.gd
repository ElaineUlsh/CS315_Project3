extends Node

signal quest_accepted(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_updated(quest_id: String, progress: int, goal: int)

var active_quests := {}
var completed_quests := []

class Quest:
	var id: String
	var title: String
	var description: String
	var type: String  # "talk", "plant", "harvest", "deliver"
	var goal: int
	var current_progress: int = 0
	var reward_items: Dictionary = {}
	var target_npc: String = ""
	var target_item: String = ""
	
	func _init(quest_id: String, quest_title: String, quest_desc: String):
		id = quest_id
		title = quest_title
		description = quest_desc

var quest_database := {
	"quest_001": {"title": "Meet the Farmer", "description": "Talk to Farmer John in the village.", "type": "talk", "goal": 1, "reward_items": {"gold": 50}, "target_npc": "Farmer John"},
	"quest_002": {"title": "Plant Corn", "description": "Plant 5 corn seeds in your farm.", "type": "plant", "goal": 5, "reward_items": {"corn_seed": 5}, "target_npc": ""}
}

func create_quest_for_id(quest_id: String) -> Quest:
	if not quest_database.has(quest_id):
		return null
	var q_data = quest_database[quest_id]
	var quest = Quest.new(quest_id, q_data.title, q_data.description)
	quest.type = q_data.type
	quest.goal = q_data.goal
	quest.reward_items = q_data.reward_items
	quest.target_npc = q_data.target_npc
	quest.target_item = q_data.get("target_item", "")
	return quest

func offer_quest(quest_id: String, npc_name: String) -> void:
	var quest = create_quest_for_id(quest_id)
	if quest:
		accept_quest(quest)
		if DialogueManager.dialogue_box:
			DialogueManager.show_message(npc_name, "New Quest: " + quest.title + "\n" + quest.description)

func accept_quest(quest: Quest) -> void:
	active_quests[quest.id] = quest
	emit_signal("quest_accepted", quest.id)
	print("Quest accepted: ", quest.title)

func update_quest_progress(quest_id: String, amount: int = 1) -> void:
	if not active_quests.has(quest_id):
		return
	
	var quest = active_quests[quest_id]
	quest.current_progress += amount
	emit_signal("quest_updated", quest_id, quest.current_progress, quest.goal)
	
	if quest.current_progress >= quest.goal:
		complete_quest(quest_id)

func complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	
	var quest = active_quests[quest_id]
	completed_quests.append(quest_id)
	
	# Give rewards
	for item_name in quest.reward_items.keys():
		var quantity = quest.reward_items[item_name]
		Inventory.add_item(item_name, quantity)
	
	active_quests.erase(quest_id)
	emit_signal("quest_completed", quest_id)
	print("Quest completed: ", quest.title)

func is_quest_active(quest_id: String) -> bool:
	return active_quests.has(quest_id)

func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quests

func get_quest(quest_id: String) -> Quest:
	return active_quests.get(quest_id, null)
