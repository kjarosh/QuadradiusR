extends Node2D

const LOBBY_SCENE = preload("res://scenes/lobby.tscn")



func _on_login(is_guest, remember_pw, username, password):
	var user_data = {
		"is_guest": is_guest,
		"remember_pw": remember_pw,
		"username": username,
		"password": password
	}
	if is_guest:
		print('GUEST LOGIN NOT SUPPORTED YET')
		return
#	NetworkHandler.create_user('asd', '', null, {}) # DEBUG
#	NetworkHandler.create_user('test', '', null, {}) # DEBUG
	NetworkHandler.authorize_user(username, password, funcref(self, "_cb_login_done"), user_data)


func _cb_login_done(is_authorized, user_data, message: Message):
	print('Login done is_authorized=', is_authorized, ' user_data=', user_data)
	NetworkHandler.rest_api.get_user_me(NetworkHandler.token, funcref(self, "_dbg_print"))  # DEBUG
	if is_authorized:
		_join_lobby()
	else:
		print('Failed to authorize: ', message['result']) # DEBUG
		print('Auto-registering user') # DEBUG
		NetworkHandler.create_user(user_data['username'], user_data['password'], null, {})  # DEBUG
		NetworkHandler.authorize_user(user_data['username'], user_data['password'], funcref(self, "_cb_second_login_done"), user_data)  # DEBUG


func _cb_second_login_done(is_authorized, user_data, message: Message):
	if is_authorized:
		_cb_login_done(true, user_data, message)
	else:
		print('Failed to auto register: ', message['result'])




func _dbg_print(message, data):  # DEBUG
	print('me: ', message, ' + ', data)  # DEBUG


func _join_lobby():
	NetworkHandler.join_lobby(funcref(self, "_cb_lobby_joined"))

func _cb_lobby_joined():
	get_tree().change_scene_to(LOBBY_SCENE)
