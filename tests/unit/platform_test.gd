extends GdUnitTestSuite
## Yandex backend ad logic without a browser (SPEC 14): the reward goes out
## once, only after the video was watched; closing early or an error refuses it.

var yandex: PlatformYandex
var rewards: Array[StringName] = []
var refusals: Array[StringName] = []


func before_test() -> void:
	yandex = auto_free(PlatformYandex.new())
	rewards.clear()
	refusals.clear()
	yandex.rewarded.connect(func(tag: StringName) -> void: rewards.append(tag))
	yandex.rewarded_failed.connect(func(tag: StringName) -> void: refusals.append(tag))
	# As if showRewarded() was called with the SDK up.
	yandex.sdk_ok = true
	yandex._reward_tag = &"double"
	yandex._reward_open = true


func test_watched_video_rewards_once() -> void:
	yandex._on_rewarded(["open"])
	yandex._on_rewarded(["rewarded"])
	yandex._on_rewarded(["close"])
	yandex._on_rewarded(["close"])
	assert_array(rewards).is_equal([&"double"])
	assert_array(refusals).is_empty()


func test_closed_early_refuses() -> void:
	yandex._on_rewarded(["open"])
	yandex._on_rewarded(["close"])
	assert_array(rewards).is_empty()
	assert_array(refusals).is_equal([&"double"])


func test_error_refuses_and_unblocks() -> void:
	yandex._on_rewarded(["error"])
	assert_array(refusals).is_equal([&"double"])
	assert_bool(yandex._reward_open).is_false()


func test_offline_backend_refuses_rewarded() -> void:
	var offline: PlatformYandex = auto_free(PlatformYandex.new())
	offline.show_rewarded(&"double")
	await await_idle_frame()
	# Not connected here: just make sure nothing throws and no ad is "open".
	assert_bool(offline._reward_open).is_false()


func test_language_mapping() -> void:
	yandex._lang = "kk"
	assert_str(yandex.get_lang()).is_equal("ru")
	yandex._lang = "tr"
	assert_str(yandex.get_lang()).is_equal("en")
