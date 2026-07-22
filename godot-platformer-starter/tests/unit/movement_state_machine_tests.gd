extends RefCounted
const Command=preload("res://game/core/movement/movement_command.gd")
const Contacts=preload("res://game/core/movement/movement_contacts.gd")
const Machine=preload("res://game/core/movement/movement_state_machine.gd")
const Snapshot=preload("res://game/core/movement/movement_snapshot.gd")
const TICK:=1.0/60.0
func run(config)->Array[String]:
	var f:Array[String]=[];_run(config,f);_coyote(config,f);_jumps(config,f);_buffer(config,f);_dash(config,f);_fall(config,f);_wall(config,f);_ceiling(config,f);return f
func _machine(config):var m:=Machine.new();m.configure(config);return m
func _run(c,f):
	var m=_machine(c);var s
	for tick in 20:s=m.step(Command.create(1),Contacts.create(true),TICK)
	_assert(s.velocity.x>0 and s.velocity.x<=c.max_run_speed and s.state==Snapshot.State.RUN,"M2 run limit/state",f)
func _coyote(c,f):
	var m=_machine(c);m.step(Command.create(),Contacts.create(true),TICK);var s
	for tick in 7:s=m.step(Command.create(0,tick==6),Contacts.create(false),TICK)
	_assert("jump_started" in s.events,"M2 seven-tick coyote",f)
	var late=_machine(c);late.step(Command.create(),Contacts.create(true),TICK)
	for tick in 8:s=late.step(Command.create(0,tick==7),Contacts.create(false),TICK)
	_assert("jump_started" not in s.events,"M2 coyote expires",f)
func _jumps(c,f):
	var m=_machine(c);var a=m.step(Command.create(0,true),Contacts.create(true),TICK);var b=m.step(Command.create(0,true),Contacts.create(false),TICK);var d=m.step(Command.create(0,true),Contacts.create(false),TICK)
	_assert("jump_started" in a.events and "double_jump_started" in b.events and "double_jump_started" not in d.events,"M2 double jump cap",f)
func _buffer(c,f):
	var m=_machine(c);m.step(Command.create(0,true),Contacts.create(true),TICK);m.step(Command.create(0,true),Contacts.create(false),TICK);m.step(Command.create(0,true),Contacts.create(false),TICK);var s=m.step(Command.create(),Contacts.create(true),TICK);_assert("jump_started" in s.events,"M2 jump buffer",f)
func _dash(c,f):
	var m=_machine(c);var a=m.step(Command.create(1,false,true,1),Contacts.create(true),TICK);var b=m.step(Command.create(-1),Contacts.create(true),TICK);_assert("dash_started" in a.events and b.state==Snapshot.State.DASH and b.velocity.x>0 and b.invulnerable,"M2 committed dash",f)
func _fall(c,f):
	var m=_machine(c);m.step(Command.create(0,true),Contacts.create(true),TICK);var a=m.step(Command.create(0,false,false,0,true),Contacts.create(false),TICK);var b=m.step(Command.create(),Contacts.create(true),TICK);_assert(a.state==Snapshot.State.FAST_FALL and "hard_landing" in b.events and b.gameplay_events.size()==1,"M2 fast-fall landing context",f)
func _wall(c,f):
	var m=_machine(c);var s
	for tick in 4:s=m.step(Command.create(1),Contacts.create(false,tick==3,Vector2.LEFT),TICK)
	_assert(s.state==Snapshot.State.WALL_SLIDE and s.velocity.y<=c.wall_slide_max_speed,"M2 wall slide",f)
func _ceiling(c,f):
	var m=_machine(c);m.step(Command.create(0,true),Contacts.create(true),TICK);var s=m.step(Command.create(),Contacts.create(false,false,Vector2.ZERO,true),TICK);_assert("ceiling_contact" in s.events and s.velocity.y>=0,"M3 ceiling contact",f)
func _assert(condition:bool,message:String,failures:Array[String])->void:if not condition:failures.append(message)
