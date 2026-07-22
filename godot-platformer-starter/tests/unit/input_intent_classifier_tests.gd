extends RefCounted
const Sample=preload("res://game/core/input/pointer_sample.gd")
const Intent=preload("res://game/core/input/input_intent.gd")
const Classifier=preload("res://game/core/input/input_intent_classifier.gd")
func run(config)->Array[String]:
	var failures:Array[String]=[]
	_assert(_flick(config,Vector2(.15,.75),Vector2(.80,.75),false)==Intent.Kind.DASH_REQUEST,"M1 horizontal flick",failures)
	_assert(_flick(config,Vector2(.5,.82),Vector2(.5,.15),false)==Intent.Kind.JUMP_REQUEST,"M1 upward flick",failures)
	_assert(_flick(config,Vector2(.5,.18),Vector2(.5,.82),true)==Intent.Kind.FAST_FALL_REQUEST,"M1 airborne downward flick",failures)
	_assert(_flick(config,Vector2(.5,.18),Vector2(.5,.82),false)==Intent.Kind.MOVE,"M1 grounded downward fallback",failures)
	_assert(_flick(config,Vector2(.2,.7),Vector2(.64,.29),false)==Intent.Kind.MOVE,"M1 diagonal ambiguity fallback",failures)
	_assert(JSON.stringify(_replay(config))==JSON.stringify(_replay(config)),"M1 same trace deterministic",failures)
	return failures
func _flick(config,origin:Vector2,target:Vector2,airborne:bool)->int:
	var classifier:=Classifier.new();classifier.configure(config);classifier.classify(Sample.create(10,origin,Sample.Phase.DOWN),airborne);return classifier.classify(Sample.create(10.08,target,Sample.Phase.MOVE),airborne).kind
func _replay(config)->Array[Dictionary]:
	var classifier:=Classifier.new();classifier.configure(config);var output:Array[Dictionary]=[]
	for sample in [Sample.create(20,Vector2(.2,.75),Sample.Phase.DOWN),Sample.create(20.04,Vector2(.4,.75),Sample.Phase.MOVE),Sample.create(20.09,Vector2(.82,.75),Sample.Phase.MOVE),Sample.create(20.12,Vector2(.84,.75),Sample.Phase.UP)]:output.append(classifier.classify(sample,false).to_dictionary())
	return output
func _assert(condition:bool,message:String,failures:Array[String])->void:if not condition:failures.append(message)
